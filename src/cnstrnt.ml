
(*i
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
 i*)

(*i*)
open Mpa         
(*i*)

(*s Set of rational numbers. *)

module Diseqs = Set.Make(
  struct
    type t = Q.t
    let compare = Q.compare
  end)


(*s A constraint consists an interval and a set of rational numbers. *)

type t = Interval.t * Diseqs.t

let destruct c = c

let eq (i, qs) (j, ps) = 
  Interval.eq i j && Diseqs.equal qs ps

let dom_of (i,_) =
  let (d,_,_) = Interval.destructure i in
  d


(*s Empty constraint. *)

let mk_empty = (Interval.mk_empty, Diseqs.empty)

let is_empty (i,_) = Interval.is_empty i

let is_full (i,qs) = 
  Interval.is_full i && Diseqs.is_empty qs

(*s Membership. *)

let mem q (i,qs) =
  Interval.mem q i && not(Diseqs.mem q qs)


(*s Constructing a constraint from components *)

let of_interval i = (i, Diseqs.empty)

exception Found of Mpa.Q.t

let rec make (i, qs) =
  if Interval.is_empty i then
    mk_empty
  else if Diseqs.is_empty qs then
    (i, Diseqs.empty)
  else 
    let (d, lo, hi) = Interval.destructure i in
    if d = Dom.Int then
      let (a, alpha) = Endpoint.destruct lo in
      match alpha, endpoint a qs with
	| true, Some(p) -> 
	    let i' = Interval.make (Dom.Int, Endpoint.make (a,false), hi) in
	    make (i', Diseqs.remove p qs)
	| _ ->
	    let (b, beta) = Endpoint.destruct hi in
	    match beta, endpoint b qs with
	      | true, Some(p) ->
		  let i' = Interval.make (Dom.Int, lo, Endpoint.make (b,false)) in
		  make (i', Diseqs.remove p qs)
	      | _ ->
		  normalize (i, qs)
    else
      normalize (i, qs)

and endpoint a qs =
  match Extq.to_q a with
    | None -> None
    | Some(q) -> 
	try
	  Diseqs.iter
	    (fun p -> 
	       if Mpa.Q.equal q p then raise (Found p))
	    qs;
	  None
	with
	    Found(p) -> Some(p)

and normalize (i, qs) = 
  let qs' = Diseqs.filter (fun q -> Interval.mem q i) qs in
  (i, qs')
      


(*s Constraint for the real number line, the integers, and the
 natural numbers. *)

let mk_real = 
  of_interval Interval.mk_real

let mk_int = 
  of_interval Interval.mk_int

let mk_nat = 
  let i = Interval.make (Dom.Int, Endpoint.nonstrict Q.zero, Endpoint.posinf) in
  of_interval i

(*s Constructing singleton constraints. *)

let mk_singleton q = 
  of_interval (Interval.mk_singleton q)

let d_singleton (i,qs) =
  match Interval.d_singleton i with
    | Some(q) -> 
	assert(Diseqs.is_empty qs);
	Some(q)
    | None ->
	None
	

let mk_zero = mk_singleton Mpa.Q.zero
let mk_one = mk_singleton Mpa.Q.one


(*s Disequality constraint. *)

let mk_diseq q = (Interval.mk_real, Diseqs.singleton q)


(*s Checks wether [c] is a subconstraint of [d]. *)

let sub (i,qs) (j,ps) =
  Interval.sub i j &&
  Diseqs.subset ps qs
  

(*s Intersection of two constraints *)

let inter (i,qs) (j,ps) =
  make (Interval.inter i j, Diseqs.union qs ps)


(*s Comparison. *)

let rec cmp c d =
  let (i,qs) = destruct c in
  let (j,ps) = destruct d in
  match Interval.cmp i j with 
    | Binrel.Disjoint -> 
	Binrel.Disjoint
    | Binrel.Overlap(k) -> 
	analyze (make (k, Diseqs.union qs ps))
    | Binrel.Same when Diseqs.equal qs ps -> 
	Binrel.Same
    | Binrel.Same when Diseqs.subset qs ps -> 
	Binrel.Super
    | Binrel.Same when Diseqs.subset ps qs -> 
	Binrel.Sub
    | Binrel.Same -> 
	analyze (make (i, Diseqs.union qs ps))
    | Binrel.Singleton(q) when Diseqs.mem q qs || Diseqs.mem q ps -> 
	Binrel.Disjoint
    | Binrel.Singleton(q) ->
	Binrel.Singleton(q)
    | Binrel.Sub when Diseqs.subset ps qs ->
	Binrel.Sub
    | Binrel.Sub -> 
	analyze (make (i, Diseqs.union qs ps))
    | Binrel.Super when Diseqs.subset qs ps ->
	Binrel.Super
    | Binrel.Super ->
	analyze (make (j, Diseqs.union qs ps))

and analyze c =
  if is_empty c then
    Binrel.Disjoint
  else 
    match d_singleton c with
      | Some(q) -> Binrel.Singleton(q)
      | None -> Binrel.Overlap(c)

(*s Status. *)

let status c =
  if is_empty c then
    Status.Empty
  else 
    match d_singleton c with
      | Some(q) -> Status.Singleton(q)
      | None -> Status.Other


(*s Printing constraints. *)

let pp fmt c =
  let (i,qs) = destruct c in
  Format.fprintf fmt "@[";
  Interval.pp fmt i;
  if not(Diseqs.is_empty qs) then
    begin
      Format.fprintf fmt "\\";
      Pretty.set Mpa.Q.pp fmt (Diseqs.elements qs)
    end


(*s Additional constructors. *)

let of_endpoints (dom, lo, hi) = 
  of_interval (Interval.make (dom, lo, hi))

let mk_oo dom u v = of_endpoints (dom, Endpoint.strict u, Endpoint.strict v)
let mk_oc dom u v = of_endpoints (dom, Endpoint.strict u, Endpoint.nonstrict v)
let mk_co dom u v = of_endpoints (dom, Endpoint.nonstrict u, Endpoint.strict v)
let mk_cc dom u v = of_endpoints (dom, Endpoint.nonstrict u, Endpoint.nonstrict v)

let mk_lt dom u = of_endpoints (dom, Endpoint.neginf, Endpoint.strict u)
let mk_le dom u = of_endpoints (dom, Endpoint.neginf, Endpoint.nonstrict u)
let mk_gt dom u = of_endpoints (dom, Endpoint.strict u, Endpoint.posinf)
let mk_ge dom u = of_endpoints (dom, Endpoint.nonstrict u, Endpoint.posinf)

let mk_neg dom = mk_lt dom Q.zero
let mk_pos dom = mk_gt dom Q.zero
let mk_nonneg dom = mk_ge dom Q.zero
let mk_nonpos dom = mk_le dom Q.zero


(*s Abstract interpretation. *)

let addq q (j, ps) = 
  let i = Interval.mk_singleton q in
  let j' = Interval.add i j in
  let ps' = Diseqs.fold (fun p -> Diseqs.add (Q.add q p)) ps Diseqs.empty in
  make (j', ps')

let add (i,_) (j,_) = 
  of_interval (Interval.add i j)

let subtract (i,_) (j,_) =
  of_interval (Interval.subtract i j)

let rec addl = function
  | [] -> mk_singleton Q.zero
  | [c] -> c
  | c :: cl -> add c (addl cl)

let multq q (i,qs) =
  let j' = Interval.multq q i in
  let qs' = Diseqs.fold (fun p -> Diseqs.add (Mpa.Q.mult q p)) qs Diseqs.empty in
  make (j', qs')

let mult (i,_) (j,_) =
  of_interval (Interval.mult i j)


let rec multl = function
  | [] -> mk_singleton Q.one
  | [c] -> c
  | c :: cl -> mult c (multl cl)

let expt n (i,_) =
  of_interval (Interval.expt n i)

let div (i,_) (j,_) =
  of_interval (Interval.div i j)
