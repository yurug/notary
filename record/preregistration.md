# Pre-registration of the case-study essay

**Provenance.** This document was committed to the author's blog repository,
which is private, as `kb/notes/case-study-preregistration-2.md`, commit
`b842475`, on 2026-08-04 at 08:12, before this repository's first take opened
at 06:12 UTC (08:12 local). It is reproduced here verbatim so a reader of the
essay can see what was promised before the run. The original timestamp lives
in a private history, so it is not independently checkable; the essay says so
and does not claim otherwise.

---

# The case-study essay, pre-registered

**Written 2026-08-04, before the first take of the recorded development exists.**
That date is the point of this file. A list of what an essay will show, written
after the material exists, describes the material that survived. Written before,
it is a commitment, and the essay reports against it whatever happens.

**This file is append-only.** Amendments are dated and added; nothing is edited
away. If a commitment below turns out to be impossible, the essay says so and
quotes the original.

## The subject

A redactable notary, built with a **certified core**: prove you already knew
about a bug without handing over everything you knew, by making every word of
the finding a leaf of a Merkle tree so a redacted version stays checkable
against a published root.

The architecture is the essay's real subject. One small part carries the whole
claim, and it is proven in Rocq. Everything else is ordinary OCaml and ordinary
tests, because the system's validity does not depend on it. Where that line
falls, and what the proof covers once it is drawn, is what a reader takes away.

**SHA-256 is not proven. It is named in the trusted base.** The Rocq module
proves the tree logic for an abstract hash, so the theorem holds for any hash
with the stated property, and the implementation OCaml supplies is a trust
assumption written down beside the theorem rather than hidden behind it.

## What the essay will show

Each line is a commitment. The sentence after each is what the essay reports if
that artifact never materialises, because an absence reported is evidence and an
absence quietly dropped is not.

1. **The boundary, drawn and justified.** What is inside the proven core, what is
   outside, and the argument for that line. If the line moves during the
   development, the essay shows both positions and what moved it.
2. **The theorem, in one readable statement**, with what it does not cover said
   in the same breath. If it cannot be stated readably, that is a finding about
   the design, not a presentation problem.
3. **The trusted base, enumerated.** Every assumption the proof rests on,
   including SHA-256 and the extraction. If the list is longer than expected,
   the essay prints the longer list.
4. **One decision card with its rationale**, from the ambiguity round. If the
   round is decided by accepting defaults with no reasons recorded, the essay
   reports that ratio, because it is evidence against the mechanism's value.
5. **A real specification excerpt and a real knowledge-base entry.**
6. **One cycle end to end**: the goal, the pinned inputs, the diff, the check
   output, and the judgement line written at the time.
7. **A check failure whose message pointed at a place.** If nothing fails during
   the recorded development, the essay reports that the harness never fired and
   treats it as a finding about the slice.
8. **The routing rule discriminating**, on two failures with different owners.
   If every failure routes to the same owner, the essay says the rule was not
   exercised.
9. **A comprehension checkpoint, in whichever direction it goes.** If it teaches
   the engineer something, the essay shows what. If the engineer corrects the
   agent instead, the essay says so and states that this is a weaker claim than
   the series makes.
10. **One occasion of leaving the inner loop and changing the goal.** If the stop
    rule never fires, the essay reports that it never fired. It is not arranged.

## The accounting the essay publishes, whatever it says

- The number of takes, the number re-run, the number discarded.
- The re-run criterion, as stated in advance: re-run when a take failed for a
  reason about our tooling, never when it failed for a reason about the work.
- The wall-clock time of the development.
- Which parts of the product the essay did not walk.
- The ratio of decisions carrying a recorded rationale.

## What the essay will not claim

- That the proof establishes the specification captures anyone's intent. It
  establishes a statement about a statement.
- That the untested-but-not-proven parts are correct. They are tested, and the
  claim is that the system's validity does not depend on them.
- That a redaction is safe to share. The tool renders what a redaction discloses
  and the judgement stays with the person.
- That any of this holds at team scale. One engineer, one project.
- That the loop caused the outcome. There is no control.

## What would make me abandon the essay rather than publish it

If the development produces no check failure, no routed failure and no
checkpoint worth reporting, the essay has no mechanism to show. The honest
output is then a short report saying the loop ran and left no observable trace,
published as a finding.

## Amendments

None yet.
