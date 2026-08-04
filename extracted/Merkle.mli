open Datatypes
open List
open PeanoNat

val pair_up : ('a1 -> 'a1 -> 'a1) -> 'a1 list -> 'a1 list

val fold_levels : ('a1 -> 'a1 -> 'a1) -> nat -> 'a1 list -> 'a1 option

val leaves_from : (nat -> 'a2 -> 'a1) -> nat -> 'a2 list -> 'a1 list

val leaves_of : (nat -> 'a2 -> 'a1) -> 'a2 list -> 'a1 list

val root_of :
  (nat -> 'a2 -> 'a1) -> ('a1 -> 'a1 -> 'a1) -> (nat -> 'a1 -> 'a1) -> 'a2
  list -> 'a1 option

type 'word disclosure = { leaf_count : nat; revealed : (nat * 'word) list }

type 'digest proof_data = 'digest list

val build :
  (nat -> 'a2 -> 'a1) -> 'a2 disclosure -> 'a2 list -> 'a1 proof_data

val checks_out :
  (nat -> 'a2 -> 'a1) -> ('a1 -> 'a1 -> bool) -> 'a1 proof_data ->
  (nat * 'a2) -> bool

val verify :
  (nat -> 'a2 -> 'a1) -> ('a1 -> 'a1 -> 'a1) -> (nat -> 'a1 -> 'a1) -> ('a1
  -> 'a1 -> bool) -> 'a2 disclosure -> 'a1 proof_data -> 'a1 -> bool
