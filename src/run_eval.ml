open Kat
open Addition
open Boolean
open Product
open Decide

module T = ANSITerminal
module KA = Addition.K
module KB = Boolean.K
module Prod = Product(Addition)(Boolean)
module KP = Prod.K
module DA = Decide(Addition)
module DB = Decide(Boolean)
module DP = Decide(Prod)

let variables = ["a"; "b"; "c"; "d"; "e"; "f"; "g"; "h"; "i"]

let random_addition_theory (vars: int) (bound: int) =
  let v = Random.int vars in
  let b = Random.int bound in
  let dir = Random.int 2 in
  let str = List.nth variables v in
  if dir = 0 then Lt (str, b) else Gt (str, b)


let random_addition_action (vars: int) (bound: int) =
  let v = Random.int vars in
  let b = Random.int bound in
  let str = string_of_int v in
  Increment (str, b)


module Random (K : KAT_IMPL) = struct
  let split sz =
    let x = Random.int (sz + 1) in
    if x = 0 then (1, sz - 1) else if x = sz then (sz - 1, 1) else (x, sz - x)


  let rec random_test (size: int) (f: unit -> K.A.t) : K.Test.t =
    if size = 1 then K.theory (f ())
    else
      let x = Random.int 5 in
      let l, r = split size in
      if x < 1 then K.not (random_test (size - 1) f)
      else if x < 3 then K.ppar (random_test l f) (random_test r f)
      else K.pseq (random_test l f) (random_test r f)


  let rec random_term (size: int) (f: unit -> K.P.t) : K.Term.t =
    if size = 1 then K.action (f ())
    else
      let x = Random.int 5 in
      let l, r = split size in
      if x < 2 then K.par (random_term l f) (random_term r f)
      else if x < 4 then K.seq (random_term l f) (random_term r f)
      else K.star (random_term (size - 1) f)
end

module RA = Random (KA)

let test_astar_a_norm test =
  let term1 = DA.K.pred test in
  let term2 = DA.K.star term1 in
  try 
    let eq = DA.equivalent term1 term2 in
    assert (not eq);
    ()
  with _ -> ()

let test_count_twice_norm () =
  let term1 = DA.K.parse "(inc(x,1))*; x > 10" in
  let term2 = DA.K.parse "(inc(x,1))*;(inc(x,1))*; x > 10" in
  let eq = DA.equivalent term1 term2 in
  assert eq ;
  ()

let test_count_order_norm () =
  let term1 = DA.K.parse "(inc(x,1))*; x > 3; (inc(y,1))*; y > 3" in
  let term2 = DA.K.parse "(inc(x,1))*; (inc(y,1))*; x > 3; y > 3" in
  let eq = DA.equivalent term1 term2 in
  assert eq;
  ()

let test_parity_loop_norm () =
  let term1 =
    DB.K.parse
      "x=F; ( (x=T; set(x,F) + x=F; set(x,T));(x=T; set(x,F) + x=F; set(x,T)) )*"
  in
  let term2 =
    DB.K.parse
      "     ( (x=T; set(x,F) + x=F; set(x,T));(x=T; set(x,F) + x=F; set(x,T)) )*; x=F"
  in
  let eq = DB.equivalent term1 term2 in
  assert eq;
  ()

let test_boolean_formula_norm () =
  let term1 =
    DB.K.parse
      "set(w,F); set(x,T); set(y,F); set(z,F); ((w=T + x=T + y=T + z=T); \
        set(a,T) + (not (w=T + x=T + y=T + z=T)); set(a,F))"
  in
  let term2 =
    DB.K.parse
      "set(w,F); set(x,T); set(y,F); set(z,F); (((w=T + x=T) + (y=T + z=T)); \
        set(a,T) + (not ((w=T + x=T) + (y=T + z=T))); set(a,F))"
  in
  let eq = DB.equivalent term1 term2 in
  assert eq;
  ()

let test_population_count_norm () = 
  let term1 = DP.K.parse "y<1; (true + a=T; inc(y,1)); (true + b=T; inc(y,1)); (true + c=T; inc(y,1)); y>2" in
  let term2 = DP.K.parse "y<1; a=T; b=T; c=T; inc(y,1); inc(y,1); inc(y,1)" in 
  let eq = DP.equivalent term1 term2 in 
  assert eq;
  ()

let test_toggle_three_norm () =
  let term1 = DP.K.parse "(x=F;set(x,T) + y=F;set(y,T) + x=T;set(x,F) + y=T;set(y,F) + z=F;set(z,T) + z=T;set(z,F))*" in
  let term2 = term1 in
  let eq = DP.equivalent term1 term2 in 
  assert eq; 
  ()

  
let go timeout () () : unit =
  let run_test name tester arg =
    Printf.printf "%-30srunning...%!" name;
    let t = Common.timeout timeout tester arg in
    Printf.printf "\b\b\b\b\b\b\b\b\b\b   ";
    begin
      match t with
      | Some time -> Printf.printf "%7.4f" time
      | None -> Printf.printf "%-7s" "timeout"
    end;
    Printf.printf "\n%!"
  in

  let test1 = RA.random_test 10 (fun () -> random_addition_theory 2 3) in
  (* let test2 = RA.random_test 100 (fun () -> random_addition_theory 2 3) in *)

  Printf.printf "test                      time (seconds)\n";
  Printf.printf "% 31ds timeout\n%!" timeout;
  Printf.printf "----------------------------------------\n%!";
  run_test "a* != a (10 random `a`s)" test_astar_a_norm test1;

  run_test "count twice" test_count_twice_norm ();

  run_test "count order" test_count_order_norm ();

  run_test "parity loop" test_parity_loop_norm ();

  run_test "boolean tree" test_boolean_formula_norm ();

  run_test "population count" test_population_count_norm ();

  run_test "toggle three bits" test_toggle_three_norm ()

(* arg parsing *)
open Cmdliner

let setup_log =
  let setup_log style_renderer level =
    Fmt_tty.setup_std_outputs ?style_renderer ();
    Logs.set_level level;
    Logs.set_reporter (Logs_fmt.reporter ())
  in
  Term.(const setup_log $ Fmt_cli.style_renderer () $ Logs_cli.level ())

let setup_debugs =
  let debugs =
    let debug_flags = Logs.Src.list () |> List.map (fun src -> (Logs.Src.name src, src)) in
    let doc = "Turn on debugging from $(docv). $(docv) must be " ^
                (Arg.doc_alts_enum debug_flags) ^ "."          
    in
    Arg.(value & opt_all (enum debug_flags) [] & info ["d"; "debug"] ~docv:"SRC" ~doc)
  in
  let setup_debugs srcs =
    srcs |> List.iter (fun src -> Logs.Src.set_level src (Some Logs.Debug))
  in
  Term.(const setup_debugs $ debugs)

let timeout =
  let doc = "Timeout after $(docv) seconds (set <=0 for no timeout; defaults to 30)"
  in
  Arg.(value & opt Arg.int 30 & info ["t"; "timeout"] ~docv:"SECONDS" ~doc)

let cmd =
  let doc = "Run PLDI2022 evaluation" in
  let info = Cmd.info "run_eval" ~doc in
  Cmd.v info Term.(const go $ timeout $ setup_log $ setup_debugs)

let main () = exit (Cmd.eval cmd)
;;

main()

