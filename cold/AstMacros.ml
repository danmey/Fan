open AstLoc
type key = string 
type expander = exp -> exp 
let macro_expanders: (key,expander) Hashtbl.t = Hashtbl.create 40
let register_macro (k,f) = Hashtbl.replace macro_expanders k f
let rec fib =
  function
  | 0|1 -> 1
  | n when n > 0 -> (fib (n - 1)) + (fib (n - 2))
  | _ -> invalid_arg "fib"
let fibm y =
  match y with
  | `Int (_loc,x) -> `Int (_loc, (string_of_int (fib (int_of_string x))))
  | x ->
      let _loc = loc_of x in
      `App (_loc, (`Id (_loc, (`Lid (_loc, "fib")))), x)
let _ = register_macro ("FIB", fibm)
open LibUtil
let macro_expander =
  object (self)
    inherit  Objs.map as super
    method! exp =
      function
      | `App (_loc,`Id (_,`Uid (_,a)),y) ->
          ((try
              let f = Hashtbl.find macro_expanders a in
              fun ()  -> self#exp (f y)
            with
            | Not_found  ->
                (fun ()  ->
                   `App (_loc, (`Id (_loc, (`Uid (_loc, a)))), (self#exp y)))))
            ()
      | e -> super#exp e
  end