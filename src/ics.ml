(*
 * The contents of this file are subject to the ICS(TM) Community Research
 * License Version 1.0 (the ``License''); you may not use this file except in
 * compliance with the License. You may obtain a copy of the License at
 * http://www.icansolve.com/license.html.  Software distributed under the
 * License is distributed on an ``AS IS'' basis, WITHOUT WARRANTY OF ANY
 * KIND, either express or implied. See the License for the specific language
 * governing rights and limitations under the License.  The Licensed Software
 * is Copyright (c) SRI International 2001, 2002.  All rights reserved.
 * ``ICS'' is a trademark of SRI International, a California nonprofit public
 * benefit corporation.
 * 
 * Author: Harald Ruess
 *)

open Format
open Sym
open Term


let init (n, pp, eot, inch, outch) =
  Istate.initialize pp eot inch outch;
  if n = 0 then
    Sys.catch_break true                 (** raise [Sys.Break] exception upon *)
                                         (** user interrupt. *)

let set_maxloops n =
  Rule.maxclose := n
let _ = Callback.register "set_maxloops" set_maxloops

let do_at_exit () = Tools.do_at_exit ()
let _ = Callback.register "do_at_exit" do_at_exit

let _ = Callback.register "init" init

(** Channels. *)

type inchannel = in_channel
type outchannel = Format.formatter

let channel_stdin () = Pervasives.stdin
let _ = Callback.register "channel_stdin" channel_stdin

let channel_stdout () = Format.std_formatter
let _ = Callback.register "channel_stdout"  channel_stdout

let  channel_stderr () = Format.err_formatter
let _ = Callback.register "channel_stderr"  channel_stderr

let inchannel_of_string = Pervasives.open_in
let _ = Callback.register "inchannel_of_string" inchannel_of_string

let outchannel_of_string str = 
  Format.formatter_of_out_channel (Pervasives.open_out str)
let _ = Callback.register "outchannel_of_string" outchannel_of_string


(* Names. *)

type name = Name.t

let name_of_string = Name.of_string
let _ = Callback.register "name_of_string" name_of_string

let name_to_string = Name.to_string
let _ = Callback.register "name_to_string" name_to_string

let name_eq = Name.eq
let _ = Callback.register "name_eq" name_eq


(** Constrains. *)

type cnstrnt = Cnstrnt.t

let cnstrnt_of_string s = 
  let lb = Lexing.from_string s in 
  Parser.cnstrnteof Lexer.token lb
let _ = Callback.register "cnstrnt_of_string" cnstrnt_of_string

let cnstrnt_input ch =
 let lb = Lexing.from_channel ch in 
  Parser.cnstrnteof Lexer.token lb
let _ = Callback.register "cnstrnt_input" cnstrnt_input

let cnstrnt_output = Cnstrnt.pp
let _ = Callback.register "cnstrnt_output" cnstrnt_output

let cnstrnt_pp = Cnstrnt.pp Format.std_formatter
let _ = Callback.register "cnstrnt_pp" cnstrnt_pp


let cnstrnt_mk_int () = Cnstrnt.mk_int
let _ = Callback.register "cnstrnt_mk_int" cnstrnt_mk_int

let cnstrnt_mk_nonint () = Cnstrnt.mk_nonint
let _ = Callback.register "cnstrnt_mk_nonint" cnstrnt_mk_nonint

let cnstrnt_mk_nat () = Cnstrnt.mk_nat
let _ = Callback.register "cnstrnt_mk_nat" cnstrnt_mk_nat

let cnstrnt_mk_singleton = Cnstrnt.mk_singleton
let _ = Callback.register "cnstrnt_mk_singleton" cnstrnt_mk_singleton

let cnstrnt_mk_diseq = Cnstrnt.mk_diseq
let _ = Callback.register "cnstrnt_mk_diseq" cnstrnt_mk_diseq

let cnstrnt_mk_oo = Cnstrnt.mk_oo Dom.Real
let _ = Callback.register "cnstrnt_mk_oo" cnstrnt_mk_oo

let cnstrnt_mk_oc = Cnstrnt.mk_oc Dom.Real
let _ = Callback.register "cnstrnt_mk_oc" cnstrnt_mk_oc

let cnstrnt_mk_co = Cnstrnt.mk_co Dom.Real
let _ = Callback.register "cnstrnt_mk_co" cnstrnt_mk_co

let cnstrnt_mk_cc = Cnstrnt.mk_cc Dom.Real
let _ = Callback.register "cnstrnt_mk_cc" cnstrnt_mk_cc

let cnstrnt_mk_lt = Cnstrnt.mk_lt Dom.Real
let _ = Callback.register "cnstrnt_mk_lt" cnstrnt_mk_lt

let cnstrnt_mk_le = Cnstrnt.mk_le Dom.Real
let _ = Callback.register "cnstrnt_mk_le" cnstrnt_mk_le


let cnstrnt_mk_gt = Cnstrnt.mk_gt Dom.Real
let _ = Callback.register "cnstrnt_mk_gt" cnstrnt_mk_gt

let cnstrnt_mk_ge = Cnstrnt.mk_ge Dom.Real
let _ = Callback.register "cnstrnt_mk_ge" cnstrnt_mk_ge


let cnstrnt_inter = Cnstrnt.inter
let _ = Callback.register "cnstrnt_inter" cnstrnt_inter

let cnstrnt_add = Cnstrnt.add
let _ = Callback.register "cnstrnt_add" cnstrnt_add

let cnstrnt_multq = Cnstrnt.multq
let _ = Callback.register "cnstrnt_multq" cnstrnt_multq

let cnstrnt_mult = Cnstrnt.mult
let _ = Callback.register "cnstrnt_mult" cnstrnt_mult

let cnstrnt_div = Cnstrnt.div
let _ = Callback.register "cnstrnt_div" cnstrnt_div

(** Theories. *)

type th = int

let th_to_string n = Th.to_string (Th.of_int n)
let _ = Callback.register "th_to_string" th_to_string



(** Function symbols. These are partitioned into uninterpreted
 function symbols and function symbols interpreted in one of the
 builtin theories. For each interpreted function symbol there is
 a recognizer function [is_xxx].  Some values of type [sym] represent 
 families of function symbols. The corresponding indices can be obtained
 using the destructor [d_xxx] functions (only after checking that [is_xxx]
 holds. *)

open Sym

type sym = Sym.t

let sym_is_uninterp = function Uninterp _ -> true | _ -> false
let _ = Callback.register "sym_is_uninterp" sym_is_uninterp

let sym_is_interp n sym =
  Th.eq (Th.of_int n) (Th.of_sym sym)
let _ = Callback.register "sym_is_interp" sym_is_interp

let sym_eq = Sym.eq
let _ = Callback.register "sym_eq" sym_eq

let sym_cmp = Sym.cmp
let _ = Callback.register "sym_cmp" sym_cmp

let sym_is_num = function Arith(Num _) -> true | _ -> false
let _ = Callback.register "sym_is_num" sym_is_num

let sym_d_num = function Arith(Num(q)) -> q | _ -> assert false
let _ = Callback.register "sym_d_num" sym_d_num

let sym_is_multq = function Arith(Multq _) -> true | _ -> false
let _ = Callback.register "sym_is_multq" sym_is_multq

let sym_d_multq = function Arith(Multq(q)) -> q | _ -> assert false
let _ = Callback.register "sym_d_multq" sym_d_multq

let sym_is_add = function Arith(Add) -> true | _ -> false
let _ = Callback.register "sym_is_add" sym_is_add

let sym_is_tuple = function Product(Tuple) -> true | _ -> false
let _ = Callback.register "sym_is_tuple" sym_is_tuple

let sym_is_proj = function Product(Proj _) -> true | _ -> false
let _ = Callback.register "sym_is_proj" sym_is_proj

let sym_d_proj = function Product(Proj(i,n)) -> (i,n) | _ -> assert false
let _ = Callback.register "sym_d_proj" sym_d_proj

let sym_is_inl = function Coproduct(InL) -> true | _ -> false
let _ = Callback.register "sym_is_inl" sym_is_inl

let sym_is_inr = function Coproduct(InR) -> true | _ -> false
let _ = Callback.register "sym_is_inr" sym_is_inr

let sym_is_outl = function Coproduct(OutL) -> true | _ -> false
let _ = Callback.register "sym_is_outl" sym_is_outl

let sym_is_outr = function Coproduct(OutR) -> true | _ -> false
let _ = Callback.register "sym_is_outr" sym_is_outr

let sym_is_bv_const = function Bv(Const _) -> true | _ -> false
let _ = Callback.register "sym_is_bv_const" sym_is_bv_const

let sym_is_bv_conc = function Bv(Conc _) -> true | _ -> false
let _ = Callback.register "sym_is_bv_conc" sym_is_bv_conc

let sym_d_bv_conc = function Bv(Conc(n, m)) -> (n, m) | _ -> assert false
let _ = Callback.register "sym_d_bv_conc" sym_d_bv_conc

let sym_is_bv_sub = function Bv(Sub _) -> true | _ -> false
let _ = Callback.register "sym_is_bv_sub" sym_is_bv_sub

let sym_d_bv_sub = function Bv(Sub(n, i, j)) -> (n, i, j) | _ -> assert false
let _ = Callback.register "sym_d_bv_sub" sym_d_bv_sub

let sym_is_bv_bitwise = function Bv(Bitwise _) -> true | _ -> false
let _ = Callback.register "sym_is_bv_bitwise" sym_is_bv_bitwise

let sym_d_bv_bitwise = function Bv(Bitwise(n)) -> n | _ -> assert false
let _ = Callback.register "sym_d_bv_bitwise" sym_d_bv_bitwise

let sym_is_mult = function Pp(Mult) -> true | _ -> false
let _ = Callback.register "sym_is_mult" sym_is_mult

let sym_is_expt = function Pp(Mult) -> true | _ -> false
let _ = Callback.register "sym_is_expt" sym_is_expt

let sym_is_apply = function Fun(Apply _) -> true | _ -> false
let _ = Callback.register "sym_is_apply" sym_is_apply

let sym_d_apply = function Fun(Apply(i)) -> i | _ -> assert false
let _ = Callback.register "sym_d_apply" sym_d_apply

let sym_is_abs = function Fun(Abs) -> true | _ -> false
let _ = Callback.register "sym_is_abs" sym_is_abs

let sym_is_select = function Arrays(Select) -> true | _ -> false
let _ = Callback.register "sym_is_select" sym_is_select

let sym_is_update = function Arrays(Update) -> true | _ -> false
let _ = Callback.register "sym_is_update" sym_is_update

let sym_is_unsigned = function Bvarith(Unsigned) -> true | _ -> false
let _ = Callback.register "sym_is_unsigned" sym_is_unsigned




(** Terms ar either variables, uninterpreted applications,
  or interpreted applications including boolean terms. *)
  
type term = Term.t

let term_of_string s =
  let lb = Lexing.from_string s in 
  Parser.termeof Lexer.token lb
let _ = Callback.register "term_of_string" term_of_string

let term_to_string = Pretty.to_string Term.pp 
let _ = Callback.register "term_to_string" term_to_string

let term_input ch =
  let lb = Lexing.from_channel ch in 
  Parser.termeof Lexer.token lb
let _ = Callback.register "term_input" term_input

let term_output = Term.pp
let _ = Callback.register "term_output" term_output

let term_pp a = Term.pp Format.std_formatter a; Format.print_flush ()
let _ = Callback.register "term_pp" term_pp


(** Construct a variable. *)

let term_mk_var str =
  let x = Name.of_string str in
  Term.mk_var x
let _ = Callback.register "term_mk_var" term_mk_var


(** Uninterpred function application and function update. *)
         
let term_mk_uninterp x l =
  let f = Sym.Uninterp(Name.of_string x) in
  App.sigma f l
let _ = Callback.register "term_mk_uninterp" term_mk_uninterp

  
(** Constructing arithmetic expressions. *)

let term_mk_num = Arith.mk_num
let _ = Callback.register "term_mk_num" term_mk_num

let term_mk_multq q = Arith.mk_multq q
let _ = Callback.register "term_mk_multq" term_mk_multq

let term_mk_add = Arith.mk_add
let _ = Callback.register "term_mk_add" term_mk_add

let term_mk_addl = Arith.mk_addl
let _ = Callback.register "term_mk_addl" term_mk_addl

let term_mk_sub  = Arith.mk_sub
let _ = Callback.register "term_mk_sub" term_mk_sub

let term_mk_unary_minus  = Arith.mk_neg
let _ = Callback.register "term_mk_unary_minus" term_mk_unary_minus

let term_is_arith = Arith.is_interp
let _ = Callback.register "iterm_s_arith" term_is_arith




(** Constructing tuples and projections. *)

let term_mk_tuple = Tuple.mk_tuple
let _ = Callback.register "term_mk_tuple" term_mk_tuple

let term_mk_proj i j = Tuple.mk_proj i j
let _ = Callback.register "term_mk_proj" term_mk_proj


(** Bitvector terms. *)

let term_mk_bvconst s = Bitvector.mk_const (Bitv.from_string s)
let _ = Callback.register "term_mk_bvconst" term_mk_bvconst

let term_mk_bvsub (n,i,j) = Bitvector.mk_sub n i j
let _ = Callback.register "term_mk_bvsub" term_mk_bvsub

let term_mk_bvconc (n,m) = Bitvector.mk_conc n m
let _ = Callback.register "term_mk_bvconc" term_mk_bvconc

let term_mk_bwite n (a,b,c) = Bitvector.mk_bitwise n a b c
let _ = Callback.register "term_mk_bwite" term_mk_bwite

let term_mk_bwand n a b =
  Bitvector.mk_bitwise n a b (Bitvector.mk_zero n)
let _ = Callback.register "term_mk_bwand" term_mk_bwand

let term_mk_bwor n a b =
  Bitvector.mk_bitwise n a (Bitvector.mk_one n) b
let _ = Callback.register "term_mk_bwor" term_mk_bwor

let term_mk_bwnot n a =
  Bitvector.mk_bitwise n a (Bitvector.mk_zero n) (Bitvector.mk_one n)
let _ = Callback.register "term_mk_bwnot" term_mk_bwnot

	  
(** Boolean terms. *)

let term_mk_true = Boolean.mk_true
let _ = Callback.register "term_mk_true" term_mk_true

let term_mk_false = Boolean.mk_false
let _ = Callback.register "term_mk_false" term_mk_false

(** Coproducts. *)

let term_mk_inj = Coproduct.mk_inj
let _ = Callback.register "term_mk_inj" term_mk_inj

let term_mk_out = Coproduct.mk_out
let _ = Callback.register "term_mk_out" term_mk_out

(** Atoms. *)

type atom = Atom.t
type atoms = Atom.Set.t

let atom_pp a = 
  Atom.pp Format.std_formatter a;
  Format.print_flush ()
let _ = Callback.register "atom_pp" atom_pp

let atom_of_string s = 
  let lb = Lexing.from_string s in 
  Parser.atomeof Lexer.token lb
let _ = Callback.register "atom_of_string" atom_of_string

let atom_to_string = Pretty.to_string Atom.pp
let _ = Callback.register "atom_to_string" atom_to_string

let atom_mk_equal a b = 
  Atom.mk_equal (Fact.mk_equal a b (Some(Fact.Axiom)))
let _ = Callback.register "atom_mk_equal" atom_mk_equal  

let atom_mk_diseq a b = 
  Atom.mk_diseq (Fact.mk_diseq a b Fact.mk_axiom)
let _ = Callback.register "atom_mk_diseq" atom_mk_diseq

let atom_mk_in i a = 
  Atom.mk_in (Fact.mk_cnstrnt a i Fact.mk_axiom)
let _ = Callback.register "atom_mk_in" atom_mk_in

let atom_mk_true = Atom.mk_true
let _ = Callback.register "atom_mk_true" atom_mk_true

let atom_mk_false = Atom.mk_false
let _ = Callback.register "atom_mk_false" atom_mk_false

let atom_mk_real a = 
  Atom.mk_in (Fact.mk_cnstrnt a Cnstrnt.mk_real Fact.mk_axiom)
let _ = Callback.register "atom_mk_real" atom_mk_real

let atom_mk_int a = 
  Atom.mk_in (Fact.mk_cnstrnt a Cnstrnt.mk_int Fact.mk_axiom)
let _ = Callback.register "atom_mk_int" atom_mk_int

let atom_mk_nonint a = 
  Atom.mk_in (Fact.mk_cnstrnt a Cnstrnt.mk_nonint Fact.mk_axiom)
let _ = Callback.register "atom_mk_nonint" atom_mk_nonint

let atom_mk_lt a b = 
  Atom.mk_in (Fact.mk_cnstrnt  
		(Arith.mk_sub a b)
		(Cnstrnt.mk_neg Dom.Real)
		Fact.mk_axiom)
let _ = Callback.register "atom_mk_lt"  atom_mk_lt

let atom_mk_le a b = 
  Atom.mk_in (Fact.mk_cnstrnt  
		(Arith.mk_sub a b)
		(Cnstrnt.mk_nonpos Dom.Real)
		Fact.mk_axiom)
let _ = Callback.register "atom_mk_le"  atom_mk_le

let atom_mk_gt a b = atom_mk_lt b a
let _ = Callback.register "atom_mk_gt" atom_mk_gt

let atom_mk_ge a b = atom_mk_le b a
let _ = Callback.register "atom_mk_ge" atom_mk_ge

let term_is_true = Boolean.is_true
let _ = Callback.register "term_is_true" term_is_true

let term_is_false = Boolean.is_false
let _ = Callback.register "term_is_false" term_is_false



(** Nonlinear terms. *)


let term_mk_mult = Sig.mk_mult
let _ = Callback.register "term_mk_mult" term_mk_mult

let rec term_mk_multl = function
  | [] -> Arith.mk_one
  | [a] -> a
  | a :: b :: l -> term_mk_multl (term_mk_mult a b :: l)
let _ = Callback.register "term_mk_multl" term_mk_multl


let term_mk_expt = Sig.mk_expt 
let _ = Callback.register "term_mk_expt" term_mk_expt


(** Builtin applications. *)

let term_mk_unsigned = Bvarith.mk_unsigned
let _ = Callback.register "term_mk_unsigned" term_mk_unsigned

let term_mk_update  = Arr.mk_update 
let _ = Callback.register "term_mk_update" term_mk_update

let term_mk_select = Arr.mk_select
let _ = Callback.register "term_mk_select" term_mk_select

let term_mk_div = Sig.mk_div
let _ = Callback.register "term_mk_div" term_mk_div

let term_mk_apply = 
  Apply.mk_apply (Context.sigma Context.empty) None
let _ = Callback.register "term_mk_apply" term_mk_apply

let term_mk_arith_apply c = 
  Apply.mk_apply (Context.sigma Context.empty) (Some(c))
let _ = Callback.register "term_mk_arith_apply" term_mk_arith_apply


(** Set of terms. *)

type terms = Term.Set.t

(* Term map. *)

type 'a map = 'a Term.Map.t
	  

(** Equalities. *)

let term_eq = Term.eq
let _ = Callback.register "term_eq" term_eq

let term_cmp = Term.cmp
let _ = Callback.register "term_cmp" term_cmp

(** Trace level. *)
    
type trace_level = string

let trace_reset = Trace.reset
let _ = Callback.register "trace_reset" trace_reset

let trace_add = Trace.add
let _ = Callback.register "trace_add" trace_add

let trace_remove = Trace.add
let _ = Callback.register "trace_remove" trace_remove

let trace_get = Trace.get
let _ = Callback.register "trace_get" trace_get


(** Solution sets. *)

type solution = Solution.t

let solution_apply s x = Solution.apply s x

let solution_find s x = Solution.find s x

let solution_inv s b = Solution.inv s b

let solution_mem = Solution.mem

let solution_occurs = Solution.occurs

let solution_use = Solution.use

let solution_is_empty = Solution.is_empty




(** States. *)

open Process

type context = Context.t

let context_eq = Context.eq
let _ = Callback.register "context_eq" context_eq  

let context_empty () = Context.empty
let _ = Callback.register "context_empty" context_empty

let context_ctxt_of s = (Atom.Set.elements (Context.ctxt_of s))
let _ = Callback.register "context_ctxt_of" context_ctxt_of

let context_u_of s = Context.eqs_of s Th.u
let _ = Callback.register "context_u_of" context_u_of

let context_a_of s = Context.eqs_of s Th.la
let _ = Callback.register "context_a_of" context_a_of

let context_t_of s = Context.eqs_of s Th.p
let _ = Callback.register "context_t_of" context_t_of

let context_bv_of s =  Context.eqs_of s Th.bv
let _ = Callback.register "context_bv_of" context_bv_of

let context_pp s = Context.pp Format.std_formatter s; Format.print_flush()
let _ = Callback.register "context_pp" context_pp

let context_ctxt_pp s = 
  let al = (Atom.Set.elements (Context.ctxt_of s)) in
  let fmt = Format.std_formatter in
    List.iter
      (fun a ->
	 Pretty.string fmt "\nassert ";
	 Atom.pp fmt a;
	 Pretty.string fmt " .")
      al;
    Format.print_flush()
let _ = Callback.register "context_ctxt_pp" context_ctxt_pp

	  

(** Processing of new equalities. *)

type status = Context.t Process.status

let is_consistent r = 
  (match r with
     | Process.Ok _ -> true
     | _ -> false)
let _ = Callback.register "is_consistent" is_consistent

let is_redundant r = (r = Process.Valid)
let _ = Callback.register "is_redundant" is_redundant

let is_inconsistent r =
   (r = Process.Inconsistent)
let _ = Callback.register "is_inconsistent" is_inconsistent  

let d_consistent r =
  match r with
    | Process.Ok s -> s
    | _ -> (context_empty())
         (* failwith "Ics.d_consistent: fatal error" *)
	
let _ = Callback.register "d_consistent" d_consistent 
 
let process s =
  Trace.func "api" "Process" Atom.pp (Process.pp Context.pp)
    (Process.atom s)
let _ = Callback.register "process" process   

let split s = 
  Atom.Set.elements (Context.split s) 
let _ = Callback.register "split" split

(** Normalization functions *)

let can = Can.atom
let _ = Callback.register "can" can


let read_from_channel ch = 
  Parser.commands Lexer.token (Lexing.from_channel ch)

let read_from_string str =  
  Parser.commandseof Lexer.token (Lexing.from_string str)

let rec cmd_rep () =
  let inch = Istate.inchannel() in
  let outch = Istate.outchannel() in
  try
    cmd_output outch (read_from_channel inch);
    Format.fprintf outch "@?"
  with
    | Invalid_argument str -> cmd_error outch str
    | Parsing.Parse_error -> cmd_error outch ("Syntax error on line " ^ string_of_int !Tools.linenumber)
    | End_of_file ->
	 cmd_quit 0 outch;
    | Sys.Break -> 
	 cmd_quit 1 outch;
    | Failure "drop" -> raise (Failure "drop")
    | exc -> (cmd_error outch ("Exception " ^ (Printexc.to_string exc)); exit 2)

and cmd_batch () =
  let inch = Istate.inchannel() in
  let outch = Istate.outchannel() in
  try
    cmd_output outch (Parser.commandsequence Lexer.token (Lexing.from_channel inch));
    Format.fprintf outch "@?"
  with
    | Invalid_argument str -> cmd_error outch str
    | Parsing.Parse_error -> cmd_error outch ("Syntax error on line " ^ string_of_int !Tools.linenumber)
    | End_of_file ->
	 cmd_quit 0 outch;
    | Sys.Break -> 
	 cmd_quit 1 outch;
    | Failure "drop" -> raise (Failure "drop")
    | exc -> (cmd_error outch ("Exception " ^ (Printexc.to_string exc)); exit 2)



and cmd_output fmt result =
  (match result with
     | Result.Process(status) -> 
	 Process.pp Name.pp fmt status
     | Result.Unit() ->
	 Format.fprintf fmt ":unit@?"
     | Result.Bool(true) ->
	 Format.fprintf fmt ":true@?"
     | Result.Bool(false) ->
	 Format.fprintf fmt ":false@?"
     | value -> 
	 Format.fprintf fmt ":val ";
	 Result.output fmt value;
         Format.fprintf fmt "@?");
  cmd_endmarker fmt
	
and cmd_error fmt str =
  Format.fprintf fmt ":error %s" str;
  Format.fprintf fmt "\n%s@?" (Istate.eot())

and cmd_quit n fmt = 
 Format.fprintf fmt ":quit\n@?";
 cmd_endmarker fmt;
 exit n

and cmd_endmarker fmt =
  let eot = Istate.eot () in
  if eot = "" then
    Format.pp_print_flush fmt ()
  else 
    begin
      Format.fprintf fmt "\n%s" eot;
      Format.pp_print_flush fmt ()
    end 

let _ = Callback.register "cmd_rep" cmd_rep
let _ = Callback.register "cmd_batch" cmd_batch


(** Abstract sign interpretation. *)

let cnstrnt s a = 
  try
    Some(Context.cnstrnt s a)
  with
      Not_found -> None
 

(** Tools *)

let reset () = Tools.do_at_reset ()
let _ = Callback.register "reset" reset

let gc () = Gc.full_major ()
let _ = Callback.register "gc" gc

let flush = print_flush
let _ = Callback.register "flush" flush


(** Lists. *)

let is_nil = function [] -> true | _ -> false
let _ = Callback.register "is_nil" is_nil

let cons x l = x :: l
let _ = Callback.register "cons" cons

let head = List.hd
let _ = Callback.register "head" head

let tail = List.tl
let _ = Callback.register "tail" tail


(** Pairs. *)

let pair x y = (x,y)
let _ = Callback.register "pair" pair

let fst = fst
let _ = Callback.register "fst" fst

let snd = snd
let _ = Callback.register "snd" snd


(** Triples. *)

let triple x y z = (x,y,z)
let _ = Callback.register "triple" triple

let fst_of_triple = function (x,_,_) -> x
let _ = Callback.register "fst_of_triple" fst_of_triple

let snd_of_triple = function (_,y,_) -> y
let _ = Callback.register "snd_of_triple" snd_of_triple

let third_of_triple = function (_,_,z) -> z
let _ = Callback.register "third_of_triple" third_of_triple
  

(** Quadruples. *)
   
let fst_of_quadruple  = function (x1,_,_,_) -> x1
let _ = Callback.register "fst_of_quadruple" fst_of_quadruple

let snd_of_quadruple = function (_,x2,_,_) -> x2
let _ = Callback.register "snd_of_quadruple" snd_of_quadruple

let third_of_quadruple = function (_,_,x3,_) -> x3
let _ = Callback.register "third_of_quadruple" third_of_quadruple

let fourth_of_quadruple = function (_,_,_,x4) -> x4
let _ = Callback.register "fourth_of_quadruple" fourth_of_quadruple
    

(** Options. *)

let is_some = function
  | Some _ -> true
  | None -> false

let is_none = function
  | None -> true
  | _ -> false

let value_of = function
  | Some(x) -> x
  | _ -> assert false
	
let _ = Callback.register "is_some" is_some
let _ = Callback.register "is_none" is_none
let _ = Callback.register "value_of" value_of

(** Sleeping. *)

let sleep = Unix.sleep
let _ = Callback.register "sleep" sleep
	 
(** Multi-precision arithmetic.*)

open Mpa

type q = Q.t

let ints_of_num q = (Z.to_string (Q.numerator q), Z.to_string (Q.denominator q))
let _ = Callback.register "ints_of_num" ints_of_num

let num_of_int = Q.of_int
let _ = Callback.register "num_of_int" num_of_int
		   
let num_of_ints i1 i2 = Q.div (num_of_int i1) (num_of_int i2)
let _ = Callback.register "num_of_ints" num_of_ints

let string_of_num = Q.to_string
let _ = Callback.register "string_of_num" string_of_num

let num_of_string = Q.of_string
let _ = Callback.register "num_of_string" num_of_string

