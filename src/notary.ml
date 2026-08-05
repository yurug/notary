(* The shell: everything the proof does not cover.
 *
 * It supplies what the core quantifies over, splits a finding into salted
 * words, reads and writes files, and talks to a person. None of it is proven,
 * and by the architecture's claim none of it needs to be. *)

open Boundary

let sha (parts : string list) : string =
  let ctx =
    List.fold_left (fun c s -> Digestif.SHA256.feed_string c s) Digestif.SHA256.empty parts
  in
  Digestif.SHA256.(to_raw_string (get ctx))

module Sha256 : HASH with type digest = string = struct
  type digest = string
  let equal = String.equal

  (* Tag 0x00, the index, the leaf's salt, the word. The salt is what makes a
   * hidden leaf's hash unguessable. *)
  let leaf i (w : leaf_word) =
    let b = Bytes.create 5 in
    Bytes.set_uint8 b 0 0x00;
    Bytes.set_int32_be b 1 (Int32.of_int i);
    sha [ Bytes.to_string b; w.salt; w.text ]

  let node a b = sha [ "\x01"; a; b ]

  let count n r =
    let b = Bytes.create 5 in
    Bytes.set_uint8 b 0 0x02;
    Bytes.set_int32_be b 1 (Int32.of_int n);
    sha [ Bytes.to_string b; r ]
end

let hex s =
  String.concat ""
    (List.map (fun c -> Printf.sprintf "%02x" (Char.code c))
       (List.init (String.length s) (String.get s)))

let unhex s =
  String.init (String.length s / 2) (fun i ->
      Char.chr (int_of_string ("0x" ^ String.sub s (2 * i) 2)))

let core_leaf i w = Sha256.leaf (int_of_nat i) w
let core_count n r = Sha256.count (int_of_nat n) r
let core_root ws = Extracted.Merkle.root_of core_leaf Sha256.node core_count ws

(* The proven verifier over a pruned tree. This is the trusted checking path:
 * every argument is a thing the theorem quantifies over. *)
let core_mp_verify cnt t r =
  Extracted.Merkle.mp_verify core_leaf Sha256.node core_count Sha256.equal cnt t r

(* Building the pruned tree is shell work, not covered by the proof: soundness
 * holds for whatever tree the verifier is handed, so a bug here can only make an
 * honest disclosure fail to verify, never make a forged one pass. The concrete
 * tree mirrors the core's pair_forest, duplicating the last node on an odd
 * level, so its root is the one root_of computed. *)
type ctree = CL of int * Boundary.leaf_word * string | CN of ctree * ctree * string
let cdigest = function CL (_, _, d) -> d | CN (_, _, d) -> d

let build_ctree (ws : Boundary.leaf_word list) : ctree option =
  match ws with
  | [] -> None
  | _ ->
    let level0 = List.mapi (fun i w -> CL (i, w, Sha256.leaf i w)) ws in
    let rec pair = function
      | [] -> []
      | [ t ] -> [ CN (t, t, Sha256.node (cdigest t) (cdigest t)) ]
      | a :: b :: rest -> CN (a, b, Sha256.node (cdigest a) (cdigest b)) :: pair rest
    in
    let rec fold = function [] -> assert false | [ t ] -> t | l -> fold (pair l) in
    Some (fold level0)

(* Prune bottom-up: a subtree all of whose leaves are hidden collapses to its
 * digest (one Hide), which is the whole point of a multiproof. *)
let rec prune (revealed : int list) (t : ctree)
  : (string, Boundary.leaf_word) Extracted.Merkle.ptree =
  match t with
  | CL (i, w, d) ->
    if List.mem i revealed then Extracted.Merkle.Reveal (nat_of_int i, w)
    else Extracted.Merkle.Hide d
  | CN (a, b, d) ->
    let pa = prune revealed a and pb = prune revealed b in
    (match (pa, pb) with
     | Extracted.Merkle.Hide _, Extracted.Merkle.Hide _ -> Extracted.Merkle.Hide d
     | _ -> Extracted.Merkle.Branch (pa, pb))


let read_file path =
  let ic = open_in_bin path in
  let n = in_channel_length ic in
  let s = really_input_string ic n in
  close_in ic; s

let json_string s =
  let b = Buffer.create (String.length s + 2) in
  Buffer.add_char b '"';
  String.iter
    (fun c ->
      match c with
      | '"' -> Buffer.add_string b "\\\""
      | '\\' -> Buffer.add_string b "\\\\"
      | '\n' -> Buffer.add_string b "\\n"
      | '\t' -> Buffer.add_string b "\\t"
      | c when Char.code c < 0x20 -> Buffer.add_string b (Printf.sprintf "\\u%04x" (Char.code c))
      | c -> Buffer.add_char b c)
    s;
  Buffer.add_char b '"';
  Buffer.contents b

let flag name =
  let rec go = function
    | a :: b :: _ when a = name -> Some b
    | _ :: t -> go t
    | [] -> None
  in
  go (Array.to_list Sys.argv)

let need name =
  match flag name with
  | Some v -> v
  | None -> prerr_endline ("E_ARGS: " ^ name ^ " is required."); exit 1

(* What protects the hidden words, said at the moment someone decides rather
 * than in a document they read once (round 5, card 3). *)
let protection_note () =
  print_string
    "\n\
     What hides a redacted word: its leaf carries a salt derived from this\n\
     finding's secret, so its hash cannot be guessed from a dictionary. Without\n\
     the salt it could be, in milliseconds. What is still public: how many words\n\
     each gap holds, and where they sit.\n"

(* 32 bytes per finding. The salts derive from it, so one secret is kept rather
 * than one per word. *)
let fresh_secret () =
  Random.self_init ();
  String.init 32 (fun _ -> Char.chr (Random.int 256))

(* The file the committer keeps (round 5, card 2). It holds the secret, so it
 * never leaves their machine; the disclosure they hand over is a different
 * file. *)
let write_finding path ~subject ~secret ~root ~leaves =
  if Sys.file_exists path then begin
    prerr_endline ("E_EXISTS: " ^ path ^ " already exists; notary never overwrites a secret.");
    exit 1
  end;
  let oc = open_out path in
  Printf.fprintf oc
    "{\n  \"subject\": %s,\n  \"secret\": \"%s\",\n  \"root\": \"%s\",\n  \"leaf_count\": %d\n}\n"
    (json_string subject) (hex secret) (hex root) leaves;
  close_out oc

let read_finding path =
  let s = read_file path in
  let field name =
    let key = "\"" ^ name ^ "\"" in
    let i = Str.search_forward (Str.regexp_string key) s 0 in
    let j = String.index_from s (i + String.length key) ':' in
    let k = String.index_from s j '"' in
    let l = String.index_from s (k + 1) '"' in
    String.sub s (k + 1) (l - k - 1)
  in
  (field "subject", unhex (field "secret"), field "root")

let cmd_commit subject file out =
  let secret = fresh_secret () in
  let ws = words_of ~hash:sha ~secret subject (read_file file) in
  match core_root ws with
  | None -> prerr_endline "E_EMPTY: a finding needs at least a subject."; 1
  | Some r ->
    write_finding out ~subject ~secret ~root:r ~leaves:(List.length ws);
    Printf.printf "root %s\n%d leaves, subject at 0\nwrote %s\n" (hex r) (List.length ws) out;
    print_string
      "\nThat file holds the secret this finding's salts come from. Keep it: without\n\
       it you can never disclose any part of this finding, and the root becomes a\n\
       commitment you cannot open.\n";
    0

let cmd_show finding file =
  let subject, secret, _ = read_finding finding in
  let ws = words_of ~hash:sha ~secret subject (read_file file) in
  List.iteri (fun i w -> Printf.printf "%4d  %s\n" i w.text) ws;
  0

let parse_ranges spec =
  String.split_on_char ',' spec
  |> List.concat_map (fun part ->
         match String.split_on_char '-' (String.trim part) with
         | [ a ] -> [ int_of_string a ]
         | [ a; b ] ->
           List.init (int_of_string b - int_of_string a + 1) (fun k -> int_of_string a + k)
         | _ -> failwith ("cannot read \"" ^ part ^ "\" as an index or range"))

(* The disclosure wire format: the pruned tree, tagged. A stranger folds it with
 * three rules and checks the count binding. *)
let rec json_ptree : (string, Boundary.leaf_word) Extracted.Merkle.ptree -> string =
  function
  | Extracted.Merkle.Reveal (i, w) ->
    Printf.sprintf "{\"r\": [%d, %s, \"%s\"]}" (int_of_nat i) (json_string w.text) (hex w.salt)
  | Extracted.Merkle.Hide d -> Printf.sprintf "{\"h\": \"%s\"}" (hex d)
  | Extracted.Merkle.Branch (a, b) ->
    Printf.sprintf "{\"n\": [%s, %s]}" (json_ptree a) (json_ptree b)

let rec count_nodes : (string, Boundary.leaf_word) Extracted.Merkle.ptree -> int =
  function
  | Extracted.Merkle.Reveal _ | Extracted.Merkle.Hide _ -> 1
  | Extracted.Merkle.Branch (a, b) -> count_nodes a + count_nodes b

let cmd_disclose finding file spec =
  let subject, secret, _ = read_finding finding in
  let ws = words_of ~hash:sha ~secret subject (read_file file) in
  let idx = List.sort_uniq compare (0 :: parse_ranges spec) in
  let revealed =
    List.filter_map
      (fun i -> match List.nth_opt ws i with Some w -> Some (nat_of_int i, w) | None -> None)
      idx
  in
  let shown = List.map (fun (i, _) -> int_of_nat i) revealed in
  let buf = Buffer.create 256 in
  let run = ref 0 in
  List.iteri
    (fun i w ->
      if List.mem i shown then begin
        if !run > 0 then (Buffer.add_string buf (Printf.sprintf "___[%d words] " !run); run := 0);
        Buffer.add_string buf (if i = 0 then "[subject] " ^ w.text ^ "\n" else w.text ^ " ")
      end
      else incr run)
    ws;
  if !run > 0 then Buffer.add_string buf (Printf.sprintf "___[%d words]" !run);
  print_newline ();
  print_string "--- what your recipient will read ---\n";
  print_string (Buffer.contents buf);
  Printf.printf "\n\n%d of %d words revealed.\n" (List.length shown) (List.length ws);
  protection_note ();
  print_string "Judging whether the gaps can be guessed is yours; nothing here scores it.\n";
  match (core_root ws, build_ctree ws) with
  | Some r, Some ct ->
    let t = prune shown ct in
    let cnt = nat_of_int (List.length ws) in
    Printf.printf "\nroot %s\nproof %d nodes\nverifies: %b\n" (hex r) (count_nodes t)
      (core_mp_verify cnt t r);
    (match flag "--out" with
     | None -> ()
     | Some path ->
       let oc = open_out path in
       Printf.fprintf oc "{\n  \"leaf_count\": %d,\n  \"proof\": %s\n}\n"
         (List.length ws) (json_ptree t);
       close_out oc;
       Printf.printf "wrote %s\n" path);
    0
  | _ -> 1

let () =
  match Array.to_list Sys.argv with
  | _ :: "commit" :: _ ->
    exit (cmd_commit (need "--subject") (need "--description") (need "--out"))
  | _ :: "show" :: _ -> exit (cmd_show (need "--finding") (need "--description"))
  | _ :: "disclose" :: _ ->
    exit (cmd_disclose (need "--finding") (need "--description") (need "--reveal"))
  | _ ->
    prerr_endline
      "usage: notary commit   --subject T --description FILE --out finding.json\n\
      \       notary show     --finding finding.json --description FILE\n\
      \       notary disclose --finding finding.json --description FILE --reveal 0,4-19 [--out d.json]";
    exit 1
