
(*i*)
open Ics
(*i*)

val state : unit -> Congstate.t
  
val sigma : term -> unit
val solve : term * term -> unit
val process : term -> unit
val processl : term list -> unit
val reset : unit -> unit
val drop : unit -> unit
val compare : term * term -> unit
val verbose : int -> unit
val find : term option -> unit
val use : term option -> unit
val universe : term option -> unit
val can : term -> unit
val norm : term -> unit
val check : term -> unit
val unify : term * term -> unit
val fol : term -> unit
