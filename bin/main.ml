open Regexp

module M = Necromonads.List

module CMap = Map.Make(Stdlib.Int)

module Types = struct
  type symb = char
  type lett = char
  type word = lett list
  type cref = int
  type nat = int
  type heap = (word option) CMap.t * cref
end

module Spec = struct
  include Unspec(M)(Types)

  let equal ((s: symb), (l: lett)) =
    if (s = l) then M.ret () else M.fail ()

  let eps : word = []

  let isempty (w: word) = match w with
    | [] -> M.ret ()
    | _ -> M.fail ()

  let head (w: word) = match w with
    | [] -> M.fail ()
    | l :: _ -> M.ret l
  
  let tail (w: word) = match w with
    | [] -> M.fail ()
    | _ :: t -> M.ret t

  let cons ((l: lett), (w: word)) =
    M.ret (l :: w)
  
  let rec wrdcmp (w1, w2) = match w1, w2 with
    | [], [] -> M.ret ()
    | l1 :: t1, l2 :: t2 when l1 = l2 -> wrdcmp (t1, t2)
    | _ -> M.fail ()

  let isz n = match n with
    | 0 -> M.ret ()
    | _ -> M.fail ()
  
  let pred n = match n with
    | 0 -> M.fail ()
    | _ -> M.ret (n - 1)

  let empty_heap : heap =
    CMap.empty, 1

  let alloc (cm, nr) =
    let cm' = CMap.add nr None cm in
    M.ret (nr, (cm', nr + 1))

  let set (r, w, (cm, nr)) =
    let cm' = CMap.add r (Some w) cm in
    M.ret (cm', nr)

  let get (r, (cm, nr)) =
    let woo = CMap.find_opt r cm in
    match woo with
      | Some (Some w) -> M.ret w
      | _ -> M.fail ()
end

open MakeInterpreter(Spec)

let word_of_string (s : string) = List.init (String.length s) (String.get s)
let string_of_word (w : word) = String.init (List.length w) (List.nth w)

let list_of_trace tr =
  let rec aux acc tr =
    match tr with
    | Nil -> acc
    | Elt te -> te :: acc
    | Conc (tr1, tr2) ->
      let acc2 = aux acc tr2 in
      aux acc2 tr1
  in
  aux [] tr

let string_of_elt te = match te with
  | TrEps -> Printf.sprintf "ε"
  | TrSymb s -> Printf.sprintf "%c" s
  | TrOrL -> "L("
  | TrOrR -> "R("
  | TrParL -> "("
  | TrParR -> ")"
  | TrDot -> "⋅"
  | TrStarL -> "{"
  | TrStarR -> "}"
  | TrEsp -> " "
  | TrGroupL r -> Printf.sprintf "\\%d[" r
  | TrGroupR -> "]"
  | TrRef (r, w) -> Printf.sprintf "\\%d\"%s\"" r (string_of_word w)

let string_of_trace tr =
  String.concat "" (List.map string_of_elt (list_of_trace tr))

let testnb = ref 0
let test t =
  incr testnb;
  Printf.printf "\nTEST n°%d:\n" (!testnb);
  let e, s = t in
  let w = word_of_string s in
  let res = exec (e, w) in
  match res with
    | [] -> Printf.printf "Non reconnu\n"
    | _ ->
      Printf.printf "Reconnu de %d façon(s):\n" (List.length res);
      List.iter
        (fun (tr, (cm, nr)) ->
          print_endline (string_of_trace tr);
          for i=1 to nr-1 do
            Printf.printf "Groupe %d:\n" i;
            match (CMap.find i cm) with
              | None -> ()
              | Some w -> print_endline (string_of_word w)
            ;
            Printf.printf "\n"
          done
        )
        res

let t1 = Or(Or(Symb 'a', Symb 'b'), Symb 'c'), "c"
(*
    (a | b) | c                      
*)
let t2 = Or(Symb 'a', Symb 'b'), "c"
(*
    a | b
*)

let t3 = Or(Or(Symb 'a', Symb 'b'), Symb 'a'), "a"
(*
    (a | b) | a
*)
let t4 = Dot(Symb 'a', Symb 'b'), "ab"
(*
    a b
*)
let t5 = Dot(Symb 'a', Symb 'b'), "a"
(*
    a b
*)
let t6 = Dot(Or(Symb 'a', Symb 'a'), Symb 'b'), "ab"
(*
    (a | a) b
*)
let t7 = Dot(Dot(Symb 'a', Symb 'b'), Symb 'c'), "abc"
(*
    (a b) c
*)
let t8 = Dot(
  Or(
    Dot(Symb 'a', Symb 'b'),
    Symb 'a'
  ),
  Or(
    Symb 'c',
    Dot(Symb 'b', Symb 'c')
  )
), "abc"
(*
    (a b | a) (c | b c)
*)
let t9 = Star(Symb 'a'), "aa"
(*
    a*
*)
let t10 = Star(Star(Symb 'a')), "aa"
(*
    a**
*)
let e11 = 
  Star(
    Dot(
      Star(
        Or(
          Star(Symb 'a'),
          Symb 'b'
        )
      ),
      Symb 'c'
    )
  )
(*
    ((a* | b)* c)*
*)
let t11 = e11, "abba"
let t12 = e11, "abccaac"

let t13 = Star(Star(Symb 'a')), "aaaa"
(*
    a**
*)
let t14 = Eps, ""
(*
    ε
*)
let t15 = Eps, "a"
(*
    ε
*)
let t16 = Dot(Star(Symb 'a'), Star(Symb 'a')), "aa"
(*
    a* a*
*)
let t17 = Group(Symb 'a'), "a"
(*
    [a]
*)
let t18 = Dot(Symb 'a', Group (Dot(Symb 'b', Dot(Group (Symb 'c'), Dot(Symb 'd', Group(Symb 'e')))))), "abcde"
(*
    a [b [c] d [e]]
*)
let t19 = Dot(Star (Symb 'a'), Star (Symb 'a')), "aaa"
(*
    a* a*
*)
let t20 = Dot(Group(Symb 'a'), Dot(Ref 1, Symb 'b')), "aab"
(*
    [a] \1 b
*)
let t21 = Star(Group(Or(Dot(Ref 1, Symb 'a'), Symb 'b'))), "bba"
(*
    [\1 a | b]*
*)
let t22 = Star(Star(Group(Symb 'b'))), "bbb"
(*
    [b]**
*)
let t23 = Star(Or(Dot(Ref 1, Symb 'a'), Group(Symb 'b'))), "bba"
(*
    (\1 a | [b])*
*)
let e24 = Plus(Or(Symb 'a', Symb 'b'))
(*
    (a | b)+
*)
let t24 = e24, "aba"
let t25 = e24, ""
let t26 = Exp(Symb 'a', 0), ""
(*
    (a)^0
*)
let t27 = Exp(Or(Symb 'a', Eps), 3), "aa"
(*
    (a | ε)^3
*)
let t28 = Star(Symb 'a'), ""
(*
    a*
*)
let t29 = Dot(Plus(Symb 'a'), Plus(Symb 'a')), "aaa"
(*
    a+ a+
*)
let e30 = Dot(Or(Group(Symb 'a'), Symb 'a'), Dot(Group(Symb 'b'), Ref 1))
(*
    ([a] | a) [b] \1
*)
let t30 = e30, "aba"
let t31 = e30, "abb"
let t32 = Dot(Star(Group(Symb 'a')), Dot(Symb 'a', Ref 1)), "aaa"
(*
    [a]* a \1
*)
let e33 = Dot(Option(Symb 'a'), Symb 'b')
(*
    a? b
*)
let t33 = e33, "b"
let t34 = e33, "ab"
let e35 = Dot(Or(Group(Symb 'a'), Symb 'c'), Dot(Group(Symb 'b'), Option(Ref 1)))
(*
    ([a] | c) [b] (\1)?
*)
let t35 = e35, "ab"
let t36 = e35, "cb"
let t37 = e35, "aba"
let t38 = e35, "cbb"


let tests = 
  [
    t1; t2; t3; t4; t5; t6; t7; t8; t9; t10;
    t11; t12; t13; t14; t15; t16; t17; t18; t19; t20;
    t21; t22; t23; t24; t25; t26; t27; t28; t29; t30;
    t31; t32; t33; t34; t35; t36; t37; t38
  ]

let _ = List.iter test tests

