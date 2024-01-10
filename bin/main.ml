open Regexp

module M = Necromonads.List

module IMap = Map.Make(Stdlib.Int)

module Types = struct
  type symb = char
  type lett = char
  type word = lett list
  type loc = int
  type heap = (word option) IMap.t * int
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
    IMap.empty, 0

  let alloc (m, ln) =
    let m' = IMap.add ln None m in
    M.ret (ln, (m', ln + 1))

  let set (l, v, (m, ln)) =
    let m' = IMap.add l (Some v) m in
    M.ret (m', ln)

  let get (l, (m, _)) =
    let vo = IMap.find l m in
    match vo with
      | None -> M.fail ()
      | Some v -> M.ret v
  
end

open MakeInterpreter(Spec)

let word_of_string (s : string) = List.init (String.length s) (String.get s)

let list_of_trace tr =
  let rec aux acc tr =
    match tr with
    | Nil -> acc
    | Elt e -> e :: acc
    | Conc (tr1, tr2) ->
      let acc2 = aux acc tr2 in
      aux acc2 tr1
  in
  aux [] tr

let string_of_elt e = match e with
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
  let l = exec (e, w) in
  match l with
    | [] -> Printf.printf "Non reconnu\n"
    | _ ->
      Printf.printf "Reconnu de %d façon(s):\n" (List.length l);
      List.iter
        (fun x -> let (_, tr, (m, ln)) = x in
          print_endline (string_of_trace tr);
          print_int ln;
          for i=0 to (ln-1) do
            Printf.printf "Groupe %d:\n" i;
            match (IMap.find i m) with
              | None -> ()
              | Some w -> List.iter (fun l -> print_char l) w
          done
        )
        l

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