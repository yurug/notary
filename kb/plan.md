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

## Cycle 3c — Discharge `fold_determines_leaves`

**Ships:** the axiom, proven, and `make assumptions` reporting both theorems
closed under the global context.

**The unknown:** whether it is true as stated. It quantifies over sequences of
different lengths, and the argument that it holds runs through
`hleaf_hnode_disjoint`, which is exactly the hypothesis nothing has used yet.

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
