(* 
 * The MIT License (MIT)
 *
 * Copyright (c) 2020 SRI International
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *)

(** {i ICS inference system for the combination of theories}

    This module provides incremental online processing of propositional
    constraints in the combination of the theories of

    - linear rational arithmetic,
    - equality over uninterpreted functions (see module {!Cc}),
    - tuples (see module {!Tuple}), and
    - functional arrays (see module {!Funarr}).

    Propositional constraints are added to the {i current logical context}
    by updating the {i current configuration} until either a contradiction
    is detected or no more ICS inference rules are applicable. In the latter
    case, the conjunction of the processed constraint with the
    {i current logical context} is satisfiable.

    @author Harald Ruess *)

(** Names of component theories.

    - {!Ics.U}: equality over uninterpreted functions,
    - {!Ics.A}: rational linear arithmetic,
    - {!Ics.T}: tuples and projections,
    - {!Ics.F}: functional arrays. *)
type theory = U | A | T | F

(** {9 Terms} *)

(** {i Term variables.} Variables are partitioned into {i external} and
    {i internal} variables.

    An external variable [x] has a string [s] associated with it, whereas
    internal variables are indices that are usually generated by applying
    the ICS inference system.

    An internal variable is {i fresh} if its index is below a certain,
    configuration-dependant threshhold. *)
module Var : sig
  (** Representation of term variables. *)
  type t

  val is_internal : t -> bool
  (** [is_internal x] holds iff [x] is an internal variable. *)

  val is_external : t -> bool
  (** [is_external x] holds iff [x] is an external variable. *)

  val is_fresh : t -> bool
  (** [is_fresh x] holds iff [x] is a fresh variable with respect to the
      current configuration. In particular, such a fresh variable does not
      occur in the current configuration. *)

  val of_string : string -> t
  (** [of_string str] creates a representation of a term variable with name
      [str]. *)

  val of_name : Name.t -> t
  val internal : int -> t

  val to_string : t -> string
  (** [to_string x] returns the unique name associated with variable [x].
      [to_string x] is bijective with {!of_string} the inverse. *)

  val equal : t -> t -> bool
  (** [equal x y] holds iff the names associated with [x] and [y] are equal;
      that is, [to_string x = to_string y]; The [equal] equality test is
      constant time. *)

  val compare : t -> t -> int
  (** [compare x y] returns [0] iff [equal x y] holds; furthermore,
      [compare x y > 0] iff [compare x y < 0]. In particular, {!compare}
      does not necessarily respect the natural ordering on names of
      variables! Also, the order might change between different runs of ICS. *)

  val hash : t -> int
  (** {!hash} returns a nonnegative hash value. *)

  val pp : Format.formatter -> t -> unit
  (** [pp fmt x] pretty-prints variable [x] on formatter [fmt]. *)

  val fresh : unit -> t
  (** Create a fresh variable (with respect to the current context). Note
      that such a variable might not be fresh with respect to other
      contexts. *)
end

(** {i Set of variables.} *)
module Vars : Sets.S with type elt = Var.t

(** {i Uninterpreted function symbols}. The {i arity} of all function
    symbols is [1], since multiple arguments in term applications are
    represented using tuples of type [Ics.Term.Tuple.t]. *)
module Funsym : sig
  (** Representation of an uninterpreted function symbol. *)
  type t

  val of_string : string -> t
  (** [of_string s] creates an uninterpreted function symbol with name [s]. *)

  val to_string : t -> string
  (** [to_string f] returns the name associated with a function symbol [f]. *)

  val equal : t -> t -> bool
  (** The equality test [equal f g] holds iff the associated names
      [to_string f] and [to_string g] are equal. Unlike equality on string,
      the equality test on function symbols is constant time. *)

  val compare : t -> t -> int
  (** [compare f g] returns [0] iff [equal f g] holds; furthermore,
      [compare f g > 0] iff [compare f g < 0]. In particular, {!compare}
      does not necessarily respect the natural ordering on names of function
      symbols. Also, the order might change between different runs of ICS. *)

  val hash : t -> int
  (** Nonnegative hash value for a function symbol. *)

  val pp : Format.formatter -> t -> unit
  (** [pp fmt f] prints the name associated with function symbol [f] onto
      the formatting string [fmt]. *)
end

(** {i Terms}. A {i term} is either

    - a {i term variable} or
    - a theory-specific {i term application}.

    All terms are {i pure} in that they do not contain subterms of another
    theory. In order to represent {i impure} terms such as [f(x + 1)] a
    variable [v] needs to be introduced such that [v = x + 1] is valid in
    the current configuration; then [f(x + 1)] is represented as [f(v)].

    Context-dependent term constructors are collected in Section
    {!Ics.termconstr}.*)
module Term : sig
  (** A {i linear arithmetic term} is a polynomial [p] of the form
      [c{0} + c{1}*x{1} + ... + c{n}*x{n}] with [c{i}] rational numbers and
      [x{i}] variables. [c{0}] is with {i constant} part of [p] and
      [c{i}*x{i}] are the {i monomials} of [p]. *)
  module Polynomial :
    Polynomial.P with type coeff = Q.t and type indet = Var.t

  (** An {i uninterpreted application} is of the form [f(x)] with [f] a
      function symbol in {!Ics.Funsym.t} and [x] a variable. *)
  module Uninterp :
    Cc.APPLY with type var = Var.t and type funsym = Funsym.t

  (** A term in the theory of tuples is either a tuple [<t{0},...,t{n-1}>],
      with [t{i}] tuple terms, or a projection [proj\[i,n\](t)] with
      [0 <= i < n < max_int] and [t] a tuple term. *)
  module Tuple : Tuple.T with type var = Var.t

  (** A term in the theory of functional arrays is either a lookup [a\[i\]]
      or an update [a\[i:=x\]]. *)
  module Array : Funarr.FLAT with type var = Var.t

  (** Representation of pure terms. As an invariant, all application term
      are {i canonical} in their respective theories. *)
  type t = private
    | Var of Var.t
    | Uninterp of Uninterp.t
    | Arith of Polynomial.t
    | Tuple of Tuple.t
    | Array of Array.t

  val hash : t -> int
  (** Nonnegative hash value for terms. *)

  val pp : Format.formatter -> t -> unit
  (** [pp fmt t] prints term [t] onto formatter [fmt]. *)

  val to_string : t -> string
  (** Print a term to a string. *)

  val equal : t -> t -> bool
  (** [equal s t] holds iff the equlity [s = t] is valid. This equality test
      is performed in constant time. *)

  val compare : t -> t -> int
  (** [compare s t] returns [0] iff [equal s t] holds. Furthermore,

      - [compare s t > 0] iff [compare s t < 0],
      - [compare x t < 0] for [x] a variable term and [t] an application.
        Otherwise, the order might change between different runs of ICS. *)

  (** Exception for indicating a variable argument. *)
  exception Variable

  val theory : t -> theory
  (** For a term application [t] return the corresponding theory name.
      Raises {!Variable} if [t] is a term variable. *)

  val to_var : t -> Var.t
  (** For a variable term [x] return the corresponding variable; raises
      [Not_found] otherwise. *)
end

(** {9 Formulas} *)

(** {i Propositional variables.} *)
module Propvar : sig
  (** Representation of propositional variables. *)
  type t

  val of_string : string -> t
  (** [of_string s] constructs a proposition variable [p] with associated
      name [s], that is [to_string p] returns [s]. *)

  val to_string : t -> string
  (** Return name associated with a propositional variable. *)

  val equal : t -> t -> bool
  (** The equality test [equal p q] holds iff the associated names
      [to_string p] and [to_string q] are equal. Unlike equality on string,
      the equality test on propositional variables is constant time. *)

  val compare : t -> t -> int
  (** [compare p q] returns [0] iff [equal p q] holds; furthermore,
      [compare p q > 0] iff [compare q p < 0]. In particular, {!compare}
      does not necessarily respect the natural ordering on names of
      propositional variables. Also, the order might change between
      different runs of ICS. *)

  val hash : t -> int
  (** Nonnegative hash value for terms. *)

  val pp : Format.formatter -> t -> unit
  (** [pp fmt p] prints propositional variable [p] on formatter [fmt]. *)

  val fresh : unit -> t
  (** Return a fresh propositional variable not seen before. *)
end

(** {i Monadic predicate symbols.} Predicate symbols are partitioned into

    - uninterpreted predicate symbols,
    - arithmetic predicate symbols [pos], [nonneg], [real], [equal0], and
      [diseq0], and
    - tuple constraints [tuple(n)], and
    - the [array] constraint. *)
module Predsym : sig
  (** Representation of monadic predicate symbols. *)
  type t

  val uninterp : string -> t
  (** [uninterp s] constructs an uninterpreted symbol of name [s]. *)

  val nonneg : t
  (** Extension of [nonneg] are all nonnegative reals. *)

  val pos : t
  (** Extension of [pos] are all positive reals. *)

  val equal0 : t
  (** Extension of [equal] is the singleton set [0]. *)

  val diseq0 : t
  (** Extension of [equal] is the singleton set [0]. *)

  val real : t
  (** Extension of [real] are all reals. *)

  val integer : t
  (** Extension of [integer] are all integers. *)

  val array : t
  (** Extension of [array] are all arrays (disjoint from tuples and reals). *)

  val tuple : int -> t
  (** Extension of [tuple n] are all tuples (disjoint form arrays and reals)
      of length [n] ([n >= 0]). *)

  val to_string : t -> string
  (** [to_string p] returns unique name associated with predicate symbol
      [p]. *)

  val equal : t -> t -> bool
  (** [equal p q] holds for uninterpreted [p], [q] if the associated names
      are equal. Otherwise, [equal p q] holds one if the extensions
      associated with [p], [q] are equal. *)

  val compare : t -> t -> int
  (** [compare p q] returns [0] iff [equal p q] holds; furthermore,
      [compare p q > 0] iff [compare q p < 0]. Note that the order might
      change between different runs of ICS. *)

  val sub : t -> t -> bool
  (** [sub p q] holds iff the extension of [p] is a subset of the extension
      for [q]. *)

  val disjoint : t -> t -> bool
  (** [sub p q] holds iff the extensions of [p] and [q] are disjoint. *)

  val hash : t -> int
  (** [hash p] returns a nonnegative hash value. *)

  val pp : Format.formatter -> t -> unit
  (** [pp fmt p] prints [p] on formatter [fmt]. *)

  (** {i Arithmetic predicate symbols} *)
  module Arith : sig
    type t = Nonneg | Pos | Real | Equal0 | Diseq0 | Int
  end

  val of_arith : Arith.t -> t
  (** Inject an arithmetic predicate symbol. *)
end

(** {i Formulas.} A formula is either

    - a term equality or disequality,
    - a literal consisting of an application of a predicate symbol to a term
      or the negation thereof, or
    - a propositional formula represented as a binary decision diagram. *)
module Formula : sig
  (** Binary decision diagrams with propositional variables of type
      {!Ics.Propvar.t} as nodes. *)
  module Bdd : Bdd.FML with type var = Propvar.t

  (** Representation of formulas

      - [Equal(s, t)] represents term equalities [s = t]; as an invariant
        [Term.compare s t > 0].
      - [Diseq(s, t)] represents term disequalities [s <> t], as an
        invariant [Term.compare s t > 0].
      - [Apply(p, t)] represents atoms [p(t)]. For efficiency, application
        of arithmetic predicates [q] is represented separately using
        [Arith(q, t)] where [t] is a polynomial.
      - [Prop(b)] represents a binary decision diagram (BDD) with
        propositional formulas. The ordering used to built BDDs is
        unspecified. *)
  type t = private
    | Equal of Term.t * Term.t
    | Diseq of Term.t * Term.t
    | Poslit of Predsym.t * Term.t
    | Neglit of Predsym.t * Term.t
    | Arith of Predsym.Arith.t * Term.Polynomial.t
    | Prop of Bdd.t

  val hash : t -> int
  (** Nonnegative hash value for formulas. *)

  val pp : Format.formatter -> t -> unit
  (** [pp fmt f] printf formula [f] on formatter [fmt]. *)

  val to_string : t -> string
  (** Print formula to a string. *)

  val equal : t -> t -> bool
  (** [equal f1 f2] holds iff [f1 <=> f2] is valid in the combined ICS
      theory. This test is performed in constant time. *)

  val compare : t -> t -> int
  (** [compare p q] returns [0] iff [equal p q] holds; Furthermore,
      [compare p q > 0] iff [compare q p < 0]. Note that the order might
      change between different runs of ICS. *)

  val is_true : t -> bool
  (** [is_true f] holds iff [f] is valid in the combined ICS theory. *)

  val is_false : t -> bool
  (** [is_false f] holds iff [f] is unsatisfiable in the combined ICS
      theory. *)
end

(** {i Set of formulas.} *)
module Formulas : Sets.S with type elt = Formula.t

(** {9:config Configurations} *)

(** {i Propositional inference system} The [P] inference system has binary
    decision diagrams as configurations. As an invariant, configurations do
    not include any implied propositional variables. *)
module P : Prop.INFSYS with type var = Propvar.t

(** {i Variable partitioning inference system}. The [V] inference system
    maintains configurations [(E,D)] consisting

    - a finite set of variable equalities [E] and
    - a finite set of variable disequalities [D]. The variable equalities
      [E] induce an equivalence relation [=E] on variables with [x =E y] iff
      [E => x = y] is valid in the theory of pure identity. *)
module V : Partition.INFSYS with type var = Var.t

(** {i Propositional assignment inference system}. Configurations [(P, N)]
    of the [L0] inference systems records the assigned propositional
    variables. [P], [N] are both finite set of propoositional variables, and
    configurations are equivalent to the conjunction of variables in [P]
    with negated variables in [N]. *)
module L0 : Nullary.INFSYS with type var = Propvar.t

(** {i Literal assignment inference system}. The [L1] inference systems
    records valid literals [p(x)] and [~p(x)] with [p] a monadic predicate
    symbol and [x] a variable. *)
module L1 :
  Literal.INFSYS with type predsym = Predsym.t and type var = Var.t

(** {i Renaming inference system.} The rename inference system [R] maintains
    a renaming map [u |-> p(x)] between propositional variables [u] and
    monadic applications [p(x)]. *)
module R :
  Rename.INFSYS
    with type propvar = Propvar.t
     and type predsym = Predsym.t
     and type var = Var.t

(** {i Congruence closure inference system.} The [U] inference system
    maintains a congruence-closed representation for a finite set of
    equalities over uninterpreted (monadic) terms. *)
module U : Cc.INFSYS with type var = Var.t and type funsym = Funsym.t

(** {i Linear arithmetic inference system.} The [A] inference system
    maintains a configuration equivalent to a conjunction of linear
    arithmetic equalities and inequalities. More precisely, configurations
    consist of

    - a set of (internally generated) {i slack variables} which are
      interpreted over the nonnegative reals,
    - constant assignments [x{1} = c{1};... x{n} = c{n}] with [x{i}]
      non-slack variables and [c{n}] rational constants,
    - a {i regular} solution set including equalities of the form [x = a]
      with [x] a non-slack variable and [a] a linear arithmetic term which
      is not a non-slack variable,
    - a {i regular} solution set with equalities of the form [x = a] with
      [x] a non-slack variable and [a] a linear arithmetic term which is not
      a non-slack variable,
    - a {i feasible tableau} solution set with equalities of the form
      [x = a] with[x] a slack variable and [a] is a linear arithmetic term
      containing only slack variables and the constant part of [a] is
      nonnegative. *)
module A :
  Simplex.INFSYS
    with type var = Var.t
     and type coeff = Q.t
     and type poly = Term.Polynomial.t

(** {i Tuple inference system.} Configurations of the [T] inference system
    are solution sets with equalities [x = t] where [t] is a variable and
    [t] is a non-variable tuple term. Codomain terms [t] might contain
    internally generated variable. Also, configurations are
    {i inverse functional} in that they do not simultaneously contain
    equalities [x1 = t] and [x2 = t]. *)
module T : Shostak.INFSYS with type var = Var.t and type trm = Term.Tuple.t

(** {i Functional array inference system.} Configurations of the [F]
    inference system consist of flat equalities [u = update(x,y,z)] or
    [v = lookup(x, y)] with [u], [v] internally generated variables and [x],
    [y], [z] arbitrary variables. *)
module F : Funarr.INFSYS with type var = Var.t and type flat = Term.Array.t

val footprint : bool ref
(** Output trace information on [stderr] when flag {!Ics.footprint} is set
    to [true]. *)

(** Status [Sat] ([Unsat]) means that the current context is {i satisfiable}
    ({i unsatisfiable}) in the combined ICS theory, and [Unknown] indicates
    that the ICS inference system has, for sake of efficiency, not been run
    to completion. In the latter case, the status might be resolved by
    explicitly calling [Ics.resolve()]. *)
type status = Sat of Formula.t | Unsat of Formula.t list | Unknown

(** {i Decision procedure states.} A decision procedure state consists of

    - a {i combined configuration} [(P, L0, L1, R, V, U, A, T, F)] which is
      the union of the configurations of the individual inference systems as
      described above.
    - a {i logical context} [context] which is the sequence of asserted
      formulas (through {!Ics.process}). The conjunction of these formulas
      is {i equisatisfiable} with the combined configuration. Note that
      context formulas might include internally generated variables, since,
      first, ICS does not explicitly construct input formulas before
      canonization, and, second, ICS can only represent flat terms.
    - an {i upper bound} [upper] on internally generated variables. As an
      invariant, all internal variables in the logical context and the
      configuration of a decision procedure state are of index less or equal
      to [upper],
    - a [status] flag. *)
type t = private
  { context: Formula.t list
  ; p: P.t
  ; l0: L0.t
  ; l1: L1.t
  ; r: R.t
  ; v: V.t
  ; u: U.t
  ; a: A.t
  ; t: T.t
  ; f: F.t
  ; upper: int
  ; mutable status: status }

val empty : t
(** The empty decision procedure state with empty logical context [\[\]]. *)

val pp : Format.formatter -> t -> unit
(** Printing a decision procedure state. *)

val equal : t -> t -> bool
(** [equal s1 s2] holds if [s1] is identical with [s2]. This test is
    constant time. Failure of this test does not imply that the
    corresponding configurations are not equivalent. *)

val descendant : t -> t -> bool
(** [descendant s1 s2] holds if the logical context of [s2] (viewed as a
    sequence) is a postfix of the logical context of [s1]. This test is
    linear in the length of these sequences. Failure of this test does not
    imply that the corresponding configurations are not equivalent. *)

val initialize : t -> unit
(** [initialize s] initializes the {i current state} of the ICS inference
    system with the configuration of the decision procedure state [s]. Also,
    the notion of {i freshness} for variables is modified as to exclude all
    internal variables of [s]. *)

val reset : unit -> unit
(** [reset()] is synonymous with [initialize empty]. *)

val current : unit -> t
(** Save the {i current state} into a decision procedure state. *)

val unchanged : unit -> bool
(** [unchanged()] holds iff the current configuration has not been updated
    since the last call to [initialize] or [reset]. *)

val context : unit -> Formula.t list
(** Return the current logical context. *)

(** {i Variable equalities.} Representation of a set of variable equalities
    [E] as a map with bindings [x |-> {x{1},...,x{n}}] with [x] the
    canonical representative of the equivalence class modulo [E] containing
    [x], and [x{i}] are all variables with [x = x{i}] is valid in [E]. *)
module Vareqs : Maps.S with type key = Var.t and type value = Vars.t

val var_equals : unit -> Vareqs.t
(** Return the set of variable equalities [E] of the current configuration. *)

val var_diseqs : unit -> Formulas.t
(** Return the set of variable disequalities [D] of the current
    configuration. *)

val constant_equals : unit -> Formulas.t
(** Return the set of constant equalities [x = c], with [c] a rational
    constant, of the current configuration. *)

val regular_equals : unit -> Formulas.t
(** Return the regular solution set (for linear arithmetic) of the current
    configuration. *)

val tableau_equals : unit -> Formulas.t
(** Return the tableau solution set (for linear arithmetic) of the current
    configuration. *)

val slacks : unit -> Vars.t
(** Return the set of slack variables of the current configuration. *)

val theory_equals : theory -> Formulas.t
(** For given theory [i], [theory_equals i] returns the set of equalities
    [x = t], with [x] a variable and [t] a term of theory [i] of the current
    configuration. *)

val literals : unit -> Formulas.t
(** Return the set of valid formulas [p], [p(x)], [~p], [~p(x)] of the
    current configuration. *)

val prop : unit -> Formula.t
(** Return the propositional formula of the current configuration. *)

(** {i Renames}. Set of bindings [u |-> p(x)] or [v |-> x = y] with [p] a
    predicate symbol, [x], [y] term variables, and [u], [v] propositional
    variables. *)
module Rename : Maps.S with type key = Propvar.t and type value = Formula.t

val renames : unit -> Rename.t
(** Return the set of renames of the current configuration. *)

val status : unit -> status
(** Return the status of the current state. *)

val pp_context : unit -> unit
(** Print the current logical context on [stdout]. *)

val pp_config : unit -> unit
(** Print the current configuration on [stdout]. *)

(** {9:termconstr Term constructors} *)

(** All constructed term applications are {i canonical} in their respective
    theories. In addition, context information is used to construct terms,
    which are canonical with respect to the current context. Moreover,
    construction of terms might lead to updates of the current state. *)

val var : Var.t -> Term.t
(** [var x] constructs a term variable for the canonical representative [x']
    of the [E]-equivalence class containing [x]. *)

val constz : Z.t -> Term.t
(** For an arbitrary precision integer [c], [constz c] either returns a term
    numeral [c] or an [E]-canonical variable [x] if [x = c] is valid in the
    current state. *)

val constq : Q.t -> Term.t
(** For rational [q], [constq q] either returns a term numeral representing
    [q] or an [E]-canonical variable [x] if [x = q] is valid in the current
    state. *)

val multq : Q.t -> Term.t -> Term.t
(** For a rational [q] and a term [t], the constructor [mult q t] for
    {i linear multiplication} returns a term [t'] with [t' = q*t] is valid
    in the current state. If [t] is canonical, then [t'] is also canonical. *)

val add : Term.t -> Term.t -> Term.t
(** For terms [s], [t], the constructor [add s t] returns a term [r] with
    [r = s + t] valid in the current context. If [s], [t] are canonical,
    then [r] is also canonical. *)

val sub : Term.t -> Term.t -> Term.t
(** For terms [s], [t], the constructor [add s t] returns a term [r] with
    [r = s - t] valid in the current context. If [s], [t] are canonical,
    then [r] is also canonical. *)

val minus : Term.t -> Term.t
(** For a term [t], the constructor [minus t] returns a term [t'] with
    [t' = -t] valid in the current context. If [t] is canonical, then [t']
    is also canonical. *)

val nil : unit -> Term.t
(** [nil()] returns either the empty tuple term [<>] or a canonical variable
    [x] with [x = <>] valid in the current state. *)

val pair : Term.t -> Term.t -> Term.t
(** [pair s t] returns either a canonical term for representing the pair
    [<s, t>] or a canonical variable [x] with [x = <s,t>] valid in the
    current state. If [s], [t] are canonical, then the result also
    canonical. *)

val tuple : Term.t list -> Term.t
(** [tuple tl] returns either a canonical term for representing the tuple
    [<t{1},...,t{n}>] or a canonical variable [x] with [x = <t{1},...,t{n}>]
    valid in the current state. If all [t{i}] are canonical, then the result
    also canonical. *)

val proj : int -> int -> Term.t -> Term.t
(** For [0 <= i < n] and a term [t], [proj i n t] returns the [i]th
    {i projection} of an [n]-tuple or a canonical variable [x] which is
    equal to such a projection in the current state. If [t] is canonical,
    then so is the result. *)

val left : Term.t -> Term.t
(** The {i left projection} [left t] is synonymous with [proj 0 2 t]. *)

val right : Term.t -> Term.t
(** The {i right projection} [right t] is synonymous with [proj 1 2 t]. *)

val constant : Funsym.t -> Term.t
(** [constant f] returns either an uninterpreted application term [f()] or a
    canonical variable [x] with [x = f()]. *)

val apply : Funsym.t -> Term.t -> Term.t
(** [apply f t] returns either an uninterpreted term application [f(x)] with
    [x = t] valid in a possibly updated current state or [y] with [y = f(t)]
    is valid in the current state. *)

val lookup : Term.t -> Term.t -> Term.t
(** For terms [a], [i], the constructor [lookup a i] either returns a term
    application [t'] for representing the lookup [a\[i\]] of a functional
    array at position [i] or a variable [x] with [x = t'] in the current
    state. If [a], [i] are canonical, then so is [t']. *)

val update : Term.t -> Term.t -> Term.t -> Term.t
(** For terms [a], [i], [x], [update a i] either returns a term application
    [t'] for representing the update [a\[i:=x\]] of a functional array at
    position [i] with [x] or a variable [y] with [y = t'] in the current
    state. If [a], [i], [x] are canonical, then so is [t']. *)

val d_num : Term.t -> Q.t
(** [d_num t] returns [q] if [t = q] is valid in the current state.
    Otherwise, [Not_found] is raised. *)

(** {9:fmlconstr Formula constructors} *)

val do_minimize : bool ref
(** Flag for determining the amount of simplifications for formula
    constructors. Defaults to [true]. *)

val tt : Formula.t
(** Construct a representation of the trivially valid formula. *)

val ff : Formula.t
(** Construct a representation of the trivially unsatisfiable formula. *)

val posvar : Propvar.t -> Formula.t
(** The result of [posvar p] is equivalent, in the current context, with the
    propositional variable [p]. In particular, the result is

    - [tt] iff [p] holds in the current state, and
    - [ff] if [~p] holds in the current state. *)

val negvar : Propvar.t -> Formula.t
(** The result of [negvar p] is equivalent, in the current context, with the
    negation [~p] of the propositional variable [p]. In particular, the
    result is

    - [ff] iff [p] holds in the current state, and
    - [tt] if [~p] holds in the current state. *)

val poslit : Predsym.t -> Term.t -> Formula.t
(** [poslit p t] returns a formula equivalent, in the current context, with
    the application [p(t)] of the monadic predicate symbol [p] with term
    [t].

    The result is

    - [tt] if [p(t)] holds in the theory [Predsym.theory p] associated with
      [p].
    - [ff] if [p(t)] does not hold in the theory [Predsym.theory p]
      associated with [p].

    Further context dependent simplifications might apply. If
    {!Ics.do_minimize} is set to [false], then [p(x)], for arithmetic
    predicates [p] is simplified such that the result is

    - [tt] iff [p(x)] holds in the current context, and
    - [ff] iff [p(x)] is inconsistent with the current context as long as
      [prop()] is trivially true. *)

val neglit : Predsym.t -> Term.t -> Formula.t
(** [neglit p t] is synonymous with [neg(poslit p t)]. *)

val eq : Term.t -> Term.t -> Formula.t
(** [eq s t] constructs a formula [fml] which is equivalent to the equality
    [s = t] in the current state.

    - [fml] is [tt] if [Term.equal s t] holds,
    - [fml] is [ff] if [Term.diseq s t] holds,
    - If [prop()] is trivially true, then [fml] is [tt] iff [s = t] is valid
      in the current state. *)

val deq : Term.t -> Term.t -> Formula.t
(** [deq s t] constructs a formula [fml] which is equivalent to the
    disequality [s /= t] in the current state.

    - [fml] is [tt] if [Term.equal s t] holds,
    - [fml] is [ff] if [Term.diseq s t] holds,
    - If [prop()] is trivially true, then [fml] is [tt] iff [s = t] is valid
      in the current state. *)

val nonneg : Term.t -> Formula.t
(** Creating a nonnegativity constraint for a term [t]. In fact, [nonneg t]
    is synonymous with [poslit Predsym.nonneg t]. *)

val pos : Term.t -> Formula.t
(** Creating a positivity constraint for a term [t]. In fact, [pos t] is
    synonymous with [poslit Predsym.pos t]. *)

val ge : Term.t -> Term.t -> Formula.t
(** [ge s t] creates a constraint equivalent to the arithmeitc inequality
    [s >= t]. In fact, [ge s t] is synonymous with
    [poslit Predsym.nonneg (sub s t)]. *)

val gt : Term.t -> Term.t -> Formula.t
(** [gt s t] creates a constraint equivalent to the arithmetic inequality
    [s > t]. In fact, [gt s t] is synonymous with
    [poslit Predsym.pos (sub s t)]. *)

val lt : Term.t -> Term.t -> Formula.t
(** [lt s t] is synonymous with [gt t s]. *)

val le : Term.t -> Term.t -> Formula.t
(** [le s t] is synonymous with [ge t s]. *)

val is_real : Term.t -> Formula.t
(** [is_real t] constrains term [t] to be interpreted over the reals. *)

val is_integer : Term.t -> Formula.t
(** [is_integer t] constrains term [t] to be interpreted over the integers.
    It is synonymous with [poslit Predsym.integer t]. *)

val is_tuple : int -> Term.t -> Formula.t
(** [is_tuple n t] constrains term [t] to be interpreted over the tuples of
    length [n] only. It is synonymous with [poslit (Predsym.tuple n) t]. *)

val is_array : Term.t -> Formula.t
(** [isArray t] constrains term [t] to be interpreted over arrays only. It
    is synonymous with [poslit Predsym.array t]. *)

val neg : Formula.t -> Formula.t
(** The formula [neg fml] is equivalent, in the current context, to the
    negation of [fml]. *)

val andthen : Formula.t -> Formula.t -> Formula.t
(** The formula [andthen fml1 fml2] is equivalent, in the current context,
    to the conjunction [fml1 & fml2]. *)

val orelse : Formula.t -> Formula.t -> Formula.t
(** The formula [orelse fml1 fml2] is equivalent, in the current context, to
    the disjunction [fml1 | fml2]. *)

val equiv : Formula.t -> Formula.t -> Formula.t
(** The formula [equiv fml1 fml2] is equivalent, in the current context, to
    the equivalence [fml1 <=> fml2]. *)

val xor : Formula.t -> Formula.t -> Formula.t
(** The formula [xor fml1 fml2] is equivalent, in the current context, to
    the exclusive or [fml1 # fml2]. *)

val implies : Formula.t -> Formula.t -> Formula.t
(** The formula [implies fml1 fml2] is equivalent, in the current context,
    to the implication [fml1 => fml2]. *)

val ite : Formula.t -> Formula.t -> Formula.t -> Formula.t
(** The formula [ite cond pos neg] is equivalent, in the current context, to
    the formula [(cond & pos) | (~cond & neg)]. *)

(** {9:process Inference system} *)

val find : theory -> Var.t -> Term.t
(** [find i x] returns a term [t] of theory [i] if there is an equality
    [x = t] in the current configuration. Raises [Not_found] whenever such a
    term [t] does not exist. *)

val inv : Term.t -> Var.t
(** [inv t] returns a variable [x] if there is a term of theory [i] and an
    equality [x = t] in the current equality configuration
    [theory_equals i]. *)

val can : Term.t -> Term.t
(** [can t] returns a term [t'] with [t = t'] valid in the current
    configuration. [can] does not update the current state. *)

val max : Term.t -> Term.t
(** [max t] returns a {i maximized term} of the form
    [c{0} - c{1}*x{1} - ... - c{n}*x{n}] with [x{i}] slack variables and
    [c{i}] rational constants, if [t <= c{0}] is valid in the current
    context. Notice that [max] might update the curerent tableau solution
    set. *)

val min : Term.t -> Term.t
(** [max t] is [-min(-1)]. *)

val sup : Term.t -> Q.t
(** [sup t] either returns a rational [q] or raises [Not_found]. If the
    result is a rational [q] then [t <= q] is valid in the current state;
    otherwise there is no such [q]. *)

val inf : Term.t -> Q.t
(** [inf t] is [-(sup(-t))]. *)

val alias : Term.t -> Var.t
(** [alias t] returns a variable [x] such that [x = t] is valid in a
    possibly modified state. *)

val complete_tests : bool ref
(** The value of [complete_tests] determines if {!Ics.valid} is complete. *)

val valid : Formula.t -> bool
(** If [valid fml] holds, then [fml] is valid in the current state. The
    contraposite, however, does not hold in general. The completeness of
    [valid] is influenced by the flags {!Ics.do_minimize} and
    {!Ics.complete_tests}.

    - If {!Ics.do_minimize} is unset, then more formulas are detected to be
      valid. In fact, if [prop()] is trivially true, then [valid] is
      complete. In this case, [valid] is polynomial in the size of the
      current configuration.
    - If {!Ics.complete_tests} is set, then [valid] is complete. In this
      case, [valid] might take time exponential in the number of variables
      in [prop()]. *)

(** Indicates unsatisfiability of the current state. *)
exception Unsatisfiable

val process : Formula.t -> status
(** [process fml] adds [fml] to the current logical state and returns the
    resulting status. [process] is {i incomplete} in that it does not detect
    all inconsistencies, but it is complete as long as the current
    propositional formula [prop()] is trivially true. For completeness,
    {!Ics.resolve} needs to be called explicitly. *)

val unsat_cores : bool ref
(** Compute unsatisfiable cores if set. *)

val resolve : unit -> status
(** [resolve()] resolves a possible [Unknown] status of the current state to
    either [Sat] or [Unsat]. This inference step is exponential in the
    number of variables of the current propositional formula [prop()].

    If the current status is [Unsat] and if the flag {!Ics.unsat_cores} is
    set, then [resolve()] computes an {i unsatisfiable core} of the current
    inconstent logical context; that is, a subset of the current logical
    context which is still unsatisfiable and which is {i irredundant} in the
    sense that removing any formula from the core yields a satisfiable
    logical context. *)

(**/**)

module Name = Name
