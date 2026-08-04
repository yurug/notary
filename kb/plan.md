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

## Cycle 3 — The proof

**Ships:** the theorem, proven, no `Admitted` left.

**The unknown:** the reverse direction. Forgery-freeness is where the injectivity
hypothesis earns its place, and it is the half that can turn out to need a
stronger assumption than the statement carries.

**Acceptance:** `make` is green from a clean checkout, and the trusted-base list
in `architecture.md` has grown or not, on the record.

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
