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


(** Description of the theory of products as a convex Shostak theory. *)
module T = struct
  let th = Th.p
  let map = Product.map
  let solve e = 
    let (a, b, rho) = e in
      try
	let sl = Product.solve (a, b) in
	let inj (a, b) = Fact.Equal.make a b rho in
	  List.map inj sl
      with
	  Exc.Inconsistent -> raise(Jst.Inconsistent(rho))
  let disjunction _ =
    raise Not_found
end

(** Inference system for products as an instance 
  of a Shostak inference system. *)
module Infsys: (Infsys.EQ with type e = Solution.Set.t) =
  Shostak.Make(T)

