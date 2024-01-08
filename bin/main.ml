open Regexp

module M = Necromonads.ID

module Types = struct
  type symb = char
  type lett = char
  type word = Buffer.t
end

module Spec = struct
  include Unspec(M)(Types)

  let lett_of_symb (s: symb) = s

  let equal ((s: symb), (l: lett)) =
    match (s = l) with
    | true -> True
    | false -> False
  
  let isempty (w: word) =
    if w.length = 0 then M.ret () else M.fail ()
  
  let head (w: word) =
    
end

open MakeInterpreter(Spec)

let t1 = Plus(Plus(Symb 'a', Symb 'b'), Symb 'c'), 

let test 