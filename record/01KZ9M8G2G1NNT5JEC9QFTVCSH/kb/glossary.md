---
id: glossary
type: glossary
summary: finding, subject, leaf, root, redaction, disclosure, compatibility, trusted base.
domain: vocabulary
tags: [glossary]
last-updated: 2026-08-04
related: [product, architecture]
---
# Glossary

Defined here and nowhere else.

## finding

One security issue as the team wrote it internally. The unit of everything: one
finding, one tree, one root.

## subject

A one-line declaration of what the finding is about, committed with it and
revealed by every disclosure. It turns "a text existed" into "a text about this
existed".

## leaf

One whitespace-separated word. Leaf 0 is the subject.

## root

The Merkle root over the leaves. The only thing published.

## redaction

A version of the finding with parts hidden, produced by a person.

## disclosure

What is handed over: the redaction, a proof, and the reference of the published
root.

## compatibility

What a proof establishes: this redaction is a redaction of the text committed to
by this root. Not that the text describes anyone's finding, not that anything
hidden is true.

## trusted base

Everything the guarantee rests on that no proof here covers: SHA-256, the
injectivity idealisation, Rocq's extractor, the leaf splitting, the runtime.
Enumerated in [`architecture.md`](architecture.md).
