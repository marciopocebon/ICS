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

(** Propositional logic

  @author Harald Ruess

  Propositional is just defined in terms of bitwise operations
  on bitvectors of width [1].  This module provides the
  corresponding definitions. 
*)
 
val mk_true : Term.t
val mk_false : Term.t

val is_true : Term.t -> bool
val is_false : Term.t -> bool

val mk_conj : Term.t -> Term.t -> Term.t
val mk_disj : Term.t -> Term.t -> Term.t
val mk_xor : Term.t -> Term.t -> Term.t
val mk_neg : Term.t -> Term.t
