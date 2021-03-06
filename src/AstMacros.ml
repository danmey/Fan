
open AstLoc;
(*
  {:macro|M a b c|}

  {:macro|fib 32 |}

  {:defmacro|fib a b =
  
  |}

  challegens lie in how to extract the
  macro name, and apply

  fib 32 -->
     fib 31 + fib 30

     -- `App
     --
  {:stru| g |};

  -- macro.exp
     

  -- macro.stru
     `StExp ..  

  1. the position where macro quotation appears
     - cstru
       combine with translate, this should be inferred automatically


  2. the position where macro expander appears?
     currently only exp

  3. the type macro expander
     - macro.cstru should generate cstru 

  4. register

  5. dependency

  Guarantee:
    macro.exp should return exp
    macro.stru should return stru 
 *)
type key = string;

type expander =  exp -> exp;

(*
   exp -> stru
*)
  
let macro_expanders: Hashtbl.t key expander = Hashtbl.create 40 ;

let register_macro (k,f) =
  Hashtbl.replace macro_expanders k f;

let rec fib = fun
  [ 0 | 1 ->  1
  | n when n > 0 -> fib (n-1) + fib (n-2)
  | _ -> invalid_arg "fib" ];

(* {:exp| f a b c|}
   don't support currying
   always
   f a
   or f (a,b,c)
   {:exp| f (a,b,c) |}
 *)
  
let fibm  y =
  match y with
  [ {:exp|$int:x|}  -> {:exp| $(`int:fib (int_of_string x))|}
  |  x -> let _loc = loc_of x in {:exp| fib $x |} ];

register_macro ("FIB",fibm);      

open LibUtil;
    
(* let generate_fibs = with exp fun *)
(*   [ {:exp|$int:x|} -> *)
(*     let j = int_of_string x in *)
(*     let res = zfold_left ~until:j ~acc:{||} (fun acc i -> {| $acc; print_int (FIB $`int:i) |}) in *)
(*     {:exp| $seq:res |} *)
(*     (\* Array.map (fun i -> {|print_int (FIB $`int:i) |} ) *\) *)
(*     (\* {:exp| for _j = 0 to $int:x do print_int (FIB _j) done |} *\) *)
(*   | e -> e ]; *)

(* register_macro ("GFIB", generate_fibs);     *)

(*
#filter "macro";;
GFIB 10;
(* let u x = *)
  [FIB 13;
   FIB 13;
   FIB x]
   ;
(*
  {:exp| [FIB 13; FIB 13; FIB x ] |}
 *)

*)
    

let macro_expander = object(self)
  inherit Objs.map as super;
  method! exp = with exp fun
  [{| $uid:a $y |} ->
    let try f = Hashtbl.find macro_expanders a in
    self#exp (f y)
    with Not_found -> {| $uid:a $(self#exp y)|}
  | e -> super#exp e ];
end;

(* AstFilters.register_stru_filter ("macro", macro_expander#stru);   *)
