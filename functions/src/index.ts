import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";

import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import ffmpegPath from "ffmpeg-static";

initializeApp();

const execFileAsync = promisify(execFile);

const openAiApiKey = defineSecret("OPENAI_API_KEY");

const FREE_DAILY_LIMIT = 10;

type SummaryLevel = "preserve" | "standard" | "compact";

function normalizeSummaryLevel(value: unknown): SummaryLevel {
  if (value === "standard" || value === "compact" || value === "preserve") {
    return value;
  }
  return "preserve";
}

/** クライアント（Flutterアプリ）の表示言語。UIの多言語対応に合わせてサーバー側の
 * 音声認識言語・AIプロンプト・エラーメッセージを切り替えるために使う。 */
type Locale = "ja" | "en";

function normalizeLocale(value: unknown): Locale {
  return value === "en" ? "en" : "ja";
}

/** ユーザー向けエラーメッセージ。localeごとに文面を分ける。 */
const MESSAGES: Record<
  Locale,
  {
    authRequired: string;
    noAudio: string;
    noText: string;
    transcriptionEmpty: string;
    quotaExceeded: (limit: number) => string;
    transcriptionFailed: (body: string) => string;
    analysisFailed: (body: string) => string;
    unexpectedError: (message: string) => string;
  }
> = {
  ja: {
    authRequired: "認証が必要です。",
    noAudio: "音声データがありません。",
    noText: "テキストがありません。",
    transcriptionEmpty: "音声を認識できませんでした。",
    quotaExceeded: (limit) =>
      `本日の無料利用回数（${limit}回）の上限に達しました。また明日お試しください。`,
    transcriptionFailed: (body) => `文字起こしに失敗しました: ${body}`,
    analysisFailed: (body) => `AI解析に失敗しました: ${body}`,
    unexpectedError: (message) => `処理中に予期しないエラーが発生しました: ${message}`,
  },
  en: {
    authRequired: "Authentication is required.",
    noAudio: "No audio data was provided.",
    noText: "No text was provided.",
    transcriptionEmpty: "Couldn't recognize any speech in the recording.",
    quotaExceeded: (limit) =>
      `You've reached today's free limit of ${limit} recordings. Please try again tomorrow.`,
    transcriptionFailed: (body) => `Transcription failed: ${body}`,
    analysisFailed: (body) => `AI analysis failed: ${body}`,
    unexpectedError: (message) =>
      `An unexpected error occurred while processing: ${message}`,
  },
};

function buildNotesStyleSection(level: SummaryLevel): string {
  switch (level) {
    case "compact":
      return `【notesの本文（content）の書き方：超コンパクト】
tasksと同様に、内容を要点だけに絞って短くまとめてください。
- 言い淀みや重複表現だけでなく、瑣末な描写や繰り返しの説明も削って構いません。
- 1つのnoteにつき1〜2文程度を目安に、核心の出来事・思いつき・感情だけを簡潔にまとめてください。
- 一人称視点（「〜と感じた」「〜だった」など）は保ってください。`;
    case "standard":
      return `【notesの本文（content）の書き方：標準】
tasksほど短くはせず、日記らしい自然な文章の長さは保ちつつ、冗長な繰り返しや脱線は整理してください。
- 感情の手がかりになる言葉、固有名詞、印象的な言い回しはできるだけ残してください。ただし発言をそのまま書き起こす必要はなく、読みやすいよう軽く整えて構いません。
- 客観的な三人称ではなく、話者自身の一人称視点（「〜と感じた」「〜だった」など）で自然な日記の文体にしてください。
- 感情が動いた場面では、不自然にならない範囲で「！」も使ってください。`;
    case "preserve":
    default:
      return `【notesの本文（content）の書き方：原型重視】
tasksとは違い、notesは要約・圧縮しないでください。
- 話者が語った「生の感情」「独特な言い回し」「情景の描写」「具体的な固有名詞」は、できる限り削除せずそのまま残してください。要点だけを抜き出した短い要約にはしないでください。
- 取り除いてよいのは言い淀み（「えっと」「あー」など）と同じ内容の重複表現だけです。それ以外は発言の内容・順序・粒度を保ったまま、読みやすい文章に整える（整文する）程度にとどめてください。
- 客観的な三人称の説明文にはせず、話者自身の一人称視点（「〜と感じた」「〜だった」「〜かもしれない」など）で、自然な日記の文体にリライトしてください。
- 感情が高ぶった場面や驚き・嬉しさなどは、不自然にならない範囲で「！」も使い、実際に喋っていたときの自然なトーンを残してください。`;
  }
}

function buildNotesStyleSectionEn(level: SummaryLevel): string {
  switch (level) {
    case "compact":
      return `[How to write the note body ("content"): very compact]
Just like tasks, boil this down to only the essentials.
- You may cut not just filler and repeated phrases, but also minor descriptions and redundant explanations.
- Aim for about 1-2 sentences per note, covering only the core event, idea, or feeling.
- Keep the first-person point of view ("I felt...", "It was...").`;
    case "standard":
      return `[How to write the note body ("content"): standard]
Don't shorten it as much as a task, but keep a natural diary-entry length while tidying up redundant repetition or tangents.
- Keep emotional cues, names, and memorable phrasing where you can. You don't need to transcribe verbatim — light editing for readability is fine.
- Write in the speaker's own first-person voice ("I felt...", "It was...."), not an objective third-person description.
- Where the emotion is high, it's fine to use "!" if it doesn't feel forced.`;
    case "preserve":
    default:
      return `[How to write the note body ("content"): preserve original]
Unlike tasks, do not summarize or compress notes.
- Keep the speaker's raw emotion, distinctive phrasing, scene description, and specific names as intact as possible. Do not reduce it to a short summary of just the key points.
- The only things you may remove are filler words (like "um", "uh") and exact repeated phrases. Otherwise, keep the content, order, and level of detail, only lightly tidying the prose for readability.
- Rewrite it in the speaker's own first-person voice ("I felt...", "It was...", "Maybe I..."), not an objective third-person account.
- Where there's excitement, surprise, or joy, it's fine to use "!" to keep the natural tone of how it was actually said.`;
  }
}

function buildSystemPrompt(
  todayJst: string,
  weekdayJst: string,
  summaryLevel: SummaryLevel,
  glossary?: string
): string {
  const glossarySection = glossary
    ? `\n\n【固有名詞・用語の表記】\n入力テキストは音声認識結果のため、以下の固有名詞・用語が誤った表記で紛れ込んでいる場合があります。文脈上それらを指していると判断できる場合は、正しい表記に直してから処理してください。\n${glossary}`
    : "";

  return `あなたは日本語の日常会話・独り言を解析して構造化データに変換するAIアシスタントです。${glossarySection}

【入力テキストの特性】
入力されるテキストは音声認識結果であり、日本語特有の言い淀み（「えっと」「あー」）、曖昧な文末（「〜かも」「〜じゃん」）、話の脱線、主語の省略が含まれます。

【今日の日付】
${todayJst}（${weekdayJst}曜日、日本時間）。期限の相対表現はこの日付を基準に解釈してください。

【分類ルール（3分類）】
1. フィラー（「えっと」「あー」等の言い淀み）や同じ内容の重複表現を除去してください。
2. tasksは文脈から主語や時系列を補完し、簡潔な行動内容に要約してください。
3. 発言は以下の3種類のいずれかに分類してください。
   - 【tasks（ToDo）】: 「確定した行動」。話者が実際にやる・やらないといけないと言っていること。
   - 【notes category="アイデア"】: 未確定な思いつき・疑問・アイデア・検討事項。
   - 【notes category="感情ログ"】: 感情・気分・愚痴・モヤモヤ・出来事の振り返りなど、行動を伴わない心情の吐露。
4. 話が脱線している場合は、文脈ごとに適切に分類を分けてください。

${buildNotesStyleSection(summaryLevel)}

【期限の自動推測】
tasksに期限らしき表現（「明日」「来週月曜まで」「今月中」など）があれば、上記の今日の日付を基準に実際の日付（YYYY-MM-DD）を計算し due_date に入れてください。日付を一意に決められない・期限の言及がない場合は due_date は null にしてください。due_hint には元の言い回しをそのまま短く残してください。

【時刻付きリマインダー】
tasksの中に「15時に」「明日の朝9時」「夜7時に病院」のように"時刻"まで明言されているものがあれば、上記の今日の日付と日本時間を基準に実際の日時を計算し、reminder_at に "YYYY-MM-DDTHH:mm:00"（24時間表記、秒は00固定）の形式で入れてください。日付の指定がなく時刻のみの場合は今日の日付を使い、その時刻がすでに過ぎていれば翌日の日付にしてください。時刻の明言が無い場合（日付や「午前中」「そのうち」のような曖昧な言い回ししか無い場合）は reminder_at は null にしてください。
さらに「10時から17時まで」「15時〜16時半」のように終了時刻まで明言されている場合は、同じ日付を基準に reminder_end_at にも同じ形式で終了日時を入れてください。終了時刻が翌日にまたがる場合（例:「夜22時から翌朝6時まで」）は日付を1日進めてください。終了時刻の明言が無ければ reminder_end_at は null にしてください。

【労いメッセージ】
分類の結果、category="感情ログ" のnoteが1件以上ある場合のみ、その内容に寄り添う一言（10〜40文字程度、説教や解決策の押し付けにならない労いの言葉）を comfort_message に入れてください。感情ログが無い場合は comfort_message は null にしてください。

【感情タグ】
comfort_messageと同じ条件（category="感情ログ" のnoteが1件以上ある場合のみ）で、その内容から読み取れる最も中心的な感情をひとつだけ選び、emotion に次のいずれかの英語の識別子（この通りのスペルで、翻訳せずに）を入れてください：
fatigue（疲労・くたびれ）, love（愛情・愛おしさ）, anxious（焦り・不安）, excited（ワクワク・期待）, joy（喜び・嬉しさ）, sadness（悲しみ・落ち込み）, anger（怒り・苛立ち）, satisfaction（満足・達成感）, neutral（それ以外・判別しづらい穏やかな心情）。
感情ログが無い場合は emotion は null にしてください。

【noteのタイトル】
各noteについて、日記の見出しになるような短いタイトル（8〜16文字程度、体言止め推奨）を title に入れてください。例:「花火大会が楽しかった」「新しいカフェのアイデア」。

【出力フォーマット】
必ず以下のJSON形式のみで出力してください（余計な解説文は含めないでください）：

{
  "summary": "全体の1行要約",
  "tasks": [
    {"title": "タスク内容", "due_hint": "期限の元の言い回し（なければnull）", "due_date": "YYYY-MM-DD（推測できなければnull）", "reminder_at": "YYYY-MM-DDTHH:mm:00（時刻の明言が無ければnull）", "reminder_end_at": "YYYY-MM-DDTHH:mm:00（終了時刻の明言が無ければnull）"}
  ],
  "notes": [
    {"category": "アイデア または 感情ログ", "title": "短い見出し", "content": "上記「notesの本文の書き方」に従って一人称でリライトした文章"}
  ],
  "comfort_message": "感情ログがある場合のみ短い労いの言葉。なければnull",
  "emotion": "感情ログがある場合のみ fatigue/love/anxious/excited/joy/sadness/anger/satisfaction/neutral のいずれか。なければnull"
}`;
}

function buildSystemPromptEn(
  today: string,
  weekday: string,
  summaryLevel: SummaryLevel,
  glossary?: string
): string {
  const glossarySection = glossary
    ? `\n\n[Spelling of names and terms]\nThe input text is a speech-to-text transcript, so the following names/terms may appear misspelled. If context makes it clear the speaker meant one of them, correct the spelling before processing.\n${glossary}`
    : "";

  return `You are an AI assistant that analyzes everyday spoken English conversation/monologue and converts it into structured data.${glossarySection}

[Output language — read this first]
The speaker is speaking English, and every text field you write (summary, task title, due_hint, note title, note content, comfort_message) MUST be written in English. Do NOT translate anything into Japanese. The ONLY exception is the note "category" field itself, which is a fixed internal label and must always be the literal Japanese text アイデア or 感情ログ exactly as shown, never translated, never romanized, never written in English — every other field stays in English.

[Nature of the input text]
The input text is a speech-to-text transcript, so it will contain filler words ("um", "uh"), hedged/trailing phrasing ("...I guess", "...or something"), tangents, and dropped subjects.

[Today's date]
${today} (${weekday}, Japan time). Interpret any relative due-date expressions against this date.

[Classification rules (3 categories)]
1. Remove filler words ("um", "uh", etc.) and exact repeated phrases.
2. For tasks, infer the missing subject/timing from context and summarize into a concise action.
3. Classify each utterance into exactly one of these three categories:
   - [tasks (to-do)]: a "confirmed action" — something the speaker says they will do or need to do.
   - [notes category="アイデア"]: an unconfirmed idea, question, thought, or something to consider.
   - [notes category="感情ログ"]: a feeling, mood, complaint, or reflection on something that happened, with no associated action.
4. If the speaker jumps between topics, split them into separate entries classified appropriately.

${buildNotesStyleSectionEn(summaryLevel)}

[Automatic due-date inference]
If a task contains a due-date-like expression ("tomorrow", "by next Monday", "sometime this month", etc.), compute the actual date (YYYY-MM-DD) relative to today's date above and put it in due_date. If the date can't be determined uniquely, or there's no due-date mention at all, set due_date to null. Put a short version of the original phrase in due_hint.

[Timed reminders]
If a task explicitly states a time (e.g. "at 3pm", "tomorrow morning at 9", "7pm at the clinic"), compute the actual date/time relative to today's date and Japan time above, and put it in reminder_at as "YYYY-MM-DDTHH:mm:00" (24-hour time, seconds fixed at 00). If only a time is given with no date, use today's date, and if that time has already passed today, use tomorrow's date instead. If no explicit time is stated (only a date, or a vague phrase like "in the morning" or "sometime"), set reminder_at to null.
If an end time is also explicitly stated (e.g. "from 10am to 5pm", "3pm to 4:30pm"), put that end date/time in reminder_end_at using the same format and date. If the end time crosses into the next day (e.g. "10pm to 6am"), advance the date by one day. If no end time is stated, set reminder_end_at to null.

[Comforting message]
Only if there is at least one note with category="感情ログ", write a short, warm one-liner (about 10-25 words) that acknowledges the feeling without lecturing or pushing a solution, and put it in comfort_message. If there is no 感情ログ note, set comfort_message to null.

[Emotion tag]
Under the same condition as comfort_message (only if there is at least one note with category="感情ログ"), pick the single most central emotion conveyed by that content and put it in emotion as exactly one of these English identifiers (spelled exactly as shown, never translated):
fatigue, love, anxious, excited, joy, sadness, anger, satisfaction, neutral (use neutral for anything calm or ambiguous that doesn't clearly fit the others).
If there is no 感情ログ note, set emotion to null.

[Note title]
For each note, write a short heading (about 3-6 words) suitable as a diary entry title, and put it in title. Examples: "Fireworks festival was fun", "New café idea".

[Output format]
Output ONLY the following JSON format, with no extra commentary. Remember: every field is in English except "category", which is always the fixed Japanese label アイデア or 感情ログ:

{
  "summary": "one-line overall summary, in English",
  "tasks": [
    {"title": "task content, in English", "due_hint": "original due-date phrase (or null)", "due_date": "YYYY-MM-DD (or null if it can't be inferred)", "reminder_at": "YYYY-MM-DDTHH:mm:00 (or null if no explicit time)", "reminder_end_at": "YYYY-MM-DDTHH:mm:00 (or null if no explicit end time)"}
  ],
  "notes": [
    {"category": "アイデア or 感情ログ (must stay in Japanese, unchanged)", "title": "short heading, in English", "content": "first-person rewrite per the note style rules above, in English"}
  ],
  "comfort_message": "short comforting message in English, only if there is a 感情ログ note, otherwise null",
  "emotion": "one of fatigue/love/anxious/excited/joy/sadness/anger/satisfaction/neutral, only if there is a 感情ログ note, otherwise null"
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

function jstWeekdayString(locale: Locale, date: Date = new Date()): string {
  return new Intl.DateTimeFormat(locale === "en" ? "en-US" : "ja-JP", {
    timeZone: "Asia/Tokyo",
    weekday: "short",
  }).format(date);
}

async function consumeDailyQuota(uid: string, locale: Locale): Promise<void> {
  const db = getFirestore();
  const usageRef = db.collection("usage").doc(`${uid}_${jstDateString()}`);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(usageRef);
    const count = (snap.data()?.count as number | undefined) ?? 0;

    if (count >= FREE_DAILY_LIMIT) {
      throw new HttpsError(
        "resource-exhausted",
        MESSAGES[locale].quotaExceeded(FREE_DAILY_LIMIT)
      );
    }

    tx.set(
      usageRef,
      { count: count + 1, updatedAt: FieldValue.serverTimestamp() },
      { merge: true }
    );
  });
}

export const getUsageStatus = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "認証が必要です。");
  }

  const db = getFirestore();
  const usageRef = db.collection("usage").doc(`${uid}_${jstDateString()}`);
  const snap = await usageRef.get();
  const used = (snap.data()?.count as number | undefined) ?? 0;

  return { used, limit: FREE_DAILY_LIMIT };
});

interface CustomWordEntry {
  word: string;
  description?: string | null;
}

function normalizeCustomWords(customWords: unknown): CustomWordEntry[] {
  if (!Array.isArray(customWords)) return [];

  return customWords
    .map((w): CustomWordEntry | null => {
      if (typeof w === "string") {
        const word = w.trim();
        return word ? { word } : null;
      }
      if (w && typeof w === "object" && typeof (w as CustomWordEntry).word === "string") {
        const word = (w as CustomWordEntry).word.trim();
        if (!word) return null;
        const rawDescription = (w as CustomWordEntry).description;
        const description =
          typeof rawDescription === "string" && rawDescription.trim()
            ? rawDescription.trim().slice(0, 80)
            : undefined;
        return { word, description };
      }
      return null;
    })
    .filter((w): w is CustomWordEntry => w !== null && w.word.length <= 40)
    .slice(0, 100);
}

function buildTranscriptionPrompt(words: CustomWordEntry[], locale: Locale): string | undefined {
  const list = words.map((w) => w.word);
  if (list.length === 0) return undefined;
  return list.join(locale === "en" ? ", " : "、");
}

function buildGlossaryContext(words: CustomWordEntry[], locale: Locale): string | undefined {
  const withDescription = words.filter((w) => w.description);
  if (withDescription.length === 0) return undefined;

  return withDescription
    .map((w) => (locale === "en" ? `- ${w.word}: ${w.description}` : `・${w.word}：${w.description}`))
    .join("\n");
}

interface EnhancedAudio {
  buffer: Buffer;
  mimeType: string;
}

/**
 * 小声・ボソボソ声（ウィスパーボイス）でも文字起こし精度を落とさないよう、
 * Whisperに送る前にffmpegで音量の底上げ（dynaudnorm）とノイズ除去（afftdn）をかける。
 * 処理に失敗した場合は元の音声データのまま続行する（文字起こし自体は止めない）。
 */
async function enhanceAudio(inputBuffer: Buffer, mimeType: string): Promise<EnhancedAudio> {
  if (!ffmpegPath) return { buffer: inputBuffer, mimeType };

  const dir = await mkdtemp(join(tmpdir(), "voicejournal-"));
  const inputPath = join(dir, "input.m4a");
  const outputPath = join(dir, "output.wav");

  try {
    await writeFile(inputPath, inputBuffer);
    await execFileAsync(ffmpegPath, [
      "-y",
      "-i",
      inputPath,
      "-af",
      "afftdn,loudnorm=I=-16:TP=-1.5:LRA=11",
      "-ar",
      "16000",
      "-ac",
      "1",
      outputPath,
    ]);
    const buffer = await readFile(outputPath);
    return { buffer, mimeType: "audio/wav" };
  } catch (err) {
    logger.warn("enhanceAudio failed, using original audio", err);
    return { buffer: inputBuffer, mimeType };
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

function transcriptionFilename(mimeType: string): string {
  return mimeType === "audio/wav" ? "audio.wav" : "audio.m4a";
}

async function transcribe(
  apiKey: string,
  audioBuffer: Buffer,
  mimeType: string,
  locale: Locale,
  prompt?: string
): Promise<string> {
  const form = new FormData();
  form.append(
    "file",
    new Blob([new Uint8Array(audioBuffer)], { type: mimeType }),
    transcriptionFilename(mimeType)
  );
  form.append("model", "whisper-1");
  form.append("language", locale);
  if (prompt) {
    form.append("prompt", prompt);
  }

  const response = await fetch("https://api.openai.com/v1/audio/transcriptions", {
    method: "POST",
    headers: { Authorization: `Bearer ${apiKey}` },
    body: form,
  });

  if (!response.ok) {
    const body = await response.text();
    throw new HttpsError("unavailable", MESSAGES[locale].transcriptionFailed(body));
  }

  const data = (await response.json()) as { text: string };
  return data.text;
}

interface StructuredResult {
  summary: string;
  tasks: {
    title: string;
    due_hint: string | null;
    due_date: string | null;
    reminder_at: string | null;
    reminder_end_at: string | null;
  }[];
  notes: { category: string; title: string | null; content: string }[];
  comfort_message: string | null;
  emotion: string | null;
}

const VALID_EMOTIONS = new Set([
  "fatigue",
  "love",
  "anxious",
  "excited",
  "joy",
  "sadness",
  "anger",
  "satisfaction",
  "neutral",
]);

async function structure(
  apiKey: string,
  transcript: string,
  summaryLevel: SummaryLevel,
  locale: Locale,
  glossary?: string
): Promise<StructuredResult> {
  const now = new Date();
  const systemPrompt =
    locale === "en"
      ? buildSystemPromptEn(jstDateString(now), jstWeekdayString(locale, now), summaryLevel, glossary)
      : buildSystemPrompt(jstDateString(now), jstWeekdayString(locale, now), summaryLevel, glossary);

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
    throw new HttpsError("unavailable", MESSAGES[locale].analysisFailed(body));
  }

  const data = (await response.json()) as {
    choices: { message: { content: string } }[];
  };
  return JSON.parse(data.choices[0].message.content) as StructuredResult;
}

function toClientResponse(structured: StructuredResult) {
  const isoDate = /^\d{4}-\d{2}-\d{2}$/;
  const isoDateTime = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/;

  return {
    summary: structured.summary ?? "",
    tasks: (structured.tasks ?? []).map((task) => {
      const reminderAt =
        task.reminder_at && isoDateTime.test(task.reminder_at) ? task.reminder_at : null;
      const reminderEndAt =
        reminderAt &&
        task.reminder_end_at &&
        isoDateTime.test(task.reminder_end_at) &&
        task.reminder_end_at > reminderAt
          ? task.reminder_end_at
          : null;
      return {
        title: task.title,
        due_hint: task.due_hint ?? null,
        due_date: task.due_date && isoDate.test(task.due_date) ? task.due_date : null,
        reminder_at: reminderAt,
        reminder_end_at: reminderEndAt,
      };
    }),
    notes: structured.notes ?? [],
    comfort_message: structured.comfort_message ?? null,
    emotion:
      structured.emotion && VALID_EMOTIONS.has(structured.emotion)
        ? structured.emotion
        : null,
  };
}

interface ProcessVoiceMemoRequest {
  audioBase64: string;
  mimeType?: string;
  customWords?: (string | CustomWordEntry)[];
  summaryLevel?: string;
  locale?: string;
}

export const processVoiceMemo = onCall(
  { secrets: [openAiApiKey], timeoutSeconds: 120, memory: "1GiB" },
  async (request) => {
    const { audioBase64, mimeType, customWords, summaryLevel, locale } =
      (request.data ?? {}) as ProcessVoiceMemoRequest;
    const loc = normalizeLocale(locale);

    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", MESSAGES[loc].authRequired);
    }
    if (!audioBase64) {
      throw new HttpsError("invalid-argument", MESSAGES[loc].noAudio);
    }

    try {
      await consumeDailyQuota(uid, loc);

      const apiKey = openAiApiKey.value();
      const rawAudioBuffer = Buffer.from(audioBase64, "base64");
      const enhanced = await enhanceAudio(rawAudioBuffer, mimeType ?? "audio/m4a");
      const words = normalizeCustomWords(customWords);
      const prompt = buildTranscriptionPrompt(words, loc);

      const transcript = await transcribe(
        apiKey,
        enhanced.buffer,
        enhanced.mimeType,
        loc,
        prompt
      );
      if (!transcript.trim()) {
        throw new HttpsError("invalid-argument", MESSAGES[loc].transcriptionEmpty);
      }

      const glossary = buildGlossaryContext(words, loc);
      const structured = await structure(
        apiKey,
        transcript,
        normalizeSummaryLevel(summaryLevel),
        loc,
        glossary
      );
      return toClientResponse(structured);
    } catch (err) {
      if (err instanceof HttpsError) {
        throw err;
      }
      logger.error("processVoiceMemo unexpected error", err);
      const message = err instanceof Error ? err.message : String(err);
      // NOTE: コード"internal"/"unknown"はクライアントにメッセージが届かず"INTERNAL"に
      // 潰されるため、デバッグ中は詳細が見える"unavailable"を使う。
      throw new HttpsError("unavailable", MESSAGES[loc].unexpectedError(message));
    }
  }
);

function buildKnowledgeBaseSystemPrompt(locale: Locale): string {
  if (locale === "en") {
    return `You are an AI assistant that answers the user's questions by referencing their own past voice memos and journal entries.

You will be given a list of the user's past diary entries, ideas, and tasks below, each with its date.
Answer the user's question in English, using ONLY the information in that list as your source.
- If you find relevant entries, mention which date(s) they're from.
- If nothing relevant is found, honestly say so instead of guessing or making something up.
- If asked for a trend or pattern, back it up with concrete counts or frequency from the entries.
- If asked to compile a list, present it as a concise bullet list.
Keep your answer concise and conversational, not a wall of text.`;
  }

  return `あなたはユーザー本人が過去に記録した音声メモ・日記を横断的に参照して、質問に答えるAIアシスタントです。

以下に、ユーザーが過去に記録した日記・アイデア・タスクの一覧を日付つきで渡します。
これらの内容だけを根拠に、ユーザーの質問に日本語で答えてください。
- 該当する記録があれば、いつの記録か（日付）に触れてください。
- 該当する記録が見当たらない場合は、推測で答えを作らず、正直に見つからなかったと伝えてください。
- 傾向や頻度を尋ねられた場合は、件数など具体的な根拠を示してください。
- リスト化を求められた場合は、簡潔な箇条書きでまとめてください。
簡潔で会話的な答え方をしてください。長文の説明文にはしないでください。`;
}

/**
 * 過去の記録を丸ごとプロンプトに詰め込んで回答させるMVP実装。
 * メモ量が増えてコンテキストに収まらなくなったら、埋め込み検索で関連する
 * 記録だけを絞り込んで渡す方式に置き換える想定。
 */
async function answerKnowledgeBaseQuestion(
  apiKey: string,
  question: string,
  context: string,
  locale: Locale
): Promise<string> {
  const systemPrompt = buildKnowledgeBaseSystemPrompt(locale);
  const userContent =
    locale === "en"
      ? `[Past entries]\n${context || "(none)"}\n\n[Question]\n${question}`
      : `【過去の記録】\n${context || "（記録がありません）"}\n\n【質問】\n${question}`;

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userContent },
      ],
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new HttpsError("unavailable", MESSAGES[locale].analysisFailed(body));
  }

  const data = (await response.json()) as {
    choices: { message: { content: string } }[];
  };
  return data.choices[0].message.content.trim();
}

interface AskKnowledgeBaseRequest {
  question: string;
  context?: string;
  locale?: string;
}

// NOTE: 有料プラン限定にする予定だが、課金基盤（RevenueCat等）が未実装のため
// 現状は認証済みユーザーなら誰でも呼び出せる。課金基盤が入り次第ゲートを追加する。
export const askKnowledgeBase = onCall(
  { secrets: [openAiApiKey], timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    const { question, context, locale } = (request.data ?? {}) as AskKnowledgeBaseRequest;
    const loc = normalizeLocale(locale);

    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", MESSAGES[loc].authRequired);
    }
    if (!question || !question.trim()) {
      throw new HttpsError("invalid-argument", MESSAGES[loc].noText);
    }

    try {
      const apiKey = openAiApiKey.value();
      const answer = await answerKnowledgeBaseQuestion(
        apiKey,
        question.trim(),
        (context ?? "").trim(),
        loc
      );
      return { answer };
    } catch (err) {
      if (err instanceof HttpsError) {
        throw err;
      }
      logger.error("askKnowledgeBase unexpected error", err);
      const message = err instanceof Error ? err.message : String(err);
      throw new HttpsError("unavailable", MESSAGES[loc].unexpectedError(message));
    }
  }
);

function buildWeeklyReportSystemPrompt(locale: Locale): string {
  if (locale === "en") {
    return `You are an AI assistant that reviews a user's own voice-memo journal entries from the past week and writes a short "weekly brain report" summarizing their emotional trends and thinking patterns.

You will be given the week's diary entries, ideas, and tasks below, each with its date. Analyze ONLY this content and respond with a JSON object in this exact shape:

{
  "emotion_narrative": "1-2 sentences describing the emotional trend across the week (e.g. which day had the most of a particular feeling, whether it improved or worsened toward the weekend). Write it in a warm, encouraging tone, in English. If there isn't enough emotional content to say anything meaningful, say so briefly instead of inventing a trend.",
  "top_keywords": [ up to 3 objects like {"keyword": "short theme name", "count": approximate number of times it came up} ], ordered by how often they came up. Empty array if nothing recurring.
  "shining_ideas": [ up to 2 objects like {"title": "short idea title", "reason": "1 short sentence on why this idea stands out"} ] — pick from the "Idea" entries only, the ones with the most potential or spark. Empty array if there are no ideas this week.
  "advice": "One short, concrete, actionable tip for the upcoming week based on the patterns you noticed (e.g. a day of the week that tends to be busy). Keep it under 2 sentences, warm and non-preachy, in English."
}

Output ONLY the JSON object, no extra commentary.`;
  }

  return `あなたはユーザー本人が1週間分記録した音声メモ（日記・アイデア・タスク）を振り返り、「週刊脳内レポート」として感情の傾向や思考パターンを短くまとめるAIアシスタントです。

以下に今週の日記・アイデア・タスクの一覧を日付つきで渡します。この内容だけを根拠に分析し、必ず以下の形のJSONオブジェクトで出力してください：

{
  "emotion_narrative": "今週の感情の傾向を1〜2文で。例えば特定の感情がどの曜日に集中していたか、週末にかけて改善/悪化したかなど。温かく励ますようなトーンで日本語で書いてください。感情に関する記録が少なすぎて有意な傾向が言えない場合は、無理に傾向を作らず正直にそう書いてください。",
  "top_keywords": [ 最大3件、{"keyword": "短いテーマ名", "count": 言及されたおおよその回数} という形のオブジェクト。よく出てきた順。繰り返し出てきたテーマが無ければ空配列。 ],
  "shining_ideas": [ 最大2件、{"title": "アイデアの短いタイトル", "reason": "なぜこのアイデアが光っているかの短い理由（1文）"} という形のオブジェクト。「アイデア」カテゴリのnoteの中から、特にポテンシャルや閃きを感じるものを選ぶこと。今週アイデアが無ければ空配列。 ],
  "advice": "気づいたパターンを踏まえた、来週に向けた短く具体的なワンポイントアドバイス。2文以内、説教くさくなく温かいトーンで、日本語で。"
}

JSONオブジェクトのみを出力し、余計な説明文は含めないでください。`;
}

interface WeeklyReportInsightsResult {
  emotion_narrative: string;
  top_keywords: { keyword: string; count: number }[];
  shining_ideas: { title: string; reason: string }[];
  advice: string;
}

/**
 * 過去の記録を丸ごとプロンプトに詰め込んで分析させるMVP実装。askKnowledgeBaseと同様、
 * メモ量が増えてコンテキストに収まらなくなったら埋め込み検索方式への置き換えを検討する。
 */
async function generateWeeklyReportInsights(
  apiKey: string,
  context: string,
  locale: Locale
): Promise<WeeklyReportInsightsResult> {
  const systemPrompt = buildWeeklyReportSystemPrompt(locale);
  const userContent =
    locale === "en"
      ? `[This week's entries]\n${context || "(none)"}`
      : `【今週の記録】\n${context || "（記録がありません）"}`;

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
        { role: "user", content: userContent },
      ],
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new HttpsError("unavailable", MESSAGES[locale].analysisFailed(body));
  }

  const data = (await response.json()) as {
    choices: { message: { content: string } }[];
  };
  return JSON.parse(data.choices[0].message.content) as WeeklyReportInsightsResult;
}

function toWeeklyReportResponse(result: WeeklyReportInsightsResult) {
  return {
    emotion_narrative: result.emotion_narrative ?? "",
    top_keywords: (result.top_keywords ?? []).slice(0, 3).map((k) => ({
      keyword: k.keyword ?? "",
      count: typeof k.count === "number" ? k.count : 0,
    })),
    shining_ideas: (result.shining_ideas ?? []).slice(0, 2).map((i) => ({
      title: i.title ?? "",
      reason: i.reason ?? "",
    })),
    advice: result.advice ?? "",
  };
}

interface GenerateWeeklyReportRequest {
  context?: string;
  locale?: string;
}

// NOTE: 有料プラン限定にする予定だが、課金基盤（RevenueCat等）が未実装のため
// 現状は認証済みユーザーなら誰でも呼び出せる。課金基盤が入り次第ゲートを追加する。
export const generateWeeklyReport = onCall(
  { secrets: [openAiApiKey], timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    const { context, locale } = (request.data ?? {}) as GenerateWeeklyReportRequest;
    const loc = normalizeLocale(locale);

    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", MESSAGES[loc].authRequired);
    }

    try {
      const apiKey = openAiApiKey.value();
      const result = await generateWeeklyReportInsights(
        apiKey,
        (context ?? "").trim(),
        loc
      );
      return toWeeklyReportResponse(result);
    } catch (err) {
      if (err instanceof HttpsError) {
        throw err;
      }
      logger.error("generateWeeklyReport unexpected error", err);
      const message = err instanceof Error ? err.message : String(err);
      throw new HttpsError("unavailable", MESSAGES[loc].unexpectedError(message));
    }
  }
);

interface ProcessTextMemoRequest {
  text: string;
  summaryLevel?: string;
  locale?: string;
}

export const processTextMemo = onCall(
  { secrets: [openAiApiKey], timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    const { text, summaryLevel, locale } = (request.data ?? {}) as ProcessTextMemoRequest;
    const loc = normalizeLocale(locale);

    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", MESSAGES[loc].authRequired);
    }
    if (!text || !text.trim()) {
      throw new HttpsError("invalid-argument", MESSAGES[loc].noText);
    }

    try {
      await consumeDailyQuota(uid, loc);

      const apiKey = openAiApiKey.value();
      const structured = await structure(
        apiKey,
        text.trim(),
        normalizeSummaryLevel(summaryLevel),
        loc
      );
      return toClientResponse(structured);
    } catch (err) {
      if (err instanceof HttpsError) {
        throw err;
      }
      logger.error("processTextMemo unexpected error", err);
      const message = err instanceof Error ? err.message : String(err);
      throw new HttpsError("unavailable", MESSAGES[loc].unexpectedError(message));
    }
  }
);
