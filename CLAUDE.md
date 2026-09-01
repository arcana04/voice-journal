# voice-journal

## Git ワークフロー

- 作業(コード変更)が一段落するたびに、確認を挟まず自動的に `git add` → `git commit` → `git push origin main` を行ってよい。
  - ユーザーから2026-09-01に明示的に許可された標準方針。
  - ただし force push、履歴の書き換え(rebase -i, reset --hard など)、ブランチ削除は対象外 — これらは引き続き都度確認する。
  - コミットメッセージは変更内容が分かる日本語または英語で簡潔に。
