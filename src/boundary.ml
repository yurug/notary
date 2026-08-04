(* The boundary between the proven core and the shell.
 *
 * The core is parameterised by five things and OCaml has to supply all five,
 * which is what makes the boundary a type signature rather than a convention.
 * This file is the whole of what crosses it, and everything in it is trusted:
 * no proof covers a line below.
 *
 * The one piece of real logic here is the conversion between OCaml's int and
 * Rocq's unary nat. It is trusted, it is six lines, and it is deliberately not
 * hidden inside an extraction directive: mapping nat to int with
 * `Extract Inductive nat => "int"` would make the same assumption invisible and
 * additionally assume that no index exceeds 63 bits. Written here, it can be
 * read by whoever audits the trusted base. *)

let rec nat_of_int (n : int) : Extracted.Datatypes.nat =
  if n <= 0 then Extracted.Datatypes.O else Extracted.Datatypes.S (nat_of_int (n - 1))

let rec int_of_nat (n : Extracted.Datatypes.nat) : int =
  match n with Extracted.Datatypes.O -> 0 | Extracted.Datatypes.S m -> 1 + int_of_nat m

(* Splitting a finding into words happens outside the proof, by decision. A bug
 * here means the theorem is about a different sequence than the one the
 * engineer wrote, which is the exposure the architecture names. *)
let words_of (subject : string) (description : string) : string list =
  subject :: (String.split_on_char ' ' description
              |> List.concat_map (String.split_on_char '\n')
              |> List.concat_map (String.split_on_char '\t')
              |> List.filter (fun w -> w <> ""))

(* The hashes the core quantifies over. A concrete SHA-256 is a decision that
 * has not been taken; this signature is what any answer has to satisfy. *)
module type HASH = sig
  type digest
  val equal : digest -> digest -> bool
  val leaf : int -> string -> digest      (* domain-separated, index inside *)
  val node : digest -> digest -> digest
  val count : int -> digest -> digest     (* binds the leaf count into the root *)
end
