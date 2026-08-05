# notary

**Prove you knew about a bug, without revealing everything you knew.**

A white hat reports a security issue and you already had it. Publishing a hash of
your internal write-up when you found it would prove that, and would force you to
hand over the whole document to make the proof checkable.

So every word of the finding is a leaf of a Merkle tree. You publish the root.
Later you hand over a redacted version plus a proof that it is a redaction of the
text that root was built from. Prior knowledge is proven; the rest stays hidden.

## What is proven, and what is not

Three layers, and the middle line is the point.

| | | |
|---|---|---|
| **core** | the tree, the proof, the verification | **proven in Rocq**, extracted to OCaml |
| **shell** | word splitting, SHA-256, files, the command line | ordinary OCaml, ordinary tests |
| **chain** | a key, a signer, a network client, a contract | a separate binary, so you can tell it apart |

Both theorems are closed under the global context. Ask the kernel yourself:

```sh
make assumptions
# build_verify_complete : Closed under the global context
# verify_is_sound       : Closed under the global context
```

**Soundness** says the verifier accepts a disclosure only when it really is a
redaction of the committed text. **Completeness** says an honest disclosure
always has a proof that is accepted. Neither says anything about
confidentiality, and that distinction cost this project a working product once:
[`kb/architecture.md`](kb/architecture.md) tells that story where it happened.

What the kernel cannot see is enumerated by hand beside it: SHA-256, an
idealisation of its collision behaviour, its preimage resistance, Rocq's
extractor, six lines converting `int` to unary `nat`, and the word splitting.
That list is the honest part of the guarantee.

## Try it

```
$ notary commit --subject "session cookie issued without the Secure flag on staging" \
                --description finding.txt --out finding.json
root b8f1bed6a68f8743eb7cb76506e31382afeb869d176c6513e413ab233a31c3a3
30 leaves, subject at 0
wrote finding.json

That file holds the secret this finding's salts come from. Keep it: without
it you can never disclose any part of this finding, and the root becomes a
commitment you cannot open.
```

Publish that root, by whatever means you already use or with the separate
[`chain/`](chain/) program. Then, when the report arrives:

```
$ notary disclose --finding finding.json --description finding.txt \
                  --reveal 1-6,17-21 --out disclosure.json

--- what your recipient will read ---
[subject] session cookie issued without the Secure flag on staging
The session cookie is issued without ___[10 words] travels in the clear whenever ___[8 words]

12 of 30 words revealed.

What hides a redacted word: its leaf carries a salt derived from this
finding's secret, so its hash cannot be guessed from a dictionary. Without
the salt it could be, in milliseconds. What is still public: how many words
each gap holds, and where they sit.
Judging whether the gaps can be guessed is yours; nothing here scores it.
```

Widening a gap proves less and hides more. That trade is yours: the tool shows
you what the recipient will see, and does not score it.

## What the reporter does

They need neither this repository nor OCaml. The format is written down in
[`kb/format.md`](kb/format.md), completely enough to reimplement from, and
[`verifier/verify.py`](verifier/verify.py) is sixty lines of Python that was
written from that document alone:

```
$ python3 verifier/verify.py disclosure.json <root-hex>
compatible: this redaction is a redaction of the text committed to by b8f1bed6a68f…
What that does not establish: that the text describes your finding,
that whoever committed it understood it, or anything about the parts
they did not reveal.
```

That second paragraph is not modesty. A timestamp establishes when a text
existed; whether the text covers the reporter's finding is a human dispute that
a bounty programme's own rules decide, and this tool will not pretend to settle
it.

## Build

Needs [Rocq](https://rocq-prover.org/) 9.1, OCaml 5 with `dune`, and `digestif`.

```sh
make               # check the proofs
make assumptions   # print what they rest on
dune build         # the command-line tool
```

The extracted OCaml is committed under [`extracted/`](extracted/) so the result
of the proof can be read without installing Rocq.

## Layout

```
theories/    the proven core, in Rocq
extracted/   what Rocq's extractor produces from it (generated, committed)
src/         the shell: hashing, splitting, files, the command line
chain/       a separate program that publishes a root and reads one back
verifier/    an independent verifier, written from the format alone
kb/          six files: product, architecture, format, glossary, plan, decisions
```

## Status

The core is proven, the tool works, and a root it computed is on a testnet.

Two things are decided and not built: redacting whole subtrees, which would
shrink a disclosure by two orders of magnitude and add defence in depth at the
edges, and a chain layer the tool can call rather than the user.

One thing is deliberately absent, and will stay absent: any claim that a
redaction is safe to publish.

## About this repository

This is a recorded development. Every cycle is a take whose goal was written
before the work and whose judgement was written after it, every decision is in
[`.forebrief/`](.forebrief/) with whatever reasoning was given, and the
onboarding and comprehension sessions are in [`.inbrief/`](.inbrief/) and
[`.backbrief/`](.backbrief/).

The point of keeping it is that a claim about how this tool came to be, or about
why any of it is shaped the way it is, can be checked against the record instead
of taken on trust. The tag `recorded-run-2026-08-04` marks the run as it stood
on the day, before the commit messages were rewritten to describe the changes
rather than the session.

MIT licensed.
