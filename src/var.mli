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

(** Abstract datatype for variables.

  @author Harald Ruess

 The set of all variables is partitioned into 
  - {b external}, 
  - {b internal}, and 
  - {b bound} variables.

 External variables consist of a name and a domain construction. 

  Internal variables are generated by the system, and we distinguish
  between two different kinds of internal variables
  - {b rename} variables for abstracting terms.
  - {b slack} variables generated by the linear arithmetic module {!La.t}
  for expressing nonnegativity and zero constraints.

  Finally, bound variables are used for quantification. They are realized
  as deBruijn indices.
  
  There is a name of type {!Name.t} associated with each variable. Names for 
  rename and fresh variables are always of the form ["x!i"], where [x] is an 
  arbitrary string and [i] is an integer string. The name associated 
  with a free variable is of the form ["!i"] for an integer [i].
*)


(** Variable constraints. *)
module Cnstrnt : sig
  type t =
    | Unconstrained
    | Real of Dom.t
    | Bitvector of int

  val mk_real : Dom.t -> t
  val mk_bitvector : int -> t

  val pp : t Pretty.printer

  exception Empty

  val sub : t -> t -> bool

  val inter : t -> t -> t

end 


type t
  (** Representation type for variables. *)
    

(** {6 Destructors} *)

val name_of : t -> Name.t
  (** [name_of x] returns the name associated with a variable [x]. *)

val cnstrnt_of : t -> Cnstrnt.t
  (** [cnstrnt_of x] returns the domain constraint of variable [x].
    Raises [Not_found] is interpretation for the variable is unconstrained. *)

val dom_of : t -> Dom.t
  (** [dom_of x] returns the domain of interpretation of variable [x],
    and raises [Not_found] if this domain is "unrestricted". *)

val width_of : t -> int
  (** [width_of x] returns the length [n]  of variable [x]
    with a bitvector interpretation,  and raises [Not_found] otherwise. *)


(** {6 Comparisons} *)

val cmp : t -> t -> int
  (** [cmp x y] realizes a total ordering on variables. The result is [0]
    if [eq x y] holds, it is less than [0] we say, '[x] is less than [y]',
    and, otherwise, '[x] is greater than [y]'. An slack variable [x] is always
    less than a rename variable [y]. Otherwise, the outcome of [cmp x y] is 
    unspecified. *)

val (<<<) : t -> t -> bool
  (** [x <<< y] holds iff [cmp x y <= 0]. *)


(** {6 Constructors} *)


val mk_external : Name.t -> Cnstrnt.t -> t
  (** [mk_external n d] creates an external variable with associated name [n]
    and optional domain constraint [d]. *)


val mk_rename : Name.t -> int -> Cnstrnt.t -> t
  (** [mk_rename n d] constructs a rename variable with associated 
    name ["n!i"] and optional domain constraint. *)


type slack = Zero | Nonneg of Dom.t

val nonneg : Dom.t -> slack
  (** [nonneg d] constructs [Nonneg(d)]. *)

val mk_slack : int -> slack -> t
  (** - [mk_slack i Zero] creates a  {i zero slack} variable with [0]
    as the only possible interpretation.
    - [mk_slack i Nonneg(d)] creates a  {i nonnegative slack} variable 
    the possible interpretations in the subset [{q in D | q >= 0}]
    of the reals, where [D] the interpretation set of [d] according 
    to {!Dom.t}. *)

val mk_fresh : Th.t -> int -> Cnstrnt.t -> t
  (** [mk_fresh th i d] creates a {i fresh} variable associated with
    theory [i] and optional domain [d]. These variables are typically
    generated by theory-specific solvers. *)

(** {6 Recognizers} *)

val is_var : t -> bool
  (** [is_var x] holds iff [x] is an external variable, that is,
    it has been returned by a call to [mk_external]. *)
  
val is_rename : t -> bool
  (** [is_rename x] holds iff [x] is a rename variable. *)

val is_slack : slack -> t -> bool
  (** [is_cnstrnt x] holds iff [x] is a slack variable. *)

val is_zero_slack : t -> bool
  (** [is_zero_slack x] holds iff [x] is a zero slack variable. *)

val is_nonneg_slack : t -> bool
  (** [is_zero_slack x] holds iff [x] is a nonnegative slack variable. *)

val is_fresh : Th.t -> t -> bool
  (** [is_fresh i x] holds iff [x] is a fresh variable of theory [i]. *)

val is_some_fresh : t -> bool

val is_internal : t -> bool
  (** [is_internal x] holds iff either [is_rename x], [is_slack x], or
    [is_fresh x] holds. *)


(** Interpretation domains *)

val is_real : t -> bool
  (** [is_real x] holds iff [x] is constraint over the reals. *)

val is_int : t -> bool
  (** [is_int x] holds iff [x] is constraint over the integers. *)


(** {6 Destructors} *)

val d_external : t -> Name.t * Cnstrnt.t


(** {6 Printing} *)

val pretty : bool ref

val pp : t Pretty.printer
  (** Pretty-printer for variables. If {!Var.pretty} is set to true, then
    printing of domain restrictions is suppressed. *)
