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
 *)


(** Sets of equalities and disequalities over variables.
  See also modules {!V.t} and {!D.t}. *)

type t = {
  mutable v : V.t;              (* Variable equalities. *)
  mutable d : D.t               (* Variables disequalities. *)
}

let v_of p = p.v
let d_of p = p.d


(** Empty partition. *)
let empty = {v = V.empty; d = D.empty}

(** Pretty-printing *)
let pp fmt p =
  V.pp fmt p.v;
  D.pp fmt p.d

(** Test if states are unchanged. *)
let eq p q = 
  V.eq p.v q.v && D.eq p.d q.d


(** Choose in equivalence class. *)

let choose p apply y = 
  let rhs x = try Some(apply x) with Not_found -> None in
    V.choose p.v rhs y

let iter_if p f y =
  let f' x = try f x with Not_found -> () in
    V.iter p.v f y
  

(** Canonical variables module [p]. *)
let find p = V.find p.v


(** All disequalities of some variable [x]. *)
let diseqs p x =
  let (y, rho) = find p x in                   (* [rho |- x = y] *)
  let ds = D.diseqs p.d y in
    if Term.eq x y then ds else
      D.Set.fold 
	(fun (z, tau) ->                       (* [tau |- y <> z] *)
	   let sigma = Justification.subst_diseq (x, z) tau [rho] in
	     D.Set.add (z, sigma))
	ds D.Set.empty


(** Abstract domain interpretation *)
let dom p a =
  let hyps = ref [] in
  let rec of_term a =
    match a with
      | Term.Var _ -> 
	  of_var a
      | Term.App(f, al) ->
	  (match f with 
	     | Sym.Arith(op) -> Arith.dom of_term op al
             | Sym.Pp(op) ->  Pprod.dom of_term op al
	     | _ -> raise Not_found)
  and of_var x =
     let (y, rho) = find p x in
     let d = Term.Var.dom_of y in
       if not(x == y) then hyps := rho :: !hyps;
       d
  in
  let d = of_term a in
  let rho = Justification.dependencies !hyps in
    (d, rho)



(** {6 Predicates} *)

(** Apply the equality test on canonical variables. *)
let is_equal p = 
  Justification.Pred2.apply 
    (find p) 
    (V.is_equal p.v)


(** Apply the equality test on canonical variables. *)
let is_diseq p = 
  Justification.Pred2.apply 
    (find p) 
    (D.is_diseq p.d)


(** Test for equality or disequality of canonical variables. *)
let is_equal_or_diseq p =
  Justification.Rel2.apply
    (find p)
    (Justification.Rel2.of_preds
       (V.is_equal p.v)            (* positive test *)
       (D.is_diseq p.d))           (* negative test *)


(** Test whether [x] is known to be in domain [d] by looking up
  the domain of the corresponding canonical variable [x']. The
  variable ordering ensures that [x'] is 'more constraint' than [x]. *)
let is_in p d x = 
  let (x', rho') = find p x in
    try
      let d' = Term.Var.dom_of x in
	if Dom.sub d d' then
	  Justification.Three.Yes(rho')
	else if Dom.disjoint d d' then
	  Justification.Three.No(rho')
	else 
	  Justification.Three.X
    with
	Not_found -> 
	  Justification.Three.X



(** {6 Updates} *)

(** Shallow copy for protecting against destructive 
  updates in [merge], [diseq], and [gc]. *)
let copy p = {v = p.v; d = p.d}


(** Merge a variable equality. *)
let merge p e =  
  Trace.msg "p" "Merge(p)" e Fact.Equal.pp;
  p.v <- V.merge e p.v;
  p.d <- D.merge e p.d


(** Add a disequality of the form [x <> y]. *)
let dismerge p d =  
  Trace.msg "p" "Dismerge(p)" d Fact.Diseq.pp;
  let d' = Fact.Diseq.map (find p) d in
  let (x', y', rho') = Fact.Diseq.destruct d' in
    if Term.eq x' y' then
      raise(Justification.Inconsistent(rho'))
    else 
      p.d <- D.add d' p.d
 


(** {6 Garbage collection} *)

(** Garbage collection of noncanonical variables satisfying [f]. Since variable
  disequalities and constraints are always in canonical form, only variable equalities
  need to be considered. *)
let gc f p = 
  let v' = V.gc f p.v in
    p.v <- v'


(** {6 Canonical forms} *)
 
(** Sigma normal forms for individual theories. These are largely independent
 of the current state, except for sigma-normal forms for arrays, which use
 variable equalities and disequalities. *)
let rec sigma p sym l = 
  match sym with
    | Sym.Arrays(op) ->
	let rhos = ref [] in
	let is_equal' = Justification.Three.to_three rhos (is_equal_or_diseq p) in
	let b = Funarr.sigma is_equal' op l in
	let rho = Justification.sigma ((sym, l), b) !rhos in
	  (b, rho)
    | _ ->
	let b = sigma0 sym l in
	let rho =  Justification.sigma ((sym, l), b) [] in
	  (b, rho)
	  
and sigma0 f =
  match f with
    | Sym.Arith(op) -> Arith.sigma op
    | Sym.Pair(op) -> Product.sigma op
    | Sym.Bv(op) -> Bitvector.sigma op
    | Sym.Coproduct(op) -> Coproduct.sigma op
    | Sym.Fun(op) -> Apply.sigma op
    | Sym.Pp(op) -> Pprod.sigma op
    | Sym.Arrays(op) -> Funarr.sigma Term.is_equal op
    | Sym.Uninterp _ -> Term.App.mk_app f



