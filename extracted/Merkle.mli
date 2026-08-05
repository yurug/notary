open Datatypes

val pair_up : ('a1 -> 'a1 -> 'a1) -> 'a1 list -> 'a1 list

val fold_levels : ('a1 -> 'a1 -> 'a1) -> nat -> 'a1 list -> 'a1 option

val leaves_from : (nat -> 'a2 -> 'a1) -> nat -> 'a2 list -> 'a1 list

val leaves_of : (nat -> 'a2 -> 'a1) -> 'a2 list -> 'a1 list

val root_of :
  (nat -> 'a2 -> 'a1) -> ('a1 -> 'a1 -> 'a1) -> (nat -> 'a1 -> 'a1) -> 'a2
  list -> 'a1 option

type ('digest, 'word) ptree =
| Reveal of nat * 'word
| Hide of 'digest
| Branch of ('digest, 'word) ptree * ('digest, 'word) ptree

val proot :
  (nat -> 'a2 -> 'a1) -> ('a1 -> 'a1 -> 'a1) -> ('a1, 'a2) ptree -> 'a1

val preveals : ('a1, 'a2) ptree -> (nat * 'a2) list

val mp_verify :
  (nat -> 'a2 -> 'a1) -> ('a1 -> 'a1 -> 'a1) -> (nat -> 'a1 -> 'a1) -> ('a1
  -> 'a1 -> bool) -> nat -> ('a1, 'a2) ptree -> 'a1 -> bool
