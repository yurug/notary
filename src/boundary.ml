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

(* A leaf carries a word AND a salt.
 *
 * Without the salt a disclosure ships one hash per leaf including the hidden
 * ones, the index is public, and words come from a tiny space. Measured on
 * 2026-08-04: a forty-word dictionary recovered sixteen of eighteen hidden
 * words in milliseconds. The redaction hid nothing.
 *
 * The proven core is untouched by this. It quantifies over an abstract word
 * type, so making a word carry its salt changes what the shell hands it and
 * leaves both theorems exactly as they were. *)
type leaf_word = { salt : string; text : string }

(* One secret per finding; salts derived from it, so the committer keeps one
 * thing rather than one per word. Revealing a salt does not reveal the secret,
 * and that is where preimage resistance genuinely enters this design. It was
 * not in the trusted base until the attack above was measured. *)
let salt_of ~(hash : string list -> string) (secret : string) (i : int) : string =
  let b = Bytes.create 5 in
  Bytes.set_uint8 b 0 0x03;
  Bytes.set_int32_be b 1 (Int32.of_int i);
  hash [ Bytes.to_string b; secret ]

(* Splitting a finding into words happens outside the proof, by decision. A bug
 * here means the theorem is about a different sequence than the one the
 * engineer wrote, which is the exposure the architecture names. *)
let split_words (subject : string) (description : string) : string list =
  subject :: (String.split_on_char ' ' description
              |> List.concat_map (String.split_on_char '\n')
              |> List.concat_map (String.split_on_char '\t')
              |> List.filter (fun w -> w <> ""))

(* The hashes the core quantifies over. A concrete SHA-256 is a decision that
 * has not been taken; this signature is what any answer has to satisfy. *)
let words_of ~(hash : string list -> string) ~(secret : string) subject description =
  List.mapi
    (fun i text -> { salt = salt_of ~hash secret i; text })
    (split_words subject description)

module type HASH = sig
  type digest
  val equal : digest -> digest -> bool
  val leaf : int -> leaf_word -> digest   (* index and salt inside *)
  val node : digest -> digest -> digest
  val count : int -> digest -> digest     (* binds the leaf count into the root *)
end
