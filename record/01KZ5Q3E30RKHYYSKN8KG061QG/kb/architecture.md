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

Round 1, card 1: verification accepts a disclosure **if and only if** it is a
projection of the committed sequence. Both directions are load-bearing.
Accepting too much lets a claim be forged; rejecting too much leaves an honest
team unable to defend a true one.

Round 1, card 2: the hash is a module parameter carrying an injectivity
hypothesis, so the statement reads *for any hash injective on the encodings we
use*. The assumption is in the theorem rather than in a footnote.

**And it is an idealisation.** Injectivity is strictly stronger than the
computational collision resistance SHA-256 actually offers. The trusted-base
report says so in those words; a reader who is told "proven" and discovers this
later has been misled by omission.

## The trusted base, so far

1. **SHA-256**, by decision. Not proven, supplied by OCaml.
2. **The injectivity idealisation** above.
3. **Rocq's extractor** (round 1, card 3), which is what carries the proof to
   the running program.
4. **The leaf splitting**, outside the proof by card 4.
5. The OCaml runtime and everything under it.

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
