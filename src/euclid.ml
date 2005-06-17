(*
 * The contents of this file are subject to the ICS(TM) Community Research
 * License Version 2.0 (the ``License''); you may not use this file except in
 * compliance with the License. You may obtain a copy of the License at
 * http://www.icansolve.com/license.html.  Software distributed under the
 * License is distributed on an ``AS IS'' basis, WITHOUT WARRANTY OF ANY
 * KIND, either express or implied. See the License for the specific language
 * governing rights and limitations under the License.  The Licensed Software
 * is Copyright (c) SRI International 2003, 2004.  All rights reserved.
 * ``ICS'' is a trademark of SRI International, a California nonprofit public
 * benefit corporation.
 *)

module type RAT = sig
  type t
  val eq : t -> t -> bool
  val pp : Format.formatter -> t -> unit
  val ( + ) : t -> t -> t
  val zero : t
  val neg : t -> t
  val ( * ) : t -> t -> t
  val one : t
  val ( / ) : t -> t -> t
  val floor : t -> t  
  val is_int : t -> bool
end


module Particular(Q: RAT) = struct
  type q = Q.t

  open Q

  let ( - ) a b = a + neg b

  (** Given two rational numbers [a0], [b0], [euclid a0 b0] finds
    integers [x0], [y0], [(a0, b0)] satisfying
                 [a0 * x0 + b0 * y0 = (a0, b0)],
    where [(a0, b0)] denotes the greatest common divisor of [a0], [b0].
    For example,  [euclid 1547 560] equals [(7, 21, -58)]
    
    The value of [(a, b)] is unchanged in the loop in [euclid], since
    [(a, b) = (a - (a/b)*b, b)]; thus, using [(a, 0) = a],
    the first result of [euclid] computes [(a0, b0)]. Other
    invariants are:
        [c * a + e * b = a]
        [d * a + f * b = b]
    Now it is obvious that [a * x0 + b * y0 = (a, b)]. *)	    
  let euclid a0 b0 =
    let rec loop k a b c d e f =
      if eq zero a & not(eq zero b) then 
	(b, d, f)
      else if eq zero b & not(eq zero a) then 
	(a, c, e)
      else if (k mod 2 = 0) & not(eq zero b) then
	let u = floor(a / b) in
	  loop (succ k) 
	    (a - u * b) b
	    (c - u * d) d
	    (e - u * f) f
      else if (k mod 2 = 1) & not(eq zero a) then
	let v = floor(b / a) in
	  loop (succ k) 
	    a (b - v * a)
	    c (d - v * c)
	    e (f - v * e)
      else 
	invalid_arg "Euclid: unreachable"
    in
    loop 0 
      a0   b0
      one  zero
      zero one

  let gcd2 a b = 
    let d, _, _ = euclid a b in
      d

  let rec gcd = function
    | [] -> assert false
    | [a] -> a
    | a :: l -> gcd2 a (gcd l)

  let product al bl = 
    assert(List.length al = List.length bl);
    let rec accumulate acc al bl = 
      match al, bl with
	| [], [] -> acc
	| a :: al', b :: bl' -> 
	    accumulate ((a*b) + acc) al' bl'
	| _ -> 
	    assert false
    in
      accumulate Q.zero al bl  

  exception Unsolvable

  (** Solving a linear diophantine equation with nonzero, rational coefficients
    [ci], for [i = 1,...,n] with [n >= 1]:
         [c0*x0 + ... cn*xn = b] (1)
    The algorithm proceeds by recursion on [n]. The case [n = 1] is
    trivial. Let [n >= 2]. Find, with the Euclidean algorithm
    [c'] and integers [d], [e] satisfying
    [c' = (c0, c1) = c0 * d + c1 * e]
    Next solve the linear diophantine equation (in [n] variables)
         [c'*x + c2 * x2 + ... + cn * xn = b] (2)
    If equation (2) has no integral solution, then neither has (1). Otherwise,
    if [x,x2,...,xn] is an integral solution of (2), then [d*x, e*x,x2,...,xn] 
    gives an integral solution of (1). *)
  let rec solve cl b = 
    let rec loop = function
      | [] -> assert false
      | [c0] -> (c0, [b / c0])
      | c0 :: c1 :: l ->
	  let (d, e1, e2) = euclid c0 c1 in
	    match loop (d :: l) with
	      | e, x :: xs ->
		  (gcd2 d e, (e1 * x) :: (e2 * x) :: xs)
	      | _ -> assert false
  in
    let ((d, xs) as res) = loop cl in
      assert(not(Q.eq d Q.zero));
      assert(Q.eq (gcd cl) d); 
      if is_int (b / d) then 
	res
      else 
	raise Unsolvable
end


module type POLYNOMIAL = sig
  type q
  type t
  val pp : Format.formatter -> t -> unit
  val fresh : unit -> t
  val of_q : q -> t
  val add : t -> t -> t
  val multq : q -> t -> t
end


(** Compute the general solution of a linear Diophantine
  equation with coefficients [al], the gcd [d] of [al]
  and a particular solution [pl]. In the case of four
  coeffients, compute, for example,
   [(p0 p1 p2 p3) + k0/d * (a1 -a0 0 0) + k1/d * (0 a2 -a1 0) + k2/d * (0 0 a3 -a2)]
  Here, [k0], [k1], and [k2] are fresh variables. Note that
  any basis of the vector space of solutions [xl] of the 
  equation [al * xl = 0] would be appropriate. *)
module Solve(Q: RAT)(P: POLYNOMIAL with type q = Q.t) = struct
  type q = Q.t
  type poly = P.t

  open Q

  module Particular = Particular(Q)

  exception Unsolvable = Particular.Unsolvable

  let solve al b = 
    assert(al <> []);
    let d, pl = Particular.solve al b in
    let rec loop al zl =
      match al, zl with
	| [_], [_] -> 
	    zl
	| a0 :: ((a1 :: al'') as al'),  z0 :: z1 :: zl'' ->
            let k = P.fresh () in
            let e0 = P.add z0 (P.multq (a1 / d) k) in
            let e1 = P.add z1 (P.multq (neg a0 / d) k) in
	    let sl' =  loop al' (e1 :: zl'') in
              e0 :: sl'
	| _ -> assert false
  in
    loop al (List.map P.of_q pl)
end



(**/**)

module Q = struct
  open Num
  type t = num
  let eq = eq_num
  let pp fmt x = Format.fprintf fmt "%s" (string_of_num x)
  let of_int = num_of_int
  let make x y = div_num (num_of_int x) (num_of_int y)   
  let zero = of_int 0
  let one = of_int 1
  let ( + ) = add_num
  let neg = minus_num
  let ( * ) = mult_num
  let ( / ) = div_num
  let is_int = is_integer_num
  let floor = floor_num 
end


module Test = struct
  module Euclid = Particular(Q)

  let num_of_tests = ref 1000

  let max_num_of_variables = ref 10

  let max_rat = ref 17

  let randomDim () =
    (Random.int !max_num_of_variables) + 1 

  let randomInt () = 
    let n = Random.int !max_rat in
    let sign = (Random.int 2 = 0) in
      if sign then Q.of_int n else Q.of_int (-n)

  let randomRat () = 
    let n = Random.int !max_rat + 1 in
    let d = Random.int !max_rat + 1 in
      if d mod 2 == 0 then Q.of_int n else
	Q.make n d

  let randomEquality () = 
    let n = randomDim() in
    let b = randomRat() in
    let cl =
      let rec loop acc = function
	| 0 -> acc 
	| k -> 
	    let c = randomRat() in
	      loop (c :: acc) (k - 1)
      in
	loop [] n
    in
      cl, b

  let outCoeffs cl = 
    Format.eprintf "@[ <";
    (let rec loop = function
       | [] -> ()
       | [c] -> Q.pp Format.err_formatter c
       | c :: cl ->  Q.pp Format.err_formatter c; Format.eprintf ", "; loop cl
     in
       loop cl);
    Format.eprintf "> @]@?"

  let outEquality cl b =
    Format.eprintf "\nEq: ";
    outCoeffs cl;
    Format.eprintf " * X = ";
    Q.pp Format.err_formatter b;
    Format.eprintf "@?"

  let outSolution sl = 
    Format.eprintf "\n --> ";
    outCoeffs sl;
    Format.eprintf "@?"

  let outUnsat gcd b = 
    Format.eprintf "\n --> Unsat (not(";
    Q.pp Format.err_formatter gcd;
    Format.eprintf " / ";
    Q.pp Format.err_formatter b;
    Format.eprintf ")@?"

  let test () = 
    let cl, b = randomEquality() in
      outEquality cl b;
      try
	let d, sl = Euclid.solve cl b in
	  outSolution sl;
	  assert(List.length sl = List.length cl);
	  let eval = Euclid.product sl cl in
	    if Q.eq b eval then Format.eprintf "yes" else
	      (Format.eprintf "no(";
	       Q.pp Format.err_formatter eval;
	       Format.eprintf ")@?")
	       
      with
	  Euclid.Unsolvable -> 
	    outUnsat (Euclid.gcd cl) b;
	    ()
	     
  let run () = 
    for i = 0 to !num_of_tests do
      test()
    done

end
