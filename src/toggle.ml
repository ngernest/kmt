open Kat
open Addition
open Boolean
open Product
open Automata
open Decide

module T = ANSITerminal
module DB = Decide(Boolean)

let test_toggle_three_norm () =
  let term1 = DB.K.parse "(x=F;set(x,T) + x=T;set(x,F) + y=F;set(y,T) + y=T;set(y,F) + z=F;set(z,T) + z=T;set(z,F))*" in
  let term2 = term1 in
  let eq = DB.equivalent term1 term2 in 
  assert eq; 
  ()

  (* timeout [in seconds] *)
let timeout = ref 300

let run_test name tester arg =
  Printf.printf "%-30srunning...%!" name;
  let t = Common.timeout !timeout tester arg in
  Printf.printf "\b\b\b\b\b\b\b\b\b\b   ";
  begin
    match t with
    | Some time -> Printf.printf "%7.4f" time
    | None -> Printf.printf "%-7s" "timeout"
  end;
  Printf.printf "\n%!"

let main =
  Printf.printf "test                      time (seconds)\n";
  Printf.printf "% 31ds timeout\n%!" !timeout;
  Printf.printf "----------------------------------------\n%!";
  run_test "toggle three bits (rewrite)" test_toggle_three_norm ();
    
