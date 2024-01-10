open Regexp

module M = Necromonads.List

module CMap = Map.Make(Stdlib.Int)

module Types = struct
  type symb = char
  type lett = char
  type word = lett list
  type cap = int
  type heap = (word option) CMap.t * cap
end

module Spec = struct
  include Unspec(M)(Types)

  let lett_of_symb (s: symb) = M.ret s

  let equal ((s: symb), (l: lett)) =
    if (s = l) then M.ret () else M.fail ()

  let eps : word = []

  let head (w: word) = match w with
    | [] -> M.fail ()
    | l :: _ -> M.ret l
  
  let tail (w: word) = match w with
    | [] -> M.fail ()
    | _ :: t -> M.ret t

  let cons ((l: lett), (w: word)) =
    M.ret (l :: w)

  let isempty (w: word) = match w with
    | [] -> M.ret ()
    | _ -> M.fail ()
  
  let empty_heap : heap =
    CMap.empty, 0

  let alloc (cm, nc) =
    let cm' = CMap.add nc None cm in
    M.ret (nc, (cm', nc + 1))

  let set (c, w, (cm, nc)) =
    let cm' = CMap.add c (Some w) cm in
    M.ret (cm', nc)

  let get (c, (cm, nc)) =
    if c >= nc then
      M.fail ()
    else
      let wo = CMap.find c cm in
      match wo with
        | None -> M.fail ()
        | Some w -> M.ret w
  
  let rec wrdcmp (w1, w2) = match w1, w2 with
    | [], [] -> M.ret ()
    | l1 :: t1, l2 :: t2 when l1 = l2 -> wrdcmp (t1, t2)
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
  | TrOrEnd -> ")"
  | TrParL -> "("
  | TrParR -> ")"
  | TrStarL -> "{"
  | TrStarR -> "}"
  | TrGroupL c -> Printf.sprintf "\\%d[" c
  | TrGroupR -> "]"
  | TrRef (c, w) -> Printf.sprintf "\\%d\"%s\"" c (string_of_word w)


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
        (fun (tr, (cm, nc)) ->
          print_endline (string_of_trace tr);
          for i=0 to (nc-1) do
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
    a • b
*)
let t5 = Dot(Symb 'a', Symb 'b'), "a"
(*
    a • b
*)
let t6 = Dot(Or(Symb 'a', Symb 'a'), Symb 'b'), "ab"
(*
    (a | a) • b
*)
let t7 = Dot(Dot(Symb 'a', Symb 'b'), Symb 'c'), "abc"
(*
    (a • b) • c
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
    (a • b | a) • (c | b • c)
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
    ((a* | b)* • c)*
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
    a* • a*
*)
let t17 = Group(Symb 'a'), "a"
(*
    [a]
*)
let t18 = Dot(Symb 'a', Group (Dot(Symb 'b', Dot(Group (Symb 'c'), Dot(Symb 'd', Group(Symb 'e')))))), "abcde"
(*
    a • [b [c] d [e]]
*)
let t19 = Dot(Star (Symb 'a'), Star (Symb 'a')), "aaa"
(*
    a* • a*
*)
let t20 = Dot(Group(Symb 'a'), Dot(Ref 0, Symb 'b')), "aab"
(*
    [a] \0 b
*)
let t21 = Star(Group(Or(Dot(Ref 0, Symb 'a'), Symb 'b'))), "bba"
(*
    [\0 a | b]*
*)
let t22 = Star(Star(Group(Symb 'b'))), "bbb"
(*
    [b]**
*)
let t23 = Star(Or(Dot(Ref 0, Symb 'a'), Group(Symb 'b'))), "bba"
(*
    (\0 a | [b])*
*)


let _ = test t1
let _ = test t2
let _ = test t3
let _ = test t4
let _ = test t5
let _ = test t6
let _ = test t7
let _ = test t8
let _ = test t9
let _ = test t10
let _ = test t11
let _ = test t12
let _ = test t13
let _ = test t14
let _ = test t15
let _ = test t16
let _ = test t17
let _ = test t18
let _ = test t19
let _ = test t20
let _ = test t21
let _ = test t22
let _ = test t23