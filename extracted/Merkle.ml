open Datatypes

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

type ('digest, 'word) ptree =
| Reveal of nat * 'word
| Hide of 'digest
| Branch of ('digest, 'word) ptree * ('digest, 'word) ptree

(** val proot :
    (nat -> 'a2 -> 'a1) -> ('a1 -> 'a1 -> 'a1) -> ('a1, 'a2) ptree -> 'a1 **)

let rec proot hleaf hnode = function
| Reveal (i, w) -> hleaf i w
| Hide d -> d
| Branch (a, b) -> hnode (proot hleaf hnode a) (proot hleaf hnode b)

(** val preveals : ('a1, 'a2) ptree -> (nat * 'a2) list **)

let rec preveals = function
| Reveal (i, w) -> (i,w)::[]
| Hide _ -> []
| Branch (a, b) -> app (preveals a) (preveals b)

(** val mp_verify :
    (nat -> 'a2 -> 'a1) -> ('a1 -> 'a1 -> 'a1) -> (nat -> 'a1 -> 'a1) -> ('a1
    -> 'a1 -> bool) -> nat -> ('a1, 'a2) ptree -> 'a1 -> bool **)

let mp_verify hleaf hnode hcount digest_eqb cnt t r =
  digest_eqb (hcount cnt (proot hleaf hnode t)) r
