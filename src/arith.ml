(*i*)
open Tools
open Hashcons
open Mpa
open Term
(*i*)

module Poly = Poly.Make(
  struct
    type tnode = Term.tnode
    type t = Term.t
    let cmp = Term.cmp
  end)

type monomial = Q.t * (Term.t list) hashed
		  
(*s Constants *)

let num q = hc(Arith(Num(q)))
let zero  = num Q.zero
let one  = num Q.one

let is_one = function
  | {node=Arith (Num q)} when Q.equal q Q.one -> true
  | _ -> false

let is_zero = function
  | {node=Arith (Num q)} when Q.is_zero q -> true
  | _ -> false

(*s Building products and sums. *)
	
let mk_multq q x =
  if Q.is_zero q then
    zero
  else if Q.is_one q then
    x
  else
    hc(Arith(Multq(q,x)))
      
let mk_mult = function
  | [] -> hc(Arith(Num(Q.one)))
  | [t] -> t
  | l -> hc(Arith(Mult l))
	       
let mk_add = function
  | [] -> hc(Arith(Num(Q.zero)))
  | [t] -> t
  | l -> hc(Arith(Add l))  
		  


(*s Building a power product *)

let pproduct l =
  match l with
  | [t] -> t
  | _ -> mk_mult l

(* Translations between arithmetic terms and polynomials

    A Polynomial is generated by the grammar:
      poly ::= monomial
             | monomial + poly

      monomial ::= q
                 | pproduct 
                 | q * pproduct    where q <> 1

      pproduct ::= t0 * ... * tn      where n >= 0
  *)
   
module PolyCache = Hasht.Make(
  struct 
    type t = Term.t
    let equal = (===) 
    let hash x = x.tag 
  end)
	 
let table = PolyCache.create 10007
		   
let to_mono t =
  match t.node with
    | Arith a ->
	(match a with
	   | Num q -> Poly.num q
	   | Multq(q,x) -> Poly.monomial (q,[x])
	   | Mult l -> Poly.pproduct l
	   | Div _ -> Poly.pproduct [t]
	   | Add _ -> assert false)
    | _ ->
	Poly.pproduct [t]

let to_poly t =
  try
    PolyCache.find table t
  with
      Not_found ->
	let p = to_mono t in
	PolyCache.add table t p; p
		      
let of_mono m =
  let (q,xl) = Poly.of_monomial m in
  match Poly.of_pproduct xl with
    | [] -> num q
    | [t] -> mk_multq q t
    | l -> mk_multq q (mk_mult l)
	  
let of_poly p =
  let t =
    let l = Poly.to_list p in
    mk_add (List.map of_mono l)
  in
  PolyCache.add table t p; t
	    
let of_pproduct xl =
  mk_mult (Poly.of_pproduct xl)

    
(*s Operations on the coefficients of a polynomial *)

let mapq f t = of_poly (Poly.mapq f (to_poly t))

let neg     = mapq Q.minus
let divq q  = mapq (Q.div q)
let multq q = mapq (Q.mult q)
let addq q  = mapq (Q.add q)

		
(*s Adding Polynomials *)

let add2 (t1,t2) = of_poly (Poly.add2 (to_poly t1) (to_poly t2))

let addl tl =
  of_poly (Poly.add (List.map to_poly tl))
  
let add = (* Tools.profile "Add" (cachel 107 addl) *) addl

let incr t = add2 (t, one)
  
let sub (t1,t2) =
  of_poly (Poly.sub (to_poly t1) (to_poly t2))

let mult2 (t1,t2) =
  of_poly (Poly.mult2 (to_poly t1) (to_poly t2))

let multl tl =
  of_poly (Poly.mult (List.map to_poly tl))

let mult = (* Tools.profile "Mult" (cachel 107 multl) *) multl

	     
(*s Division of polynomials. Rather incomplete. *)

let div2 (t1,t2) =
  match t2.node with
    | Arith(Num q) when not(Q.is_zero q) -> divq q t1
    | _ -> hc (Arith(Div(t1,t2)))
	  
(*s Test for arithmetic constant. *)

let is_num a =
  match a.node with
    | Arith(Num _) -> true
    | _ -> false
	  
let num_of a =
  match a.node with
    | Arith(Num q) -> q
    | _ -> assert false
	  
(*s Integer test for power products of a polynomial. *)

let is_diophantine is_int a =
  Poly.for_all (fun m ->
		  let (q,pp) = Poly.of_monomial m in
		  let xl = Poly.of_pproduct pp in
		  List.for_all is_int xl)
    (to_poly a)
	

(*s Solving of an equality [a = b], represented by the pair [a,b)]
    in the rationals and the integers.
  *)

let qsolve x e =
  match Poly.qsolve x (to_poly (sub e)) with
    | Poly.Valid -> []
    | Poly.Inconsistent -> raise(Exc.Inconsistent "Rational solver")
    | Poly.Solution (x,p) -> [of_pproduct x, of_poly p]


let zsolve e =
  let fresh () = Var.fresh "k" [] in
  match Poly.zsolve fresh (to_poly (sub e)) with
    | Poly.Valid -> ([],[])
    | Poly.Inconsistent -> raise(Exc.Inconsistent "Integer solver")
    | Poly.Solution (ks, rho) ->
	(ks, List.map (fun (x,p) -> (of_pproduct x, of_poly p)) rho)

	  
(*s Test if some term is trivially an integer. *)

let rec is_integer t =
  match t.node with
    | Arith a ->
	(match a with
	   | Num q -> Q.is_integer q
	   | Multq(q,x) -> Q.is_integer q && is_integer x
	   | Mult l -> List.for_all is_integer l
	   | Add l -> List.for_all is_integer l
	   | Div(x,y) -> x === y)
    | _ -> false  

(*s Destructure an arithmetic polynomial in constant and nonconstant part. *)

let d_poly t =
  let (p,q) = Poly.destructure (to_poly t) in
  (of_poly p, q)
  

(*s Normalized inequalities. First we make all the coefficients integer,
    then we make the [gcd] of these new coefficients equal to 1. *)

let normalize p =
  let lcm = Q.of_z(Poly.lcm p) in
  assert(Q.gt lcm Q.zero);
  let p' = Poly.multq lcm p in
  let gcd = Q.of_z(Poly.gcd p') in
  assert (Q.gt gcd Q.zero);
  let p'' = Poly.divq gcd p' in
  Poly.destructure p''

let lt (x,y) =
  let p = Poly.sub (to_poly x) (to_poly y) in
  if Poly.is_zero p then
    hc(Bool False)
  else if Poly.is_num p then
    let c = Poly.num_of p in
    if Q.lt c Q.zero then hc(Bool True) else hc(Bool False)
  else
    let (p',q') = normalize p in
    if Q.ge (Poly.leading p') Q.zero then
      Cnstrnt.app (Cnstrnt.lt Interval.Real (Q.minus q')) (of_poly p')
    else
      Cnstrnt.app (Cnstrnt.gt Interval.Real q') (of_poly (Poly.neg p'))

let le (x,y) =
  let p = Poly.sub (to_poly x) (to_poly y) in
  if Poly.is_zero p then
    hc(Bool True)
  else if Poly.is_num p then
    let c = Poly.num_of p in
    if Q.le c Q.zero then hc(Bool True) else hc(Bool False)
  else
    let (p',q') = normalize p in
    if Q.ge (Poly.leading p') Q.zero then
      Cnstrnt.app (Cnstrnt.le Interval.Real (Q.minus q')) (of_poly p')
    else
      Cnstrnt.app (Cnstrnt.ge Interval.Real q') (of_poly (Poly.neg p'))
      
      
(*s Constructor for domain constraints *)

let int a = Cnstrnt.app Cnstrnt.int a
    
let real a = Cnstrnt.app Cnstrnt.real a
