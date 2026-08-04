# notary

Prove you knew about a bug, without revealing everything you knew.

Every word of a finding is a leaf of a Merkle tree, so any redacted version of it
can be shown compatible with a root published earlier. Prior knowledge is
proven; the confidential remainder stays confidential.

**The tree logic is proven in Rocq and extracted to OCaml. SHA-256 is not
proven: it is named in the trusted base.** Everything around the core is
ordinary OCaml with ordinary tests, because the system's validity does not
depend on it.

Status: defining the product. No code yet, by design.
