
(*i*)
open Ics
open Tools
open Format
(*i*)

let verbose n =
  Tools.set_verbose n

(*s Pretty-printers with newlines. *)

let endline () = printf "\n"; print_flush ()

let with_nl pp x = pp x; endline ()
 
let pp_term_nl = with_nl pp_term
let pp_mapsto (x,y) = pp_term x; printf " |-> "; pp_term y
let pp_mapsto_nl = with_nl pp_mapsto

(*s The state of the toplevel is composed of a mapping (type [seqns]) and 
    a list of dis-equalities. *)

let current = ref (empty_state())

let state () = !current

let rollback f x =
  let s = !current in
  try
    f x
  with
      Term.Inconsistent _ ->
	current := s;
	raise (Term.Inconsistent "")
	     
(*s Canonizer test (command [sigma]). *)

let sigma t =
  pp_term_nl t; print_flush ()

(*s Solver test (command [solve]). *)
    
let solve e =
  let e' = canon !current (fst e), canon !current (snd e) in
  try
    let s = solve !current e' in
    List.iter pp_mapsto_nl s
  with
      Term.Inconsistent _ -> printf "F"; endline ()

(*s The command [do_assert] introduces a new atom, which is either an equality
    or a dis-equality. The state is left unchanged is an inconsistency is 
    discovered.  *)

let change_state f =
  match f !current with
    | Consistent st -> current := st
    | Redundant -> print_string "Redundant"; endline ()
    | Inconsistent -> raise (Term.Inconsistent "")
  
let process a = change_state (fun st -> process st a)

let processl l = rollback (List.iter process) l
	  
(*s Other commands. *)
			 
let reset () =
  Tools.do_at_reset ();
  current := (empty_state())

let drop () = failwith "drop"
			 
let compare (t1,t2) =
  let cmp = Ics.compare t1 t2 in
  print_string (if cmp = 0 then "=" else if cmp < 0 then "<" else ">");
  endline ()

let find = function
  | Some(t) -> let t' = find !current t in pp_term_nl t'
  | None -> Ics.pp_find !current

let use = function
  | Some(t) ->
      let ts = use !current t in
      printf "{"; Pp.list pp_term ts; printf "}";
      endline ()
  | None ->
      Ics.pp_use !current

let universe = function
  | Some(t) -> 
      if universe !current t then
	printf "true"
      else
	printf "false";
      endline ()
  | None ->
      Ics.pp_universe !current

let can t =
  let t' = canon !current t in pp_term_nl t'
				 
let norm t =
  let t' = norm !current t in pp_term_nl t'
				 
let check t =
 (match Ics.process !current t with
    | Redundant -> printf "T"
    | Inconsistent ->  printf "F"
    | Consistent _ -> printf "X");
  endline ()

let unify (s,t) = print_string "\nCurrently disabled"
  (*
  try
    let phi = unify !current (s,t) Subst.empty in
    let rec pr psi =
      try
	Stream.empty psi
      with Stream.Failure ->
	print_string "Substitution:\n";
        Subst.pp (Stream.next psi);
        print_string "\n";
        pr psi
    in
    pr phi
  with
      Unify.Not_unifiable -> (print_string "Not unifiable"; endline ())
 *)
    
let fol t = print_string "\nCurrently disabled"
		 (*
  match fol !current t with
    | Fol.Valid   -> print_string "Valid"; endline ()
    | Fol.Unsat   -> print_string "Unsatisfiable"; endline ()
		   *)









