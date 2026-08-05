(** Extraction of the proven core.

    Everything the core is parameterised by, the digest type, the word type, the
    three hashes and the digest comparison, becomes an argument on the OCaml
    side. That is the boundary made mechanical: OCaml cannot call this without
    supplying exactly the things the theorem quantifies over. *)

From Notary Require Import Merkle.
From Stdlib Require Extraction.

Extraction Language OCaml.
Set Extraction Output Directory "extracted".

Extract Inductive bool => "bool" [ "true" "false" ].
Extract Inductive list => "list" [ "[]" "(::)" ].
Extract Inductive prod => "( * )" [ "(,)" ].
Extract Inductive option => "option" [ "Some" "None" ].

Separate Extraction root_of mp_verify proot preveals.
