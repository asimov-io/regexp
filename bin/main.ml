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

  let get (c, (cm, _)) =
    let wo = CMap.find c cm in
    match wo with
      | None -> M.fail ()
      | Some w -> M.ret w
  
end

open MakeInterpreter(Spec)

let word_of_string (s : string) = List.init (String.length s) (String.get s)

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
  | TrDotL -> "("
  | TrDotR -> ")"
  | TrStarL -> "{"
  | TrStarR -> "}"

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
        (fun (_, tr, (cm, nc)) ->
          print_endline (string_of_trace tr);
          for i=0 to (nc-1) do
            Printf.printf "Groupe %d:\n" i;
            match (CMap.find i cm) with
              | None -> ()
              | Some w -> List.iter (fun l -> print_char l) w
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
    a • a
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