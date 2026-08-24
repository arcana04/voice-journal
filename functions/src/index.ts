import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";

initializeApp();

const openAiApiKey = defineSecret("OPENAI_API_KEY");

// TODO: 本番リリース前に元の値（5程度）へ戻す。テスト中の上限詰まりを避けるため一時的に緩めている。
const FREE_DAILY_LIMIT = 100;

function buildSystemPrompt(todayJst: string, weekdayJst: string): string {
  return `あなたは日本語の日常会話・独り言を解析して構造化データに変換するAIアシスタントです。

【入力テキストの特性】
入力されるテキストは音声認識結果であり、日本語特有の言い淀み（「えっと」「あー」）、曖昧な文末（「〜かも」「〜じゃん」）、話の脱線、主語の省略が含まれます。

【今日の日付】
${todayJst}（${weekdayJst}曜日、日本時間）。期限の相対表現はこの日付を基準に解釈してください。

【分類ルール（3分類）】
1. フィラー（意味のない雑音・言い淀み）を除去してください。
2. 文脈から主語や時系列を補完してください。
3. 発言は以下の3種類のいずれかに分類してください。
   - 【tasks（ToDo）】: 「確定した行動」。話者が実際にやる・やらないといけないと言っていること。
   - 【notes category="アイデア"】: 未確定な思いつき・疑問・アイデア・検討事項。
   - 【notes category="感情ログ"】: 感情・気分・愚痴・モヤモヤ・出来事の振り返りなど、行動を伴わない心情の吐露。
4. 話が脱線している場合は、文脈ごとに適切に分類を分けてください。

【期限の自動推測】
tasksに期限らしき表現（「明日」「来週月曜まで」「今月中」など）があれば、上記の今日の日付を基準に実際の日付（YYYY-MM-DD）を計算し due_date に入れてください。日付を一意に決められない・期限の言及がない場合は due_date は null にしてください。due_hint には元の言い回しをそのまま短く残してください。

【労いメッセージ】
分類の結果、category="感情ログ" のnoteが1件以上ある場合のみ、その内容に寄り添う一言（10〜40文字程度、説教や解決策の押し付けにならない労いの言葉）を comfort_message に入れてください。感情ログが無い場合は comfort_message は null にしてください。

【出力フォーマット】
必ず以下のJSON形式のみで出力してください（余計な解説文は含めないでください）：

{
  "summary": "全体の1行要約",
  "tasks": [
    {"title": "タスク内容", "due_hint": "期限の元の言い回し（なければnull）", "due_date": "YYYY-MM-DD（推測できなければnull）"}
  ],
  "notes": [
    {"category": "アイデア または 感情ログ", "content": "整理された文章"}
  ],
  "comfort_message": "感情ログがある場合のみ短い労いの言葉。なければnull"
}`;
}

function jstDateString(date: Date = new Date()): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Tokyo",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(date);
}

function jstWeekdayString(date: Date = new Date()): string {
  return new Intl.DateTimeFormat("ja-JP", {
    timeZone: "Asia/Tokyo",
    weekday: "short",
  }).format(date);
}

async function consumeDailyQuota(uid: string): Promise<void> {
  const db = getFirestore();
  const usageRef = db.collection("usage").doc(`${uid}_${jstDateString()}`);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(usageRef);
    const count = (snap.data()?.count as number | undefined) ?? 0;

    if (count >= FREE_DAILY_LIMIT) {
      throw new HttpsError(
        "resource-exhausted",
        `本日の無料利用回数（${FREE_DAILY_LIMIT}回）の上限に達しました。また明日お試しください。`
      );
    }

    tx.set(
      usageRef,
      { count: count + 1, updatedAt: FieldValue.serverTimestamp() },
      { merge: true }
    );
  });
}

async function transcribe(apiKey: string, audioBuffer: Buffer, mimeType: string): Promise<string> {
  const form = new FormData();
  form.append("file", new Blob([new Uint8Array(audioBuffer)], { type: mimeType }), "audio.m4a");
  form.append("model", "whisper-1");
  form.append("language", "ja");

  const response = await fetch("https://api.openai.com/v1/audio/transcriptions", {
    method: "POST",
    headers: { Authorization: `Bearer ${apiKey}` },
    body: form,
  });

  if (!response.ok) {
    const body = await response.text();
    throw new HttpsError("internal", `文字起こしに失敗しました: ${body}`);
  }

  const data = (await response.json()) as { text: string };
  return data.text;
}

interface StructuredResult {
  summary: string;
  tasks: { title: string; due_hint: string | null; due_date: string | null }[];
  notes: { category: string; content: string }[];
  comfort_message: string | null;
}

async function structure(apiKey: string, transcript: string): Promise<StructuredResult> {
  const now = new Date();
  const systemPrompt = buildSystemPrompt(jstDateString(now), jstWeekdayString(now));

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: transcript },
      ],
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new HttpsError("internal", `AI解析に失敗しました: ${body}`);
  }

  const data = (await response.json()) as {
    choices: { message: { content: string } }[];
  };
  return JSON.parse(data.choices[0].message.content) as StructuredResult;
}

interface ProcessVoiceMemoRequest {
  audioBase64: string;
  mimeType?: string;
}

export const processVoiceMemo = onCall(
  { secrets: [openAiApiKey], timeoutSeconds: 120, memory: "512MiB" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "認証が必要です。");
    }

    const { audioBase64, mimeType } = (request.data ?? {}) as ProcessVoiceMemoRequest;
    if (!audioBase64) {
      throw new HttpsError("invalid-argument", "音声データがありません。");
    }

    try {
      await consumeDailyQuota(uid);

      const apiKey = openAiApiKey.value();
      const audioBuffer = Buffer.from(audioBase64, "base64");

      const transcript = await transcribe(apiKey, audioBuffer, mimeType ?? "audio/m4a");
      if (!transcript.trim()) {
        throw new HttpsError("invalid-argument", "音声を認識できませんでした。");
      }

      const structured = await structure(apiKey, transcript);
      const isoDate = /^\d{4}-\d{2}-\d{2}$/;

      return {
        summary: structured.summary ?? "",
        tasks: (structured.tasks ?? []).map((task) => ({
          title: task.title,
          due_hint: task.due_hint ?? null,
          due_date: task.due_date && isoDate.test(task.due_date) ? task.due_date : null,
        })),
        notes: structured.notes ?? [],
        comfort_message: structured.comfort_message ?? null,
      };
    } catch (err) {
      if (err instanceof HttpsError) {
        throw err;
      }
      logger.error("processVoiceMemo unexpected error", err);
      const message = err instanceof Error ? err.message : String(err);
      throw new HttpsError("internal", `処理中に予期しないエラーが発生しました: ${message}`);
    }
  }
);
