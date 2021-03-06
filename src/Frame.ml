
#default_quotation "exp";;
open AstLoc;


open Format;
open LibUtil;
open Lib;
open Lib.Basic;
open FSig;

open Lib.EP;
open Lib.Expr;

(* preserved keywords for the generator *)
let preserve =  ["self"; "self_type"; "unit"; "result"];

let check names =
    (* we preserve some keywords to avoid variable capture *)
  List.iter (fun name ->
    if List.mem name preserve  then begin 
      eprintf "%s is not a valid name\n" name;
      eprintf "preserved keywords:\n";
      List.iter (fun s -> eprintf "%s\n" s) preserve;
      exit 2
    end
    else check_valid name) names;

(* +-----------------------------------------------------------------+
   | utilities                                                       |
   +-----------------------------------------------------------------+ *)
  
(* collect the [partial evaluated Ast node]
   and meta data
   The input [y] is handled by
   [simple_exp_of_ctyp], generally it will
   be  exlcuding adt or variant type
 *)      
let mapi_exp ?(arity=1) ?(names=[])
    ~f:(f:(ctyp->exp))
    (i:int) (ty : ctyp)  :
    FSig.ty_info =
  with {pat:ctyp;exp}
  let name_exp = f ty in 
  let base = name_exp  +> names in
  (** FIXME as a tuple it is useful when arity> 1??? *)
  let id_exps =
    (List.init arity (fun index  -> {| $(id:xid ~off:index i) |} )) in 
  let exp0 = List.hd id_exps in 
  let id_pats = id_exps in
  let pat0 = exp0 in
  let id_exp = tuple_com  id_exps  in
  let id_pat = id_exp in
  let exp = appl_of_list [base:: id_exps]  in
  {name_exp; exp; id_exp; id_exps; id_pat;id_pats;exp0;pat0;ty};       

(* @raise Invalid_argument when type can not be handled *)  
let tuple_exp_of_ctyp ?(arity=1) ?(names=[]) ~mk_tuple
    simple_exp_of_ctyp (ty:ctyp) : exp =
  match ty with
  [ `Tup (_loc,t)  -> 
    let ls = list_of_star t [] in
    let len = List.length ls in
    let pat = EP.mk_tuple ~arity ~number:len in
    let tys =
      List.mapi
        (mapi_exp ~arity ~names  ~f:simple_exp_of_ctyp) ls in
    names <+ (currying
                  [ {:case| $pat:pat -> $(mk_tuple tys ) |} ] ~arity)
  | _  ->
      FanLoc.errorf _loc
        "tuple_exp_of_ctyp %s" (Objs.dump_ctyp ty)];
  
(*
 @supported types type application: list int
     basic type: int
     product type: (int * float * int)
 [m_list
 (fun _loc fmt ((a0, a1, a2), (b0, b1, b2)) ->
   ((m_int _loc fmt (a0, b0)), (m_float _loc fmt (a0, b0)),
    (m_float _loc fmt (a0, b0))))]
 return type is result
Plz supply current type [type list 'a] =>  [list]
 *)    
let rec  normal_simple_exp_of_ctyp
    ?arity ?names ~mk_tuple
    ~right_type_id ~left_type_id
    ~right_type_variable
    cxt ty = 
  let open Transform in
  let right_trans = transform right_type_id in
  let left_trans = basic_transform left_type_id in 
  let tyvar = right_transform right_type_variable  in 
  let rec aux = with {pat:ctyp;exp} fun
    [ `Id(_loc,`Lid(_,id)) -> 
      if Hashset.mem cxt id then {| $(lid:left_trans id) |}
      else right_trans {:ident| $lid:id |} 
    | `Id (_loc,id) ->   right_trans id (* recursive call here *)
    | `App(_loc,t1,t2) ->
        {| $(aux t1) $(aux t2) |}
    | `Quote (_loc,_,`Lid(_,s)) ->   tyvar s
    | `Arrow(_loc,t1,t2) ->
        aux {:ctyp| arrow $t1 $t2 |} (* arrow is a keyword now*)
    | `Tup _  as ty ->
        tuple_exp_of_ctyp  ?arity ?names ~mk_tuple
          (normal_simple_exp_of_ctyp
             ?arity ?names ~mk_tuple
             ~right_type_id ~left_type_id ~right_type_variable
             cxt) ty 
    | ty ->
        FanLoc.errorf (loc_of ty) "normal_simple_exp_of_ctyp : %s"
          (Objs.dump_ctyp ty)] in
  aux ty;




(*
   list int ==>
      self#list (fun self -> self#int)
   list 'a  ==>
       self#list mf_a 
   'a  ==> (mf_a self)

  list (list 'a) ==>
      self#list (fun self -> (self#list mf_a))

  m_list (tree 'a) ==>
      self#m_list (fun self -> self#tree mf_a)
 *)      
let rec obj_simple_exp_of_ctyp ~right_type_id ~left_type_variable ~right_type_variable
    ?names ?arity ~mk_tuple ty = with {pat:ctyp}
  let open Transform in 
  let trans = transform right_type_id in
  let var = basic_transform left_type_variable in
  let tyvar = right_transform right_type_variable  in 
  let rec aux = fun
    [ `Id (_loc,id) -> trans id
    | `Quote(_loc,_,`Lid(_,s)) ->   tyvar s
    | `App _  as ty ->
        match  list_of_app ty []  with
        [ [ {| $id:tctor |} :: ls ] ->
          appl_of_list [trans tctor::
                        (ls |> List.map
                          (fun
                            [ `Quote (_loc,_,`Lid(_,s)) -> {:exp| $(lid:var s) |} 
                            | t ->   {:exp| fun self -> $(aux t) |} ])) ]
        | _  ->
            FanLoc.errorf  (loc_of ty)
              "list_of_app in obj_simple_exp_of_ctyp: %s"
              (Objs.dump_ctyp ty)]
    | `Arrow(_loc,t1,t2) -> 
        aux {:ctyp| arrow $t1 $t2 |} 
    | `Tup _  as ty ->
        tuple_exp_of_ctyp ?arity ?names ~mk_tuple
          (obj_simple_exp_of_ctyp ~right_type_id ~left_type_variable
             ~right_type_variable ?names ?arity ~mk_tuple) ty 
    | ty ->
        FanLoc.errorf (loc_of ty) "obj_simple_exp_of_ctyp: %s" (Objs.dump_ctyp ty) ] in
  aux ty ;

(*
  accept [simple_exp_of_ctyp]
  call [reduce_data_ctors]  for [sum types]
  assume input is  [sum type]
  accept input type to generate  a function expession 
 *)  
let exp_of_ctyp
    ?cons_transform
    ?(arity=1)
    ?(names=[])
    ~trail ~mk_variant
    simple_exp_of_ctyp (ty : or_ctyp)  =
  let f  (cons:string) (tyargs:list ctyp)  : case = 
    let args_length = List.length tyargs in  (* ` is not needed here *)
    let p : pat =
      (* calling gen_tuple_n*)
      EP.gen_tuple_n ?cons_transform ~arity  cons args_length in
    let mk (cons,tyargs) =
      let exps = List.mapi (mapi_exp ~arity ~names ~f:simple_exp_of_ctyp) tyargs in
      mk_variant cons exps in
    let e = mk (cons,tyargs) in
    {:case| $pat:p -> $e |} in  begin 
    let info = (Sum, List.length (list_of_or ty [])) in 
    let res : list case =
      Ctyp.reduce_data_ctors ty  [] f ~compose:cons  in
    let res =
      let t = (* only under this case we need trailing  *)
        if List.length res >= 2 && arity >= 2 then
          match trail info with [Some x-> [x::res] | None -> res ]
          (* [ trail info :: res ] *)
        else res in
      List.rev t in 
    currying ~arity res 
  end;

(* return a [exp] node
   accept [variant types]
 *)  
let exp_of_variant ?cons_transform ?(arity=1)?(names=[]) ~trail ~mk_variant ~destination
    simple_exp_of_ctyp result ty = with {pat:ctyp;exp:case}
  let f (cons,tyargs) :  case=
    let len = List.length tyargs in
    let p = EP.gen_tuple_n ?cons_transform ~arity cons len in
    let mk (cons,tyargs) =
      let exps = List.mapi (mapi_exp ~arity ~names ~f:simple_exp_of_ctyp) tyargs in
      mk_variant cons exps in
    let e = mk (cons,tyargs) in
    {| $pat:p -> $e |} in 
  (* for the case [`a | b ] *)
  let simple lid :case=
    let e = (simple_exp_of_ctyp {:ctyp|$id:lid|}) +> names  in
    let (f,a) = view_app [] result in
    let annot = appl_of_list [f :: List.map (fun _ -> {:ctyp|_|}) a] in
    MatchCase.gen_tuple_abbrev ~arity ~annot ~destination lid e in
  (* FIXME, be more precise  *)
  let info = (TyVrnEq, List.length (list_of_or ty [])) in
  let ls = Ctyp.view_variant ty in
  let res =
    let res = List.fold_left
      (fun  acc x ->
        match x with
        [ (`variant (cons,args)) -> [f ("`"^cons,args)::acc]
        | `abbrev (lid) ->  [simple lid :: acc ] ])  [] ls in
  let t =
    if List.length res >= 2 && arity >= 2 then
      match trail info with [Some x-> [x::res] | None -> res ]
      (* [trail info :: res] *)
    else res in
  List.rev t in
  currying ~arity res ;

(* add extra arguments to the generated expession node
 *)  
let mk_prefix (vars:opt_decl_params) (acc:exp) ?(names=[])  ~left_type_variable=
  let open Transform in 
  let varf = basic_transform left_type_variable in
  let  f (var:decl_params) acc =
    match var with
    [ `Quote(_,_,`Lid(_loc,s)) ->
        {| fun $(lid: varf s) -> $acc |}
    | t  ->
        FanLoc.errorf (loc_of t) "mk_prefix: %s" (Objs.dump_decl_params t)] in
  match vars with
  [`None _ -> (names <+ acc)
  |`Some(_,xs) ->
      let vars = list_of_com xs [] in
      List.fold_right f vars (names <+ acc)
  ];  
  (* let xs  = list_of_com vars [] in *)
  (* List.fold_right f vars ( names <+ acc); *)


(* +-----------------------------------------------------------------+
   | Combine the utilities together                                  |
   +-----------------------------------------------------------------+ *)
  
(*
  Given type declarations, generate corresponding
  Ast node represent the [function]
  (combine both exp_of_ctyp and simple_exp_of_ctyp) *)  
let fun_of_tydcl
    ?(names=[]) ?(arity=1) ~left_type_variable ~mk_record ~destination ~result_type
    simple_exp_of_ctyp exp_of_ctyp exp_of_variant  tydcl :exp = 
    match (tydcl:typedecl) with 
    [ `TyDcl (_, _, tyvars, ctyp, _constraints) ->
      (* let ctyp = *)
       match ctyp with
       [  `TyMan(_,_,_,repr) | `TyRepr(_,_,repr) ->
         match repr with
         [`Record(_loc,t) ->       
           let cols =  Ctyp.list_of_record t  in
           let pat = (EP.mk_record ~arity  cols  : pat)in
           let info =
             List.mapi
               (fun i x ->  match x with
                 [ {col_label;col_mutable;col_ctyp} ->
                     {re_info = (mapi_exp ~arity ~names ~f:simple_exp_of_ctyp) i col_ctyp  ;
                      re_label = col_label;
                      re_mutable = col_mutable}
                 ] ) cols in
        (* For single tuple pattern match this can be optimized
           by the ocaml compiler *)
        mk_prefix ~names ~left_type_variable tyvars
            (currying ~arity [ {:case| $pat:pat -> $(mk_record info)  |} ])

       |  `Sum (_,ctyp) -> 
          let funct = exp_of_ctyp ctyp in  
          (* for [exp_of_ctyp] appending names was delayed to be handled in mkcon *)
          mk_prefix ~names ~left_type_variable tyvars funct
       | t ->
          FanLoc.errorf (loc_of t) "fun_of_tydcl outer %s" (Objs.dump_type_repr t) ]
    | `TyEq(_,_,ctyp) ->
        match ctyp with 
        [ (`Id _ | `Tup _ | `Quote _ | `Arrow _ | `App _ as x) ->
          let exp = simple_exp_of_ctyp x in
          let funct = eta_expand (exp+>names) arity  in
          mk_prefix ~names ~left_type_variable tyvars funct
        | `PolyEq(_,t) | `PolySup(_,t) | `PolyInf(_,t)|`PolyInfSup(_,t,_) -> 
            let case =  exp_of_variant result_type t  in
            mk_prefix ~names ~left_type_variable tyvars case
        | t -> FanLoc.errorf  (loc_of t)"fun_of_tydcl inner %s" (Objs.dump_ctyp t)]
    | t -> FanLoc.errorf (loc_of t) "fun_of_tydcl middle %s" (Objs.dump_type_info t)]
   | t -> FanLoc.errorf (loc_of t) "fun_of_tydcl outer %s" (Objs.dump_typedecl t)] ;             

(* destination is [Str_item] generate [stru], type annotations may
   not be needed here
 *)          
let binding_of_tydcl ?cons_transform simple_exp_of_ctyp
    tydcl ?(arity=1) ?(names=[]) ~trail ~mk_variant
    ~left_type_id ~left_type_variable
    ~mk_record = with {pat:ctyp}
  let open Transform in 
  let tctor_var = basic_transform left_type_id in
  let (name,len) = Ctyp.name_length_of_tydcl tydcl in 
  let (ty,result_type) = Ctyp.mk_method_type_of_name
      ~number:arity ~prefix:names (name,len) Str_item in
  if not ( Ctyp.is_abstract tydcl) then 
    let fun_exp =
      fun_of_tydcl  ~destination:Str_item
        ~names ~arity ~left_type_variable ~mk_record  ~result_type
        simple_exp_of_ctyp
        (exp_of_ctyp
           ?cons_transform ~arity ~names ~trail ~mk_variant simple_exp_of_ctyp)
        (exp_of_variant
           ?cons_transform 
           ~arity ~names ~trail ~mk_variant
           ~destination:Str_item
           simple_exp_of_ctyp) tydcl  in
    (* {:binding| $(lid:tctor_var name) : $ty = $fun_exp |} *)
    {:binding| $(lid:tctor_var name) = $fun_exp |}
  else begin
    eprintf "Warning: %s as a abstract type no structure generated\n"
      (Objs.dump_typedecl tydcl);
    {:binding| $(lid:tctor_var  name) =
    failwithf $(str:"Abstract data type not implemented") |};
  end ;

let stru_of_module_types ?module_name ?cons_transform
    ?arity ?names ~trail ~mk_variant ~left_type_id ~left_type_variable
    ~mk_record
    (* ~destination *)
    simple_exp_of_ctyp_with_cxt
    (lst:module_types)  =
  let cxt  = Hashset.create 50 in 
  let mk_binding (* : string -> ctyp -> binding *) =
    binding_of_tydcl ?cons_transform ?arity
      ?names ~trail ~mk_variant ~left_type_id ~left_type_variable ~mk_record
      (* ~destination *)
      (simple_exp_of_ctyp_with_cxt cxt) in
  (* return new types as generated  new context *)
  let fs (ty:types) : stru= match ty with
    [ `Mutual named_types ->
      (* let binding = *)
      match named_types with
      [ [] -> {:stru| let _ = ()|} (* FIXME *)
      | xs -> begin 
          List.iter (fun (name,_ty)  -> Hashset.add cxt name) xs ;
          let binding = List.reduce_right_with
              ~compose:(fun x y -> {:binding| $x and $y |} )
              ~f:(fun (_name,ty) ->begin
                mk_binding  ty;
              end ) xs;
         {:stru| let rec $binding |} 
      end ]

    | `Single (name,tydcl) -> begin 
        Hashset.add cxt name;
        let rec_flag =
          if Ctyp.is_recursive tydcl then `Recursive _loc
          else `ReNil  _loc
        and binding = mk_binding  tydcl in 
        {:stru| let $rec:rec_flag  $binding |}
    end ] in
  let item =
    match lst with
    [[] -> {:stru|let _ = ()|}
    | _ ->  sem_of_list (List.map fs lst ) ]  in
  match module_name with
  [ None -> item
  | Some m -> {:stru| module $uid:m = struct $item end |} ];


 (*
   Generate warnings for abstract data type
   and qualified data type.
   all the types in one module will derive a class 
  *)
let obj_of_module_types
    ?cons_transform
    ?module_name
    ?(arity=1) ?(names=[]) ~trail  
    ~left_type_variable:(left_type_variable:FSig.basic_id_transform)
    ~mk_record
    ~mk_variant
     base
    class_name  simple_exp_of_ctyp (k:kind) (lst:module_types) : stru = with {pat:ctyp}
  let tbl = Hashtbl.create 50 in 
    let f tydcl result_type =
      fun_of_tydcl ~names ~destination:(Obj k)
        ~arity ~left_type_variable
        ~mk_record 
        simple_exp_of_ctyp
        (exp_of_ctyp ?cons_transform
           ~arity ~names
           ~trail ~mk_variant
           simple_exp_of_ctyp)
        (exp_of_variant ?cons_transform
           ~destination:(Obj k)
           ~arity ~names
           ~trail ~mk_variant
           simple_exp_of_ctyp) ~result_type tydcl in
    let mk_type tydcl =
        let (name,len) = Ctyp.name_length_of_tydcl tydcl in
        let (ty,result_type) = Ctyp.mk_method_type ~number:arity ~prefix:names ({:ident| $lid:name |} ,len )
            (Obj k) in
        (ty,result_type) in
        
    let mk_cstru (name,tydcl) : cstru = 
      let (ty,result_type) = mk_type tydcl in
      {:cstru| method $lid:name : $ty = $(f tydcl result_type) |}  in 
    let fs (ty:types) : cstru =
      match ty with
      [ `Mutual named_types ->
        sem_of_list (List.map mk_cstru named_types)
      | `Single ((name,tydcl) as  named_type) ->
         match Ctyp.abstract_list tydcl with
         [ Some n  -> begin
           let ty_str =  (* (Ctyp.to_string tydcl) FIXME *) "" in
           let () = Hashtbl.add tbl ty_str (Abstract ty_str) in 
           let (ty,_) = mk_type tydcl in
           {:cstru| method $lid:name : $ty= $(unknown n) |}
         end
         | None ->  mk_cstru named_type ]] in 
      (* Loc.t will be translated to loc_t
       we need to process extra to generate method loc_t *)
    let (extras,lst) = Ctyp.transform_module_types lst in 
    let body = List.map fs lst in 
    let body : cstru =
      let items = List.map (fun (dest,src,len) ->
        let (ty,_dest) = Ctyp.mk_method_type ~number:arity ~prefix:names (src,len) (Obj k) in
        let () = Hashtbl.add tbl dest (Qualified dest) in
        {:cstru| method
            $lid:dest : $ty = $(unknown len) |} ) extras in
      sem_of_list (body @ items) in begin 
        let v = Ctyp.mk_obj class_name  base body;
        Hashtbl.iter (fun _ v ->
          eprintf "@[%a@]@." FSig.pp_print_warning_type  v)
            tbl;
        match module_name with
        [None -> v
        |Some u -> {:stru| module $uid:u = struct $v  end  |} ]  
      end ;
  
  

(*   check S.names; *)





















