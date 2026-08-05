(** * The proven core: a Merkle tree over a sequence, and what verifying a
      redaction establishes.

    This is the whole of what is proven. Everything else in the product is
    ordinary OCaml with ordinary tests (see [kb/architecture.md]).

    The hash is a parameter, not a definition. SHA-256 is in the trusted base by
    decision (round 1, card 2), so the theorem below holds for *any* hash that
    is injective on the encodings used here, and the gap between injectivity and
    the computational collision resistance SHA-256 actually offers is named in
    the trusted-base list rather than hidden. *)

From Stdlib Require Import List Arith Lia.
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

(** The root commits to the leaf count as well as to the leaves (round 2). A
    fifth parameter, and the reason it exists is worth keeping next to it: two
    sequences of *different* lengths sharing a root was the last obligation
    standing, and binding the count makes the question unaskable rather than
    answerable. The cost is on the format, not on the proof: a root computed
    without this cannot be recomputed with it. *)

Variable hcount : nat -> digest -> digest.
Hypothesis hcount_inj :
  forall n m a b, hcount n a = hcount m b -> n = m /\ a = b.

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

(** Written with an index accumulator rather than [combine (seq 0 …)]. The two
    are equal; this one is the one whose lemmas are three lines each, and a
    definition chosen for provability is a legitimate design decision in a
    module whose reason to exist is that it is proven. *)

Fixpoint leaves_from (i : nat) (ws : list word) : list digest :=
  match ws with
  | [] => []
  | w :: rest => hleaf i w :: leaves_from (S i) rest
  end.

Definition leaves_of (ws : list word) : list digest := leaves_from 0 ws.

(** [None] only for the empty sequence, which is not a finding: leaf 0 is the
    subject, so every real finding has at least one leaf. *)

Definition root_of (ws : list word) : option digest :=
  match fold_levels (length ws) (leaves_of ws) with
  | Some r => Some (hcount (length ws) r)
  | None => None
  end.

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

(** Digests come off a hash, so they compare. This is a fourth parameter and it
    is honest: SHA-256 outputs are bytes. *)

Variable digest_eqb : digest -> digest -> bool.
Hypothesis digest_eqb_true : forall a b, digest_eqb a b = true <-> a = b.

(** ** The proof a disclosure carries

    The leaf digests of the whole sequence. Every hidden word contributes its
    hash and nothing else, which is what a hash is for. The alternative, a
    multiproof of shared siblings, is smaller and is a cycle of its own; this
    one is the shape that can be proven today, and the size is a few hundred
    hashes for a finding a person wrote. *)

Definition proof_data := list digest.

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

(** ** A concrete prover and verifier *)

Definition build (_ : disclosure) (ws : list word) : proof_data := leaves_of ws.

Definition checks_out (p : proof_data) (iw : nat * word) : bool :=
  match nth_error p (fst iw) with
  | Some h => digest_eqb h (hleaf (fst iw) (snd iw))
  | None => false
  end.

Definition verify (d : disclosure) (p : proof_data) (r : digest) : bool :=
  Nat.eqb (length p) (leaf_count d)
  && forallb (checks_out p) (revealed d)
  && match fold_levels (length p) p with
     | Some r' => digest_eqb (hcount (length p) r') r
     | None => false
     end.

(** ** Two lemmas about the leaf sequence *)

Lemma leaves_from_length :
  forall ws i, length (leaves_from i ws) = length ws.
Proof.
  induction ws as [| w rest IH]; intros i; simpl; auto.
Qed.

Lemma leaves_of_length : forall ws, length (leaves_of ws) = length ws.
Proof. intros ws. apply leaves_from_length. Qed.

Lemma leaves_from_nth :
  forall ws k i w, nth_error ws k = Some w ->
    nth_error (leaves_from i ws) k = Some (hleaf (i + k) w).
Proof.
  induction ws as [| w0 rest IH]; intros k i w H.
  - destruct k; discriminate.
  - destruct k as [| k']; simpl in *.
    + injection H as ->. rewrite Nat.add_0_r. reflexivity.
    + rewrite (IH k' (S i) w H). rewrite Nat.add_succ_comm. reflexivity.
Qed.

Lemma leaves_of_nth :
  forall ws i w, nth_error ws i = Some w ->
    nth_error (leaves_of ws) i = Some (hleaf i w).
Proof.
  intros ws i w H. unfold leaves_of.
  rewrite (leaves_from_nth ws i 0 w H). reflexivity.
Qed.

(** ** Completeness: an honest disclosure is always defensible *)

Theorem build_verify_complete : prover_complete build verify.
Proof.
  unfold prover_complete, verify, build.
  intros ws d r Hroot [Hlen Hin].
  unfold root_of in Hroot.
  destruct (fold_levels (length ws) (leaves_of ws)) as [r0 |] eqn:Hf;
    [| discriminate].
  injection Hroot as Hr. subst r.
  rewrite leaves_of_length.
  apply andb_true_intro; split.
  - apply andb_true_intro; split.
    + apply Nat.eqb_eq. symmetry. exact Hlen.
    + apply forallb_forall. intros [i w] Hmem.
      unfold checks_out. cbn [fst snd].
      rewrite (leaves_of_nth ws i w (Hin i w Hmem)).
      apply digest_eqb_true. reflexivity.
  - rewrite Hf. apply digest_eqb_true. reflexivity.
Qed.

(** ** Soundness

    Reading a word back out of the leaf sequence is where [hleaf_inj] earns its
    place: from a leaf digest we recover the word only because no other word at
    no other index could have produced it. *)

Lemma leaves_from_nth_inv :
  forall ws k i w, nth_error (leaves_from i ws) k = Some (hleaf (i + k) w) ->
    nth_error ws k = Some w.
Proof.
  induction ws as [| w0 rest IH]; intros k i w H.
  - destruct k; discriminate.
  - destruct k as [| k']; simpl in *.
    + injection H as H. rewrite Nat.add_0_r in H.
      apply hleaf_inj in H. destruct H as [_ ->]. reflexivity.
    + apply (IH k' (S i) w).
      replace (S i + k') with (i + S k') by lia. exact H.
Qed.

Lemma leaves_of_nth_inv :
  forall ws i w, nth_error (leaves_of ws) i = Some (hleaf i w) ->
    nth_error ws i = Some w.
Proof.
  intros ws i w H. unfold leaves_of in H.
  apply (leaves_from_nth_inv ws i 0 w). exact H.
Qed.

(** The one thing this development does not prove yet.

    Two sequences of leaves that fold to the same root are the same sequence.
    It should follow from [hnode_inj] and [hleaf_hnode_disjoint], by induction
    on the levels, and it is the piece that makes forgery impossible. Until it
    is discharged it is an assumption, so it is listed in the trusted base with
    the others rather than hidden behind an [Admitted] nobody reads.

    Worth recording: the classic duplication attack, where a sequence and the
    same sequence with its last element repeated share a root, is *blocked here
    by construction* rather than by this lemma. Leaves carry their index, so no
    two leaves are ever equal, so the last element can never be a duplicate of
    its neighbour. *)

(** *** The decomposition

    Four steps. Distinctness is what rules out the one case where pairing is not
    injective: [pair_up [x]] and [pair_up [x; x]] agree, so a list may only be
    recovered from its next level if no element repeats. Leaves never repeat
    because they carry their index, and that property has to survive each
    level. *)

Lemma leaves_from_nodup : forall ws i, NoDup (leaves_from i ws).
Proof.
  induction ws as [| w rest IH]; intros i; simpl; constructor.
  - intros Hin.
    (* a leaf at index i cannot appear later, where indices are all > i *)
    assert (Hgen : forall rest' j, i < j -> In (hleaf i w) (leaves_from j rest') -> False).
    { induction rest' as [| w' r' IH']; intros j Hlt Hin'.
      - exact Hin'.
      - simpl in Hin'. destruct Hin' as [Heq | Hlater].
        + apply hleaf_inj in Heq. destruct Heq as [Hij _]. lia.
        + apply (IH' (S j)); [lia | exact Hlater]. }
    apply (Hgen rest (S i)); [lia | exact Hin].
  - apply IH.
Qed.

Lemma leaves_of_nodup : forall ws, NoDup (leaves_of ws).
Proof. intros ws. apply leaves_from_nodup. Qed.

(** [pair_up] consumes two elements at a time and the library has no induction
    principle for that shape, so every lemma below runs on a length bound. *)

Lemma pair_up_in_aux :
  forall n l d, length l <= n -> In d (pair_up l) ->
    exists a b, d = hnode a b /\ In a l /\ In b l.
Proof.
  induction n as [| n IH]; intros l d Hlen Hin.
  - destruct l as [| x l']; simpl in *; [contradiction | lia].
  - destruct l as [| x [| y r]]; simpl in *.
    + contradiction.
    + destruct Hin as [Heq | []]. exists x, x. auto.
    + destruct Hin as [Heq | Hlater].
      * exists x, y. auto.
      * assert (Hr : length r <= n) by lia.
        destruct (IH r d Hr Hlater) as [a [b [Hd [Ha Hb]]]].
        exists a, b. auto.
Qed.

Lemma pair_up_in :
  forall l d, In d (pair_up l) -> exists a b, d = hnode a b /\ In a l /\ In b l.
Proof. intros l d. apply (pair_up_in_aux (length l) l d). lia. Qed.

Lemma pair_up_nodup_aux :
  forall n l, length l <= n -> NoDup l -> NoDup (pair_up l).
Proof.
  induction n as [| n IH]; intros l Hlen Hnd.
  - destruct l as [| x l']; simpl in *; [constructor | lia].
  - destruct l as [| x [| y r]]; simpl in *.
    + constructor.
    + constructor; [intros [] | constructor].
    + inversion Hnd as [| ? ? Hx Hnd']; subst.
      inversion Hnd' as [| ? ? Hy Hnd'']; subst.
      constructor.
      * intros Hin. destruct (pair_up_in r (hnode x y) Hin) as [a [b [Hd [Ha Hb]]]].
        apply hnode_inj in Hd. destruct Hd as [Hax Hby]. subst.
        apply Hx. simpl. right. exact Ha.
      * apply IH; [lia | exact Hnd''].
Qed.

Lemma pair_up_nodup : forall l, NoDup l -> NoDup (pair_up l).
Proof. intros l. apply (pair_up_nodup_aux (length l) l). lia. Qed.

Lemma pair_up_inj_aux :
  forall n l l', length l <= n -> NoDup l -> NoDup l' ->
    pair_up l = pair_up l' -> l = l'.
Proof.
  induction n as [| n IH]; intros l l' Hlen Hl Hl' Heq.
  - destruct l as [| x l0]; simpl in *; [| lia].
    destruct l' as [| y' [| z' r']]; simpl in *; auto; discriminate.
  - destruct l as [| x [| y r]]; simpl in *.
    + destruct l' as [| y' [| z' r']]; simpl in *; auto; discriminate.
    + destruct l' as [| y' [| z' r']]; simpl in *.
      * discriminate.
      * injection Heq as Hh. apply hnode_inj in Hh. destruct Hh as [Hx _].
        subst. reflexivity.
      * injection Heq as Hh Ht. apply hnode_inj in Hh. destruct Hh as [Ha Hb].
        subst. inversion Hl' as [| ? ? Hnin ?]; subst.
        exfalso. apply Hnin. simpl. left. reflexivity.
    + destruct l' as [| y' [| z' r']]; simpl in *.
      * discriminate.
      * injection Heq as Hh. apply hnode_inj in Hh. destruct Hh as [Ha Hb].
        subst. inversion Hl as [| ? ? Hnin ?]; subst.
        exfalso. apply Hnin. simpl. left. reflexivity.
      * injection Heq as Hh Ht. apply hnode_inj in Hh. destruct Hh as [Ha Hb].
        subst. f_equal. f_equal.
        inversion Hl as [| ? ? _ Hl2]; subst. inversion Hl2 as [| ? ? _ Hl3]; subst.
        inversion Hl' as [| ? ? _ Hl2']; subst. inversion Hl2' as [| ? ? _ Hl3']; subst.
        apply (IH r r'); [lia | assumption | assumption | exact Ht].
Qed.

Lemma pair_up_inj :
  forall l l', NoDup l -> NoDup l' -> pair_up l = pair_up l' -> l = l'.
Proof. intros l l'. apply (pair_up_inj_aux (length l) l l'). lia. Qed.

(** Only the equality of the two lengths is needed, never their value, so the
    lemma says that and the proof never meets a division. *)

Lemma pair_up_length_eq_aux :
  forall n l l', length l <= n -> length l = length l' ->
    length (pair_up l) = length (pair_up l').
Proof.
  induction n as [| n IH]; intros l l' Hn Heq.
  - destruct l as [| x l0]; destruct l' as [| x' l0']; simpl in *; lia || reflexivity.
  - destruct l as [| x [| y r]]; destruct l' as [| x' [| y' r']];
      simpl in *; try lia; try reflexivity.
    f_equal. apply (IH r r'); lia.
Qed.

Lemma pair_up_length_eq :
  forall l l', length l = length l' -> length (pair_up l) = length (pair_up l').
Proof. intros l l'. apply (pair_up_length_eq_aux (length l) l l'). lia. Qed.

(** With the length bound into the root, the two sequences a verifier compares
    always have the same length, and at equal length pairing is injective with
    **no distinctness hypothesis at all**: the only case [NoDup] ever ruled out
    was a singleton against a longer list, which is a length mismatch. So the
    critical path shortens, and [leaves_of_nodup] stops being load-bearing and
    becomes what it always described, the reason the duplication attack cannot
    reach the leaves. *)

Lemma pair_up_inj_len_aux :
  forall n l l', length l <= n -> length l = length l' ->
    pair_up l = pair_up l' -> l = l'.
Proof.
  induction n as [| n IH]; intros l l' Hn Hlen Heq.
  - destruct l as [| x l0]; destruct l' as [| x' l0']; simpl in *;
      lia || reflexivity.
  - destruct l as [| x [| y r]]; destruct l' as [| x' [| y' r']];
      simpl in *; try lia.
    + reflexivity.
    + injection Heq as Hh. apply hnode_inj in Hh. destruct Hh as [Ha _].
      subst. reflexivity.
    + injection Heq as Hh Ht. apply hnode_inj in Hh. destruct Hh as [Ha Hb].
      subst. f_equal. f_equal. apply (IH r r'); [lia | lia | exact Ht].
Qed.

Lemma pair_up_inj_len :
  forall l l', length l = length l' -> pair_up l = pair_up l' -> l = l'.
Proof. intros l l'. apply (pair_up_inj_len_aux (length l) l l'). lia. Qed.

Lemma fold_levels_inj_len :
  forall n l l' r, length l = length l' ->
    fold_levels n l = Some r -> fold_levels n l' = Some r -> l = l'.
Proof.
  induction n as [| n IH]; intros l l' r Hlen H H'.
  - destruct l as [| x [| y t]]; destruct l' as [| x' [| y' t']];
      simpl in *; try discriminate; try lia.
    injection H as Hx. injection H' as Hx'. subst. reflexivity.
  - destruct l as [| x [| y t]]; destruct l' as [| x' [| y' t']];
      simpl in *; try discriminate; try lia.
    + injection H as Hx. injection H' as Hx'. subst. reflexivity.
    + apply pair_up_inj_len; [simpl; lia |].
      apply (IH (hnode x y :: pair_up t) (hnode x' y' :: pair_up t') r).
      * change (hnode x y :: pair_up t) with (pair_up (x :: y :: t)).
        change (hnode x' y' :: pair_up t') with (pair_up (x' :: y' :: t')).
        apply pair_up_length_eq. simpl. lia.
      * exact H.
      * exact H'.
Qed.

(** Injectivity of the fold, at equal length, with distinctness. This is the whole of
    [fold_determines_leaves] except the question of whether two sequences of
    *different* lengths can share a root, which is a question about the
    construction rather than about this proof, and which round 2 decides. *)

Lemma fold_levels_inj :
  forall n l l' r, NoDup l -> NoDup l' -> length l = length l' ->
    fold_levels n l = Some r -> fold_levels n l' = Some r -> l = l'.
Proof.
  induction n as [| n IH]; intros l l' r Hl Hl' Hlen H H'.
  - destruct l as [| x [| y t]]; destruct l' as [| x' [| y' t']];
      simpl in *; try discriminate; try lia.
    injection H as Hx. injection H' as Hx'. subst. reflexivity.
  - destruct l as [| x [| y t]]; destruct l' as [| x' [| y' t']];
      simpl in *; try discriminate; try lia.
    + injection H as Hx. injection H' as Hx'. subst. reflexivity.
    + apply pair_up_inj; [exact Hl | exact Hl' |].
      apply (IH (hnode x y :: pair_up t) (hnode x' y' :: pair_up t') r).
      * change (hnode x y :: pair_up t) with (pair_up (x :: y :: t)).
        apply pair_up_nodup. exact Hl.
      * change (hnode x' y' :: pair_up t') with (pair_up (x' :: y' :: t')).
        apply pair_up_nodup. exact Hl'.
      * change (hnode x y :: pair_up t) with (pair_up (x :: y :: t)).
        change (hnode x' y' :: pair_up t') with (pair_up (x' :: y' :: t')).
        apply pair_up_length_eq. simpl. lia.
      * exact H.
      * exact H'.
Qed.

Lemma fold_determines_leaves :
  forall ws p r0 rp,
    fold_levels (length ws) (leaves_of ws) = Some r0 ->
    fold_levels (length p) p = Some rp ->
    hcount (length ws) r0 = hcount (length p) rp ->
    p = leaves_of ws.
Proof.
  intros ws p r0 rp Hw Hp Hc.
  apply hcount_inj in Hc. destruct Hc as [Hlen Hr]. subst rp.
  symmetry. apply (fold_levels_inj_len (length ws) (leaves_of ws) p r0).
  - rewrite leaves_of_length. exact Hlen.
  - exact Hw.
  - rewrite Hlen. exact Hp.
Qed.

Theorem verify_is_sound : verify_sound verify.
Proof.
  unfold verify_sound, verify. intros ws d p r Hroot Hv.
  apply andb_prop in Hv. destruct Hv as [Hv12 H3].
  apply andb_prop in Hv12. destruct Hv12 as [H1 H2].
  apply Nat.eqb_eq in H1.
  destruct (fold_levels (length p) p) as [rp |] eqn:Hfp; [| discriminate].
  apply digest_eqb_true in H3.
  unfold root_of in Hroot.
  destruct (fold_levels (length ws) (leaves_of ws)) as [r0 |] eqn:Hfw;
    [| discriminate].
  injection Hroot as Hr.
  assert (Hc : hcount (length ws) r0 = hcount (length p) rp)
    by (rewrite Hr, H3; reflexivity).
  assert (Hp : p = leaves_of ws)
    by (apply (fold_determines_leaves ws p r0 rp); assumption).
  subst p. split.
  - rewrite <- H1. apply leaves_of_length.
  - intros i w Hmem.
    apply (leaves_of_nth_inv ws i w).
    pose proof (proj1 (forallb_forall (checks_out (leaves_of ws)) (revealed d)) H2 (i, w) Hmem) as Hc2.
    unfold checks_out in Hc2. cbn [fst snd] in Hc2.
    destruct (nth_error (leaves_of ws) i) as [h |] eqn:Hn; [| discriminate].
    apply digest_eqb_true in Hc2. subst h. reflexivity.
Qed.

(** ** Cycle 9: the multiproof

    Round 7's decision. A disclosure has carried one hash per leaf; here a
    maximal fully-hidden subtree collapses to a single digest, so a hidden run
    costs one hash however long it is. The root construction does not change:
    [root_of] is still [hcount (length ws) (fold …)], so every published root
    stays valid and the chain layer is untouched. What changes is the proof a
    disclosure carries and the verifier over it, and the two theorems are
    reproven from scratch against statements that do not change. *)

(** The concrete Merkle tree of a finding, made explicit. [fold_levels] computes
    its root without naming it; [tree] names it, [pair_forest] mirrors
    [pair_up], and the two agree through [troot] by construction rather than by
    an axiom. *)

Inductive tree : Type := Tip : digest -> tree | Fork : tree -> tree -> tree.

Fixpoint troot (t : tree) : digest :=
  match t with Tip d => d | Fork a b => hnode (troot a) (troot b) end.

Fixpoint pair_forest (f : list tree) : list tree :=
  match f with
  | [] => [] | [t] => [Fork t t]
  | a :: b :: r => Fork a b :: pair_forest r
  end.

Fixpoint fold_forest (fuel : nat) (f : list tree) : option tree :=
  match fuel, f with
  | _, [] => None | _, [t] => Some t
  | 0, _ => None | S k, _ => fold_forest k (pair_forest f)
  end.

Lemma map_troot_pair_forest :
  forall f, map troot (pair_forest f) = pair_up (map troot f).
Proof.
  fix IH 1. intros f. destruct f as [| a [| b r]]; try reflexivity.
  simpl. f_equal. apply IH.
Qed.

(** The bridge, both directions. Forest-fold then root equals level-fold; and
    whenever the level-fold succeeds, the forest-fold does too, on any forest
    whose tips carry those digests. *)
Lemma fold_forest_root :
  forall fuel f t, fold_forest fuel f = Some t ->
    fold_levels fuel (map troot f) = Some (troot t).
Proof.
  induction fuel as [| fuel IH]; intros f t H.
  - destruct f as [| a [| b r]]; simpl in *; try discriminate.
    injection H as <-. reflexivity.
  - destruct f as [| a [| b r]]; simpl in *.
    + discriminate.
    + injection H as <-. reflexivity.
    + apply IH in H. simpl in H. rewrite map_troot_pair_forest in H. exact H.
Qed.

Lemma fold_forest_exists_gen :
  forall fuel f r, fold_levels fuel (map troot f) = Some r ->
    exists t, fold_forest fuel f = Some t /\ troot t = r.
Proof.
  induction fuel as [| fuel IH]; intros f r H.
  - destruct f as [| a [| b rest]]; simpl in *; try discriminate.
    injection H as <-. exists a. split; reflexivity.
  - destruct f as [| a [| b rest]]; simpl in *.
    + discriminate.
    + injection H as <-. exists a. split; reflexivity.
    + apply (IH (pair_forest (a :: b :: rest)) r).
      rewrite map_troot_pair_forest. simpl. simpl in H. exact H.
Qed.

Lemma map_troot_map_Tip : forall L, map troot (map Tip L) = L.
Proof. induction L as [| x r IH]; simpl; [reflexivity | rewrite IH; reflexivity]. Qed.

Lemma fold_forest_exists :
  forall fuel L r, fold_levels fuel L = Some r ->
    exists t, fold_forest fuel (map Tip L) = Some t /\ troot t = r.
Proof.
  intros fuel L r H. apply fold_forest_exists_gen. rewrite map_troot_map_Tip. exact H.
Qed.

(** A pruned tree: what a disclosure now carries. A revealed leaf the verifier
    recomputes, a hidden subtree stands as one digest, a branch pairs two. It
    carries its own reveals, so no separate revealed-word list has to be
    reconciled with it, and the verifier never compares words. *)

Inductive ptree : Type :=
  | Reveal : nat -> word -> ptree
  | Hide   : digest -> ptree
  | Branch : ptree -> ptree -> ptree.

Fixpoint proot (t : ptree) : digest :=
  match t with
  | Reveal i w => hleaf i w | Hide d => d
  | Branch a b => hnode (proot a) (proot b)
  end.

Fixpoint preveals (t : ptree) : list (nat * word) :=
  match t with
  | Reveal i w => [(i, w)] | Hide _ => []
  | Branch a b => preveals a ++ preveals b
  end.

(** [prunes t T]: [t] is a pruning of the concrete tree [T]. Pruning keeps the
    root, which is why a hidden disclosure still verifies. *)
Inductive prunes : ptree -> tree -> Prop :=
  | prunes_reveal : forall i w, prunes (Reveal i w) (Tip (hleaf i w))
  | prunes_hide   : forall T, prunes (Hide (troot T)) T
  | prunes_branch : forall a b A B,
      prunes a A -> prunes b B -> prunes (Branch a b) (Fork A B).

Lemma prunes_root : forall t T, prunes t T -> proot t = troot T.
Proof.
  intros t T H. induction H as [i w | T | a b A B Ha IHa Hb IHb]; simpl;
    [ reflexivity | reflexivity | rewrite IHa, IHb; reflexivity ].
Qed.

(** Soundness rests on the real tree being leaf-tipped: every tip a leaf hash,
    never a node hash. That is what stops a prover passing a [Tip] whose digest
    is secretly a node, and with it root equality alone forces genuine reveals,
    whatever shape the prover chose. *)

Fixpoint tips (T : tree) : list digest :=
  match T with Tip d => [d] | Fork A B => tips A ++ tips B end.

Inductive leaf_tipped : tree -> Prop :=
  | lt_tip  : forall i w, leaf_tipped (Tip (hleaf i w))
  | lt_fork : forall A B, leaf_tipped A -> leaf_tipped B -> leaf_tipped (Fork A B).

Lemma troot_leaf_is_tip :
  forall i w T, leaf_tipped T -> hleaf i w = troot T -> tips T = [hleaf i w].
Proof.
  intros i w T Hlt H. destruct Hlt as [j v | A B HA HB]; simpl in *.
  - apply hleaf_inj in H. destruct H as [-> ->]. reflexivity.
  - exfalso. apply (hleaf_hnode_disjoint i w (troot A) (troot B) H).
Qed.

Lemma troot_node_is_fork :
  forall x y T, leaf_tipped T -> hnode x y = troot T ->
    exists A B, T = Fork A B /\ leaf_tipped A /\ leaf_tipped B
                /\ troot A = x /\ troot B = y.
Proof.
  intros x y T Hlt H. destruct Hlt as [j v | A B HA HB]; simpl in *.
  - exfalso. symmetry in H. apply (hleaf_hnode_disjoint j v x y H).
  - apply hnode_inj in H. destruct H as [-> ->]. exists A, B. repeat split; assumption.
Qed.

Lemma sound_core :
  forall t T, leaf_tipped T -> proot t = troot T ->
    forall i w, In (i, w) (preveals t) -> In (hleaf i w) (tips T).
Proof.
  induction t as [i0 w0 | d | a IHa b IHb]; intros T Hlt Hr i w Hin; simpl in *.
  - destruct Hin as [Heq | []]. injection Heq as -> ->.
    rewrite (troot_leaf_is_tip i w T Hlt Hr). simpl. left. reflexivity.
  - destruct Hin.
  - destruct (troot_node_is_fork (proot a) (proot b) T Hlt Hr)
      as [A [B [HT [HA [HB [HrA HrB]]]]]].
    subst T. simpl. apply in_or_app. apply in_app_or in Hin.
    destruct Hin as [Hia | Hib].
    + left. apply (IHa A HA (eq_sym HrA) i w Hia).
    + right. apply (IHb B HB (eq_sym HrB) i w Hib).
Qed.

(** The real finding's forest is leaf-tipped, and its folded tips are exactly
    its leaves. *)

Lemma leaves_from_leaf_tipped_forall :
  forall ws i, Forall leaf_tipped (map Tip (leaves_from i ws)).
Proof.
  induction ws as [| w rest IH]; intros i; simpl.
  - constructor.
  - constructor; [apply lt_tip | apply IH].
Qed.

Lemma leaves_of_leaf_tipped_forall :
  forall ws, Forall leaf_tipped (map Tip (leaves_of ws)).
Proof. intros ws. apply leaves_from_leaf_tipped_forall. Qed.

Lemma pair_forest_leaf_tipped :
  forall f, Forall leaf_tipped f -> Forall leaf_tipped (pair_forest f).
Proof.
  fix IH 1. intros f Hf. destruct f as [| a [| b rest]].
  - constructor.
  - inversion Hf as [| ? ? Ha ?]; subst. simpl.
    constructor; [apply lt_fork; assumption | constructor].
  - inversion Hf as [| ? ? Ha Hf']; subst.
    inversion Hf' as [| ? ? Hb Hrest]; subst. simpl.
    constructor; [apply lt_fork; assumption | apply IH; assumption].
Qed.

Lemma fold_forest_leaf_tipped :
  forall fuel f t, Forall leaf_tipped f -> fold_forest fuel f = Some t -> leaf_tipped t.
Proof.
  induction fuel as [| fuel IH]; intros f t Hf H.
  - destruct f as [| a [| b rest]]; simpl in *; try discriminate.
    injection H as <-. inversion Hf; assumption.
  - destruct f as [| a [| b rest]]; simpl in *.
    + discriminate.
    + injection H as <-. inversion Hf; assumption.
    + apply (IH (Fork a b :: pair_forest rest) t); [| exact H].
      inversion Hf as [| ? ? Ha Hf']; subst. inversion Hf' as [| ? ? Hb Hrest]; subst.
      constructor; [apply lt_fork; assumption | apply pair_forest_leaf_tipped; assumption].
Qed.

Fixpoint concat_tips (f : list tree) : list digest :=
  match f with [] => [] | t :: rest => tips t ++ concat_tips rest end.

Lemma tips_pair_forest_sub :
  forall f d, In d (concat_tips (pair_forest f)) -> In d (concat_tips f).
Proof.
  fix IH 1. intros f d H. destruct f as [| a [| b rest]]; simpl in *.
  - exact H.
  - rewrite app_nil_r in H. rewrite app_nil_r. apply in_app_or in H.
    destruct H; assumption.
  - apply in_app_or in H. apply in_or_app. destruct H as [Hab | Hrest].
    + apply in_app_or in Hab. destruct Hab as [Ha | Hb].
      * left. exact Ha.
      * right. apply in_or_app. left. exact Hb.
    + apply IH in Hrest. right. apply in_or_app. right. exact Hrest.
Qed.

Lemma tips_fold_forest_sub :
  forall fuel f t, fold_forest fuel f = Some t ->
    forall d, In d (tips t) -> In d (concat_tips f).
Proof.
  induction fuel as [| fuel IH]; intros f t H d Hd.
  - destruct f as [| a [| b rest]]; simpl in *; try discriminate.
    injection H as <-. rewrite app_nil_r. exact Hd.
  - destruct f as [| a [| b rest]]; simpl in *.
    + discriminate.
    + injection H as <-. rewrite app_nil_r. exact Hd.
    + apply (tips_pair_forest_sub (a :: b :: rest) d).
      apply (IH (pair_forest (a :: b :: rest)) t); [exact H | exact Hd].
Qed.

Lemma concat_tips_map_Tip : forall L d, In d (concat_tips (map Tip L)) -> In d L.
Proof.
  induction L as [| x rest IH]; intros d H; simpl in *.
  - exact H.
  - destruct H as [Heq | Hrest]; [left; congruence | right; apply IH; exact Hrest].
Qed.

(** Reading a revealed leaf's word back out of the finding. As in v1 soundness,
    [hleaf_inj] is what makes a leaf digest name exactly one (position, word). *)
Lemma leaves_from_in_inv :
  forall ws i w j, In (hleaf i w) (leaves_from j ws) -> j <= i ->
    nth_error ws (i - j) = Some w.
Proof.
  induction ws as [| w0 rest IH]; intros i w j Hin Hle; simpl in *.
  - contradiction.
  - destruct Hin as [Heq | Hlater].
    + apply hleaf_inj in Heq. destruct Heq as [-> ->].
      rewrite Nat.sub_diag. reflexivity.
    + assert (Hlt : j < i \/ j = i) by lia. destruct Hlt as [Hlt | ->].
      * specialize (IH i w (S j) Hlater ltac:(lia)).
        replace (i - j) with (S (i - S j)) by lia. exact IH.
      * (* j = i: leaf at index i appears later where all indices exceed i *)
        exfalso. clear IH Hle.
        assert (Hgen : forall rest' k, i < k -> In (hleaf i w) (leaves_from k rest') -> False).
        { induction rest' as [| w' r' IHr]; intros k Hlt Hin'; simpl in *.
          - exact Hin'.
          - destruct Hin' as [He | Hl].
            + apply hleaf_inj in He. destruct He as [Hik _]. lia.
            + apply (IHr (S k)); [lia | exact Hl]. }
        apply (Hgen rest (S i)); [lia | exact Hlater].
Qed.

Lemma leaves_of_in_inv :
  forall ws i w, In (hleaf i w) (leaves_of ws) -> nth_error ws i = Some w.
Proof.
  intros ws i w H. unfold leaves_of in H.
  pose proof (leaves_from_in_inv ws i w 0 H (Nat.le_0_l i)) as Hr.
  rewrite Nat.sub_0_r in Hr. exact Hr.
Qed.

(** ** The multiproof verifier, and its two theorems

    The disclosure is the pruned tree plus the claimed leaf count. Verifying is
    one hash: fold the tree, bind the count, compare to the published root. *)

Definition mp_verify (cnt : nat) (t : ptree) (r : digest) : bool :=
  digest_eqb (hcount cnt (proot t)) r.

Definition mp_projects (cnt : nat) (t : ptree) (ws : list word) : Prop :=
  cnt = length ws /\
  forall i w, In (i, w) (preveals t) -> nth_error ws i = Some w.

(** Soundness: whatever the verifier accepts against a real root reveals only
    genuine words, and its claimed count is the real one. No pruning hypothesis:
    injectivity forces the shape. *)
Theorem mp_verify_sound :
  forall ws cnt t r,
    root_of ws = Some r -> mp_verify cnt t r = true -> mp_projects cnt t ws.
Proof.
  intros ws cnt t r Hroot Hv. unfold mp_verify in Hv.
  apply digest_eqb_true in Hv.
  unfold root_of in Hroot.
  destruct (fold_levels (length ws) (leaves_of ws)) as [rr |] eqn:Hfl;
    [| discriminate].
  injection Hroot as Hr. subst r.
  destruct (fold_forest_exists (length ws) (leaves_of ws) rr Hfl)
    as [FT [HFT HrFT]].
  assert (Hlt : leaf_tipped FT)
    by (apply (fold_forest_leaf_tipped (length ws) (map Tip (leaves_of ws)) FT);
        [ apply leaves_of_leaf_tipped_forall | exact HFT ]).
  (* hcount cnt (proot t) = hcount (length ws) rr *)
  rewrite <- HrFT in Hv.
  apply hcount_inj in Hv. destruct Hv as [Hcnt Hpr].
  split; [exact Hcnt |].
  intros i w Hin.
  apply leaves_of_in_inv.
  pose proof (sound_core t FT Hlt Hpr i w Hin) as Htip.
  pose proof (tips_fold_forest_sub (length ws) (map Tip (leaves_of ws)) FT HFT
                (hleaf i w) Htip) as Hcat.
  apply concat_tips_map_Tip in Hcat. exact Hcat.
Qed.

(** Completeness, for prunings: any honest disclosure that prunes the real tree
    is accepted. This is what lets the tool hide, and [prunes_root] is the whole
    proof: pruning keeps the root, so the one hash the verifier computes lands
    on the published value. *)
Theorem mp_verify_complete :
  forall ws FT t r,
    fold_forest (length ws) (map Tip (leaves_of ws)) = Some FT ->
    root_of ws = Some r -> prunes t FT ->
    mp_verify (length ws) t r = true.
Proof.
  intros ws FT t r HFT Hroot Hpr. unfold mp_verify.
  unfold root_of in Hroot.
  pose proof (fold_forest_root (length ws) (map Tip (leaves_of ws)) FT HFT) as Hbridge.
  rewrite map_troot_map_Tip in Hbridge.
  destruct (fold_levels (length ws) (leaves_of ws)) as [rr |] eqn:Hfl;
    [| discriminate].
  injection Hroot as Hr. subst r. injection Hbridge as HrFT.
  rewrite (prunes_root t FT Hpr). rewrite HrFT.
  apply digest_eqb_true. reflexivity.
Qed.

End Merkle.

(** ** What the obligation does not say

    That the sequence describes anyone's finding. That the words hidden are
    true. That the redaction is wide enough to be safe to publish. That SHA-256
    is injective. Each of those is either someone's judgement or a line in the
    trusted base, and none of them is a theorem here. *)
