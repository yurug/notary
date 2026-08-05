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

## Cycle 3b — Discharge the two properties

**Ships:** a concrete `verify` and `build`, with `verify_sound` and
`prover_complete` proven.

**The unknown:** whether soundness needs more than the three hash hypotheses.
Recomputing a root from siblings and concluding that revealed words sit where
they claim is where injectivity has to do real work, and it is where a fourth
assumption would appear if one is missing.

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
