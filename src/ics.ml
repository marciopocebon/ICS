
(*i*)
open Format
open Hashcons
open Term
(*i*)

(*s Terms. *)
  
type term = Term.term

let var x = Var.var x

let is_int x = Atom.cnstrnt (Int,x)
let is_real x = Atom.cnstrnt (Real,x)
let is_pos x = Atom.cnstrnt (Pos,x)
let is_neg x = Atom.cnstrnt (Neg,x)
let is_nonneg x = Atom.cnstrnt (Nonneg,x)
let is_nonpos x = Atom.cnstrnt (Nonpos,x)

let _ = Callback.register "is_int" is_int
let _ = Callback.register "is_real" is_real
let _ = Callback.register "is_pos" is_pos
let _ = Callback.register "is_neg" is_neg
let _ = Callback.register "is_nonneg" is_nonneg
let _ = Callback.register "is_nonpos" is_nonpos

		         
let app = Arrays.app

let _ = Callback.register "var" var
let _ = Callback.register "app" app

let num = Arith.num
let div q1 q2 = Arith.num (Mpa.Q.div q1 q2)
let plus tl = Arith.add tl
let plus2 x y = Arith.add2 (x,y)
let minus t1 t2 = Arith.sub (t1,t2)
let unary_minus  = Arith.neg
let times tl = Arith.mult tl
let times2 t1 t2 = Arith.mult2 (t1,t2)         

let _ = Callback.register "num" num
let _ = Callback.register "plus" plus
let _ = Callback.register "plus2" plus2
let _ = Callback.register "minus" minus
let _ = Callback.register "unary_minus" unary_minus
let _ = Callback.register "times" times
let _ = Callback.register "times2" times2 

let tup = Tuple.tuple
let proj = Tuple.proj

let _ = Callback.register "tup" tup
let _ = Callback.register "proj" proj

let update = Arrays.update

let _ = Callback.register "update" update

let equal a b = Atom.eq (a,b)
let diseq a b = Atom.deq (a,b)
let lt x y = Atom.lt (x,y)
let le x y = Atom.le (x,y)
let gt a b = Atom.lt (b,a)
let ge a b = Atom.le (b,a)
let integer_pred = Atom.int
let mem = Sets.mem
let unsigned t = assert false

let _ = Callback.register "equal" equal
let _ = Callback.register "diseq" diseq
let _ = Callback.register "lt" lt
let _ = Callback.register "le" le
let _ = Callback.register "gt" gt
let _ = Callback.register "ge" ge
let _ = Callback.register "integer_pred" integer_pred
let _ = Callback.register "mem" mem
let _ = Callback.register "unsigned" unsigned


let ptrue () = Bool.tt
let pfalse () = Bool.ff
let ite = Bool.ite
	    
let _ = Callback.register "ptrue" ptrue
let _ = Callback.register "pfalse" pfalse
let _ = Callback.register "ite" ite

(* Derived term constructors for prop *)

let neg = Bool.neg
let conj = Bool.conj
let disj = Bool.disj
let xor = Bool.xor
let imp = Bool.imp
let iff = Bool.iff      

let _ = Callback.register "neg" neg
let _ = Callback.register "conj" conj
let _ = Callback.register "disj" disj
let _ = Callback.register "xor" xor
let _ = Callback.register "imp" imp
let _ = Callback.register "iff" iff

let empty_set = Sets.empty
let full_set = Sets.full
let setite a b c = Sets.ite 0 a b c

let _ = Callback.register "empty_set" empty_set
let _ = Callback.register "full_set" full_set
let _ = Callback.register "setite" setite

(* Derived term constructors for sets *)

let compl = Sets.compl
let inter = Sets.inter
let union = Sets.union
let diff = Sets.diff
let sym_diff = Sets.sym_diff (* symmetric difference *)
			  
let _ = Callback.register "compl" compl
let _ = Callback.register "inter" inter
let _ = Callback.register "union" union
let _ = Callback.register "diff" diff
let _ = Callback.register "sym_diff" sym_diff

let bv_eps = Bv.eps
let bv_zero = Bv.zero
let bv_one = Bv.one
let bv_const s = Bv.const (Bitv.from_string s)
let bv_conc (n1,b1) (n2,b2) =
  if n1 >= 0 && n2 >= 0 then
    Bv.conc2 n1 n2 b1 b2
  else
    raise (Invalid_argument "Bitvector concatenation")
    
let bv_extr (n,b) i j =
  if 0 <= i && i < j && i < n then
    Bv.sub n i j b
  else
    raise (Invalid_argument "Bitvector extraction")
    
let bv_neg  = Bv.neg
let bv_and = Bv.conj
let bv_or = Bv.disj
let bv_xor = Bv.xor
	     
let _ = Callback.register "bv_eps" bv_eps
let _ = Callback.register "bv_zero" bv_zero
let _ = Callback.register "bv_one" bv_one
let _ = Callback.register "bv_const" bv_const
let _ = Callback.register "bv_conc" bv_conc
let _ = Callback.register "bv_extr" bv_extr
let _ = Callback.register "bv_and" bv_and
let _ = Callback.register "bv_or" bv_or
let _ = Callback.register "bv_xor" bv_xor  

let fresh l = Var.fresh "c" l
let _ = Callback.register "fresh" fresh

let new_var s = Var.create s
let _ = Callback.register "new_var" new_var

let tag t = t.tag
let _ = Callback.register "tag" tag
	  
(*s Test functions. *)

let nodeify f x = f x.node

let is_var = nodeify (function Var _ -> true | _ -> false)
let is_app = nodeify (function App _ -> true | _ -> false)

let _ = Callback.register "is_var" is_var
let _ = Callback.register "is_app" is_app

let is_tup = function {node=Tuple Tup _} -> true | _ -> false
let is_proj = function {node=Tuple (Proj _)} -> true | _ -> false

let _ = Callback.register "is_tup" is_tup
let _ = Callback.register "is_proj" is_proj

let is_lookup = function {node=App _} -> true | _ -> false
let is_update = function {node=Update _} -> true | _ -> false

let _ = Callback.register "is_lookup" is_lookup
let _ = Callback.register "is_update" is_update

let propify f = function {node = Bool x } -> f x | _ -> false
 
let is_ptrue  = propify (function True -> true | _ -> false)
let is_pfalse = propify (function False -> true | _ -> false)
let is_ite    = propify (function Ite _ -> true | _ -> false)
let is_equal  = function {node=Equal _} -> true | _ -> false

let _ = Callback.register "is_ptrue" is_ptrue
let _ = Callback.register "is_pfalse" is_pfalse
let _ = Callback.register "is_ite" is_ite
let _ = Callback.register "is_equal" is_equal
	  
let setify f = function {node = Set x } -> f x | _ -> false

let is_empty_set = setify (function Empty _ -> true | _ -> false)
let is_full_set  = setify (function Full _ -> true | _ -> false)
let is_compl = 
  setify (function 
	    | SetIte (_,_,{node=Set(Empty _)},
		          {node=Set(Full _)}) -> true 
	    | _ -> false)
let is_inter = 
  setify (function SetIte (_,_,_,{node=Set(Empty _)})
	    -> true | _ -> false)
let is_union = 
  setify (function SetIte (_,_,{node=Set(Full _)},_)
	    -> true | _ -> false)
let is_setite    = setify (function SetIte _ -> true | _ -> false)

let _ = Callback.register "is_empty_set" is_empty_set
let _ = Callback.register "is_full_set" is_full_set
let _ = Callback.register "is_compl" is_compl
let _ = Callback.register "is_inter" is_inter
let _ = Callback.register "is_union" is_union
let _ = Callback.register "is_setite" is_setite
   
let is_zero x = match x.node with
  | Const b -> Bitv.all_zeros b
  | _ -> false

let is_one x = match x.node with
  | Const b -> Bitv.all_zeros b
  | _ -> false


(*s Pretty-print of terms. *)

let pp_term t =
  Pretty.term t; print_flush ()

let _ = Callback.register "pp_term" pp_term

(*s Equalities. *)

let eq_term = (==)
let compare = cmp

let _ = Callback.register "eq_term" eq_term
let _ = Callback.register "compare" compare

(*s Verbose level. *)

let set_verbose = Tools.set_verbose
let _ = Callback.register "set_verbose" set_verbose

(*s States. *)

module Tmap = Tmap

type state = State.t

let empty_state () = State.empty
let _ = Callback.register "empty_state" empty_state

let find = State.find
let _ = Callback.register "find" find

let use s x =
  let ys = State.use s x in
  Tset.fold (fun x acc -> x :: acc) ys [] 

let _ = Callback.register "use" use

let rec stream_map f = parser
  | [< 'x; s >] -> [< '(f x); stream_map f s >]
  | [< >] -> [< >]


let pp_find = State.pp_find
let _ = Callback.register "pp_find" pp_find

let pp_use = State.pp_use
let _ = Callback.register "pp_use" pp_use

let pp_universe = State.pp_universe
let _ = Callback.register "pp_universe" pp_universe

let universe = State.mem
let _ = Callback.register "universe" universe
	  

(*s Processing of new equalities. *)

type result = Dp.result

let is_consistent = function Dp.Consistent _ -> true | _ -> false
let is_redundant r = r = Dp.Valid
let is_inconsistent r = r = Dp.Inconsistent

let _ = Callback.register "is_consistent" is_consistent
let _ = Callback.register "is_redundant" is_redundant
let _ = Callback.register "is_inconsistent" is_inconsistent

let process st t = Dp.process None st t
	
let is_valid st p = 
  match process st p with
    | Dp.Valid -> true
    | _ -> false

let is_unsat st p =
  is_valid st (Bool.neg p)
	
		 
let _ = Callback.register "is_valid" is_valid
let _ = Callback.register "is_unsat" is_unsat
let _ = Callback.register "process" process     

let norm = Process.norm
let _ = Callback.register "norm" norm 

let canon = Can.can
let _ = Callback.register "canon" canon

let sigma st t = t
let solve _ = Solve.solve None

let polarity st t =
  match Sign.sign st t with
    | Sign.Nonpos -> Format.printf "Nonpos"
    | Sign.Neg -> Format.printf "Neg"
    | Sign.Zero -> Format.printf "Zero"
    | Sign.Pos -> Format.printf "Pos"
    | Sign.Nonneg -> Format.printf "Nonneg"
    | Sign.T -> Format.printf "Unconstrained"
    | Sign.F -> Format.printf "Inconsistent"

let typ st t =
  match Typ.typ st t with
    | Typ.Int -> Format.printf "Int"
    | Typ.Real -> Format.printf "Real"
    | Typ.Nonint -> Format.printf "Nonint"
    | Typ.Nonreal -> Format.printf "Nonreal"
    | Typ.T -> Format.printf "Unconstrained"
    | _ -> assert false

(*s Reset. *)

let reset () = Tools.do_at_reset ()
let _ = Callback.register "reset" reset

let gc () = Gc.full_major ()
let _ = Callback.register "gc" gc

(*s Pretty-print. *)

let flush = print_flush
let _ = Callback.register "flush" flush

(*s Imperative API. *)

type istate = {
  stack : state Stack.t;
  mutable current : state }

let empty_istate () = { stack = Stack.create (); current = empty_state () }

let current_state s = s.current

let push s = 
  Stack.push s.current s.stack

let pop s = 
  try 
    let c = Stack.pop s.stack in s.current <- c
  with Stack.Empty -> 
    s.current <- (empty_state())

let iprocess s t = 
  match process s.current t with
    | Dp.Consistent s' as r -> s.current <- s'; r
    | Dp.Valid -> Dp.Valid
    | Dp.Inconsistent -> Dp.Valid

let _ = Callback.register "empty_istate" empty_istate
let _ = Callback.register "current_state" current_state
let _ = Callback.register "push" push
let _ = Callback.register "pop" pop
let _ = Callback.register "iprocess" iprocess

(*s Callbacks for the basic Caml data structures. *)

(*s Lists. *)

let is_nil = function [] -> true | _ -> false
let cons x l = x :: l
let head = List.hd
let tail = List.tl

let _ = Callback.register "is_nil" is_nil
let _ = Callback.register "cons" cons
let _ = Callback.register "head" head
let _ = Callback.register "tail" tail

(*s Pairs. *)

let pair x y = (x,y)
let fst = fst
let snd = snd

let _ = Callback.register "pair" pair
let _ = Callback.register "fst" fst
let _ = Callback.register "snd" snd

(*s Multi-precision arithmetic.*)

open Mpa

type q = Q.t

let num_of_int = Q.of_int
let string_of_num = Q.to_string
let num_of_string = Q.of_string

let _ = Callback.register "num_of_int" num_of_int
let _ = Callback.register "string_of_num" string_of_num
let _ = Callback.register "num_of_string" num_of_string
