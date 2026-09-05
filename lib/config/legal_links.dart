/// アプリ全体（ペイウォール・設定画面）で使う利用規約・プライバシーポリシーのURLと
/// 問い合わせ先メールアドレス。
///
/// ページ本体は `public/terms.html` / `public/privacy.html`（Firebase Hostingで
/// `firebase deploy --only hosting` により公開）。文面を更新した場合は再デプロイが必要。
class LegalLinks {
  static const String termsOfServiceUrl = 'https://voicejournal-bbafa.web.app/terms.html';
  static const String privacyPolicyUrl = 'https://voicejournal-bbafa.web.app/privacy.html';
  static const String supportEmail = 'VoiceBrain1004@gmail.com';
}
