---
id: format
type: spec
summary: Everything a stranger needs to recompute a root and check a disclosure, without our code.
domain: spec
tags: [format, interop]
last-updated: 2026-08-05
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

`uint32be` bounds every index and the leaf count to 2^32 - 1. An implementation
must reject a finding with more leaves than that rather than wrap, and a
verifier must reject a disclosure whose `leaf_count` or indices exceed it.

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

A disclosure is not the full leaf list. It is the tree with everything hidden
pruned away: revealed words are kept as leaves, and any subtree all of whose
leaves are hidden is replaced by its single digest. A hidden run of any length
then costs one hash. This is the multiproof (round 7); the earlier one-hash-per-leaf
format is retired, and roots already published are unaffected because the root
construction above did not change.

JSON, one object. The `proof` is a **pruned tree**, a node of one of three
shapes:

```json
{
  "leaf_count": 30,
  "proof": {
    "n": [
      {"r": [0, "session cookie without Secure on staging", "<salt hex>"]},
      {"n": [ {"h": "<hex>"}, {"r": [6, "clear", "<salt hex>"]} ]}
    ]
  }
}
```

- `leaf_count` is the total number of leaves in the finding, including the
  subject.
- `{"r": [index, word, salt]}` is a **revealed** leaf: the word at that index,
  with its salt hex-encoded.
- `{"h": "<hex>"}` is a **hidden** subtree, shipped as its digest and nothing
  else. It stands for one leaf or a whole run of them.
- `{"n": [left, right]}` is an internal **node** with two children.

## Verifying

Recompute the tree's root digest from the pruned tree, then check the count
binding. Fold a node `t` to a digest `proot(t)`:

- `{"r": [i, w, salt]}`  →  `leaf(i, w)` with that salt;
- `{"h": d}`             →  `d`;
- `{"n": [a, b]}`        →  `node(proot(a), proot(b))`.

Then the disclosure is **compatible** with a published root `r` when

```
count(leaf_count, proot(proof)) == r
```

No separate check of the revealed words is needed: a revealed leaf that did not
recompute to the committed digest would change `proot` and miss the root. A
verifier is sixty lines; [`verifier/verify.py`](../verifier/verify.py) is one.

**What that does not establish**: that the text describes your finding, that the
party who committed it understood it, or anything at all about the words they
did not reveal.

## What a disclosure still shows

The salt hides the *words*; it does not hide the *shape*. The root binds the
leaf count, and every revealed leaf carries its index, so a recipient can read
off the total number of words and the position and length of every hidden gap.
That leakage is structural and deliberate, stated here rather than discovered:
if the gap structure itself is sensitive, a disclosure is the wrong tool.

## What the proof size means

A contiguous hidden run collapses to one `{"h": …}`, so a 500-word finding with
a few revealed spans ships kilobytes rather than the 16 KB the retired format
needed. The worst case, revealed and hidden words alternating so nothing
collapses, is back to one hash per leaf; for a document a person wrote, this
never happens.
