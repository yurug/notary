
type nat =
| O
| S of nat

(** val fst : ('a1 * 'a2) -> 'a1 **)

let fst = function
| x,_ -> x

(** val snd : ('a1 * 'a2) -> 'a2 **)

let snd = function
| _,y -> y

(** val length : 'a1 list -> nat **)

let rec length = function
| [] -> O
| _::l' -> S (length l')
