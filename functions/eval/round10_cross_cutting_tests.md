# Round 10 — cross-cutting bug hunt, new angles (2026-09-25〜)

## Background

Rounds so far have concentrated heavily on **date/time arithmetic** (`due_weekday`, `due_month`,
`span_days`, `recurrence`, `days_before`, "by TIME") and basic 3-way classification boundaries
(task vs idea vs diary). Both areas have been tested extensively and most known gaps have been
fixed. This round deliberately avoids re-testing date math and instead targets areas that have
had little or no dedicated adversarial testing yet:

1. **Custom dictionary** interaction with long, rambling sentences (does a registered proper noun
   survive when buried mid-paragraph, and does it get mis-transcribed/mis-cased anyway?)
2. **Idea "検討状況" (consideration-status) extraction** — subtle shifts between "just floating an
   idea" / "actively considering" / "already decided against it"
3. **Emotion tag extraction** with mixed or conflicting emotions in one long entry (17-tag system)
4. **Task cancellation via negation** — does the model correctly suppress a task the speaker
   explicitly says is no longer needed, instead of creating it anyway?
5. **Recurrence with an exception clause** ("every Tuesday except when I'm traveling") — does the
   app do something sane (base weekly recurrence, or refuse to over-promise an exception it can't
   encode) rather than silently dropping the recurrence or hallucinating exception-handling?
6. **"Every weekday" (Mon–Fri) recurrence** — a specific weekday-set pattern that may not be
   covered by the existing due_weekday/recurrence code paths
7. **Vague/no-committed-date tasks** ("whenever you get a chance", "no rush") — should still become
   a task (not silently dropped or misrouted to idea) but with due_date left genuinely null, not a
   fabricated date
8. **Externally-conditional tasks** ("once my package arrives, I need to...") — no fixed date is
   knowable; check whether the app forces a fake date instead of leaving it open
9. **Duration-based events** ("meeting from 3 to 5") — does reminder_at anchor to the start time
   correctly and not get confused by the end time?
10. **Bilingual/code-switched custom nouns** — a custom-dictionary term embedded in an
    otherwise-English sentence with a non-English pronunciation cue

**How to run:** device language = English, no category filter chip selected. Type each transcript
into the text-input fallback (NOT voice — keeps transcription noise out of it, consistent with prior
rounds), then record what actually came out. Mark: ✅ match / ⚠️ partial / ❌ wrong.

**Deploy gotcha reminder:** the text-input fallback calls `processTextMemo`, a separate Cloud
Function from `processVoiceMemo` that happens to share the same `structure()`/prompt code. Always
deploy both together after any fix: `firebase deploy --only functions:processVoiceMemo,functions:processTextMemo`.

**Before running the custom-dictionary cases**, add a custom word first (Settings → Custom Dictionary)
matching the one named in the test — the test cases below assume "Kowalczyk" and "Xiomara" have
already been registered as custom words.

## Test cases

| id | transcript | expected | actual | result | notes |
|---|---|---|---|---|---|
| dict-01-buried-proper-noun | "So I had this whole conversation today that started out about nothing in particular, just catching up, but then somehow it turned into a pretty deep talk about work stuff, and at some point my coworker Kowalczyk brought up something I hadn't thought about — that I should really ask for a raise before the fiscal year ends, since apparently the budget gets locked down after that." | note contains "Kowalczyk" correctly spelled/cased, 1 task ("ask for a raise") extracted | | | tests whether a registered custom word survives when it's not the sentence's main subject and is several clauses deep |
| dict-02-bilingual-cue | "I need to text Xiomara back about the trip — she goes by 'see-oh-MAH-rah' if you're wondering how to say it, but anyway she wants to know if I'm still in for the July dates or if my schedule changed." | note/task contains "Xiomara" correctly (not phonetic spelling), 1 task ("text Xiomara back") | | | tests whether an inline phonetic-spelling aside confuses the model into using the phonetic spelling instead of the registered term |
| idea-status-01-just-floating | "Random thought I had in the shower — what if I started doing a monthly newsletter for the team, just recapping what everyone worked on? Not saying I'd actually do it, just an idea that popped into my head." | 1 idea, consideration status = early/just an idea (not "decided" or "in progress") | | | explicit hedge against commitment — checks the idea doesn't get marked as more advanced than it is |
| idea-status-02-actively-considering | "I've actually been going back and forth for a couple weeks now on whether to switch our project management tool from Trello to something like Linear — I've watched a few demo videos, and I think I'm leaning toward doing it, just haven't pulled the trigger yet." | 1 idea, consideration status reflects active/advanced consideration (not "just floating") | | | checks the status field actually differentiates level of commitment, not just presence of an idea |
| idea-status-03-decided-against | "We did seriously look into moving the whole team to a four-day work week earlier this year, but after crunching the numbers with HR it just wasn't going to work with our client contracts, so that idea's officially dead for now." | 1 idea, consideration status = rejected/decided-against (not "considering") | | | past-tense resolution of an idea — checks whether "dead idea" language is captured as closed rather than defaulting to open/considering |
| emotion-01-mixed-conflicting | "Today was honestly one of those weird days where I felt like three different people — I was so proud of myself for finally finishing that project, but also kind of anxious the whole afternoon about the client call tomorrow, and then my sister called with good news about the baby and I just started crying, happy tears I think, but also just overwhelmed in general." | 1 diary entry with multiple emotion tags reflecting pride, anxiety, and overwhelm/joy — not collapsed into a single dominant tag | | | stress-tests the 17-tag emotion system's ability to hold several genuinely different, even contradictory, emotions in one entry |
| negation-01-explicit-cancel | "I was going to say I need to call the insurance company about the claim, but actually never mind, my wife already handled that this morning, so scratch that, nothing to do there." | 0 tasks (the call-insurance task is explicitly retracted), possibly 1 diary note about it being resolved | | | checks the model doesn't create the task anyway despite it being mentioned in full sentence form before the retraction |
| negation-02-implicit-no-longer-needed | "Funny enough, I'd been dreading rescheduling that dentist appointment all week, but they actually called ME this morning and already moved it, so that's one less thing on my plate now." | 0 tasks (no dentist task should be created — the need was resolved before it was ever added), likely 1 diary note | | | checks a task-shaped situation described entirely in past/resolved framing doesn't get misread as still-pending |
| recur-exception-01-weekly-with-exception | "I go to therapy every Tuesday at 4pm, except obviously not when I'm out of town for work, which happens every few weeks or so — can you just set that as a standing reminder?" | a weekly Tuesday 16:00 recurrence is created (the untrackable travel exception is reasonably ignored rather than breaking the whole recurrence or fabricating exception logic) | | | checks the app degrades gracefully on an exception it structurally can't encode, rather than dropping the recurrence entirely or erroring |
| recur-weekday-01-every-weekday | "Starting Monday I want to take a 15 minute walk every weekday during my lunch break, just Monday through Friday, weekends I want to actually rest." | a recurring task covering Mon/Tue/Wed/Thu/Fri only, explicitly excluding Sat/Sun | | | checks whether "every weekday" is understood as a 5-day weekday-set pattern rather than literal daily (7-day) recurrence or a single one-off task |
| vague-date-01-whenever-you-get-a-chance | "No rush at all on this one, but whenever you get a chance, it'd be nice to finally organize all those old photos on my laptop into folders instead of one giant dump." | 1 task created, due_date genuinely null/unset (not fabricated to today or some arbitrary date), not misrouted to idea | | | checks the app doesn't force a fake deadline onto an explicitly open-ended task, and doesn't drop it into idea just because there's no date |
| conditional-01-external-trigger | "Once my replacement debit card actually arrives in the mail, I need to go update the card info on all my subscriptions before the old one gets declined somewhere." | 1 task created, due_date null (trigger is an external, unknowable-date event), task content preserves the "once the card arrives" condition in its text | | | checks the app doesn't guess a date for an event it has no way to know the timing of |
| duration-01-meeting-with-end-time | "I've got a client call from 3 to 4:30 this afternoon, can you remind me 10 minutes before it starts so I'm not scrambling?" | 1 task, reminder_at = 2:50pm today (10 min before the 3pm start), NOT anchored to 4:30 (the end time) | | | checks the model correctly identifies which of two times mentioned is the actionable one when both a start and end time are given |
| duration-02-all-day-multi-hour-event | "We've got a work offsite tomorrow that runs basically all day, like 9am to 6pm, so I just need it blocked on my calendar, no reminder needed really." | 1 task/calendar entry spanning 9:00–18:00 tomorrow (timed, not all-day), no separate reminder notification required/forced | | | checks the app doesn't collapse an explicit 9-to-6 timed block into a generic all-day event just because it spans most of the day |

## Skipped

(fill in after running, if any cases turn out to already be covered by an existing round)

## What to do with results

- ✅ across the board on a topic (e.g. all 3 idea-status cases): no action needed for that feature.
- Any ❌: bring the actual (wrong) output back for a proper fix. For consideration-status and
  emotion-tag misses, check whether the issue is prompt wording (add explicit rule + JSON example,
  per the recurring `due_month`-introduction lesson) before assuming a new schema field is needed.
- vague-date-01 / conditional-01 in particular: if either comes back with a fabricated due_date
  instead of null, that's a real product-decision bug (a false deadline is worse than no deadline)
  and should be prioritized over cosmetic misses elsewhere in this round.
