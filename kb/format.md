---
id: format
type: spec
summary: Everything a stranger needs to recompute a root and check a disclosure, without our code.
domain: spec
tags: [format, interop]
last-updated: 2026-08-04
related: [architecture, glossary]
---
# The wire format

## Why this file exists

Cycle 6 tried to hand a disclosure to someone with neither the tool nor the
repository, and found there was nothing to hand them: the format lived in OCaml
source and Rocq definitions and nowhere a reader could follow. A guarantee that
only our code can check is not a guarantee anyone else can rely on.

Everything below is enough to reimplement verification from scratch. If it is
not, that is a defect in this file.

## Leaves

A finding is a subject line and a description. The leaf sequence is:

```
leaf 0      = the subject, verbatim
leaf 1..n   = the description split on runs of whitespace, empties dropped
```

Whitespace means space, newline and tab. No normalisation, no case folding, no
punctuation stripping, no Unicode processing beyond what splitting on those
three characters does.

## Hashing

`H` is SHA-256. Three tagged constructions, and the tags are what stop one kind
of hash from ever being read as another.

```
salt(i)      = H( 0x03 ‖ secret ‖ uint32be(i) )
leaf(i, w)   = H( 0x00 ‖ uint32be(i) ‖ salt(i) ‖ utf8(w) )
node(a, b)   = H( 0x01 ‖ a ‖ b )
count(n, r)  = H( 0x02 ‖ uint32be(n) ‖ r )
```

`secret` is 32 random bytes, one per finding, kept by whoever committed it and
never published. **Without the salt this scheme hides nothing**: a disclosure
carries one hash per leaf including the hidden ones, the index is public, and a
dictionary recovers every hidden word in milliseconds. Measured 2026-08-04,
sixteen of eighteen from a forty-word dictionary.

A verifier never needs the secret. Salts for revealed words travel in the
disclosure; salts for hidden words are what a recipient cannot compute.

Digests are the 32 raw bytes, concatenated as bytes, not as hex, when they feed
another hash.

## The tree

Start from the list of leaf hashes, in order. Repeatedly pair neighbours:

```
[x0, x1, x2, x3, …]  →  [node(x0,x1), node(x2,x3), …]
```

**An odd level duplicates its last node**: a level `[x0, x1, x2]` becomes
`[node(x0,x1), node(x2,x2)]`. This is the one place implementations differ, so
it is stated rather than assumed.

Repeat until one element remains. That element is the *fold*. The published
root is:

```
root = count(number_of_leaves, fold)
```

Binding the count is not decoration: without it, two findings of different
lengths could in principle share a fold, and the soundness theorem would not
hold.

## A disclosure

JSON, one object:

```json
{
  "leaf_count": 30,
  "revealed": [[0, "session cookie issued …", "<salt hex>"], [1, "The", "<salt hex>"]],
  "proof": ["<hex>", "<hex>", …]
}
```

- `leaf_count` is the total number of leaves in the finding, including the
  subject.
- `revealed` is a list of `[index, word, salt]` triples, sorted by index, the
  salt hex-encoded. Index 0 is always present.
- `proof` is the full list of leaf hashes of the finding, in order, hex-encoded.
  Every hidden word contributes its hash and nothing else.

## Verifying

Given a disclosure and a published root, in hex:

1. Check `length(proof) == leaf_count`.
2. For each `[i, w, salt]` in `revealed`, check `proof[i] == leaf(i, w)` using
   that salt.
3. Fold `proof` as described above, and check
   `count(leaf_count, fold) == root`.

If all three hold, the disclosure is **compatible** with the root: it is a
redaction of the text that root was built from.

**What that does not establish**: that the text describes your finding, that the
party who committed it understood it, or anything at all about the words they
did not reveal.

## What the proof size means

`proof` carries one hash per leaf, so a 500-word finding produces a 16 KB
disclosure. A multiproof of shared siblings would be logarithmic instead, and it
is not implemented: this shape is the one that could be proven, and the size is
irrelevant for a document a person wrote.
