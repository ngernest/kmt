open Hashcons
open Common

let word_log_src = Logs.Src.create "kmt.word"
                     ~doc:"logs regular expression/word equality tests"
module Log = (val Logs.src_log word_log_src : Logs.LOG)
   
(* TODO parse words *)
   
type letter = int
            
let show_letter l = "pi_" ^ string_of_int l
            
type word = word_hons hash_consed
and word_hons =
  | Emp
  | Eps
  | Ltr of letter
  | Alt of word * word
  | Cat of word * word
  | Str of word

let equal_word x y =
  match (x, y) with
  | Emp, Emp | Eps, Eps -> true
  | Ltr l1, Ltr l2 -> l1 = l2
  | Alt (a, b), Alt (c, d) | Cat (a, b), Cat (c, d) ->
      a.tag = c.tag && b.tag = d.tag
  | Str a, Str b -> a.tag = b.tag
  | _, _ -> false

let hash_word x =
  match x with
  | Emp -> 3
  | Eps -> 5
  | Ltr l -> 7 * l + 3
  | Alt (a, b) -> 13 * (b.hkey + (17 * a.hkey + 19))
  | Cat (a, b) -> 23 * (b.hkey + (29 * a.hkey + 31))
  | Str a -> 37 * a.hkey + 41
         
let tbl_word = Hashcons.create 8

let hashcons_word = Hashcons.hashcons hash_word equal_word tbl_word

let emp = hashcons_word Emp
let eps = hashcons_word Eps
let ltr l = hashcons_word (Ltr l)
let alt w1 w2 =
  match w1.node, w2.node with
  | Emp, _ -> w2
  | _, Emp -> w1
  | _, _ -> if w1.tag = w2.tag
            then w1
            else hashcons_word (Alt (w1, w2))
let cat w1 w2 =
  match w1.node, w2.node with
  | Eps, _ -> w2
  | _, Eps -> w1
  | _, _ -> hashcons_word (Cat (w1, w2))
          
let str w =
  match w.node with
  | Emp -> eps
  | Eps -> eps
  | _ -> hashcons_word (Str w)
  
module Word : CollectionType with type t = word = struct
  type t = word

  let equal x y = x.tag = y.tag
  let compare x y = x.tag - y.tag
  let hash x = x.hkey
  let show : t -> string =
    let rec alt w =
      match w.node with
      | Alt (w1, w2) -> alt w1 ^ " + " ^ alt w2
      | _ -> cat w

    and cat w =
      match w.node with
      | Cat (w1, w2) -> cat w1 ^ " + " ^ cat w2
      | _ -> str w

    and str w =
      match w.node with
      | Str w -> atom w ^ "*"
      | _ -> atom w

    and atom w =
      match w.node with
      | Ltr l -> show_letter l
      | Emp -> "false"
      | Eps -> "true"
      | _ -> "(" ^ alt w ^ " )"
    in
    alt
end

let rec num_letters (w: word) : int =
  match w.node with
  | Eps | Emp -> 0
  | Ltr i -> i
  | Alt (w1, w2) | Cat (w1, w2) -> max (num_letters w1) (num_letters w2)
  | Str w -> num_letters w 
                                                
let rec accepting (w: word) : bool =
  match w.node with
  | Eps -> true
  | Str _ -> true
  | Emp | Ltr _ -> false
  | Alt (w1, w2) -> accepting w1 || accepting w2
  | Cat (w1, w2) -> accepting w1 && accepting w2

let rec derivative (w: word) (l: letter) : word =
  match w.node with
  | Emp -> emp
  | Eps -> emp
  | Ltr l' -> if l = l' then eps else emp
  | Alt (w1, w2) -> alt (derivative w1 l) (derivative w2 l)
  | Cat (w1, w2) ->
     alt (cat (derivative w1 l) w2) (if accepting w1 then (derivative w2 l) else emp)
  | Str w_inner -> cat (derivative w_inner l) w

module UF = BatUref
module WordMap = Hashtbl.Make(Word)
type state = word UF.uref

let find_state (m: state WordMap.t) (w: word) : state =
  match WordMap.find_opt m w with
  | None ->
     let state = UF.uref w in
     WordMap.add m w state;
     state
  | Some state -> state
           
exception Acceptance_mismatch of word * word

let check_acceptance m w1 w2 =
  Log.debug (fun m -> m "checking acceptance of %s and %s"
                        (Word.show w1) (Word.show w2));
  if accepting w1 <> accepting w2
  then raise (Acceptance_mismatch (w1, w2))
  else
    let st1 = find_state m w1 in
    let st2 = find_state m w2 in
    if not (UF.equal st1 st2)
    then begin
        UF.unite st1 st2;
        [(w1,w2)]
      end
    else []
                               
let equivalent_words (w1: word) (w2: word) (sigma: int) : bool =
  let m : state WordMap.t = WordMap.create 16 in
  let rec loop (l: (word * word) list) : bool =
    match l with
    | [] -> true (* all done! *)
    | (w1, w2)::l' ->
       let rec inner (c: int) : (word * word) list=
         if c = sigma
         then []
         else begin
             Log.debug (fun m -> m "comparing %s and %s on %s"
                                   (Word.show w1) (Word.show w2) (show_letter c));
             let w1c = derivative w1 c in
             let w2c = derivative w2 c in
             Log.debug (fun m -> m "got derivatives %s and %s"
                                   (Word.show w1c) (Word.show w2c));
             check_acceptance m w1c w2c @ inner (c+1)
           end
       in
       let app = inner 0 in
       Log.debug (fun m -> m "added %s" (show_list (fun (w1,w2) -> "(" ^ Word.show w1 ^ ", " ^ Word.show w2 ^ ")") app));
       loop (l' @ app)
  in
  try loop (check_acceptance m w1 w2)
  with Acceptance_mismatch _ ->
    begin
      Log.debug (fun m -> m "%s and %s mismatch\n" (Word.show w1) (Word.show w2));
      false
    end

let same_words (w1: word) (w2: word) : bool =
  let sigma = max (num_letters w1) (num_letters w2) + 1 in
  equivalent_words w1 w2 sigma
