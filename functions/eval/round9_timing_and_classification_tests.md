# Round 9 — English classification & task-timing re-verification (2026-09-21〜)

How to run: device language = English, no category filter chips selected. Speak or type each
transcript into the text-input fallback, then record what actually came out (category split,
task count, and for timing cases: due date/time, all-day vs timed, recurrence).

Mark: ✅ match / ⚠️ partial (right shape, wrong detail) / ❌ wrong.

## Status so far (2026-09-21)

- Part A (5 revisit cases): #1 idea-vs-diary-wish-02 passed but sparked a product decision (idea
  boundary narrowed to "bounded proposal", deployed). #2 idea-vs-task-maybe-01 still imperfect,
  ruled genuinely ambiguous, not pursued further. #4 gratitude-vs-idea-01 fixed (vague/undecided
  specifics now a hedge signal, deployed) — re-verify. #3/#5 not yet reported back.
- Part B: #6, #7, #8 passed (timing-01, timing-02, timing-03 all ✅ — twice-a-week correctly did
  NOT resolve to interval_weeks:2, single Monday task only).
- New thread opened: multi-weekday recurrence (naming two/three explicit weekdays for one
  cadence, e.g. "Tuesdays and Thursdays") is suspected weak — see Part C below.

## Part C — new: multi-weekday recurrence extraction

Targets the "naming two different weekdays for one weekly cadence = NOT interval_weeks:2, use
recurrence with multiple weekdays instead" rule, which has never been directly tested with more
than one weekday name. All long/natural per current convention.

| id | transcript | expected | actual | result | notes |
|---|---|---|---|---|---|
| weekday-recur-01-two-days | "I've been feeling pretty sluggish lately and I think it's finally time to actually do something about it instead of just complaining — I'm going to start going to the gym on Tuesdays and Thursdays starting next week, figured splitting it up like that is more realistic than going every day and burning out in a week." | recurrence with weekdays [Tue, Thu], weekly, NOT interval_weeks:2 | | | direct test of the "two weekday names = twice a week" rule |
| weekday-recur-02-three-days | "Okay, new plan, I keep flaking on exercise so I'm setting actual fixed days this time instead of just 'whenever I feel like it' — gym on Mondays, Wednesdays, and Fridays starting this week, no more excuses." | recurrence with weekdays [Mon, Wed, Fri], weekly | | | three named weekdays instead of two — checks it generalizes past the two-day example in the prompt |
| weekday-recur-03-and-also-phrasing | "I want to get back into a routine, so here's the plan — every Monday I'm doing a long run, and then every Thursday, separately, I'm doing a shorter recovery jog." | recurrence with weekdays [Mon, Thu] (or two separate weekly tasks, since they're framed as different activities) | | | phrased as two separate "every X" clauses instead of one combined "on X and Y" — checks whether the model still merges them into one weekday-recurrence pattern (may or may not be desired; also tests whether two DIFFERENT activities on different days should even become one task or two) |
| weekday-recur-04-with-end-date | "Physical therapy wants me doing these stretches on a real schedule, not just randomly — Tuesdays and Fridays, starting next week, through the end of next month, then I'll reassess." | recurrence with weekdays [Tue, Fri], weekly, start next week, end date around next month's end | | | adds an explicit end date on top of the multi-weekday pattern — checks start_date/end_date extraction isn't broken by having 2 weekdays instead of 1 |
| weekday-recur-05-vague-count-then-days | "I keep telling myself I'll work out a couple times a week and then never actually pick which days, so this time I'm locking it in — Tuesdays and Thursdays, that's it, no more waffling." | recurrence with weekdays [Tue, Thu], weekly, NOT interval_weeks:2 | | | "a couple times a week" (vague count) immediately followed by the actual concrete days — checks the vague framing doesn't confuse the count/interval logic once concrete weekdays are given |
| weekday-recur-06-weekday-plus-weekend | "New habit I'm trying — lifting on Tuesdays and Thursdays during the week, and then Saturday mornings I'll do something lighter like a walk or a swim." | recurrence with weekdays [Tue, Thu] for one task, plus a separate Saturday-based task (via the existing due_weekday "weekend"/Sat handling) for the other | | | mixes the multi-weekday recurrence pattern with a same-utterance due_weekday/weekend task — checks they don't bleed into each other (e.g. Saturday accidentally folded into the Tue/Thu recurrence, or vice versa) |

## Part A — revisit: 5 known failures from 9/14, never retested since

Sentences below are deliberately longer/more rambling than the original 9/14 short-phrase versions
(short phrases make classification artificially easy) — same core ambiguity, more wrapping.

| id | transcript | expected | actual | result | notes |
|---|---|---|---|---|---|
| idea-vs-diary-wish-02 | "So work was kind of draining today, nothing terrible just draining, and on the walk back I ended up going down this whole rabbit hole again about moving — I've been thinking maybe I should move somewhere closer to the ocean, like actually looking into it, checking listings and stuff, not just daydreaming about it like I usually do." | 1 idea (not diary) | idea | ✅ (sparked a product discussion — see status above) | previously sorted task |
| idea-vs-task-maybe-01 | "I don't know, the new year always makes me think about picking up something new, and this time I keep coming back to the same idea — maybe I'll start learning Spanish this year, not sure when though, probably whenever I actually get around to it." | 1 idea, 0 task | multiple idea notes | ⚠ ruled genuinely ambiguous, not pursued | previously sorted task |
| question-to-self-01 | "I was going through my bank statement earlier and saw the gym charge again and just kind of sat there for a second — should I even keep this gym membership? I haven't gone in like two months, and I keep telling myself I will but I just don't." | 1 idea (not diary) | | | previously sorted diary |
| gratitude-vs-idea-01 | "Moving day was honestly a lot easier than I expected, my friend showed up super early and just powered through with me for like four hours straight without complaining once — I'm really grateful my friend helped me move this weekend, it made me think I should do something nice for her, like I don't know, dinner or something, haven't figured it out yet." | 1 diary + 1 idea | diary + task | ❌ → fixed (vague/undecided hedge rule added, deployed) — re-verify | previously sorted task "do something nice for my friend" |
| conditional-idea-01 | "My back has been absolutely killing me all week from sitting at this desk, it's honestly getting kind of unbearable by the afternoon — if I ever get a raise, I think I'd want to finally get a good office chair, one of those nice ergonomic ones, but right now it's just not in the budget." | 1 idea + 1 diary (not task) | diary + idea | ✅ | previously sorted task "get a good office chair" |

## Part B — task-timing extraction, natural/longer phrasing

Targets the due_weekday / weeks_ahead / interval_weeks / days_before / all-day-vs-timed machinery
that got rewritten across 9/16–9/21. All previous timing tests used short, isolated phrases —
these are longer and mix timing with other clauses, closer to round 7/8 style.

| id | transcript | expected | actual | result | notes |
|---|---|---|---|---|---|
| timing-01-double-relative | "I keep putting this off and I really shouldn't because it always ends up being a scramble at the last minute — I really need to renew my passport, and I think the sane move is to just block off some time, let's say two Fridays from now, that should give me enough buffer before things get busy again." | 1 task, due_weekday Fri weeks_ahead:2 | | ✅ | tests "N Fridays from now" phrasing embedded in a rambling sentence |
| timing-02-weekend-already-weekend | (record only if actually spoken on a Sat/Sun) "The garage has gotten to the point where I can't even find my toolbox anymore, boxes everywhere, and every time I open that door I just get instantly annoyed — I should really clean out the garage this weekend, it's been driving me crazy for weeks now and I keep saying I'll deal with it later." | 1 task, due_weekday day=today's actual Sat/Sun, weeks_ahead:0 | | ✅ | only valid test if run ON a Saturday or Sunday — checks the "don't push to next Sat" exception |
| timing-03-interval-explicit-twice-week | "I've been feeling pretty sluggish lately and I think it's finally time to actually do something about it instead of just complaining — I'm going to start going to the gym twice a week starting next Monday, figured splitting it up like that is more realistic than going every day and burning out in a week." | 1 task (or recurrence), NOT interval_weeks:2 (should not read as biweekly) | 1 task, single Monday, no interval_weeks:2 | ✅ | checks "twice a week" isn't misread as the biweekly default |
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
