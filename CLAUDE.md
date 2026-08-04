# notary

Prove you knew about a bug, without revealing everything you knew.

## Read first

`kb/INDEX.md`, then the file it routes you to. Six files total, on purpose.

## The rule this project is about

One module carries the whole claim and is proven in Rocq. Everything else is
ordinary OCaml with ordinary tests. **The trusted base is enumerated in
`kb/architecture.md` and grows on the record, never silently.**

Nothing here may describe the system as *proven*, *safe*, *secure* or *verified*
without naming which of the three layers is meant. The word "proven" belongs to
the tree logic and to nothing else.

## This development is recorded

Every cycle is a take: `rushes take start --goal …`, then `rushes take end
--note …`. **Close the take before committing**, because the diff is captured
from the working tree.

The workspace is publishable by construction: every bug report here is invented
and labelled, and no internal hostname, colleague name or real report identifier
is ever written down. `tools/deny-list.txt` is a floor under that, not the rule.

## Before committing

```sh
python3 tools/kb-lint.py kb
```
