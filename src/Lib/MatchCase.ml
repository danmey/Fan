#default_quotation "case";;
open LibUtil;




open AstLoc;
open Basic;
(*
  An ad-hoc solution for [`a|a|`b] code generation, to imporove later
 *)
let gen_tuple_abbrev  ~arity ~annot ~destination name e  =
  (* let annot = Ctyp.mk_dest_type *)
  let args : list pat =
    List.init arity (fun i ->
       (* `Alias (_loc, (`PaTyp (_loc, name)), (xid ~off:i 0 (\* :> ident *\)))) (\* FIXME *\) *)
      {:pat| (#$id:name as $(lid: x ~off:i 0 )) |})in
  let exps = List.init arity (fun i -> {:exp| $(id:xid ~off:i 0) |} ) in
  let e = appl_of_list [e:: exps] in 
  let pat = args |>tuple_com in
  let open FSig in
  match destination with
  [Obj(Map) ->
     {| $pat:pat -> ( $e : $id:name :> $annot) |}
  |_ ->
      {| $pat:pat -> ( $e  :> $annot) |}
  ]
    ;  
 


(* {:pat| (#$id:x as y)|} *)

















