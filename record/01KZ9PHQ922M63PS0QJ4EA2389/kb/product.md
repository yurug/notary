---
id: product
type: concept
summary: Prove you already held a finding while disclosing only the part that proves it, and never claim more than the tool establishes.
domain: product
tags: [product, scope]
last-updated: 2026-08-04
related: [architecture, glossary]
---
# What the notary is for

## One-liner

Prove you knew about a bug, without revealing everything you knew.

## The workflow

A duplicate report arrives. You show that the root of the finding's Merkle tree
was published before the report. You take the confidential description, remove
the parts you do not wish to share, and hand over that version with a proof that
it is compatible with the published root.

You control the shape of what you disclose, and you are responsible for making
the redactions wide enough that the hidden parts cannot be guessed. The tool
shows you what your redaction discloses; the judgement is yours.

## Scope

**One finding, one tree, one root.** There is no way to commit to a directory or
a corpus, and that absence is deliberate: a team that could commit to everything
it writes could later reveal whatever matched, which would make prior knowledge
cheap to assert.

## What the tool will not claim

- That the text describes the reporter's finding. It proves compatibility with a
  published root, and nothing about meaning.
- That anything hidden is true, or even coherent.
- That a redaction is safe to share.
- That the parts outside the proven core are correct. They are tested, and the
  claim is that the system's validity does not depend on them.
