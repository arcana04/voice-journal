import { createHash, randomBytes, timingSafeEqual } from "node:crypto";
import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";

import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue, FieldPath } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onObjectFinalized, onObjectDeleted } from "firebase-functions/v2/storage";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import ffmpegPath from "ffmpeg-static";

initializeApp();

const execFileAsync = promisify(execFile);

const openAiApiKey = defineSecret("OPENAI_API_KEY");
// RevenueCatダッシュボードのWebhook設定画面で、Authorizationヘッダーの値として
// この値を設定する（なりすましPOST防止）。
const revenueCatWebhookSecret = defineSecret("REVENUECAT_WEBHOOK_SECRET");
// RevenueCatダッシュボードの Project settings > API keys で取得できるSecret API
// key（"sk_"始まり、公開SDKキー"appl_"/"goog_"とは別物）。syncProStatusが
// Subscriber APIを叩くのに使う。
const revenueCatSecretApiKey = defineSecret("REVENUECAT_SECRET_API_KEY");

/** App Check未検証のリクエストを拒否するかどうか。クライアント側
 * （lib/main.dartのFirebaseAppCheck.instance.activate）は本番プロバイダ
 * （Play Integrity/App Attest）を有効化しているが、開発用署名(ad-hoc)の
 * ビルドで実機検証したところApp Attestトークンが取得できず、
 * processVoiceMemoなどiPhone本体からの通常の呼び出しまでunauthenticatedで
 * 全滅することを確認した（2026-09-02）。TestFlight配信ビルド（Codemagic経由）
 * でApp Attestが実際に通るか再検証したが（2026-09-03）、mintWatchPairingToken
 * 呼び出しがunauthenticatedで失敗することを確認 — TestFlight配信でも
 * App Attestが通っていない。原因（Firebaseコンソール側のプロバイダ登録未完了か、
 * 署名方式そのものの非対応か）を切り分けるまで、一旦falseに戻す。 */
const APP_CHECK_ENFORCED = false;

const FREE_DAILY_LIMIT = 3;
const PRO_DAILY_LIMIT = 30;
/** 写真・動画クラウド同期（サブスクプラン限定）の合計容量上限。定額課金なのに
 * Firebase Storage代が青天井になるのを防ぐための安全弁。 */
const MEDIA_STORAGE_CAP_BYTES = 5 * 1024 * 1024 * 1024; // 5GB
/** Pro/買い切みプラン共通の月間録音時間の上限（分）。1回15分×1日30回のような
 * 理論上限には合計時間の歯止めが無く、Whisper API（$0.006/分）の従量課金が
 * サブスク収益を大きく超えかねないため導入（2026-09-05）。無料プランは既存の
 * 日次回数制限だけで十分小さいため対象外。優良ユーザーが真面目に長めの日記を
 * 毎日書いただけで数日で上限に達してユーザー体験を壊さないよう、単純な
 * ハードブロックではなく下記の消費型追加パックで継続利用できるようにする。 */
const PRO_MONTHLY_MINUTES = 240;
/** 上限超過時に購入できる消費型IAP「追加60分パック」の内容。 */
const EXTRA_MINUTES_PACK_SECONDS = 60 * 60;
/** RevenueCat/App Store Connect側の商品IDと完全に一致させること。過去に
 * 月額プランのApple Product Id不一致（"pro.mon" vs "pro.monthly"）で
 * StoreKitから価格を取得できなかったバグを踏んでいるため、ここは特に注意。 */
const EXTRA_MINUTES_PACK_PRODUCT_ID = "com.arcana04.voicejournal.extra_minutes_60";
/** RevenueCatダッシュボードで作成する「Pro」プランのエンタイトルメントID。クライアント側
 * （lib/config/revenuecat_config.dart）の値と一致させること。 */
const PRO_ENTITLEMENT_ID = "voice_journal_pro";

/** Watchペアリング時に発行するデバイス秘密鍵のバイト長。 */
const WATCH_DEVICE_SECRET_BYTES = 32;
/** Watchデバイス認証済み呼び出しに対する、通常の日次クォータとは別枠の
 * バーストレート制限（このウィンドウ秒数あたり最大何回まで）。watchOSは
 * App Check（App Attest）に対応していないため正規アプリであることを
 * ハードウェアレベルで証明できない。その代わりに、ペアリング時に払い出した
 * デバイス秘密鍵で「一度は正規にペアリングされた端末」であることまでは
 * 確認できるが、秘密鍵が漏洩した場合の被害を抑えるためこの追加の壁を設ける。 */
const WATCH_RATE_LIMIT_WINDOW_SECONDS = 60;
const WATCH_RATE_LIMIT_MAX_CALLS = 5;

type SummaryLevel = "preserve" | "standard" | "compact";

function normalizeSummaryLevel(value: unknown): SummaryLevel {
  if (value === "standard" || value === "compact" || value === "preserve") {
    return value;
  }
  return "preserve";
}

/** 録音前にユーザーが「今回話す内容」として絞り込んだカテゴリ。省略・不正値・
 * 空配列の場合は常に全カテゴリ扱い（今までどおりの3分類）にフォールバックする。 */
type AllowedCategory = "diary" | "idea" | "task";
const ALL_CATEGORIES: AllowedCategory[] = ["diary", "idea", "task"];

function normalizeAllowedCategories(value: unknown): Set<AllowedCategory> {
  if (!Array.isArray(value)) return new Set(ALL_CATEGORIES);
  const filtered = value.filter(
    (v): v is AllowedCategory => v === "diary" || v === "idea" || v === "task"
  );
  const unique = new Set(filtered);
  return unique.size > 0 ? unique : new Set(ALL_CATEGORIES);
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
    monthlyMinutesExceeded: (limitMinutes: number) => string;
    watchRateLimited: string;
    unknownWatchDevice: string;
    proRequired: string;
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
    monthlyMinutesExceeded: (limitMinutes) =>
      `今月の録音時間の上限（${limitMinutes}分）に達しました。追加の録音パックを購入するか、来月までお待ちください。`,
    watchRateLimited:
      "Apple Watchからのリクエストが多すぎます。少し時間をおいてから再度お試しください。",
    unknownWatchDevice: "このApple Watchはまだペアリングされていません。iPhoneアプリで再度ペアリングしてください。",
    proRequired: "この機能はProプラン限定です。",
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
    monthlyMinutesExceeded: (limitMinutes) =>
      `You've reached this month's recording limit of ${limitMinutes} minutes. Buy an extra minutes pack, or wait until next month.`,
    watchRateLimited:
      "Too many requests from Apple Watch. Please wait a moment and try again.",
    unknownWatchDevice:
      "This Apple Watch hasn't been paired yet. Please pair it again from the iPhone app.",
    proRequired: "This feature is only available on the Pro plan.",
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
- 一人称視点（「〜と感じた」「〜だった」など）は保ってください。
- 話者が言っていない人物・出来事・感情・詳細を勝手に付け足してはいけません。要約は「削る」ことであり「足す」ことではありません。
${FABRICATION_EXAMPLE}`;
    case "standard":
      return `【notesの本文（content）の書き方：標準】
tasksほど短くはせず、日記らしい自然な文章の長さは保ちつつ、冗長な繰り返しや脱線は整理してください。
- 感情の手がかりになる言葉、固有名詞、印象的な言い回しはできるだけ残してください。ただし発言をそのまま書き起こす必要はなく、読みやすいよう軽く整えて構いません。
- 客観的な三人称ではなく、話者自身の一人称視点（「〜と感じた」「〜だった」など）で自然な日記の文体にしてください。
- 感情が動いた場面では、不自然にならない範囲で「！」も使ってください。
- 「日記らしい長さ」はあくまで文章の整え方の目安であり、分量を埋めることを目的に、話者が言っていない人物・出来事・感情・詳細を付け足してはいけません。入力が「BBQに行った」のように一言だけなら、contentも一言〜一文程度の短さのままで構いません。存在しない情報を書き足すくらいなら、短いままにしてください。
${FABRICATION_EXAMPLE}`;
    case "preserve":
    default:
      return `【notesの本文（content）の書き方：原型重視】
tasksとは違い、notesは要約・圧縮しないでください。
- 話者が語った「生の感情」「独特な言い回し」「情景の描写」「具体的な固有名詞」は、できる限り削除せずそのまま残してください。要点だけを抜き出した短い要約にはしないでください。
- 取り除いてよいのは言い淀み（「えっと」「あー」など）と同じ内容の重複表現だけです。それ以外は発言の内容・順序・粒度を保ったまま、読みやすい文章に整える（整文する）程度にとどめてください。
- 客観的な三人称の説明文にはせず、話者自身の一人称視点（「〜と感じた」「〜だった」「〜かもしれない」など）で、自然な日記の文体にリライトしてください。
- 感情が高ぶった場面や驚き・嬉しさなどは、不自然にならない範囲で「！」も使い、実際に喋っていたときの自然なトーンを残してください。
- 話者が言っていない人物・出来事・感情・詳細を勝手に付け足してはいけません。入力が短ければ、整えた後のcontentも短いままで構いません。
${FABRICATION_EXAMPLE}`;
  }
}

/** 3段階すべての要約度に共通で埋め込む、捏造禁止の具体例。抽象的な指示だけでは
 * gpt-4o-miniが短い入力を「日記らしく」しようとして人物や情景を作り話することが
 * 実際にあったため（原型重視モードでも発生）、実例で強く釘を刺す。 */
const FABRICATION_EXAMPLE = `【具体例（この通りにすること）】
入力: 「花火が楽しかった」
- 正しい出力例: 「花火が楽しかった。」（一人称に整える程度の軽微な変更にとどめる）
- 絶対にしてはいけない出力例: 「花火を見ている時間が本当に楽しかった。夜空に美しい花火が広がるのが印象的で、みんなでワイワイできた。」（「みんなで」など、話者が一言も言っていない人物・情景を捏造しており違反）`;

function buildNotesStyleSectionEn(level: SummaryLevel): string {
  switch (level) {
    case "compact":
      return `[How to write the note body ("content"): very compact]
Just like tasks, boil this down to only the essentials.
- You may cut not just filler and repeated phrases, but also minor descriptions and redundant explanations.
- Aim for about 1-2 sentences per note, covering only the core event, idea, or feeling.
- Keep the first-person point of view ("I felt...", "It was...").
- Never invent people, events, feelings, or details the speaker didn't say. Summarizing means cutting, never adding.
${FABRICATION_EXAMPLE_EN}`;
    case "standard":
      return `[How to write the note body ("content"): standard]
Don't shorten it as much as a task, but keep a natural diary-entry length while tidying up redundant repetition or tangents.
- Keep emotional cues, names, and memorable phrasing where you can. You don't need to transcribe verbatim — light editing for readability is fine.
- Write in the speaker's own first-person voice ("I felt...", "It was...."), not an objective third-person description.
- Where the emotion is high, it's fine to use "!" if it doesn't feel forced.
- "Natural diary-entry length" is only a guide for tidying prose — never invent people, events, feelings, or details the speaker didn't say just to fill out the length. If the input is only a short phrase like "went to a BBQ", the content can stay just as short — a short-but-accurate note is always better than a longer one with fabricated details.
${FABRICATION_EXAMPLE_EN}`;
    case "preserve":
    default:
      return `[How to write the note body ("content"): preserve original]
Unlike tasks, do not summarize or compress notes.
- Keep the speaker's raw emotion, distinctive phrasing, scene description, and specific names as intact as possible. Do not reduce it to a short summary of just the key points.
- The only things you may remove are filler words (like "um", "uh") and exact repeated phrases. Otherwise, keep the content, order, and level of detail, only lightly tidying the prose for readability.
- Rewrite it in the speaker's own first-person voice ("I felt...", "It was...", "Maybe I..."), not an objective third-person account.
- Where there's excitement, surprise, or joy, it's fine to use "!" to keep the natural tone of how it was actually said.
- Never invent people, events, feelings, or details the speaker didn't say. If the input is short, the tidied content can stay just as short.
${FABRICATION_EXAMPLE_EN}`;
  }
}

/** Same fabrication-prevention example as the Japanese prompt, in English —
 * abstract rules alone weren't reliably followed by gpt-4o-mini for very
 * short inputs, so a concrete example is included at every summary level. */
const FABRICATION_EXAMPLE_EN = `[Concrete example — follow this exactly]
Input: "the fireworks were fun"
- Correct output: "The fireworks were fun." (only lightly tidied into first person, nothing added)
- Never output something like: "Watching the fireworks was such a genuinely fun time. The way they lit up the night sky was so striking, and having everyone there together made it even better." (inventing people like "everyone" and scene details the speaker never said is a violation)`;

const CATEGORY_LABEL_JA: Record<AllowedCategory, string> = {
  diary: "感情ログ（日記）",
  idea: "アイデア",
  task: "タスク",
};
const CATEGORY_LABEL_EN: Record<AllowedCategory, string> = {
  diary: "感情ログ (diary)",
  idea: "アイデア (idea)",
  task: "タスク (task)",
};
const NOTE_CATEGORY_JA: Record<"diary" | "idea", string> = {
  diary: "感情ログ",
  idea: "アイデア",
};

/** 3カテゴリのうち一部だけをユーザーが録音前に選んだ場合、プロンプトに
 * 追加する制限の説明。全カテゴリ選択時（デフォルト・後方互換）は空文字を
 * 返し、今までの挙動を一切変えない。 */
function buildCategoryRestrictionNote(allowed: Set<AllowedCategory>, locale: Locale): string {
  if (allowed.size >= 3) return "";
  const fallback = ALL_CATEGORIES.find((c) => allowed.has(c)) ?? "diary";
  if (locale === "en") {
    const labels = ALL_CATEGORIES.filter((c) => allowed.has(c))
      .map((c) => CATEGORY_LABEL_EN[c])
      .join(", ");
    return `\n\n[Category restriction for this recording]\nOnly these categories are enabled this time: ${labels}. Never use a disabled category. If content would normally belong to a disabled category, reassign it to whichever enabled category fits best, defaulting to ${CATEGORY_LABEL_EN[fallback]} when in doubt. Never drop or silently omit content just because its natural category is disabled — everything the speaker said must still end up in tasks or notes.`;
  }
  const labels = ALL_CATEGORIES.filter((c) => allowed.has(c))
    .map((c) => CATEGORY_LABEL_JA[c])
    .join("、");
  return `\n\n【今回のカテゴリ制限】\n今回有効なカテゴリは${labels}のみです。無効なカテゴリは絶対に使わないでください。本来そのカテゴリに分類されるはずだった内容も、有効なカテゴリの中から最も近いものに割り当ててください（迷ったら${CATEGORY_LABEL_JA[fallback]}にしてください）。カテゴリが無効だからといって内容を書き漏らさないこと — 話された内容は必ずtasksかnotesのどちらかに残してください。`;
}

/** AIがカテゴリ制限のプロンプト指示に従わず無効なカテゴリを返してしまった
 * 場合の保険。全カテゴリ選択時は何もしない（呼び出し元でチェック済み）。 */
function enforceCategoryRestriction(
  structured: StructuredResult,
  allowed: Set<AllowedCategory>
): StructuredResult {
  if (allowed.size >= 3) return structured;
  const fallback = ALL_CATEGORIES.find((c) => allowed.has(c)) ?? "diary";

  const tasks: StructuredResult["tasks"] = [];
  const notes: StructuredResult["notes"] = [];

  for (const task of structured.tasks ?? []) {
    if (allowed.has("task")) {
      tasks.push(task);
      continue;
    }
    // taskが無効なので、fallbackは必ず"diary"か"idea"のどちらか。
    notes.push({
      category: NOTE_CATEGORY_JA[fallback as "diary" | "idea"],
      title: task.title,
      content: task.title,
    });
  }

  for (const note of structured.notes ?? []) {
    const category: AllowedCategory = note.category === "アイデア" ? "idea" : "diary";
    if (allowed.has(category)) {
      notes.push(note);
    } else if (fallback === "task") {
      tasks.push({
        title: note.title ?? note.content.slice(0, 40),
        due_hint: null,
        due_date: null,
        reminder_at: null,
        reminder_end_at: null,
      });
    } else {
      notes.push({ ...note, category: NOTE_CATEGORY_JA[fallback as "diary" | "idea"] });
    }
  }

  return { ...structured, tasks, notes };
}

function buildSystemPrompt(
  todayJst: string,
  weekdayJst: string,
  summaryLevel: SummaryLevel,
  categoryNote: string,
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
${categoryNote}

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
satisfaction（満足・達成感）, gratitude（感謝）, happy（嬉しい・心が温まる感じ）, love（好き・愛情・愛おしさ）, funny（面白い・愉快）, joy（楽しい・満喫している感じ）, excited（ドキドキ・期待）, relief（安心・ほっとした）, calm（穏やか・落ち着いた）, neutral（それ以外・判別しづらい穏やかな心情）, boredom（退屈）, anxious（不安・焦り）, sadness（悲しい・落ち込み）, fatigue（疲れた・くたびれ）, regret（後悔）, anger（怒り・苛立ち）, dislike（嫌い・苦手）。
【重要】文中に「楽しい」「楽しかった」という言葉が出てくるからといって、それだけで安易にjoyを選ばないこと。表面的な単語ではなく、実際に読み取れる感情の中身で判断する。例えば次のように、より的確な選択肢があればそちらを優先すること：誰かに親切にされた・何かをしてもらった→gratitude、目標を達成した・やり遂げた→satisfaction、大切な人や物への愛着・好意→love、冗談や滑稽な出来事で笑った→funny、これから起きることへのわくわく・期待・緊張→excited、心配事が解消してほっとした→relief。joyは「活動そのものを満喫している」という意味に明確に当てはまる場合だけ選び、ポジティブ全般の既定値として使わないこと。
happyとjoyとsatisfactionは近い感情だが、happyは他者や出来事への嬉しさ、joyは活動そのものを楽しんでいる感じ、satisfactionは達成感を伴う満足として区別すること。calmとreliefとneutralも近いが、calmは穏やかで落ち着いた状態、reliefは不安が解消してほっとした状態、neutralはどちらにも当てはまらない中立的な心情として区別すること。
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
  "emotion": "感情ログがある場合のみ satisfaction/gratitude/happy/love/funny/joy/excited/relief/calm/neutral/boredom/anxious/sadness/fatigue/regret/anger/dislike のいずれか。なければnull"
}`;
}

function buildSystemPromptEn(
  today: string,
  weekday: string,
  summaryLevel: SummaryLevel,
  categoryNote: string,
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
${categoryNote}

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
satisfaction, gratitude, happy, love, funny, joy, excited, relief, calm, neutral, boredom, anxious, sadness, fatigue, regret, anger, dislike (use neutral for anything ambiguous that doesn't clearly fit the others).
[Important] Don't default to joy just because the speaker literally says "fun" or "enjoyed it" — judge by the actual feeling being conveyed, not the surface word. Prefer a more specific match when one clearly fits: someone was kind / did something for them → gratitude; they accomplished or finished a goal → satisfaction; affection for a person or thing → love; something struck them as funny/amusing → funny; anticipation or nervous excitement about something upcoming → excited; relief after a worry resolved → relief. Reserve joy for cases that are specifically about enjoying an activity itself, not as a catch-all default for anything positive.
happy, joy, and satisfaction are close but distinct: happy is warmth toward someone/something that happened, joy is enjoying the activity itself, satisfaction is a sense of accomplishment. calm, relief, and neutral are also close but distinct: calm is a settled, peaceful state, relief is the feeling right after anxiety resolves, neutral is a plain in-between state that doesn't fit either.
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
  "emotion": "one of satisfaction/gratitude/happy/love/funny/joy/excited/relief/calm/neutral/boredom/anxious/sadness/fatigue/regret/anger/dislike, only if there is a 感情ログ note, otherwise null"
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

/** usageMonth/{uid}_{yyyyMM}ドキュメントのキーに使う「YYYYMM」形式。 */
function jstMonthString(date: Date = new Date()): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Tokyo",
    year: "numeric",
    month: "2-digit",
  })
    .format(date)
    .replace("-", "");
}

function jstWeekdayString(locale: Locale, date: Date = new Date()): string {
  return new Intl.DateTimeFormat(locale === "en" ? "en-US" : "ja-JP", {
    timeZone: "Asia/Tokyo",
    weekday: "short",
  }).format(date);
}

/** FirestoreのusersドキュメントからPro加入状態を読む。ドキュメントが無い/isProが
 * falseなら無料プラン扱い。RevenueCatのWebhook（revenueCatWebhook関数）が
 * このドキュメントを更新する。 */
async function isProUser(uid: string): Promise<boolean> {
  const db = getFirestore();
  const snap = await db.collection("users").doc(uid).get();
  return snap.data()?.isPro === true;
}

async function dailyLimitFor(uid: string): Promise<number> {
  return (await isProUser(uid)) ? PRO_DAILY_LIMIT : FREE_DAILY_LIMIT;
}

async function consumeDailyQuota(uid: string, locale: Locale): Promise<void> {
  const db = getFirestore();
  const usageRef = db.collection("usage").doc(`${uid}_${jstDateString()}`);
  const limit = await dailyLimitFor(uid);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(usageRef);
    const count = (snap.data()?.count as number | undefined) ?? 0;

    if (count >= limit) {
      throw new HttpsError(
        "resource-exhausted",
        MESSAGES[locale].quotaExceeded(limit)
      );
    }

    tx.set(
      usageRef,
      { count: count + 1, updatedAt: FieldValue.serverTimestamp() },
      { merge: true }
    );
  });
}

function usageMonthRef(uid: string) {
  return getFirestore().collection("usageMonth").doc(`${uid}_${jstMonthString()}`);
}

/**
 * Pro/買い切みプラン限定の月間録音時間チェック。無料プランは対象外
 * （既存の日次回数制限で十分小さいコストに収まるため）。実際の音声長は
 * ffmpeg処理後にしか分からないため、ここでは「前回までの累計」だけを見て、
 * 既に使い切っている場合にWhisper呼び出し前に弾く事前チェックを行う
 * （1回の録音の途中で上限を跨ぐケース自体は許容し、事後にrecordMonthlyMinutesUsageで
 * 加算する——完全な事前ブロックにはできないが、無駄なWhisper課金を防ぐには十分）。
 */
async function checkMonthlyMinutesBudget(uid: string, locale: Locale): Promise<void> {
  if (!(await isProUser(uid))) return;

  const db = getFirestore();
  const [usageSnap, userSnap] = await Promise.all([
    usageMonthRef(uid).get(),
    db.collection("users").doc(uid).get(),
  ]);
  const audioSecondsUsed = (usageSnap.data()?.audioSecondsUsed as number | undefined) ?? 0;
  const bonusSecondsBalance = (userSnap.data()?.bonusSecondsBalance as number | undefined) ?? 0;

  if (audioSecondsUsed >= PRO_MONTHLY_MINUTES * 60 && bonusSecondsBalance <= 0) {
    throw new HttpsError(
      "resource-exhausted",
      MESSAGES[locale].monthlyMinutesExceeded(PRO_MONTHLY_MINUTES),
      { reason: "monthly_minutes" }
    );
  }
}

/**
 * 実際の音声長が分かった後に呼ぶ、月間利用量の事後加算。まず月間の基本枠
 * （PRO_MONTHLY_MINUTES、月をまたぐとリセットされる）から差し引き、それを
 * 使い切っている分だけ購入済みのbonusSecondsBalance（月をまたいでも減るまで
 * 持ち越す）から差し引く。無料プランは対象外（呼び出し元でisProUserを見て
 * スキップする想定だが、念のためここでも確認する）。
 */
async function recordMonthlyMinutesUsage(uid: string, durationSeconds: number): Promise<void> {
  if (durationSeconds <= 0) return;
  if (!(await isProUser(uid))) return;

  const db = getFirestore();
  const usageRef = usageMonthRef(uid);
  const userRef = db.collection("users").doc(uid);

  await db.runTransaction(async (tx) => {
    const [usageSnap, userSnap] = await Promise.all([tx.get(usageRef), tx.get(userRef)]);
    const audioSecondsUsed = (usageSnap.data()?.audioSecondsUsed as number | undefined) ?? 0;
    const bonusSecondsBalance = (userSnap.data()?.bonusSecondsBalance as number | undefined) ?? 0;

    const monthlyBudgetSeconds = PRO_MONTHLY_MINUTES * 60;
    const remainingBase = Math.max(0, monthlyBudgetSeconds - audioSecondsUsed);
    const fromBase = Math.min(durationSeconds, remainingBase);
    const fromBonus = durationSeconds - fromBase;

    tx.set(
      usageRef,
      {
        audioSecondsUsed: audioSecondsUsed + fromBase,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    if (fromBonus > 0) {
      tx.set(
        userRef,
        { bonusSecondsBalance: bonusSecondsBalance - fromBonus },
        { merge: true }
      );
    }
  });
}

/** 追加分数パック購入時に、購入者のボーナス残高へ加算する。月をまたいでも
 * 消費されるまで減らない（月間の基本枠PRO_MONTHLY_MINUTESとは別枠）。 */
async function grantBonusMinutes(uid: string, seconds: number): Promise<void> {
  const db = getFirestore();
  await db
    .collection("users")
    .doc(uid)
    .set({ bonusSecondsBalance: FieldValue.increment(seconds) }, { merge: true });
}

function hashWatchDeviceSecret(secret: string): string {
  return createHash("sha256").update(secret).digest("hex");
}

interface WatchDeviceAuthHeaders {
  deviceId: string;
  secret: string;
}

/** CallableのrawRequestから、Watch専用の簡易デバイス認証ヘッダーを取り出す。
 * ヘッダーが無ければnull（＝通常のiPhoneクライアントからの呼び出し）。 */
function extractWatchDeviceAuth(rawRequest: {
  get(name: string): string | undefined;
}): WatchDeviceAuthHeaders | null {
  const deviceId = rawRequest.get("X-Watch-Device-Id");
  const secret = rawRequest.get("X-Watch-Device-Secret");
  if (!deviceId || !secret) return null;
  return { deviceId, secret };
}

/**
 * Watch単体からの呼び出し用の簡易デバイス認証。mintWatchPairingTokenで
 * ペアリング時に払い出したデバイス秘密鍵のハッシュと照合する。Firebase Auth
 * （uid）による本人確認とは別に、「正規にペアリングされたWatch端末からの
 * 呼び出しか」を追加でチェックするもの（App Check未対応watchOSの代替）。
 */
async function verifyWatchDeviceSecret(
  uid: string,
  auth: WatchDeviceAuthHeaders,
  locale: Locale
): Promise<void> {
  const db = getFirestore();
  const deviceRef = db
    .collection("users")
    .doc(uid)
    .collection("watchDevices")
    .doc(auth.deviceId);
  const snap = await deviceRef.get();
  const storedHash = snap.data()?.secretHash as string | undefined;
  if (!storedHash) {
    throw new HttpsError("unauthenticated", MESSAGES[locale].unknownWatchDevice);
  }

  const storedBuf = Buffer.from(storedHash, "hex");
  const providedBuf = Buffer.from(hashWatchDeviceSecret(auth.secret), "hex");
  const valid =
    storedBuf.length === providedBuf.length && timingSafeEqual(storedBuf, providedBuf);
  if (!valid) {
    throw new HttpsError("unauthenticated", MESSAGES[locale].unknownWatchDevice);
  }

  await deviceRef.set({ lastUsedAt: FieldValue.serverTimestamp() }, { merge: true });
}

/** Watchデバイス認証済みの呼び出しに対する、日次クォータとは別枠のバースト
 * レート制限。秘密鍵が漏洩した場合の被害を抑えるための追加の壁。 */
async function consumeWatchRateLimit(
  uid: string,
  deviceId: string,
  locale: Locale
): Promise<void> {
  const db = getFirestore();
  const windowStart = Math.floor(Date.now() / 1000 / WATCH_RATE_LIMIT_WINDOW_SECONDS);
  const bucketRef = db.collection("watchRateLimit").doc(`${uid}_${deviceId}_${windowStart}`);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(bucketRef);
    const count = (snap.data()?.count as number | undefined) ?? 0;
    if (count >= WATCH_RATE_LIMIT_MAX_CALLS) {
      throw new HttpsError("resource-exhausted", MESSAGES[locale].watchRateLimited);
    }
    tx.set(
      bucketRef,
      { count: count + 1, updatedAt: FieldValue.serverTimestamp() },
      { merge: true }
    );
  });
}

export const getUsageStatus = onCall(
  { enforceAppCheck: APP_CHECK_ENFORCED },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "認証が必要です。");
    }

    const db = getFirestore();
    const usageRef = db.collection("usage").doc(`${uid}_${jstDateString()}`);
    const [snap, limit, isPro] = await Promise.all([
      usageRef.get(),
      dailyLimitFor(uid),
      isProUser(uid),
    ]);
    const used = (snap.data()?.count as number | undefined) ?? 0;

    if (!isPro) {
      return { used, limit };
    }

    const [monthSnap, userSnap] = await Promise.all([
      usageMonthRef(uid).get(),
      db.collection("users").doc(uid).get(),
    ]);
    const monthlyUsedSeconds = (monthSnap.data()?.audioSecondsUsed as number | undefined) ?? 0;
    const bonusSecondsBalance = (userSnap.data()?.bonusSecondsBalance as number | undefined) ?? 0;

    return {
      used,
      limit,
      monthlyUsedSeconds,
      monthlyLimitSeconds: PRO_MONTHLY_MINUTES * 60,
      bonusSecondsBalance,
    };
  }
);

/** users/{uid}/entries/{entryId}/media/{fileName} 以下のオブジェクトだけを
 * 対象に、[uid]と抽出してマッチさせる。それ以外のパスにはマッチしない。 */
const MEDIA_OBJECT_PATH_RE = /^users\/([^/]+)\/entries\/[^/]+\/media\/[^/]+$/;

/** users/{uid}.mediaBytesUsedを加算/減算し、更新後の値を返す。トランザクション
 * にしているのは、onMediaObjectFinalizedが更新直後の値を見て5GB上限
 * （MEDIA_STORAGE_CAP_BYTES）超過を判定する必要があるため
 * （FieldValue.incrementだけでは呼び出し側が結果値を取得できない）。 */
async function adjustMediaBytesUsed(uid: string, deltaBytes: number): Promise<number> {
  const db = getFirestore();
  const userRef = db.collection("users").doc(uid);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    const current = (snap.data()?.mediaBytesUsed as number | undefined) ?? 0;
    const next = Math.max(0, current + deltaBytes);
    tx.set(userRef, { mediaBytesUsed: next }, { merge: true });
    return next;
  });
}

/** 写真・動画のアップロード完了のたびに、そのユーザーの合計使用量
 * （users/{uid}.mediaBytesUsed）を加算する。Storage Security Rulesは
 * Firestoreの集計値をクロスサービス参照できず、1ファイルごとのサイズしか
 * 判定できないため、合計5GB上限（MEDIA_STORAGE_CAP_BYTES）はここで
 * 事後的に強制する——上限を超えた場合、アップロードされたファイル自体を
 * 削除して差し戻す（削除は下のonMediaObjectDeletedを発火させ、
 * mediaBytesUsedも正しく戻る）。以前はこの上限がクライアント表示用の
 * 数字でしかなく、有効なPro認証さえあれば理論上無制限にアップロードできて
 * しまう抜け穴だった（2026-09-05に修正）。 */
export const onMediaObjectFinalized = onObjectFinalized(async (event) => {
  const match = MEDIA_OBJECT_PATH_RE.exec(event.data.name);
  if (!match) return;
  const uid = match[1];
  const newTotal = await adjustMediaBytesUsed(uid, Number(event.data.size ?? 0));

  if (newTotal > MEDIA_STORAGE_CAP_BYTES) {
    try {
      await getStorage().bucket(event.data.bucket).file(event.data.name).delete();
      logger.warn("media storage cap exceeded, deleted upload", {
        uid,
        file: event.data.name,
        newTotal,
      });
    } catch (err) {
      logger.error("failed to delete over-cap media upload", { uid, err });
    }
  }
});

/** 写真・動画の削除のたびに、そのユーザーの合計使用量を差し引く。 */
export const onMediaObjectDeleted = onObjectDeleted(async (event) => {
  const match = MEDIA_OBJECT_PATH_RE.exec(event.data.name);
  if (!match) return;
  await adjustMediaBytesUsed(match[1], -Number(event.data.size ?? 0));
});

/** クライアントはusers/{uid}を直接読めない（firestore.rules参照）ため、写真・
 * 動画クラウド同期の使用量/上限をこの呼び出し経由で取得する。 */
export const getMediaUsage = onCall(
  { enforceAppCheck: APP_CHECK_ENFORCED },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "認証が必要です。");
    }

    const db = getFirestore();
    const snap = await db.collection("users").doc(uid).get();
    const used = (snap.data()?.mediaBytesUsed as number | undefined) ?? 0;

    return { used, cap: MEDIA_STORAGE_CAP_BYTES };
  }
);

interface MintWatchPairingTokenRequest {
  locale?: string;
}

interface MintWatchPairingTokenResponse {
  customToken: string;
  deviceId: string;
  deviceSecret: string;
}

/**
 * Apple Watchのスタンドアロン録音機能のペアリング用。既にサインイン済みの
 * iPhoneアプリからペアリング時に一度だけ呼び出し、結果をWatchConnectivity
 * 経由でWatchに中継する想定。
 * - customToken: Watch側でFirebase AuthのREST API
 *   （accounts:signInWithCustomToken）と交換し、Watch専用のidToken/
 *   refreshTokenを得るためのもの（デフォルトTTL1時間・ワンタイム用。
 *   watchOSはFirebase Auth SDK未対応のためREST APIを直接叩く）。
 * - deviceId/deviceSecret: processVoiceMemo呼び出し時にWatch由来の
 *   リクエストであることを検証する簡易デバイス認証（App Check/App Attestが
 *   watchOSで使えないための代替。verifyWatchDeviceSecret参照）。
 */
export const mintWatchPairingToken = onCall(
  { enforceAppCheck: APP_CHECK_ENFORCED },
  async (request): Promise<MintWatchPairingTokenResponse> => {
    const { locale } = (request.data ?? {}) as MintWatchPairingTokenRequest;
    const loc = normalizeLocale(locale);

    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", MESSAGES[loc].authRequired);
    }

    const deviceSecret = randomBytes(WATCH_DEVICE_SECRET_BYTES).toString("hex");
    const db = getFirestore();
    const deviceRef = db.collection("users").doc(uid).collection("watchDevices").doc();
    await deviceRef.set({
      secretHash: hashWatchDeviceSecret(deviceSecret),
      createdAt: FieldValue.serverTimestamp(),
    });

    const customToken = await getAuth().createCustomToken(uid);

    return { customToken, deviceId: deviceRef.id, deviceSecret };
  }
);

/**
 * ユーザーの写真・動画（users/{uid}/entries/*\/media/*）のストレージクラスを
 * 一括変更する。Proが失効したら低頻度アクセス向けの安価なクラスに移し、
 * 再度Proに復帰したら標準クラスに戻す——バイト単価はどちらも即時ダウンロード
 * 可能な点は変わらないので、ユーザー体験に影響しない。
 */
async function setUserMediaStorageClass(
  uid: string,
  storageClass: "STANDARD" | "COLDLINE"
): Promise<void> {
  try {
    const bucket = getStorage().bucket();
    const [files] = await bucket.getFiles({ prefix: `users/${uid}/entries/` });
    await Promise.all(
      files
        .filter((f) => f.name.includes("/media/"))
        .map((f) =>
          f.setStorageClass(storageClass).catch((err) => {
            logger.error("setUserMediaStorageClass failed for file", {
              uid,
              file: f.name,
              storageClass,
              err,
            });
          })
        )
    );
  } catch (err) {
    logger.error("setUserMediaStorageClass failed", { uid, storageClass, err });
  }
}

/**
 * users/{uid}.isPro/hasMediaSync とカスタムクレームを更新する共通処理。
 * RevenueCatのWebhook（revenueCatWebhook）と、クライアント起点の自己修復用
 * 同期（syncProStatus、webhook配信が届かなかった場合のフォールバック）の
 * 両方から呼ばれる。
 *
 * [hasMediaSync]はisProとは別軸——写真・動画のクラウド同期は継続的な
 * Storage課金が発生する機能なので、単発収益の買い切りプランには提供しない
 * 方針（PurchaseService.hasMediaSyncEntitlement()のクライアント側チェックと
 * 同じ「有効期限があるサブスクかどうか」で判定）。以前はStorage Security
 * Rulesが`isPro`カスタムクレームだけを見ており、買い切み購入者を区別
 * できていなかった（クライアントのUIが出し分けているだけで、サーバー側の
 * 強制ではなかった）ため、この専用クレームを追加した（2026-09-05）。
 */
async function applyProStatus(
  uid: string,
  isPro: boolean,
  hasMediaSync: boolean,
  source: string
): Promise<void> {
  const db = getFirestore();
  const userRef = db.collection("users").doc(uid);
  const previousData = (await userRef.get()).data();
  const previousHasMediaSync = previousData?.hasMediaSync === true;
  await userRef.set(
    {
      isPro,
      hasMediaSync,
      revenueCatSource: source,
      revenueCatUpdatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  // Storage Security Rulesはfirestore.get()によるクロスサービス参照が
  // 使えないため、カスタムクレームで持たせて`request.auth.token.hasMediaSync`
  // として直接参照できるようにする（Firestore側のisProUser()はこれまで通り
  // Firestoreドキュメントを見る）。
  try {
    await getAuth().setCustomUserClaims(uid, { isPro, hasMediaSync });
  } catch (claimErr) {
    logger.error("applyProStatus setCustomUserClaims failed", claimErr);
  }

  // 失効/復帰の「遷移」のときだけメディアのストレージクラスを移動する
  // （書き換えのたびに課金が発生するオペレーションなので不要な実行を避ける）。
  // isProではなくhasMediaSyncの遷移で判定する——買い切み購入者はisProが
  // trueのままメディア同期の対象外なので、そもそも移動対象のファイルを
  // 持たない想定。
  if (hasMediaSync && !previousHasMediaSync) {
    await setUserMediaStorageClass(uid, "STANDARD");
  } else if (!hasMediaSync && previousHasMediaSync) {
    await setUserMediaStorageClass(uid, "COLDLINE");
  }
}

/**
 * RevenueCatからのWebhook受信エンドポイント。RevenueCatダッシュボードの
 * Webhook設定でこの関数のURLを登録し、AuthorizationヘッダーにREVENUECAT_WEBHOOK_SECRET
 * の値を設定する。app_user_idにはクライアント側でFirebase AuthのUIDを渡している
 * （PurchasesConfiguration.appUserID）ため、そのままFirestoreのuidとして使える。
 */
export const revenueCatWebhook = onRequest(
  { secrets: [revenueCatWebhookSecret] },
  async (req, res) => {
    const expected = revenueCatWebhookSecret.value();
    const authHeader = req.get("Authorization") ?? "";
    if (!expected || authHeader !== expected) {
      res.status(401).send("unauthorized");
      return;
    }

    try {
      const event = req.body?.event as
        | {
            type?: string;
            app_user_id?: string;
            entitlement_ids?: string[];
            product_id?: string;
            /** 非nullなら有効期限つき＝サブスク、nullなら買い切み等の
             * 非失効購入。RevenueCat Webhookのイベントペイロードに含まれる。 */
            expiration_at_ms?: number | null;
          }
        | undefined;
      const uid = event?.app_user_id;
      const eventType = event?.type;
      if (!uid || !eventType) {
        res.status(400).send("bad request");
        return;
      }

      // 追加分数パック（消費型IAP、エンタイトルメント無し）の購入はPro付与とは
      // 無関係なので、既存のisPro判定ロジックに触れる前にここで分岐して抜ける。
      // 既存ロジックは「entitlement_idsが無ければisPro=trueとみなす」フォール
      // バックを持っており、これを変えずに新しいNON_RENEWING_PURCHASE系の
      // 商品を追加すると、パック購入者に誤ってProが付与されてしまうため。
      if (eventType === "NON_RENEWING_PURCHASE" && event?.product_id === EXTRA_MINUTES_PACK_PRODUCT_ID) {
        await grantBonusMinutes(uid, EXTRA_MINUTES_PACK_SECONDS);
        res.status(200).send("ok");
        return;
      }

      const activeEventTypes = new Set([
        "INITIAL_PURCHASE",
        "RENEWAL",
        "UNCANCELLATION",
        "PRODUCT_CHANGE",
        "TRANSFER",
        "NON_RENEWING_PURCHASE",
      ]);
      const inactiveEventTypes = new Set(["EXPIRATION"]);

      // CANCELLATION（次回更新の解約予約）は期限が来るまでは有効のまま据え置き、
      // それ以外の未知イベントも状態を変えない。
      if (activeEventTypes.has(eventType) || inactiveEventTypes.has(eventType)) {
        const isPro =
          activeEventTypes.has(eventType) &&
          (!event?.entitlement_ids ||
            event.entitlement_ids.includes(PRO_ENTITLEMENT_ID));
        const hasMediaSync =
          isPro &&
          event?.expiration_at_ms !== null &&
          event?.expiration_at_ms !== undefined;
        await applyProStatus(uid, isPro, hasMediaSync, `webhook:${eventType}`);
      }

      res.status(200).send("ok");
    } catch (err) {
      logger.error("revenueCatWebhook unexpected error", err);
      res.status(500).send("internal error");
    }
  }
);

interface RevenueCatEntitlement {
  expires_date: string | null;
}

interface RevenueCatSubscriberResponse {
  subscriber?: {
    entitlements?: Record<string, RevenueCatEntitlement>;
  };
}

/**
 * クライアント（SubscriptionStore）から明示的に呼ばれ、RevenueCatのSubscriber
 * REST APIを直接叩いて現在の権利状態を取得し、users/{uid}.isProへ反映する。
 * revenueCatWebhookの配信が何らかの理由で（インフラ側の一時的な問題、ダッシュ
 * ボード設定ミス等）届かなかった場合の自己修復用フォールバック——「クライアント
 * 側はProと表示されるのに、相談機能を呼ぶとサーバー側でPro限定エラーになる」
 * という不具合（クライアントはRevenueCat SDKを直接見るが、サーバーはWebhookが
 * 書き込むFirestoreのミラー値しか見ていない、という非対称性が原因）への対策。
 * 呼び出し元は自分自身のuidの状態しか同期できない（他人のisProを書き換える
 * 経路にはならない）。
 */
export const syncProStatus = onCall(
  {
    secrets: [revenueCatSecretApiKey],
    timeoutSeconds: 30,
    memory: "256MiB",
    enforceAppCheck: APP_CHECK_ENFORCED,
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "authentication required");
    }

    const apiKey = revenueCatSecretApiKey.value();
    if (!apiKey) {
      // シークレット未設定ならRevenueCatに問い合わせようがない。誤ってisProを
      // falseへ巻き戻さないよう、何もせず安全側に倒す。
      logger.warn("syncProStatus called but REVENUECAT_SECRET_API_KEY is not set");
      return { isPro: null };
    }

    const response = await fetch(
      `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(uid)}`,
      { headers: { Authorization: `Bearer ${apiKey}` } }
    );
    if (!response.ok) {
      logger.error("syncProStatus RevenueCat request failed", {
        uid,
        status: response.status,
      });
      throw new HttpsError("unavailable", "failed to reach RevenueCat");
    }

    const data = (await response.json()) as RevenueCatSubscriberResponse;
    const entitlement = data.subscriber?.entitlements?.[PRO_ENTITLEMENT_ID];
    const isPro =
      !!entitlement &&
      (entitlement.expires_date === null ||
        new Date(entitlement.expires_date).getTime() > Date.now());
    // 買い切みプラン（expires_date: null）はisProではあるがメディア同期の
    // 対象外——applyProStatusのhasMediaSync解説コメント参照。
    const hasMediaSync = isPro && entitlement?.expires_date !== null;

    await applyProStatus(uid, isPro, hasMediaSync, "client-sync");
    return { isPro };
  }
);

/** `collection`のうち、ドキュメントIDが`prefix`で始まるものを全て削除する。
 * usage/{uid}_{date}やwatchRateLimit/{uid}_{deviceId}_{window}のように、
 * uidをドキュメントID側に埋め込んだ複合キー方式のコレクション（uidの
 * サブコレクションではないため`recursiveDelete`では触れられない）を
 * 削除するために使う。 */
async function deleteDocsWithIdPrefix(
  db: FirebaseFirestore.Firestore,
  collection: string,
  prefix: string
): Promise<void> {
  const upperBound = prefix + "";
  for (;;) {
    const snap = await db
      .collection(collection)
      .where(FieldPath.documentId(), ">=", prefix)
      .where(FieldPath.documentId(), "<", upperBound)
      .limit(400)
      .get();
    if (snap.empty) return;
    const batch = db.batch();
    snap.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    if (snap.size < 400) return;
  }
}

/**
 * ユーザー自身のアカウントとそれに紐づく全データを完全に削除する。
 * App Storeガイドライン5.1.1(v)（アカウント作成を提供するアプリは、アプリ内
 * での削除手段も提供する義務がある）への対応。呼び出し元は自分自身のuidしか
 * 操作できない（他人のデータを消す経路にはならない）。
 * 削除対象: Firestoreの users/{uid} 以下（entries/watchDevicesサブコレクション
 * を含め再帰削除）、usage/{uid}_*・watchRateLimit/{uid}_* の複合キー方式
 * ドキュメント群、Storageの users/{uid}/ 配下の写真・動画、最後にFirebase Auth
 * のユーザー本体。各ステップは冪等（すでに無いものを消そうとしても失敗しない）
 * ため、途中でタイムアウトしても安全に再試行できる。
 */
export const deleteAccount = onCall(
  { timeoutSeconds: 300, memory: "256MiB", enforceAppCheck: APP_CHECK_ENFORCED },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "authentication required");
    }

    const db = getFirestore();

    await db.recursiveDelete(db.collection("users").doc(uid));
    await deleteDocsWithIdPrefix(db, "usage", `${uid}_`);
    await deleteDocsWithIdPrefix(db, "watchRateLimit", `${uid}_`);

    try {
      const bucket = getStorage().bucket();
      await bucket.deleteFiles({ prefix: `users/${uid}/`, force: true });
    } catch (err) {
      logger.error("deleteAccount storage cleanup failed", { uid, err });
    }

    try {
      await getAuth().deleteUser(uid);
    } catch (err) {
      // 直前の呼び出しが一部失敗して再試行された場合など、既にAuth側の
      // ユーザーが消えていることがある——それ自体はエラーではない。
      const code = (err as { code?: string } | null)?.code;
      if (code !== "auth/user-not-found") {
        logger.error("deleteAccount deleteUser failed", { uid, err });
        throw new HttpsError("internal", "failed to delete auth user");
      }
    }

    return { ok: true };
  }
);

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
  /** 入力音声の実際の長さ（秒）。ffmpegの標準エラー出力にある
   * "Duration: HH:MM:SS.xx" 行から取得。パースできなければnull
   * （月間利用量の集計はその回だけスキップする——文字起こし自体は止めない）。 */
  durationSeconds: number | null;
}

/** ffmpegの標準エラー出力に含まれる"Duration: HH:MM:SS.xx"を秒数に変換する。
 * ffprobe等の追加バイナリを増やさず、既に実行しているffmpeg呼び出しの出力を
 * そのまま流用できる。 */
function parseFfmpegDurationSeconds(stderr: string | undefined | null): number | null {
  if (!stderr) return null;
  const match = /Duration:\s*(\d+):(\d+):(\d+(?:\.\d+)?)/.exec(stderr);
  if (!match) return null;
  const [, hours, minutes, seconds] = match;
  return Number(hours) * 3600 + Number(minutes) * 60 + Number(seconds);
}

/**
 * 小声・ボソボソ声（ウィスパーボイス）でも文字起こし精度を落とさないよう、
 * Whisperに送る前にffmpegで音量の底上げ（dynaudnorm）とノイズ除去（afftdn）をかける。
 * 処理に失敗した場合は元の音声データのまま続行する（文字起こし自体は止めない）。
 */
async function enhanceAudio(inputBuffer: Buffer, mimeType: string): Promise<EnhancedAudio> {
  if (!ffmpegPath) return { buffer: inputBuffer, mimeType, durationSeconds: null };

  const dir = await mkdtemp(join(tmpdir(), "voicejournal-"));
  const inputPath = join(dir, "input.m4a");
  const outputPath = join(dir, "output.wav");

  try {
    await writeFile(inputPath, inputBuffer);
    const { stderr } = await execFileAsync(ffmpegPath, [
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
    return {
      buffer,
      mimeType: "audio/wav",
      durationSeconds: parseFfmpegDurationSeconds(stderr),
    };
  } catch (err) {
    logger.warn("enhanceAudio failed, using original audio", err);
    const stderr = (err as { stderr?: string } | null)?.stderr;
    return { buffer: inputBuffer, mimeType, durationSeconds: parseFfmpegDurationSeconds(stderr) };
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
  "gratitude",
  "happy",
  "funny",
  "relief",
  "calm",
  "boredom",
  "regret",
  "dislike",
]);

const EMOTION_LABEL_JA: Record<string, string> = {
  satisfaction: "満足",
  gratitude: "感謝",
  happy: "嬉しい",
  love: "好き",
  funny: "面白い",
  joy: "楽しい",
  excited: "ドキドキ",
  relief: "安心",
  calm: "穏やか",
  neutral: "普通",
  boredom: "退屈",
  anxious: "不安",
  sadness: "悲しい",
  fatigue: "疲れた",
  regret: "後悔",
  anger: "怒り",
  dislike: "嫌い",
};

const EMOTION_LABEL_EN: Record<string, string> = {
  satisfaction: "Satisfaction",
  gratitude: "Gratitude",
  happy: "Happy",
  love: "Love",
  funny: "Funny",
  joy: "Joy",
  excited: "Excited",
  relief: "Relief",
  calm: "Calm",
  neutral: "Neutral",
  boredom: "Boredom",
  anxious: "Anxious",
  sadness: "Sad",
  fatigue: "Tired",
  regret: "Regret",
  anger: "Anger",
  dislike: "Dislike",
};

async function structure(
  apiKey: string,
  transcript: string,
  summaryLevel: SummaryLevel,
  locale: Locale,
  allowedCategories: Set<AllowedCategory>,
  glossary?: string
): Promise<StructuredResult> {
  const now = new Date();
  const categoryNote = buildCategoryRestrictionNote(allowedCategories, locale);
  const systemPrompt =
    locale === "en"
      ? buildSystemPromptEn(
          jstDateString(now),
          jstWeekdayString(locale, now),
          summaryLevel,
          categoryNote,
          glossary
        )
      : buildSystemPrompt(
          jstDateString(now),
          jstWeekdayString(locale, now),
          summaryLevel,
          categoryNote,
          glossary
        );

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      // 事実の捏造を減らすため低めに設定。
      temperature: 0.3,
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
  const parsed = JSON.parse(data.choices[0].message.content) as StructuredResult;
  return enforceCategoryRestriction(parsed, allowedCategories);
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
  allowedCategories?: string[];
}

export const processVoiceMemo = onCall(
  // Proプランは録音15分まで許可するため、ffmpeg処理・Whisper転写の時間を見込んで
  // 通常より長めのタイムアウト・メモリを確保する。
  //
  // App Check（App Attest）はwatchOSで使えないため、この関数だけは
  // フレームワークレベルでの強制をせず、ハンドラ内で「App Checkトークンが
  // あるか」「Watchペアリング時発行のデバイス秘密鍵で認証できるか」の
  // どちらかを要求する（両方無ければ拒否）。
  {
    secrets: [openAiApiKey],
    timeoutSeconds: 300,
    memory: "2GiB",
    enforceAppCheck: false,
  },
  async (request) => {
    const { audioBase64, mimeType, customWords, summaryLevel, locale, allowedCategories } =
      (request.data ?? {}) as ProcessVoiceMemoRequest;
    const loc = normalizeLocale(locale);
    const allowed = normalizeAllowedCategories(allowedCategories);

    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", MESSAGES[loc].authRequired);
    }
    if (!audioBase64) {
      throw new HttpsError("invalid-argument", MESSAGES[loc].noAudio);
    }

    // Watch単体からの呼び出しは、App Checkの代わりにペアリング時発行の
    // デバイス秘密鍵で検証し、漏洩時の被害を抑える別枠のバーストレート
    // 制限もかける。ヘッダーが無ければ通常のiPhoneクライアントからの
    // 呼び出しなので、App Checkトークンの有無で判定する。
    const watchAuth = extractWatchDeviceAuth(request.rawRequest);
    if (APP_CHECK_ENFORCED && !watchAuth && !request.app) {
      throw new HttpsError("unauthenticated", MESSAGES[loc].authRequired);
    }

    try {
      if (watchAuth) {
        await verifyWatchDeviceSecret(uid, watchAuth, loc);
        await consumeWatchRateLimit(uid, watchAuth.deviceId, loc);
      }

      await consumeDailyQuota(uid, loc);
      await checkMonthlyMinutesBudget(uid, loc);

      const apiKey = openAiApiKey.value();
      const rawAudioBuffer = Buffer.from(audioBase64, "base64");
      const enhanced = await enhanceAudio(rawAudioBuffer, mimeType ?? "audio/m4a");
      if (enhanced.durationSeconds !== null) {
        await recordMonthlyMinutesUsage(uid, enhanced.durationSeconds);
      }
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
        allowed,
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

You will be given a list of the user's past diary entries, ideas, and tasks below, each with its date. Diary entries that had an emotion tag assigned are marked with "— <emotion>" right after the date.
Answer the user's question in English, using ONLY the information in that list as your source.
- If you find relevant entries, mention which date(s) they're from.
- If nothing relevant is found, honestly say so instead of guessing or making something up.
- If asked for a trend or pattern, back it up with concrete counts or frequency from the entries.
- If asked to compile a list, present it as a concise bullet list.
- If asked to analyze the CAUSE of a feeling (e.g. "why have I been anxious lately?", "what's been bringing me down?"), don't just list the matching entries — actively look across entries near each other in time for recurring situations, people, places, or events that line up with that emotion tag, and lay out the pattern you found as a plausible explanation. Phrase it as an inference grounded in what's written ("it looks like ___ tends to coincide with ___"), not as a certain diagnosis, and say so if the entries are too sparse to support any real pattern.
Keep your answer concise and conversational, not a wall of text.`;
  }

  return `あなたはユーザー本人が過去に記録した音声メモ・日記を横断的に参照して、質問に答えるAIアシスタントです。

以下に、ユーザーが過去に記録した日記・アイデア・タスクの一覧を日付つきで渡します。感情タグが付いている日記には、日付の直後に「— <感情>」の形で付記されています。
これらの内容だけを根拠に、ユーザーの質問に日本語で答えてください。
- 該当する記録があれば、いつの記録か（日付）に触れてください。
- 該当する記録が見当たらない場合は、推測で答えを作らず、正直に見つからなかったと伝えてください。
- 傾向や頻度を尋ねられた場合は、件数など具体的な根拠を示してください。
- リスト化を求められた場合は、簡潔な箇条書きでまとめてください。
- 「最近なんで不安なんだろう」「何にモヤモヤしてるんだろう」のように感情の原因分析を求められた場合は、単に該当する記録を列挙するだけで終わらせないでください。該当する感情タグの前後・周辺の記録も横断的に見て、繰り返し出てくる出来事・人物・場所・状況などのパターンを探し、見つかった傾向を「〜という時に〜な気分になっていることが多いようです」のように、記録から読み取れる推測として筋道立てて提示してください。断定はせず、記録が少なすぎてパターンと呼べない場合は無理に決めつけず正直にそう伝えてください。
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

const EMBEDDING_MODEL = "text-embedding-3-small";
/** 相談機能の埋め込み検索で、質問に近い順に何件のエントリをコンテキストへ
 * 渡すか。多すぎるとコスト・精度が悪化し、少なすぎると見落としが増える。 */
const KNOWLEDGE_BASE_TOP_K = 15;

async function embedText(apiKey: string, text: string): Promise<number[]> {
  const response = await fetch("https://api.openai.com/v1/embeddings", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ model: EMBEDDING_MODEL, input: text }),
  });
  if (!response.ok) {
    const body = await response.text();
    throw new Error(`embeddings API failed: ${body}`);
  }
  const data = (await response.json()) as { data: { embedding: number[] }[] };
  return data.data[0].embedding;
}

function cosineSimilarity(a: number[], b: number[]): number {
  let dot = 0;
  let normA = 0;
  let normB = 0;
  const len = Math.min(a.length, b.length);
  for (let i = 0; i < len; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA === 0 || normB === 0) return 0;
  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}

/** Firestore上のentryドキュメント1件分を、埋め込み対象のプレーンテキストに変換する。 */
function entryDocToEmbeddingText(data: FirebaseFirestore.DocumentData): string {
  const parts: string[] = [];
  if (typeof data.summary === "string" && data.summary.trim()) {
    parts.push(data.summary.trim());
  }
  for (const note of (data.notes ?? []) as { title?: string; content?: string }[]) {
    if (note.title) parts.push(note.title);
    if (note.content) parts.push(note.content);
  }
  for (const task of (data.tasks ?? []) as { title?: string }[]) {
    if (task.title) parts.push(task.title);
  }
  return parts.join("\n").trim();
}

/** Firestore上のentryドキュメント一覧を、クライアント側の
 * lib/utils/journal_context_format.dart（formatEntriesAsContext）とほぼ同じ
 * 「日付つきプレーンテキスト」形式に整形する。AIが慣れた形式を保つ狙い。 */
function formatFirestoreEntriesAsContext(
  docs: FirebaseFirestore.DocumentData[],
  locale: Locale
): string {
  const dateFormatter = new Intl.DateTimeFormat(locale === "en" ? "en-US" : "ja-JP", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
  const taskLabel = locale === "en" ? "Task" : "タスク";
  const doneMark = locale === "en" ? "(done) " : "(完了) ";
  const lines: string[] = [];

  for (const data of docs) {
    const createdAt = new Date(data.created_at ?? "");
    const emotionId = typeof data.emotion === "string" ? data.emotion : null;
    const emotionLabel = emotionId
      ? (locale === "en" ? EMOTION_LABEL_EN : EMOTION_LABEL_JA)[emotionId]
      : undefined;
    const emotionSuffix = emotionLabel ? ` — ${emotionLabel}` : "";
    lines.push(
      `■ ${Number.isNaN(createdAt.getTime()) ? "" : dateFormatter.format(createdAt)}${emotionSuffix}`
    );
    for (const note of (data.notes ?? []) as {
      category?: string;
      title?: string;
      content?: string;
    }[]) {
      const label =
        locale === "en"
          ? note.category === "アイデア"
            ? "Idea"
            : "Feeling"
          : (note.category ?? "");
      const title = note.title ? `${note.title}: ` : "";
      lines.push(`[${label}] ${title}${note.content ?? ""}`);
    }
    for (const task of (data.tasks ?? []) as {
      title?: string;
      done?: number | boolean;
    }[]) {
      const done = task.done === 1 || task.done === true;
      lines.push(`[${taskLabel}] ${done ? doneMark : ""}${task.title ?? ""}`);
    }
    lines.push("");
  }
  return lines.join("\n");
}

/**
 * 相談機能（第二の脳）用のコンテキスト取得。アカウント同期済み（Firestoreに
 * entriesがある）ユーザーには埋め込み検索で質問に近い記録だけを絞り込んで渡し、
 * メモ量が増えてもコンテキスト長・コストが際限なく膨らまないようにする。
 * 同期していない（匿名）ユーザーや、埋め込みがまだ1件も無い場合は、クライアント
 * から渡された全件詰め込みコンテキストにフォールバックする
 * （[[project_voicejournal_knowledge_base_chat]]のMVP方式）。
 */
async function buildKnowledgeBaseContext(
  apiKey: string,
  uid: string,
  question: string,
  fallbackContext: string,
  locale: Locale
): Promise<string> {
  try {
    const snapshot = await getFirestore()
      .collection("users")
      .doc(uid)
      .collection("entries")
      .get();
    if (snapshot.empty) return fallbackContext;

    const withEmbeddings = snapshot.docs
      .map((doc) => doc.data())
      .filter(
        (data): data is FirebaseFirestore.DocumentData & { embedding: number[] } =>
          Array.isArray(data.embedding) && data.embedding.length > 0
      );
    if (withEmbeddings.length === 0) return fallbackContext;

    const questionEmbedding = await embedText(apiKey, question);
    const ranked = withEmbeddings
      .map((data) => ({
        data,
        score: cosineSimilarity(questionEmbedding, data.embedding),
      }))
      .sort((a, b) => b.score - a.score)
      .slice(0, KNOWLEDGE_BASE_TOP_K)
      .map((r) => r.data);

    return formatFirestoreEntriesAsContext(ranked, locale);
  } catch (err) {
    // 埋め込み検索が失敗しても機能自体は落とさず、全件詰め込みで回答を継続する。
    logger.error("buildKnowledgeBaseContext embedding search failed, falling back", err);
    return fallbackContext;
  }
}

interface AskKnowledgeBaseRequest {
  question: string;
  context?: string;
  locale?: string;
}

// Proプラン限定機能。課金基盤（RevenueCat + revenueCatWebhook）が反映した
// users/{uid}.isPro を見て、非Proは弾く。
export const askKnowledgeBase = onCall(
  {
    secrets: [openAiApiKey],
    timeoutSeconds: 60,
    memory: "256MiB",
    enforceAppCheck: APP_CHECK_ENFORCED,
  },
  async (request) => {
    const { question, context, locale } = (request.data ?? {}) as AskKnowledgeBaseRequest;
    const loc = normalizeLocale(locale);

    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", MESSAGES[loc].authRequired);
    }
    if (!(await isProUser(uid))) {
      throw new HttpsError("permission-denied", MESSAGES[loc].proRequired);
    }
    if (!question || !question.trim()) {
      throw new HttpsError("invalid-argument", MESSAGES[loc].noText);
    }

    try {
      const apiKey = openAiApiKey.value();
      const effectiveContext = await buildKnowledgeBaseContext(
        apiKey,
        uid,
        question.trim(),
        (context ?? "").trim(),
        loc
      );
      const answer = await answerKnowledgeBaseQuestion(
        apiKey,
        question.trim(),
        effectiveContext,
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

/**
 * users/{uid}/entries/{entryId} への書き込みをトリガーに、相談機能（第二の脳）の
 * 埋め込み検索用ベクトルを裏側で計算してentryドキュメントに書き戻す。書き戻し
 * 自体が再度このトリガーを起動するが、embedding_source_hashで内容が変わって
 * いなければ即座にスキップするため無限ループにはならない。
 * ベストエフォート処理: 失敗してもクラウド同期自体は妨げない（埋め込みが
 * 無い/一部のエントリだけでも、buildKnowledgeBaseContextが安全に動作する）。
 */
export const onEntryWritten = onDocumentWritten(
  { document: "users/{uid}/entries/{entryId}", secrets: [openAiApiKey] },
  async (event) => {
    const after = event.data?.after;
    if (!after || !after.exists) return; // 削除された場合は何もしない

    const data = after.data() ?? {};
    const text = entryDocToEmbeddingText(data);
    if (!text) return;

    const hash = createHash("sha256").update(text).digest("hex");
    if (data.embedding_source_hash === hash) return; // 内容未変更（自分の書き戻し含む）

    try {
      const embedding = await embedText(openAiApiKey.value(), text);
      await after.ref.update({ embedding, embedding_source_hash: hash });
    } catch (err) {
      logger.error("onEntryWritten embedding failed", err);
    }
  }
);

function buildWeeklyReportSystemPrompt(locale: Locale): string {
  if (locale === "en") {
    return `You are an AI assistant that reviews a user's own voice-memo journal entries from the past week and writes a short "weekly brain report" summarizing their emotional trends and thinking patterns.

You will be given the week's diary entries, ideas, and tasks below, each with its date, plus a pre-counted breakdown of emotion tags for the week. Analyze ONLY this content and respond with a JSON object in this exact shape:

{
  "mood_headline": "One short, punchy catchphrase headline (under ~12 words) capturing the week's emotional pattern, quoting the two most common emotions from the given breakdown with their approximate percentages of the week's total, e.g. \\"An 'Excited 70% / Anxious 30%' challenger week!\\". Compute the percentages yourself from the given counts — never invent numbers not supported by the breakdown. If the breakdown is empty, write a gentle one-line note that there wasn't enough emotional data this week instead of inventing a mood.",
  "emotion_narrative": "1-2 sentences describing the emotional trend across the week (e.g. which day had the most of a particular feeling, whether it improved or worsened toward the weekend). Write it in a warm, encouraging tone, in English. If there isn't enough emotional content to say anything meaningful, say so briefly instead of inventing a trend.",
  "top_keywords": [ up to 10 objects like {"keyword": "a literal short word or phrase (roughly 2-8 characters/words) copied as-is from the entries — NOT an abstracted theme name, so it can be matched back against the original text", "count": approximate number of times it came up} ], ordered by how often they came up. Only include a keyword if it's genuinely recurring or notable (don't pad the list to reach 10). Empty array if nothing recurring.
  "shining_ideas": [ up to 2 objects like {"title": "short idea title", "reason": "1 short sentence on why this idea stands out"} ] — pick from the "Idea" entries only, the ones with the most potential or spark. Empty array if there are no ideas this week.
  "highlight_quote": { "quote": "the single most striking/positive/insightful line quoted (or lightly trimmed) from this week's Diary entries only — pick the one that best captures a realization, a win, or genuine emotion. Empty string if there are no diary entries this week.", "reason": "1 short sentence on why this line stands out" },
  "advice": "One short, concrete, actionable tip for the upcoming week based on the patterns you noticed (e.g. a day of the week that tends to be busy). Keep it under 2 sentences, warm and non-preachy, in English.",
  "weekly_letter": "A warm, personal, narrative-style letter (roughly 150-300 words) written AS IF a thoughtful friend who read every entry this week is writing directly to the user. Open with an address like \\"To you, this week\\" (vary the exact phrasing naturally instead of repeating a fixed template every time) and write in second person (\\"you\\"), weaving together the week's diary moments, tasks accomplished, ideas sparked, and emotional arc into one flowing story — not a bullet-point recap. Reference specific concrete details from the entries (not generic platitudes) so it clearly reads as written about THIS week, not a template. Close with a genuine, warm sign-off. If there is too little content this week to write something genuine, write a short, honest, still-warm note acknowledging the quiet week instead of fabricating detail."
}

Output ONLY the JSON object, no extra commentary.`;
  }

  return `あなたはユーザー本人が1週間分記録した音声メモ（日記・アイデア・タスク）を振り返り、「週刊脳内レポート」として感情の傾向や思考パターンを短くまとめるAIアシスタントです。

以下に今週の日記・アイデア・タスクの一覧を日付つきで、そして今週の感情タグの集計済み内訳を渡します。この内容だけを根拠に分析し、必ず以下の形のJSONオブジェクトで出力してください：

{
  "mood_headline": "今週の感情パターンを表す、短くキャッチーな一言見出し（15文字〜30文字程度）。渡された感情タグの内訳から最も多い上位2つの感情とそのおおよその割合（%）を引用すること。例：「『ワクワク70%／焦り30%』の挑戦者モード」。割合は必ず渡された集計値から自分で計算し、根拠のない数字を作らないこと。内訳が空の場合は、無理に気分を作らず「今週は感情の記録が少なめでした」のような優しい一言にすること。",
  "emotion_narrative": "今週の感情の傾向を1〜2文で。例えば特定の感情がどの曜日に集中していたか、週末にかけて改善/悪化したかなど。温かく励ますようなトーンで日本語で書いてください。感情に関する記録が少なすぎて有意な傾向が言えない場合は、無理に傾向を作らず正直にそう書いてください。",
  "top_keywords": [ 最大10件、{"keyword": "記録中の文章からそのまま抜き出した、短い単語・フレーズ(2〜8文字程度)。要約・言い換えした抽象的なテーマ名にはせず、元の文章と照合できる形で使うこと。", "count": 言及されたおおよその回数} という形のオブジェクト。よく出てきた順。10件に満たなくても無理に埋めず、本当に繰り返し出てきた・印象的だったものだけを入れること。繰り返し出てきたテーマが無ければ空配列。 ],
  "shining_ideas": [ 最大2件、{"title": "アイデアの短いタイトル", "reason": "なぜこのアイデアが光っているかの短い理由（1文）"} という形のオブジェクト。「アイデア」カテゴリのnoteの中から、特にポテンシャルや閃きを感じるものを選ぶこと。今週アイデアが無ければ空配列。 ],
  "highlight_quote": { "quote": "今週の「日記」カテゴリのnoteの中から、気づき・達成・率直な感情が最もよく表れている一文を、そのまま（または軽くトリミングして）引用したもの。今週日記が無ければ空文字列。", "reason": "なぜこの一文が光っているかの短い理由（1文）" },
  "advice": "気づいたパターンを踏まえた、来週に向けた短く具体的なワンポイントアドバイス。2文以内、説教くさくなく温かいトーンで、日本語で。",
  "weekly_letter": "今週の日記・タスク・アイデア・感情の記録を全て読み込んだ、思いやりのある友人のような視点で書く、温かくストーリー性のある手紙（300〜500文字程度）。冒頭は「今週のあなたへ」のような呼びかけで始め（毎回まったく同じ言い回しの繰り返しにならないよう自然に言葉を変えること）、二人称（「あなた」）で語りかける文体で、今週の出来事・達成したタスク・浮かんだアイデア・感情の起伏を、箇条書きではなく一つの物語として織り交ぜて書くこと。抽象的な決まり文句ではなく、実際の記録に出てきた具体的な内容に触れ、「まさに今週について書かれた手紙」だと感じられるようにすること。最後は温かい結びの言葉で締めくくること。今週の記録が少なすぎて具体的に書けない場合は、無理に内容を作らず、静かな一週間だったことを認める短く正直で温かい一言にすること。"
}

JSONオブジェクトのみを出力し、余計な説明文は含めないでください。`;
}

interface WeeklyReportInsightsResult {
  mood_headline: string;
  emotion_narrative: string;
  top_keywords: { keyword: string; count: number }[];
  shining_ideas: { title: string; reason: string }[];
  highlight_quote: { quote: string; reason: string };
  advice: string;
  weekly_letter: string;
}

/**
 * 過去の記録を丸ごとプロンプトに詰め込んで分析させるMVP実装。askKnowledgeBaseと同様、
 * メモ量が増えてコンテキストに収まらなくなったら埋め込み検索方式への置き換えを検討する。
 */
async function generateWeeklyReportInsights(
  apiKey: string,
  context: string,
  emotionBreakdown: Record<string, number>,
  locale: Locale
): Promise<WeeklyReportInsightsResult> {
  const systemPrompt = buildWeeklyReportSystemPrompt(locale);
  const breakdownEntries = Object.entries(emotionBreakdown).filter(([, c]) => c > 0);
  const breakdownText = breakdownEntries.length
    ? breakdownEntries.map(([tag, count]) => `${tag}: ${count}`).join(", ")
    : locale === "en" ? "(no emotion data this week)" : "（今週の感情記録なし）";
  const userContent =
    locale === "en"
      ? `[This week's emotion tag breakdown]\n${breakdownText}\n\n[This week's entries]\n${context || "(none)"}`
      : `【今週の感情タグ内訳】\n${breakdownText}\n\n【今週の記録】\n${context || "（記録がありません）"}`;

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
    mood_headline: result.mood_headline ?? "",
    emotion_narrative: result.emotion_narrative ?? "",
    top_keywords: (result.top_keywords ?? []).slice(0, 10).map((k) => ({
      keyword: k.keyword ?? "",
      count: typeof k.count === "number" ? k.count : 0,
    })),
    shining_ideas: (result.shining_ideas ?? []).slice(0, 2).map((i) => ({
      title: i.title ?? "",
      reason: i.reason ?? "",
    })),
    highlight_quote: {
      quote: result.highlight_quote?.quote ?? "",
      reason: result.highlight_quote?.reason ?? "",
    },
    advice: result.advice ?? "",
    weekly_letter: result.weekly_letter ?? "",
  };
}

interface GenerateWeeklyReportRequest {
  context?: string;
  emotionBreakdown?: Record<string, number>;
  locale?: string;
}

// Proプラン限定機能。課金基盤（RevenueCat + revenueCatWebhook）が反映した
// users/{uid}.isPro を見て、非Proは弾く。
export const generateWeeklyReport = onCall(
  {
    secrets: [openAiApiKey],
    timeoutSeconds: 60,
    memory: "256MiB",
    enforceAppCheck: APP_CHECK_ENFORCED,
  },
  async (request) => {
    const { context, emotionBreakdown, locale } =
      (request.data ?? {}) as GenerateWeeklyReportRequest;
    const loc = normalizeLocale(locale);

    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", MESSAGES[loc].authRequired);
    }
    if (!(await isProUser(uid))) {
      throw new HttpsError("permission-denied", MESSAGES[loc].proRequired);
    }

    try {
      const apiKey = openAiApiKey.value();
      const result = await generateWeeklyReportInsights(
        apiKey,
        (context ?? "").trim(),
        emotionBreakdown ?? {},
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
  allowedCategories?: string[];
}

export const processTextMemo = onCall(
  {
    secrets: [openAiApiKey],
    timeoutSeconds: 60,
    memory: "256MiB",
    enforceAppCheck: APP_CHECK_ENFORCED,
  },
  async (request) => {
    const { text, summaryLevel, locale, allowedCategories } =
      (request.data ?? {}) as ProcessTextMemoRequest;
    const loc = normalizeLocale(locale);
    const allowed = normalizeAllowedCategories(allowedCategories);

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
        loc,
        allowed
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
