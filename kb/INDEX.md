---
id: index
type: index
summary: Root routing table.
domain: routing
tags: [routing]
last-updated: 2026-08-04
---
# Knowledge base index

Prove you knew about a bug without revealing everything you knew. Every word of
a finding is a Merkle leaf, so a redaction stays checkable against a published
root. **The tree logic is proven in Rocq; SHA-256 is in the trusted base.**

| File | Read it when you need |
|---|---|
| [`product.md`](product.md) | What this is for, and what it refuses to claim |
| [`architecture.md`](architecture.md) | Where the certified boundary falls, and the trusted base enumerated |
| [`glossary.md`](glossary.md) | finding, subject, leaf, root, disclosure, compatibility |
| [`format.md`](format.md) | The wire format, complete enough to reimplement verification without our code |
| [`plan.md`](plan.md) | The cycles in risk order, and the unknown each must settle |
| [`decisions-round-1.md`](decisions-round-1.md) | Round 1 verbatim: the four cards that drew the boundary |

Six files and this index. That is deliberate: a knowledge base nobody can hold
in their head is one nobody reads, and this project's whole thesis is that the
part that matters is small.

## Status

**The core is proven and the tool runs.** Both theorems closed under the global
context, seventeen proofs, no axioms. A finding commits to a real SHA-256 root,
a redaction is rendered with its gap lengths, and the extracted proven verifier
accepts the disclosure.

**A stranger can check it.** `verifier/verify.py`, written from
[`format.md`](format.md) alone in another language, agrees with the tool on a
real disclosure and rejects a foreign root.
