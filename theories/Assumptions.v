(** The trusted base, generated rather than maintained.

    A hand-written list of assumptions drifts the moment a proof changes. This
    file asks the kernel instead, and `make assumptions` prints the answer. What
    it shows is everything the two theorems rest on beyond the section's own
    hypotheses. *)

From Notary Require Import Merkle.

Print Assumptions build_verify_complete.
Print Assumptions verify_is_sound.
Print Assumptions mp_verify_sound.
Print Assumptions mp_verify_complete.
