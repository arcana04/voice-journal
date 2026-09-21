# Round 9 — English classification & task-timing re-verification (2026-09-21〜)

How to run: device language = English, no category filter chips selected. Speak or type each
transcript into the text-input fallback, then record what actually came out (category split,
task count, and for timing cases: due date/time, all-day vs timed, recurrence).

Mark: ✅ match / ⚠️ partial (right shape, wrong detail) / ❌ wrong.

## Part A — revisit: 5 known failures from 9/14, never retested since

These are still marked ✖ in `english_classification_eval_log.md` and predate every classification
prompt fix made in the 9/19〜9/21 audit rounds (hedge/resignation rules, topic-split direction,
factual-event diary widening, etc.). Good chance some already got fixed as a side effect — worth
confirming either way.

Sentences below are deliberately longer/more rambling than the original 9/14 short-phrase versions
(short phrases make classification artificially easy) — same core ambiguity, more wrapping.

| id | transcript | expected | actual | result | notes |
|---|---|---|---|---|---|
| idea-vs-diary-wish-02 | "So work was kind of draining today, nothing terrible just draining, and on the walk back I ended up going down this whole rabbit hole again about moving — I've been thinking maybe I should move somewhere closer to the ocean, like actually looking into it, checking listings and stuff, not just daydreaming about it like I usually do." | 1 idea (not diary) | | | previously sorted task |
| idea-vs-task-maybe-01 | "I don't know, the new year always makes me think about picking up something new, and this time I keep coming back to the same idea — maybe I'll start learning Spanish this year, not sure when though, probably whenever I actually get around to it." | 1 idea, 0 task | | | previously sorted task |
| question-to-self-01 | "I was going through my bank statement earlier and saw the gym charge again and just kind of sat there for a second — should I even keep this gym membership? I haven't gone in like two months, and I keep telling myself I will but I just don't." | 1 idea (not diary) | | | previously sorted diary |
| gratitude-vs-idea-01 | "Moving day was honestly a lot easier than I expected, my friend showed up super early and just powered through with me for like four hours straight without complaining once — I'm really grateful my friend helped me move this weekend, it made me think I should do something nice for her, like I don't know, dinner or something, haven't figured it out yet." | 1 diary + 1 idea | | | previously sorted task "do something nice for my friend" |
| conditional-idea-01 | "My back has been absolutely killing me all week from sitting at this desk, it's honestly getting kind of unbearable by the afternoon — if I ever get a raise, I think I'd want to finally get a good office chair, one of those nice ergonomic ones, but right now it's just not in the budget." | 1 idea + 1 diary (not task) | | | previously sorted task "get a good office chair" |

## Part B — new: task-timing extraction, natural/longer phrasing

Targets the due_weekday / weeks_ahead / interval_weeks / days_before / all-day-vs-timed machinery
that got rewritten across 9/16–9/21. All previous timing tests used short, isolated phrases —
these are longer and mix timing with other clauses, closer to round 7/8 style.

| id | transcript | expected | actual | result | notes |
|---|---|---|---|---|---|
| timing-01-double-relative | "I keep putting this off and I really shouldn't because it always ends up being a scramble at the last minute — I really need to renew my passport, and I think the sane move is to just block off some time, let's say two Fridays from now, that should give me enough buffer before things get busy again." | 1 task, due_weekday Fri weeks_ahead:2 | | | tests "N Fridays from now" phrasing embedded in a rambling sentence |
| timing-02-weekend-already-weekend | (record only if actually spoken on a Sat/Sun) "The garage has gotten to the point where I can't even find my toolbox anymore, boxes everywhere, and every time I open that door I just get instantly annoyed — I should really clean out the garage this weekend, it's been driving me crazy for weeks now and I keep saying I'll deal with it later." | 1 task, due_weekday day=today's actual Sat/Sun, weeks_ahead:0 | | | only valid test if run ON a Saturday or Sunday — checks the "don't push to next Sat" exception |
| timing-03-interval-explicit-twice-week | "I've been feeling pretty sluggish lately and I think it's finally time to actually do something about it instead of just complaining — I'm going to start going to the gym twice a week starting next Monday, figured splitting it up like that is more realistic than going every day and burning out in a week." | 1 task (or recurrence), NOT interval_weeks:2 (should not read as biweekly) | | | checks "twice a week" isn't misread as the biweekly default |
| timing-04-before-then-chain | "Been meaning to mention this — my cousin's wedding is the Saturday after next, and I still haven't sorted out what I'm wearing, so I really should get my suit dry-cleaned before then, otherwise I'm going to be scrambling the night before like I always do." | 2 tasks: wedding (due_weekday Sat, weeks_ahead:1) + dry-clean (same weekday/weeks_ahead, days_before:1) | | | chained relative reference, same shape as the 9/20 fixed case but different wording |
| timing-05-all-day-no-time | "I got a call from the dentist's office earlier but I was driving and could only half listen — reminder to myself, dentist appointment next Tuesday, don't remember the exact time yet, I'll have to check the voicemail again later." | 1 task, due_weekday Tue weeks_ahead:1, reminder_at should end up null/all-day (not midnight) | | | direct re-test of the 9/21 "reminder_at defaults to midnight" fix |
| timing-06-relative-hours-not-weekday | "I totally forgot I even had a load going until just now — can someone remind me in like three hours to take the laundry out, otherwise it's just going to sit there getting that damp smell again." | 1 task, reminder computed as offset from now, NOT due_weekday | | | checks pure relative-time (no weekday name) isn't routed through due_weekday |
| timing-07-vague-deadline-end-of-month | "Finance keeps sending these passive aggressive reminder emails and I keep ignoring them, which honestly isn't helping anyone including myself — I need to submit my expense report sometime before the end of the month, I really don't want it hanging over me into next month again." | 1 task, some reasonable due date near month-end (or left without a hard date if the prompt has no rule for this) | | | not covered by any existing rule — checks what the model does with a vague non-weekday deadline; may reveal a gap rather than a bug |
| timing-08-recurring-no-end-date | "I've tried meal prepping before and always give up after like two weeks, but I want to actually commit this time — I want to start doing meal prep every Sunday, no end date in mind, just ongoing, treating it more like a habit than some short challenge." | 1 task only (single nearest Sunday) — the auto-multi-generation feature was reverted 9/21 | | | confirms the revert actually holds; also check the app doesn't silently promise more than 1 occurrence in the confirmation UI copy |
| timing-09-two-relative-times-one-sentence | "Okay this is a bit chaotic, just got a message about this — the meeting got moved, it's now in 30 minutes, super last minute, but on a separate note the follow-up call about the same project is next Wednesday afternoon, so at least that one I have time to prepare for." | 2 tasks: one relative-offset (30 min), one due_weekday Wed weeks_ahead:0/1 + afternoon time inference | | | mixes a pure relative-time task and a weekday task in one utterance — checks they don't cross-contaminate each other's date field |
| timing-10-am-pm-ambiguous-evening | "We finally nailed down plans after going back and forth in the group chat for like a week — dinner with the Wattersons is at 7 next Friday, at that new place downtown they've been wanting to try, so I should probably book a table soon." | 1 task, due_weekday Fri, time 19:00 (PM inferred from "dinner" context) | | | AM/PM inference re-test, similar spirit to existing ampm-inference-01 but weekday-based instead of same-day |
| timing-11-days-before-no-explicit-anchor-date | "Got the notice this morning and now I'm slightly panicking about the state of this apartment — landlord's coming to inspect the apartment next Thursday, so I should probably vacuum and take out the trash the day before, because there is no way I'm doing all that the morning of." | 2 tasks: inspection (due_weekday Thu, weeks_ahead:1) + vacuum/trash (same weekday/weeks_ahead, days_before:1), due_hint naming the inspection explicitly | | | "the day before" phrased differently from "before then" — checks the days_before rule generalizes beyond the exact trained phrase |

## After running

Fill in `actual` + `result` for each row, then report back — I'll read the results, fix whatever's
broken in `functions/src/index.ts` (buildSystemPromptEn / due_weekday resolution code), and deploy.
