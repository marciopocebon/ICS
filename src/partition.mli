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


(** A {b partition} consists of a
    - set of variable equalities [x = y], 
    - a set of variable disequalities [x <> y], and
    - a set of variable constraints [x in i],
  where [i] is an arithmetic constraint of type {!Cnstrnt.t}.

  @author Harald Ruess
*)

type t
  (** Type [t] for representing a partitioning. *)


(** {6 Accessors} *)

val v_of : t -> V.t
val d_of : t -> D.t
val c_of : t -> C.t

val v : t -> Term.t -> Term.t
  (** [v s x] returns the canonical representative of the equivalence
    class in the partitioning [s] containing the variable [x]. *)

val c : t -> Term.t -> Cnstrnt.t
  (** [c s x] returns, for a canonical variable [x], an associatiatede
    arithmetic constraint, if there is one. Otherwise, [Not_found] is
    raised. *)


val deq : t -> Term.t -> Term.Set.t
  (** [deq s x] returns the set of all variable [y] disequal to [x] as stored
    in the variable disequality part [d] of the partitioning [s].  Disequalities as
    obtained from the constraint part [c] are not necessarily included. *)

val equality : t -> Term.t -> Fact.equal

val disequalities : t -> Term.t -> Fact.diseq list

val cnstrnt : t -> Term.t -> Fact.cnstrnt


(** {6 Destructive Updates} *)

val update_v : t -> V.t -> t
  (** [update_v s v] updates the [v] part of the partitioning [s] if it
    is different from [s.v]. *)

val update_d : t -> D.t -> t
val update_c : t -> C.t -> t

val copy : t -> t
  (** [copy p] does a shallow copying of [p]. Should be called before
    calling any of the above update functions to protect [p] from
    destructive updates. *)


(** {6 Recognizers} *)

val is_equal : t -> Term.t -> Term.t -> Three.t
  (** [is_equal s x y] for variables [x], [y] returns [Three.Yes] if [x] and
    [y] belong to the same equivalence class modulo [s], that is, if [v s x]
    and [v s y] are equal. The result is [Three.No] if [x] is in [deq y],
    [y] is in [deq x], or [x in i] and [y in j] are constraints in [s] and [i],
    [j] are disjoint. Otherwise, [Three.X] is returned. *)
 

val is_int : t -> Term.t -> bool
  (** [is_int s a] tests if the constraint [cnstrnt s a] is included in [Cnstrnt.mk_int]. *)


(** {6 Pretty-printing} *)
  
val pp : t Pretty.printer


(** {6 Constructors} *)

val empty : t
  (** The [empty] partition. *)

val merge : Fact.equal -> t -> t
  (** [merge e s] adds a new variable equality [e] of the form [x = y] into
    the partition [s]. If [x] is already equal to [y] modulo [s], then [s]
    is unchanged; if [x] and [y] are disequal, then the exception [Exc.Inconsistent]
    is raised; otherwise, the equality [x = y] is added to [s] to obtain [s'] such
    that [v s' x] is identical to [v s' y]. *)

val restrict : Term.Set.t -> t -> t
  (** [remove s] removes all internal variables which are not canonical. *)


val add : Fact.cnstrnt -> t -> t
  (** [add c s] adds a constraint of the form [x in i] to the constraint part [c]
    of the partition [s]. May raise [Exc.Inconsistent] if the resulting constraint
    for [x] is the empty constraint (see [C.add]). *)
 
val diseq : Fact.diseq -> t -> t
  (** [diseq d s] adds a disequality of the form [x <> y] to [s]. If [x = y] is
    already known in [s], that is, if [is_equal s x y] yields [Three.Yes], then
    an exception [Exc.Inconsistent] is raised; if [is_equal s x y] equals [Three.No]
    the result is unchanged; otherwise, [x <> y] is added using [D.add]. *)


val eq : t -> t -> bool
  (** [eq s t] holds if the respective equality, disequality, and constraint parts
    are identical, that is, stored in the same memory location. *)


(** Management of changed variables. *)

module Changed : sig

  val reset : unit -> unit
  val save : unit -> Term.Set.t * Term.Set.t * Term.Set.t
  val restore : Term.Set.t * Term.Set.t * Term.Set.t -> unit
  val stable : unit -> bool

end
