---
id: architecture
type: concept
summary: A small proven island and a large tested continent, with the trusted base named rather than implied.
domain: architecture
tags: [architecture, trust]
last-updated: 2026-08-04
related: [product, glossary, decisions-round-1]
---
# Where the certified boundary falls

## One-liner

One module carries the whole claim and is proven in Rocq. Everything else is
ordinary OCaml with ordinary tests, because the system's validity does not
depend on it.

## The three layers

| Layer | What it is | How it is held |
|---|---|---|
| **The core** | the Merkle tree over an abstract hash: build, prove a disclosure, verify one | proven in Rocq, extracted to OCaml |
| **The shell** | word splitting, SHA-256, files, the chain, the command line, the redaction view | tested |
| **The base** | what neither holds: the extractor, the hash implementation, the runtime | **named**, not held |

The line is drawn in round 1, card 4: everything but the tree is outside. That
makes the proven part the smallest thing that carries the claim, which is what
makes the architecture legible. It also creates one exposure this file will not
soften: **the split into leaves is outside the proof**, so a bug there means the
theorem is about a different sequence than the one the engineer wrote.

## What the theorem says

Round 1, card 1 asked for a biconditional: verification accepts a disclosure
**if and only if** it is a projection of the committed sequence.

**Cycle 3 proved that statement wrong**, in Rocq, in six lines
(`spec_forces_ignoring_the_proof`). Written as one biconditional over a given
proof, it demands that acceptance depend only on the disclosure and the root, so
any verifier satisfying it must return the same answer whatever proof it is
handed. A verifier that ignores its proof accepts anything.

The card's intent survives; its formulation did not. The obligation is now two:

- **Soundness**, of the verifier alone: whatever it accepts really is a
  redaction of the committed sequence.
- **Completeness**, of the *pair*: for an honest disclosure there exists a proof
  that is accepted, and the prover is what produces it.

That split is the finding. The single biconditional hid the fact that one of its
two directions is a statement about a program nobody had named.

Round 1, card 2: the hash is a module parameter carrying an injectivity
hypothesis, so the statement reads *for any hash injective on the encodings we
use*. The assumption is in the theorem rather than in a footnote.

**Writing it turned one hypothesis into three** (cycle 2, `theories/Merkle.v`).
Leaf hashes must be injective in both the index and the word; node hashes must
be injective in both children; and **no leaf hash may ever equal a node hash**,
which is the domain separation that stops a crafted word from standing in for a
subtree. The card said "an injectivity hypothesis", singular. The code says
three, and this line exists so the count is on the record rather than discovered
by a reader of the source.

**And it is an idealisation.** Injectivity is strictly stronger than the
computational collision resistance SHA-256 actually offers. The trusted-base
report says so in those words; a reader who is told "proven" and discovers this
later has been misled by omission.

## The trusted base, asked of the kernel

`make assumptions` prints what the two theorems actually rest on. A hand-kept
list drifts the moment a proof changes; this one cannot, because it is the
kernel's answer.

Today it says: completeness is **closed under the global context**, and
soundness rests on exactly one axiom, `fold_determines_leaves`, the unproven
claim that two leaf sequences folding to the same root are the same sequence.

What the kernel cannot tell you, and what this list is for:

1. **SHA-256**, by decision. Not proven, supplied by OCaml.
2. **The injectivity idealisation** above, in its three parts. Real hashes offer
   computational collision resistance, not injectivity; the distance between the
   two is where a cryptographer would start reading.
3. **Rocq's extractor** (round 1, card 3), which is what carries the proof to
   the running program.
4. **The leaf splitting**, outside the proof by card 4.
5. The OCaml runtime and everything under it.
6. **`fold_determines_leaves`**, still an assumption after cycle 3c stopped on
   its declared budget. It is the piece that makes forgery impossible. Four
   supporting lemmas around it are proven, so what remains is the induction over
   levels rather than the whole claim.

Worth recording beside it: the classic duplication attack, where a sequence and
the same sequence with its last element repeated share a root, is blocked here
**by construction** rather than by that lemma. Leaves carry their index, so no
two leaves are ever equal, so a last element can never be a duplicate of its
neighbour.

A list that grows is not a failure; a list nobody wrote is.

## What the boundary is not

**It is an investment decision, not a capability ceiling.** Nothing here says
the shell *cannot* be proven. With a toolchain for certified effectful
programming, the IO, the chain calls and the command line could be brought
inside too, and the same architecture would simply have a larger island.

The line sits where it sits because this is where the marginal proof buys the
most: the tree is small, total, and carries the entire claim, while the shell is
large, effectful, and wrong-in-obvious-ways when it is wrong. Saying that out
loud is what separates an engineering choice from a limitation dressed up as
one.
