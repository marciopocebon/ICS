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

open Mpa
open Format
open Sym


type t =
  | Var of Var.t
  | App of Sym.t * t list
 
let rec eq a b = 
  match a, b with
    | Var(x), Var(y) -> 
	Var.eq x y
    | App(f,l), App(g,m) -> 
	Sym.eq f g && eql l m
    | _ ->
	false

and eql al bl =
  try List.for_all2 eq al bl with Invalid_argument _ -> false


let mk_var x = Var(Var.mk_var x)

let mk_const f = App(f,[])
let mk_app f l = App(f,l)

let mk_fresh_var x k = Var(Var.mk_fresh x k)

let is_fresh_var = function
  | Var(x) -> Var.is_fresh x
  | _ -> false


let is_var = function Var _ -> true | _ -> false
let is_app = function App _ -> true | _ -> false
let is_const = function App(_,[]) -> true | _ -> false


let to_var = function
  | Var(x) -> x
  | _ -> assert false

let name_of a =
  assert(is_var a);
  match a with Var(x) -> Var.name_of x | _ -> assert false

let destruct a =
  assert(is_app a);
  match a with App(f,l) -> (f,l) | _ -> assert false

let sym_of a = 
  assert(is_app a);
  match a with App(f,_) -> f | _ -> assert false

let args_of a = 
  assert(is_app a);
  match a with App(_,l) -> l | _ -> assert false


let rec cmp a b =
  match a, b with
    | Var _, App _ -> 1
    | App _, Var _ -> -1
    | Var(x), Var(y) -> Var.cmp x y
    | App(f, l), App(g, m) ->
	let c1 = Sym.cmp f g in
	if c1 != 0 then c1 else cmpl l m
 
and cmpl l m =
  let rec loop c l m =
    match l, m with
      | [], [] -> c
      | [], _  -> -1
      | _,  [] -> 1
      | x:: xl, y:: yl -> 
	  if c != 0 then loop c xl yl else loop (cmp x y) xl yl
  in
  loop 0 l m


let (<<<) a b = (cmp a b <= 0)


let orient ((a, b) as e) =
  if cmp a b >= 0 then e else (b, a)

let min a b =
  if a <<< b then a else b

let max a b = 
  if a <<< b then b else a


(** Some recognizers. *)

let is_interp_const = function
  | App((Arith _ | Bv _ | Product _), []) -> true
  | _ -> false
   
let is_interp = function
  | App((Arith _ | Bv _ | Product _), _) -> true
  | _ -> false

let is_uninterpreted = function
  | App(Uninterp _, _) -> true
  | _ -> false


let is_equal a b =
  if eq a b then
    Three.Yes
  else match a, b with                         (* constants from within a theory are *)
    | App((Arith _ as c), []), App((Arith _ as d), []) (* assumed to interpreted differently *)
	when not(Sym.eq c d) -> Three.No
    | App((Bv _ as c), []), App((Bv _ as d), [])
	when not(Sym.eq c d) -> Three.No
    | _ ->
	Three.X


(** Mapping over list of terms. Avoids unnecessary consing. *)
let rec mapl f l =
  match l with
    | [] -> []
    | a :: l1 ->
	let a' = f a and l1' = mapl f l1 in
	if eq a' a && l1 == l1' then l else a' :: l1'


(** Association lists for terms. *)   
let rec assq a = function
  | [] -> raise Not_found
  | (x,y) :: xl -> if eq a x then y else assq a xl


(** Iteration over terms. *)
let rec fold f a acc =
  match a with
    | Var _ -> f a acc
    | App(_, l) -> f a (List.fold_right (fold f) l acc)

let rec iter f a  =
  f a; 
  if is_app a then
    List.iter (iter f) (args_of a)

let rec for_all p a  =
  p a && 
  match a with
    | Var _ -> true
    | App(_, l) -> List.for_all (for_all p) l


let rec subterm a b  =
  eq a b ||
  match b with
    | Var _ -> false
    | App(_, l) -> List.exists (subterm a) (args_of b)

let occurs x b = subterm x b


(** {6 Pretty-Printing} *)

let pretty = ref true  (* Infix/Mixfix output when [pretty] is true. *)

let rec pp fmt a =
  let str = Pretty.string fmt in
  let term = pp fmt in
  let args =  Pretty.tuple pp fmt in
  let app f l = Sym.pp fmt f; Pretty.tuple pp fmt l in
  let infixl x = Pretty.infixl pp x fmt in
  match a with
    | Var(x) -> Var.pp fmt x
    | App(f, l) when not(!pretty) -> app f l
    | App(f, l) ->
	(match f, l with
	   | Arith(Num q), [] -> 
	       Mpa.Q.pp fmt q
	   | Arith(Add), _ -> 
	       infixl " + " l
	   | Arith(Multq(q)) , [x] -> 
	       Pretty.infix Mpa.Q.pp "*" pp fmt (q, x)  
	   | Product(Proj(0, 2)), [App(Coproduct(OutR), [x])] ->
	       str "hd"; str "("; term x; str ")"
	   | Product(Proj(1, 2)), [App(Coproduct(OutR), [x])] ->
	       str "tl"; str "("; term x; str ")"
	   | Product(Proj(0,2)), [_] -> 
	       str "car"; args l
	   | Product(Proj(1,2)), [_] -> 
	       str "cdr"; args l
	   | Product(Tuple), [_; _] -> 
	       str "cons"; args l
	   | Pp(Mult), [] ->
	       str "1"
	   | Pp(Mult), xl ->
	       infixl "*" xl
	   | Pp(Expt _), [x] ->
	       term x; Sym.pp fmt f
	   | Bv(Const(b)), [] -> 
	       str ("0b" ^ Bitv.to_string b)
	   | Bv(Conc _), l -> 
	       infixl " ++ " l
	   | Bv(Sub(_,i,j)), [x] ->
	       term x; Format.fprintf fmt "[%d:%d]" i j
	   | Coproduct(InL), [App(Product(Tuple), [x; xl])] ->
	       Pretty.infix pp "::" pp fmt (x, xl)
	   | Coproduct(InR), [App(Product(Tuple), [])] ->
	       str "[]"
	   | Arrays(Update), [x;y;z] ->
	       term x; str "["; term y; str " := "; term z; str "]"
	   | Arrays(Select), [x; y] ->
	       term x; str "["; term y; str "]"
	   | _ -> 
	       app f l)

let to_string = 
  Pretty.to_string pp


(** Pretty-printing of equalities/disequalities/constraints. *)

let pp_equal fmt (x,y) = 
  Pretty.infix pp "=" pp fmt (x,y)

let pp_diseq fmt (x,y) = 
  Pretty.infix pp "<>" pp fmt (x,y)

let pp_in fmt (x,c) = 
  Pretty.infix pp "in" Cnstrnt.pp fmt (x,c)


(** {6 Sets and maps of terms.} *)

type trm = t  (* avoid type-check error below *)

module Set = Set.Make(
  struct
    type t = trm
    let compare = cmp
  end)

module Map = Map.Make(
  struct
    type t = trm
    let compare = cmp
  end)


(** Set of variables. *)
let rec vars_of a = 
  match a with
    | Var _ -> 
	Set.singleton a
    | App(_, al) ->
	List.fold_left 
	  (fun acc b ->
	     Set.union (vars_of b) acc)
	  Set.empty
	al
