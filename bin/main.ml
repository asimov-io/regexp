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

  let head (w: word) = match w with
    | [] -> M.fail ()
    | l :: _ -> M.ret l
  
  let tail (w: word) = match w with
    | [] -> M.fail ()
    | _ :: t -> M.ret t

  let isempty (w: word) = match w with
    | [] -> M.ret ()
    | _ -> M.fail ()
    
end

open MakeInterpreter(Spec)


let test t =
  let _ = M.extract (eval t) in
  Printf.printf "Reconnu\n"


let t1 = Plus(Plus(Symb 'a', Symb 'b'), Symb 'c'), ['d']


let _ = test t1