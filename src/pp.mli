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

(** Module [Pp]: Theory of power products.

  Power products are of th form [x1^n1 * ... * xk^nk], 
  where [xi^ni] represents the variable [xi] raised to the [n], 
  where [n] is any integer, positive or negative, except for [0],
  and [*] is nary multiplication; in addition [xi^1] is reduced
  to [xi], [x1,...,xn] are ordered from left-to-right such that
  [Term.cmp xi xj < 0] (see {!Term.cmp}) for [i < j]. In particular, 
  every [xi] occurs only one in a power product.
*)

(** {Symbols.} *)

val mult : Sym.t
val expt : int -> Sym.t

(** {Ordering.} *)

val cmp : Term.t -> Term.t -> int
(** Total ordering on power products. Let [pp] be of the form
  [x1^n1*...*xk^nk] and [qq] of the form [y1^m1*...*yl^ml] then
  [cmp pp qq] is [0] iff [k = l], [Term.eq xi yi], and [ni = mi]. *)

val min : Term.t -> Term.t -> Term.t

val max : Term.t -> Term.t -> Term.t


val is_interp : Term.t -> bool
(** [is_interp a] holds iff [a] is of the form described above. *)


(** {Constructors.} *)

val mk_one : Term.t
(** Power product for representing the number [1]. This is different      
    from different form {!Arith.mk_one}. *)


val mk_mult : Term.t -> Term.t -> Term.t
(** [mk_mult pp qq] multiplies the power products [pp] and [qq] to
 obtain a new power product. *)


val mk_multl : Term.t list -> Term.t
(** [mk_multl [a0;...;an]] iterates the binary constructor [mk_mult] above
 to [mk_mult a1 [mk_multl [a1;...;an]]]  with [mk_multl []] equal to [mk_one]. *)


val mk_expt : int -> Term.t -> Term.t
(** [mk_expt n pp] constructs a power product for representing the 
 power product [pp] raised to the integer exponent [n]. *)


(** {Recognizers.} *)

val is_one : Term.t -> bool
(** [is_one a] holds if [a] is syntactically equal to [mk_one]. *)


val sigma : Sym.pprod -> Term.t list -> Term.t

val map: (Term.t -> Term.t) -> Term.t -> Term.t


(** {Constraints.} *)


val tau : (Term.t -> Cnstrnt.t) -> Sym.pprod -> Term.t list -> Cnstrnt.t
(** Abstract interpretation in the domain of constraints. Given 
 a context [f], which associates uninterpreted subterms of [a]
 with constraints, [cnstrnt f a] recurses over the interpreted
 structure of [a] and accumulates constraints by calling [f] at
 uninterpreted positions and abstractly interpreting the 
 interpreted arithmetic operators in the domain of constraints. *)



val gcd : Term.t -> Term.t -> Term.t * Term.t * Term.t
(** [gcd pp qq] computes the greatest common divisor of the power products
  [pp] and [qq]. It returns a triple of power products [(p, q, g)] 
  such that [g] divides both [pp] and [qq], it is the largest such [g],
  and [mk_mult p pp] and [mk_mult q qq] are equal to [g].  *)


val lcm : Term.t * Term.t -> Term.t * Term.t * Term.t
(** Least common multiple [lcm pp qq] yields [(p, q, lcm)] such that
 [p * lcm = pp], [q * lcm = qq], and [lcm] is the smallest such
 power product. *)

val div : Term.t * Term.t -> Term.t option
(** Divisibility test [div pp qq] returns largest [Some(mm)] such that
  [pp * mm = qq] and [None] if no such [mm] exists. *)


val split : Term.t -> Term.t * Term.t
(** [split pp] splits a power product [pp] into a pair [(nn, dd)] of
 a numerator [nn] and a denumerator [dd], such that [pp] equals
 [mk_div nn dd]. *)

val numerator : Term.t -> Term.t
val denumerator : Term.t -> Term.t

val destruct : Term.t -> Term.t * int

