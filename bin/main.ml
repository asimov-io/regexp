open Regexp

module M = Necromonads.List

module Types = struct
  type symb = char
  type lett = char
  type word = lett list
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
end

open MakeInterpreter(Spec)

let to_list (w : string) = List.init (String.length w) (String.get w)

let testnb = ref 0
let test t =
  incr testnb;
  Printf.printf "\nTEST n°%d:\n" (!testnb);
  let e, w = t in
  let w_list = to_list w in
  let l = eval (e, w_list) in
  match l with
    | [] -> Printf.printf "Non reconnu\n"
    | _ -> Printf.printf "Reconnu de %d façons\n" (List.length l)

let t1 = Plus(Plus(Symb 'a', Symb 'b'), Symb 'c'), "c"

let t2 = Plus(Symb 'a', Symb 'b'), "c"

let t3 = Plus(Plus(Symb 'a', Symb 'b'), Symb 'a'), "a"

let t4 = Dot(Symb 'a', Symb 'b'), "ab"

let t5 = Dot(Symb 'a', Symb 'b'), "a"

let t6 = Dot(Plus(Symb 'a', Symb 'a'), Symb 'b'), "ab"

let t7 = Dot(Dot(Symb 'a', Symb 'b'), Symb 'c'), "abc"

let t8 = Dot(
  Plus(
    Dot(Symb 'a', Symb 'b'),
    Symb 'a'
  ),
  Plus(
    Symb 'c',
    Dot(Symb 'b', Symb 'c')
  )
), "abc"

let t9 = Star(Symb 'a'), "aa"

let t10 = Star(Star(Symb 'a')), "aa"

let e11 = 
  Star(
    Dot(
      Star(
        Plus(
          Star(Symb 'a'),
          Symb 'b'
        )
      ),
      Symb 'c'
    )
  )

let t11 = e11, "abba"

let t12 = e11, "abccaac"

let t13 = Star(Star(Symb 'a')), "aaaaaa"

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