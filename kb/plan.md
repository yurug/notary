---
id: plan
type: procedure
summary: Four cycles in risk order; the theorem is stated and proven before anything can call it.
domain: plan
tags: [plan]
last-updated: 2026-08-04
related: [architecture, product]
---
# Plan

Four cycles. The order is by risk, and the risk here is not the OCaml: it is
whether the theorem can be stated readably and proven at all.

## Cycle 2 — The statement, before any proof

**Ships:** `theories/Merkle.v` with the types, the tree, the disclosure, and the
theorem **stated** with its hash parameter and injectivity hypothesis. Admitted,
not proven.

**The unknown, and why this is its own cycle:** whether the biconditional can be
written in a form a reader of the essay can follow. If the statement needs three
auxiliary definitions to be readable, the design is wrong and this is the
cheapest possible moment to learn it.

**Acceptance:** the theorem fits on a screen, and a sentence of English says the
same thing.

## Cycle 3 — The proof *(done, and it changed the obligation)*

The reverse direction was the named unknown, and attempting it produced a
different result: the obligation as stated was unsatisfiable. That is proven
rather than argued (`spec_forces_ignoring_the_proof`), and the obligation is now
soundness plus completeness, the second being about the prover-verifier pair.

`make` is green. No `verify` exists yet, so nothing satisfies either property
and that is the honest state.

## Cycle 3b — Discharge the two properties *(done, one axiom short)*

A concrete `build` and `verify` exist. **Completeness is proven and closed under
the global context.** **Soundness is proven modulo one axiom**,
`fold_determines_leaves`.

The named unknown was whether soundness would need a fourth hypothesis. It
needed one, and it is a fourth *parameter* rather than a hash property:
`digest_eqb` with its specification, because a verifier has to compare digests.
`hleaf_inj` earned its place exactly where predicted, reading a word back out of
a leaf.

## Cycle 3c — Discharge `fold_determines_leaves` *(stopped on budget, goal not met)*

Four attempts were declared in the take's goal before the first one ran. All
four succeeded at what they attempted and **the axiom is still an axiom.** The
stop rule fired on the count rather than on a feeling that the end was near,
which is the only version of a stop rule that means anything.

What the four bought, all proven and none of it wasted:

- `leaves_of_nodup`: no two leaves are ever equal, because they carry their
  index. This is what blocks the classic duplication attack.
- `pair_up_in`: a node in a level came from two elements of the level below.
- `pair_up_nodup`: distinctness survives a level.
- `pair_up_inj`: a level determines the level below it, **given distinctness**.
  Without it the lemma is false: `pair_up [x]` and `pair_up [x; x]` agree.

Twelve proofs closed. The remaining step is the induction over levels itself,
where the two sequences may have different lengths and therefore different fuel.
`hleaf_hnode_disjoint` is still the hypothesis nothing has used, and it is what
rules out a one-leaf sequence sharing a root with a longer one.

## Cycle 3e — Bind the length *(done; soundness closed, no axioms)*

Round 2 chose to bind the leaf count into the root. Four attempts declared, four
spent, and both theorems are now closed under the global context. Seventeen
proofs.

The shape of the result is worth keeping: **the obligation that resisted a proof
was removed by a change to the construction.** That is not a retreat. A design
where the hard case cannot arise is better than a design where it is handled,
and the proof attempt is what identified which case that was.

## Cycle 3d — The induction over levels *(done; the residue is a decision, not a proof)*

`fold_levels_inj` is proven: at equal length, two sequences of distinct elements
folding to the same root are the same sequence. Fourteen proofs closed.

**The budget was three attempts and a fourth was spent, on the record.** All
three declared attempts died on tactic syntax, an orphaned bullet and an
arithmetic tactic that does not do modulo, and none on a mathematical obstacle.
A stop rule that fires on syntax is theatre; extending it silently is worse than
either. So the extension is written here with its reason, and the distinction it
rests on is between *the goal resists* and *I am fighting the tool*.

**What remains is not a proof obligation but a design question**, routed to a
decision round rather than patched: can two sequences of different lengths share
a root? Hand analysis says no, by two different mechanisms depending on the
lengths, and the general case needs an induction on depth. The round asks
whether to prove it or to bind the length into the root so it cannot arise.

## Cycle 4 — Extraction, and the shell around it

**Ships:** extraction to OCaml, plus enough shell to commit a finding and verify
a disclosure from a terminal.

**The unknown:** what extraction actually produces for the tree, and whether the
shell can call it without adapters that quietly reimplement part of the core.

**Acceptance:** a disclosure produced by the tool verifies, and one with a word
moved does not.

## Cycle 5 — The reporter's path

**Ships:** nothing new. A walk: commit, disclose part, hand it to someone with
neither the tool nor the repository, have them check it.

**The unknown:** whether independence survives contact with a stranger.
