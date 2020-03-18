open Kat
open Addition
open Network
open Automata
open Complete
open Decide
open Product
open Boolean
open Incnat

module KA = Addition.K
module AA = Automata(KA)
module DA = Decide(Addition)

module KB = Boolean.K
module AB = Automata(KB)
module DB = Decide(Boolean)          

module KI = IncNat.K
module AI = Automata(KI)
module DI = Decide(IncNat)
          
let main =
  (*
  let p = KA.parse "x>1; inc(x,1) + y>1; inc(y,1) + inc(z,1)" in
  let x = DA.normalize_term 0 p in
  let xhat = DA.locally_unambiguous_form x in
  Printf.printf "x=%s\n\nx^ = %s\n" (DA.show_nf x) (DA.show_nf xhat);
  Printf.printf "p == p via normalization: %b\n" (DA.equivalent p p);
  let q = KA.parse "x>1;inc(x,1) + z>1;inc(z,1)" in
  let y = DA.normalize_term 0 p in
  let yhat = DA.locally_unambiguous_form y in
  Printf.printf "y=%s\n\ny^ = %s\n" (DA.show_nf x) (DA.show_nf yhat);
  Printf.printf "q == q via normalization: %b\n" (DA.equivalent q q);
  Printf.printf "p == q via normalization: %b\n" (DA.equivalent p q);
  let r = KA.parse "x>1;inc(x,1) + z>1;inc(z,1)" in
  Printf.printf "q == r via normalization: %b\n" (DA.equivalent q r);
  *)

  (*
  let p = KB.parse "(x=T; set(y,T) + x=F; set(y,F)); (x=T;y=F + x=F;y=F)" in
  let x = DB.normalize_term 0 p in
  let xhat = DB.locally_unambiguous_form x in
  Printf.printf "x=%s\n\nx^ = %s\n" (DB.show_nf x) (DB.show_nf xhat);

  let q = KB.parse "(x=T; set(y,T) + x=F; set(y,F))" in  
  let y = DB.normalize_term 0 q in
  let yhat = DB.locally_unambiguous_form y in
  Printf.printf "y=%s\n\ny^ = %s\n" (DB.show_nf y) (DB.show_nf yhat);

  Printf.printf "p == q via normalization: %b\n" (DB.equivalent p q)
  *)
(*
  let p = KB.parse "(a=T)*" in
  let x = DB.normalize_term 0 p in
  let xhat = DB.locally_unambiguous_form x in
  Printf.printf "x=%s\n\nx^ = %s\n" (DB.show_nf x) (DB.show_nf xhat);

  let q = KB.parse "(a=T;a=T)* + a=T;(a=T;a=T)*" in  
  let y = DB.normalize_term 0 q in
  let yhat = DB.locally_unambiguous_form y in
  Printf.printf "y=%s\n\ny^ = %s\n" (DB.show_nf y) (DB.show_nf yhat);

  Printf.printf "p == q via normalization: %b\n" (DB.equivalent p q)
*)

  let p = KI.parse "inc(x)*; x > 2" in
  Printf.printf "p=%s\n~~ nf ~~>\n" (KI.Term.show p);
  let x = DI.normalize_term 0 p in
  let xhat = DI.locally_unambiguous_form x in
  Printf.printf "x=%s\n~~ locally unambiguous ~~>\nx^ = %s\n\n" (DI.show_nf x) (DI.show_nf xhat);

  let q = KI.parse "x>2 + inc(x);inc(x)*; x > 2" in  
  Printf.printf "q=%s\n~~ nf ~~>\n" (KI.Term.show q);
  let y = DI.normalize_term 0 q in
  let yhat = DI.locally_unambiguous_form y in
  Printf.printf "y=%s\n~~ locally unambiguous ~~>\ny^ = %s\n\n" (DI.show_nf y) (DI.show_nf yhat);

  Printf.printf "p == q via normalization: %b\n" (DI.equivalent p q)

    
(*
let test = ref false
let stats = ref false
let in_file = ref None

let usage = "Usage: tkat [options]"
let params = [
    ("-in", Arg.String (fun s -> in_file := Some s), "Input file name (default stdin)");
    ("-stats", Arg.Unit (fun n -> stats := true), "Output performance statistics as csv to stdout");
    ("-test", Arg.Unit (fun _o -> test := true), "Runs unit tests" );
  ]

let _ =
  try begin
    Arg.parse params (fun x -> raise (Arg.Bad ("Bad argument : " ^ x))) usage;
  end
  with
    | Arg.Bad msg -> Printf.printf "%s" msg
    | Arg.Help msg -> Printf.printf "%s" msg
*)
