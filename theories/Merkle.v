(** * The proven core: a Merkle tree over a sequence, and what verifying a
      redaction establishes.

    This is the whole of what is proven. Everything else in the product is
    ordinary OCaml with ordinary tests (see [kb/architecture.md]).

    The hash is a parameter, not a definition. SHA-256 is in the trusted base by
    decision (round 1, card 2), so the theorem below holds for *any* hash that
    is injective on the encodings used here, and the gap between injectivity and
    the computational collision resistance SHA-256 actually offers is named in
    the trusted-base list rather than hidden. *)

From Stdlib Require Import List Arith.
Import ListNotations.

(** ** The parameter

    [word] is whatever a leaf carries; the splitting of a finding into words
    happens outside the proof (round 1, card 4). [digest] is the hash's
    codomain. [hleaf i w] hashes the word at position [i]; the index is inside
    the hash so a revealed word verifies at exactly one position. *)

Section Merkle.

Variable digest : Type.
Variable word : Type.
Variable hleaf : nat -> word -> digest.
Variable hnode : digest -> digest -> digest.

(** The single assumption. Two different inputs never share a hash. *)

Hypothesis hleaf_inj :
  forall i j w v, hleaf i w = hleaf j v -> i = j /\ w = v.
Hypothesis hnode_inj :
  forall a b c d, hnode a b = hnode c d -> a = c /\ b = d.
Hypothesis hleaf_hnode_disjoint :
  forall i w a b, hleaf i w <> hnode a b.

(** ** The tree

    One level at a time, pairing neighbours. An odd level duplicates its last
    node, which is the one place Merkle implementations silently differ, so it
    is written here rather than assumed. *)

Fixpoint pair_up (l : list digest) : list digest :=
  match l with
  | [] => []
  | [x] => [hnode x x]
  | x :: y :: rest => hnode x y :: pair_up rest
  end.

Fixpoint fold_levels (fuel : nat) (l : list digest) : option digest :=
  match fuel, l with
  | _, [] => None
  | _, [r] => Some r
  | 0, _ => None
  | S f, _ => fold_levels f (pair_up l)
  end.

Definition leaves_of (ws : list word) : list digest :=
  map (fun p => hleaf (fst p) (snd p)) (combine (seq 0 (length ws)) ws).

(** [None] only for the empty sequence, which is not a finding: leaf 0 is the
    subject, so every real finding has at least one leaf. *)

Definition root_of (ws : list word) : option digest :=
  fold_levels (length ws) (leaves_of ws).

(** ** A disclosure

    A set of positions, with the words claimed to sit there, and the total
    length of the sequence they came from. What a verifier is handed. *)

Record disclosure := {
  leaf_count : nat;
  revealed : list (nat * word)
}.

(** [projects d ws] is the honest relation: the disclosure really is a redaction
    of [ws]. Every revealed pair sits where it claims to sit, and the claimed
    length is the real length. Nothing is said about the words that are hidden,
    which is the point. *)

Definition projects (d : disclosure) (ws : list word) : Prop :=
  leaf_count d = length ws /\
  forall i w, In (i, w) (revealed d) -> nth_error ws i = Some w.

(** ** The obligation, stated before it is discharged

    [proof_data] is whatever the siblings turn out to be; cycle 3 chooses it.
    What cannot wait is the shape of the claim, so it is written as a predicate
    over any candidate [verify]. Cycle 3 defines one and proves it satisfies
    this. In English:

      Verification accepts a disclosure exactly when that disclosure really is a
      redaction of the sequence the root was built from.

    Both directions carry weight. Left to right is forgery-freeness: nothing
    else is ever accepted. Right to left is completeness: an honest team can
    always defend a true claim. A tool with only the second proves nothing; a
    tool with only the first can refuse the truth. *)

Variable proof_data : Type.

Definition verify_spec
  (verify : disclosure -> proof_data -> digest -> bool) : Prop :=
  forall ws d p r,
    root_of ws = Some r ->
    (verify d p r = true <-> projects d ws).

(** ** Cycle 3: the statement above is wrong, and here is the proof

    It looks right and it type-checks, which is exactly why it survived a cycle.
    What it actually demands is that acceptance depend only on the disclosure
    and the root, so a verifier satisfying it must return the same answer
    whatever proof it is handed. A verifier that ignores its proof accepts
    anything. *)

Theorem spec_forces_ignoring_the_proof :
  forall verify, verify_spec verify ->
    forall ws d p p' r,
      root_of ws = Some r -> verify d p r = verify d p' r.
Proof.
  intros verify Hspec ws d p p' r Hroot.
  destruct (Hspec ws d p r Hroot) as [Hp1 Hp2].
  destruct (Hspec ws d p' r Hroot) as [Hq1 Hq2].
  destruct (verify d p r) eqn:Ep; destruct (verify d p' r) eqn:Eq; try reflexivity.
  - symmetry. apply Hq2. apply Hp1. reflexivity.
  - apply Hp2. apply Hq1. reflexivity.
Qed.

(** ** The obligation, restated

    Soundness belongs to the verifier alone: whatever it accepts really is a
    redaction. Completeness belongs to the *pair*, prover and verifier: for an
    honest disclosure there exists a proof that is accepted, and the prover is
    what produces it. Splitting them is not a technicality. The single
    biconditional hid the fact that one of the two directions is a statement
    about a program nobody had thought to name. *)

Definition verify_sound
  (verify : disclosure -> proof_data -> digest -> bool) : Prop :=
  forall ws d p r,
    root_of ws = Some r ->
    verify d p r = true ->
    projects d ws.

Definition prover_complete
  (build : disclosure -> list word -> proof_data)
  (verify : disclosure -> proof_data -> digest -> bool) : Prop :=
  forall ws d r,
    root_of ws = Some r ->
    projects d ws ->
    verify d (build d ws) r = true.

End Merkle.

(** ** What the obligation does not say

    That the sequence describes anyone's finding. That the words hidden are
    true. That the redaction is wide enough to be safe to publish. That SHA-256
    is injective. Each of those is either someone's judgement or a line in the
    trusted base, and none of them is a theorem here. *)
