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

(* TEST DES EXPRESSIONS RATIONNELLES *)

(*Test de Eps*)
let t1 = Eps, ""
(*
    ε
*)
let t2 = Eps, "a"
(*
    ε
*)

(*Test de Symb*)
let t3 = Symb 'a', "a"
(*
    a
*)
let t4 = Symb 'a', "b"

(*Test de Or*)
let t5 = Or(Symb 'a', Symb 'b'), "a"
(*
    a | b
*)
let t6 = Or(Symb 'a', Symb 'b'), "b"
(*
    a | b
*)
let t7 = Or(Symb 'a', Symb 'b'), "c"
(*
    a | b
*)
let t8 = Or(Or(Symb 'a', Symb 'b'), Symb 'a'), "a"
(*
    (a | b) | a
*)

(*Test de Dot*)
let t9 = Dot(Symb 'a', Symb 'b'), "ab"
(*
    a b
*)
let t10 = Dot(Symb 'a', Symb 'b'), "a"
(*
    a b
*)
let t11 = Dot(Or(Symb 'a', Symb 'a'), Symb 'b'), "ab"
(*
    (a | a) b
*)
let t12 = Dot(Dot(Symb 'a', Symb 'b'), Symb 'c'), "abc"
(*
    (a b) c
*)
let t13 = Dot(
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

(*Test de Star*)
let t14 = Star(Symb 'a'), ""
(*
    a*
*)
let t15 = Star(Symb 'a'), "aaa"
(*
    a*
*)
let t16 = Star(Star(Symb 'a')), "aaaa"
(*
    a**
*)
let t17 = Dot(Star (Symb 'a'), Star (Symb 'a')), "aaa"
(*
    a* a*
*)
let e1 = 
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
let t18 = e1, "abba"
let t19 = e1, "abccaac"

(* TEST DES CAPTURES *)

(*Test des extensions POSIX*)
let e2 = Option(Symb 'a')
(*
    a?
*)
let t20 = e2, "a"
let t21 = e2, ""

let e3 = Plus(Symb 'a')
(*
    a⁺
*)
let t22 = e3, "aaa"
let t23 = e3, ""

let t24 = Dot(Plus(Symb 'a'), Plus(Symb 'a')), "aaaa"
(*
    a⁺ a⁺
*)
let t25 = Exp(Symb 'a', 0), ""
(*
    (a)⁰
*)
let t26 = Exp(Symb 'a', 4), "aaaa"
(*
    (a)⁴
*)
let e4 =
  Exp(
    Dot(
      Plus(
        Or(
          Option(Symb 'a'),
          Symb 'b'
        )
      ),
      Symb 'c'
    ),
    3
  )
(*
    ((a? | b)⁺ c)³
*)
let t27 = e4, "ccc"
let t28 = e4, "bcbbcbc"
let t29 = e4, "abacabcc"

(*Test des groupes*)
let t30 = Group(Symb 'a'), "a"
(*
    [a]
*)
let t31 = Dot(Symb 'a', Group (Dot(Symb 'b', Dot(Group (Symb 'c'), Dot(Symb 'd', Group(Symb 'e')))))), "abcde"
(*
    a [b [c] d [e]]
*)
let t32 = Star(Star(Group(Symb 'b'))), "bbb"
(*
    [b]**
*)

(*Test des références*)
let t33 = Dot(Group(Symb 'a'), Ref 1), "aa"
(*
    [a] \1         référence standarde
*)
let t34 = Dot(Star(Group(Symb 'a')), Dot(Symb 'a', Ref 1)), "aaa"
(*
    [a]* a \1
*)
let t35 = Star(Or(Dot(Ref 1, Symb 'a'), Group(Symb 'b'))), "bba"
(*
    (\1 a | [b])*  référence anticipée
*)
let t36 = Star(Group(Or(Dot(Ref 1, Symb 'a'), Symb 'b'))), "bba"
(*
    [\1 a | b]*    référence imbriquée
*)

let e5 = Dot(Or(Group(Symb 'a'), Symb 'c'), Dot(Group(Symb 'b'), Option(Ref 1)))
(*
    ([a] | c) [b] (\1)?
*)
let t37 = e5, "ab"
let t38 = e5, "cb"
let t39 = e5, "aba"
let t40 = e5, "cbb"

let t41 =
  Dot(
    Group(e4),
    Dot(
      Group(e5),
      Dot(
        Ref 2,
        Ref 3
      )
    )
  ),
  "abacabcc"^"cbabacabcc"^"cbabacabcc"^"b"
(*
    [((a? | b)⁺ c)³] [([a] | c) [b] (\1)?] \2 \3
*)

let tests = 
  [
     t1;  t2;  t3;  t4;  t5;  t6;  t7;  t8;  t9; t10;
    t11; t12; t13; t14; t15; t16; t17; t18; t19; t20;
    t21; t22; t23; t24; t25; t26; t27; t28; t29; t30;
    t31; t32; t33; t34; t35; t36; t37; t38; t39; t40;
    t41
  ]

let _ = List.iter test tests

