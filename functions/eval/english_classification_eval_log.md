# English classification eval — manual run log

Companion to `english_classification_eval.json`. Speak each transcript into the app in English (device language set to English, no category filter chips selected so all 3 categories are allowed), then record what actually came out on the review screen vs. what was expected.

Mark: ✅ match / ⚠️ partial (right category, wrong split/detail) / ❌ wrong category or missed entirely.

| id | expected | actual | result | notes |
|---|---|---|---|---|
| task-clear-01 | 1 task || ✅| |
| idea-clear-01 | 1 idea | | ✅| |
| diary-clear-01 | 1 diary | | ✅| |
| complaint-hides-task-01 | 1 task (+diary optional) | |✅ | |
| complaint-hides-task-02 | 1 task + 1 diary | |✅ | |
| complaint-no-task-01 | 1 diary, 0 task | |✅ | |
| idea-vs-diary-wish-01 | 1 diary (not idea) | |✅ | |
| idea-vs-diary-wish-02 | 1 idea (not diary) | | ✖|sorted task |
| idea-vs-task-maybe-01 | 1 idea (not task) | | ✖|sorted task |
| idea-vs-task-maybe-02 | 1 task (not idea) | |✅ | |
| multi-topic-split-01 | 1 task + 1 idea + 1 diary | |✅ | |
| multi-topic-split-02 | 2 tasks | |✅ | |
| sarcasm-indirect-01 | 1 diary, 0 task | |✅ | |
| implicit-task-no-verb-01 | 1 task | |⚠ | write transfer money |
| past-reflection-with-future-action-01 | 1 diary (not idea/task) | |✅ | |
| past-reflection-with-future-action-02 | 1 task + 1 diary | |✅ | |
| question-to-self-01 | 1 idea (not task) | |✖ |sorted diary |
| question-rhetorical-01 | 1 diary (not idea) | |✅ | |
| filler-heavy-01 | 1 task, fillers stripped | |✅|  |
| repeated-phrase-01 | 1 task (not 3 duplicates) | |✅ | |
| gratitude-vs-idea-01 | 1 diary + 1 idea | |✖ |sorted task➜do something nice for my friend |
| worry-vs-task-01 | 1 diary, 0 task | |✅ | |
| worry-with-task-01 | 1 task + 1 diary | |✅ | |
| short-fragment-01 | 1 task | |✅ | |
| mixed-language-code-switch-01 | 1 task, English output | |✅ | |
| long-ramble-single-topic-01 | 1 diary (not split into several) | |✅ | |
| negation-no-task-01 | 1 diary, 0 task (no bathroom task) | |✅ | |
| conditional-idea-01 | 1 idea + 1 diary (not task) | |✖ |sorted task➜get a good ofice chair |

## Summary (fill in after the full pass)

- Total: 28
- ✅ match:
- ⚠️ partial:
- ❌ wrong:
- Recurring failure pattern(s):
