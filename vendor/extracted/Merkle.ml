open Datatypes
open List
open PeanoNat

(** val pair_up : ('a1 -> 'a1 -> 'a1) -> 'a1 list -> 'a1 list **)

let rec pair_up hnode = function
| [] -> []
| x::l0 ->
  (match l0 with
   | [] -> (hnode x x)::[]
   | y::rest -> (hnode x y)::(pair_up hnode rest))

(** val fold_levels : ('a1 -> 'a1 -> 'a1) -> nat -> 'a1 list -> 'a1 option **)

let rec fold_levels hnode fuel l =
  match fuel with
  | O ->
    (match l with
     | [] -> None
     | r::l0 -> (match l0 with
                 | [] -> Some r
                 | _::_ -> None))
  | S f ->
    (match l with
     | [] -> None
     | r::l0 ->
       (match l0 with
        | [] -> Some r
        | _::_ -> fold_levels hnode f (pair_up hnode l)))

(** val leaves_from : (nat -> 'a2 -> 'a1) -> nat -> 'a2 list -> 'a1 list **)

let rec leaves_from hleaf i = function
| [] -> []
| w::rest -> (hleaf i w)::(leaves_from hleaf (S i) rest)

(** val leaves_of : (nat -> 'a2 -> 'a1) -> 'a2 list -> 'a1 list **)

let leaves_of hleaf ws =
  leaves_from hleaf O ws

(** val root_of :
    (nat -> 'a2 -> 'a1) -> ('a1 -> 'a1 -> 'a1) -> (nat -> 'a1 -> 'a1) -> 'a2
    list -> 'a1 option **)

let root_of hleaf hnode hcount ws =
  match fold_levels hnode (length ws) (leaves_of hleaf ws) with
  | Some r -> Some (hcount (length ws) r)
  | None -> None

type 'word disclosure = { leaf_count : nat; revealed : (nat * 'word) list }

type 'digest proof_data = 'digest list

(** val build :
    (nat -> 'a2 -> 'a1) -> 'a2 disclosure -> 'a2 list -> 'a1 proof_data **)

let build hleaf _ ws =
  leaves_of hleaf ws

(** val checks_out :
    (nat -> 'a2 -> 'a1) -> ('a1 -> 'a1 -> bool) -> 'a1 proof_data ->
    (nat * 'a2) -> bool **)

let checks_out hleaf digest_eqb p iw =
  match nth_error p (fst iw) with
  | Some h -> digest_eqb h (hleaf (fst iw) (snd iw))
  | None -> false

(** val verify :
    (nat -> 'a2 -> 'a1) -> ('a1 -> 'a1 -> 'a1) -> (nat -> 'a1 -> 'a1) -> ('a1
    -> 'a1 -> bool) -> 'a2 disclosure -> 'a1 proof_data -> 'a1 -> bool **)

let verify hleaf hnode hcount digest_eqb d p r =
  if if Nat.eqb (length p) d.leaf_count
     then forallb (checks_out hleaf digest_eqb p) d.revealed
     else false
  then (match fold_levels hnode (length p) p with
        | Some r' -> digest_eqb (hcount (length p) r') r
        | None -> false)
  else false
