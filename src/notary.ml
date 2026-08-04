(* The shell: everything the proof does not cover.
 *
 * It supplies the five things the core quantifies over, splits a finding into
 * words, reads and writes files, and talks to a person. None of it is proven,
 * and by the architecture's claim none of it needs to be: the system's validity
 * rests on the core, and this file's job is to hand the core the right things
 * and to be honest about what comes back. *)

open Boundary

(* SHA-256, from digestif. In the trusted base by decision (round 1), and the
 * particular implementation by round 3. The three functions below are the ones
 * the theorem quantifies over, and their domain separation is what stops a leaf
 * from ever being read as a node, or a root from being read as either. *)
module Sha256 : HASH with type digest = string = struct
  type digest = string (* 32 raw bytes *)

  let equal = String.equal

  let h parts =
    let ctx =
      List.fold_left (fun c s -> Digestif.SHA256.feed_string c s)
        Digestif.SHA256.empty parts
    in
    Digestif.SHA256.(to_raw_string (get ctx))

  (* Tag 0x00, then the index as four big-endian bytes, then the word. *)
  let leaf i w =
    let b = Bytes.create 5 in
    Bytes.set_uint8 b 0 0x00;
    Bytes.set_int32_be b 1 (Int32.of_int i);
    h [ Bytes.to_string b; w ]

  let node a b = h [ "\x01"; a; b ]

  (* Tag 0x02: the root commits to the leaf count as well as the leaves. *)
  let count n r =
    let b = Bytes.create 5 in
    Bytes.set_uint8 b 0 0x02;
    Bytes.set_int32_be b 1 (Int32.of_int n);
    h [ Bytes.to_string b; r ]
end

let hex s = String.concat "" (List.map (Printf.sprintf "%02x") (List.map Char.code (List.init (String.length s) (String.get s))))

(* The core, with its parameters supplied once. *)
let core_leaf i w = Sha256.leaf (int_of_nat i) w
let core_root ws = Extracted.Merkle.root_of core_leaf Sha256.node (fun n r -> Sha256.count (int_of_nat n) r) ws
let core_build d ws = Extracted.Merkle.build core_leaf d ws
let core_verify d p r =
  Extracted.Merkle.verify core_leaf Sha256.node (fun n r -> Sha256.count (int_of_nat n) r) Sha256.equal d p r

(* Minimal JSON string escaping: enough for words out of a text file. *)
let json_string s =
  let b = Buffer.create (String.length s + 2) in
  Buffer.add_char b '"';
  String.iter (fun c ->
      match c with
      | '"' -> Buffer.add_string b "\\\""
      | '\\' -> Buffer.add_string b "\\\\"
      | '\n' -> Buffer.add_string b "\\n"
      | '\t' -> Buffer.add_string b "\\t"
      | c when Char.code c < 0x20 -> Buffer.add_string b (Printf.sprintf "\\u%04x" (Char.code c))
      | c -> Buffer.add_char b c) s;
  Buffer.add_char b '"';
  Buffer.contents b

let read_file path =
  let ic = open_in_bin path in
  let n = in_channel_length ic in
  let s = really_input_string ic n in
  close_in ic; s

let flag name =
  let rec go = function
    | a :: b :: _ when a = name -> Some b
    | _ :: t -> go t
    | [] -> None
  in
  go (Array.to_list Sys.argv)

let flag_out () = flag "--out"

(* A missing flag is a message, not an exception. Found by running the tool
 * with no arguments, which is the first thing anyone does. *)
let need name =
  match flag name with
  | Some v -> v
  | None -> prerr_endline ("E_ARGS: " ^ name ^ " is required."); exit 1

(* --- the commands --- *)

let cmd_commit subject file =
  let ws = words_of subject (read_file file) in
  match core_root ws with
  | None -> prerr_endline "E_EMPTY: a finding needs at least a subject."; 1
  | Some r ->
    Printf.printf "root %s\n%d leaves, subject at 0\n" (hex r) (List.length ws);
    0

let cmd_show subject file =
  let ws = words_of subject (read_file file) in
  List.iteri (fun i w -> Printf.printf "%4d  %s\n" i w) ws; 0

(* `--reveal 0,4-19` names index ranges, because the unit an author works in is
 * a contiguous run of words. Index 0, the subject, is added whether or not it
 * was asked for. *)
let parse_ranges spec =
  String.split_on_char ',' spec
  |> List.concat_map (fun part ->
      match String.split_on_char '-' (String.trim part) with
      | [ a ] -> [ int_of_string a ]
      | [ a; b ] -> List.init (int_of_string b - int_of_string a + 1) (fun k -> int_of_string a + k)
      | _ -> failwith ("cannot read \"" ^ part ^ "\" as an index or range"))

let cmd_disclose subject file spec =
  let ws = words_of subject (read_file file) in
  let idx = List.sort_uniq compare (0 :: parse_ranges spec) in
  let revealed =
    List.filter_map (fun i ->
        match List.nth_opt ws i with Some w -> Some (nat_of_int i, w) | None -> None) idx
  in
  let d = { Extracted.Merkle.leaf_count = nat_of_int (List.length ws); revealed } in
  (* What the recipient will read, gaps at their true length. The judgement of
   * whether they are wide enough is the author's; nothing here scores it. *)
  let n = List.length ws in
  let shown = List.map fst (List.map (fun (i, w) -> (int_of_nat i, w)) revealed) in
  let buf = Buffer.create 256 in
  let run = ref 0 in
  List.iteri (fun i w ->
      if List.mem i shown then begin
        if !run > 0 then (Buffer.add_string buf (Printf.sprintf "___[%d words] " !run); run := 0);
        Buffer.add_string buf (if i = 0 then "[subject] " ^ w ^ "\n" else w ^ " ")
      end else incr run) ws;
  if !run > 0 then Buffer.add_string buf (Printf.sprintf "___[%d words]" !run);
  print_newline ();
  print_string "--- what your recipient will read ---\n";
  print_string (Buffer.contents buf);
  Printf.printf "\n\n%d of %d words revealed. The gaps above are what a reader sees;\n" (List.length shown) n;
  print_string "judging whether they can be guessed is yours, and nothing here scores it.\n";
  match core_root ws with
  | None -> 1
  | Some r ->
    let p = core_build d ws in
    Printf.printf "\nroot %s\nproof %d digests\nverifies: %b\n"
      (hex r) (List.length p) (core_verify d p r);
    (* The artifact a reporter is handed. kb/format.md is what lets them check
     * it without any of this. *)
    (match flag_out () with
     | None -> ()
     | Some path ->
       let oc = open_out path in
       Printf.fprintf oc "{\n  \"leaf_count\": %d,\n  \"revealed\": [" (List.length ws);
       List.iteri (fun k (i, w) ->
           Printf.fprintf oc "%s[%d, %s]" (if k = 0 then "" else ", ")
             (int_of_nat i) (json_string w)) revealed;
       Printf.fprintf oc "],\n  \"proof\": [";
       List.iteri (fun k h ->
           Printf.fprintf oc "%s\"%s\"" (if k = 0 then "" else ", ") (hex h)) p;
       Printf.fprintf oc "]\n}\n";
       close_out oc;
       Printf.printf "wrote %s\n" path);
    0

let () =
  match Array.to_list Sys.argv with
  | _ :: "commit" :: _ -> exit (cmd_commit (need "--subject") (need "--description"))
  | _ :: "show" :: _ -> exit (cmd_show (need "--subject") (need "--description"))
  | _ :: "disclose" :: _ ->
    exit (cmd_disclose (need "--subject") (need "--description") (need "--reveal"))
  | _ ->
    prerr_endline
      "usage: notary commit   --subject T --description FILE\n\
      \       notary show     --subject T --description FILE\n\
      \       notary disclose --subject T --description FILE --reveal 0,4-19 [--out FILE]";
    exit 1
