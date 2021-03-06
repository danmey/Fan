open AstLoc
open LibUtil
open Easy
open FSig
open Lib
open Lib.Expr
let _loc = FanLoc.ghost
let mk_variant_eq _cons =
  (function
   | [] -> `Id (_loc, (`Lid (_loc, "true")))
   | ls ->
       List.reduce_left_with
         ~compose:(fun x  y  ->
                     `App
                       (_loc,
                         (`App (_loc, (`Id (_loc, (`Lid (_loc, "&&")))), x)),
                         y)) ~f:(fun { exp;_}  -> exp) ls : FSig.ty_info list
                                                              -> exp )
let mk_tuple_eq exps = mk_variant_eq "" exps
let mk_record_eq: FSig.record_col list -> exp =
  fun cols  ->
    (cols |> (List.map (fun { re_info;_}  -> re_info))) |> (mk_variant_eq "")
let (gen_eq,gen_eqobj) =
  ((gen_stru ~id:(`Pre "eq_") ~names:[] ~arity:2 ~mk_tuple:mk_tuple_eq
      ~mk_record:mk_record_eq ~mk_variant:mk_variant_eq
      ~trail:(`Id (_loc, (`Lid (_loc, "false")))) ()),
    (gen_object ~kind:Iter ~mk_tuple:mk_tuple_eq ~mk_record:mk_record_eq
       ~base:"eqbase" ~class_name:"eq" ~mk_variant:mk_variant_eq ~names:[]
       ~arity:2 ~trail:(`Id (_loc, (`Lid (_loc, "false")))) ()))
let _ = [("Eq", gen_eq); ("OEq", gen_eqobj)] |> (List.iter Typehook.register)
let (gen_fold,gen_fold2) =
  let mk_variant _cons params =
    (params |> (List.map (fun { exp;_}  -> exp))) |>
      (function
       | [] -> `Id (_loc, (`Lid (_loc, "self")))
       | ls ->
           List.reduce_right
             (fun v  acc  ->
                `LetIn
                  (_loc, (`ReNil _loc),
                    (`Bind (_loc, (`Id (_loc, (`Lid (_loc, "self")))), v)),
                    acc)) ls) in
  let mk_tuple = mk_variant "" in
  let mk_record cols =
    (cols |> (List.map (fun { re_info;_}  -> re_info))) |> (mk_variant "") in
  ((gen_object ~kind:Fold ~mk_tuple ~mk_record ~base:"foldbase"
      ~class_name:"fold" ~mk_variant ~names:[] ()),
    (gen_object ~kind:Fold ~mk_tuple ~mk_record ~base:"foldbase2"
       ~class_name:"fold2" ~mk_variant ~names:[] ~arity:2
       ~trail:(`App
                 (_loc, (`Id (_loc, (`Lid (_loc, "invalid_arg")))),
                   (`Str (_loc, "fold2 failure")))) ()))
let _ =
  [("Fold", gen_fold); ("Fold2", gen_fold2)] |> (List.iter Typehook.register)
let (gen_map,gen_map2) =
  let mk_variant cons params =
    let result =
      appl_of_list ((EP.of_str cons) ::
        (params |> (List.map (fun { exp0;_}  -> exp0)))) in
    List.fold_right
      (fun { exp; pat0;_}  res  ->
         `LetIn (_loc, (`ReNil _loc), (`Bind (_loc, pat0, exp)), res)) params
      result in
  let mk_tuple params =
    let result = (params |> (List.map (fun { exp0;_}  -> exp0))) |> tuple_com in
    List.fold_right
      (fun { exp; pat0;_}  res  ->
         `LetIn (_loc, (`ReNil _loc), (`Bind (_loc, pat0, exp)), res)) params
      result in
  let mk_record cols =
    let result =
      (cols |>
         (List.map
            (fun { re_label; re_info = ({ exp0;_} as info);_}  ->
               let _ = Obj.repr info in (re_label, exp0))))
        |> mk_record in
    List.fold_right
      (fun { re_info = { exp; pat0;_};_}  res  ->
         `LetIn (_loc, (`ReNil _loc), (`Bind (_loc, pat0, exp)), res)) cols
      result in
  ((gen_object ~kind:Map ~mk_tuple ~mk_record ~base:"mapbase"
      ~class_name:"map" ~mk_variant ~names:[] ()),
    (gen_object ~kind:Map ~mk_tuple ~mk_record ~base:"mapbase2"
       ~class_name:"map2" ~mk_variant ~names:[] ~arity:2
       ~trail:(`App
                 (_loc, (`Id (_loc, (`Lid (_loc, "invalid_arg")))),
                   (`Str (_loc, "map2 failure")))) ()))
let _ =
  [("Map", gen_map); ("Map2", gen_map2)] |> (List.iter Typehook.register)
let gen_strip =
  let mk_variant cons params =
    let params' =
      List.filter
        (function | { ty = `Id (_loc,`Lid (_,"loc"));_} -> false | _ -> true)
        params in
    let result =
      appl_of_list ((EP.of_str cons) ::
        (params' |> (List.map (fun { exp0;_}  -> exp0)))) in
    List.fold_right
      (fun { exp; pat0; ty;_}  res  ->
         match ty with
         | `Id (_loc,`Lid (_,"int"))|`Id (_loc,`Lid (_,"string"))
           |`Id (_loc,`Lid (_,"int32"))|`Id (_loc,`Lid (_,"nativeint"))
           |`Id (_loc,`Lid (_,"loc"))
           |`Id (_loc,`Dot (_,`Uid (_,"FanUtil"),`Lid (_,"anti_cxt"))) -> res
         | _ -> `LetIn (_loc, (`ReNil _loc), (`Bind (_loc, pat0, exp)), res))
      params' result in
  let mk_tuple params =
    let result = (params |> (List.map (fun { exp0;_}  -> exp0))) |> tuple_com in
    List.fold_right
      (fun { exp; pat0; ty;_}  res  ->
         match ty with
         | `Id (_loc,`Lid (_,"int"))|`Id (_loc,`Lid (_,"string"))
           |`Id (_loc,`Lid (_,"int32"))|`Id (_loc,`Lid (_,"nativeint"))
           |`Id (_loc,`Lid (_,"loc"))
           |`Id (_loc,`Dot (_,`Uid (_,"FanUtil"),`Lid (_,"anti_cxt"))) -> res
         | _ -> `LetIn (_loc, (`ReNil _loc), (`Bind (_loc, pat0, exp)), res))
      params result in
  let mk_record cols =
    let result =
      (cols |>
         (List.map
            (fun { re_label; re_info = { exp0;_};_}  -> (re_label, exp0))))
        |> mk_record in
    List.fold_right
      (fun { re_info = { exp; pat0; ty;_};_}  res  ->
         match ty with
         | `Id (_loc,`Lid (_,"int"))|`Id (_loc,`Lid (_,"string"))
           |`Id (_loc,`Lid (_,"int32"))|`Id (_loc,`Lid (_,"nativeint"))
           |`Id (_loc,`Lid (_,"loc"))
           |`Id (_loc,`Dot (_,`Uid (_,"FanUtil"),`Lid (_,"anti_cxt"))) -> res
         | _ -> `LetIn (_loc, (`ReNil _loc), (`Bind (_loc, pat0, exp)), res))
      cols result in
  gen_stru ~id:(`Pre "strip_loc_") ~mk_tuple ~mk_record ~mk_variant ~names:[]
    ()
let _ =
  Typehook.register ~filter:(fun s  -> not (List.mem s ["loc"; "ant"]))
    ("Strip", gen_strip)
let mk_variant cons params =
  let len = List.length params in
  if String.ends_with cons "Ant"
  then EP.of_vstr_number "Ant" len
  else
    (params |> (List.map (fun { exp;_}  -> exp))) |>
      (List.fold_left mee_app (mee_of_str cons))
let mk_record cols =
  (cols |>
     (List.map (fun { re_label; re_info = { exp;_};_}  -> (re_label, exp))))
    |> mk_record_ee
let mk_tuple params =
  (params |> (List.map (fun { exp;_}  -> exp))) |> mk_tuple_ee
let gen_meta_exp =
  gen_stru ~id:(`Pre "meta_") ~names:["_loc"] ~mk_tuple ~mk_record
    ~mk_variant ()
let _ =
  Typehook.register ~position:"__MetaExpr__" ~filter:(fun s  -> s <> "loc")
    ("MetaExpr", gen_meta_exp)
let gen_meta =
  gen_object ~kind:(Concrete (`Id (_loc, (`Lid (_loc, "ep"))))) ~mk_tuple
    ~mk_record ~base:"primitive" ~class_name:"meta" ~mk_variant
    ~names:["_loc"] ()
let _ =
  Typehook.register ~filter:(fun s  -> not (List.mem s ["loc"; "ant"]))
    ("MetaObj", gen_meta)
let extract info =
  (info |> (List.map (fun { name_exp; id_exp;_}  -> [name_exp; id_exp]))) |>
    List.concat
let mkfmt pre sep post fields =
  `App
    (_loc,
      (`App
         (_loc,
           (`Id
              (_loc,
                (`Dot
                   (_loc, (`Uid (_loc, "Format")), (`Lid (_loc, "fprintf")))))),
           (`Id (_loc, (`Lid (_loc, "fmt")))))),
      (`Str (_loc, (pre ^ ((String.concat sep fields) ^ post)))))
let mk_variant_print cons params =
  let len = List.length params in
  let pre =
    if len >= 1
    then
      mkfmt ("@[<1>(" ^ (cons ^ "@ ")) "@ " ")@]"
        (List.init len (fun _  -> "%a"))
    else mkfmt cons "" "" [] in
  appl_of_list (pre :: (extract params))
let mk_tuple_print params =
  let len = List.length params in
  let pre = mkfmt "@[<1>(" ",@," ")@]" (List.init len (fun _  -> "%a")) in
  appl_of_list (pre :: (extract params))
let mk_record_print cols =
  let pre =
    (cols |> (List.map (fun { re_label;_}  -> re_label ^ ":%a"))) |>
      (mkfmt "@[<hv 1>{" ";@," "}@]") in
  appl_of_list (pre ::
    ((cols |> (List.map (fun { re_info;_}  -> re_info))) |> extract))
let gen_print =
  gen_stru ~id:(`Pre "pp_print_") ~names:["fmt"] ~mk_tuple:mk_tuple_print
    ~mk_record:mk_record_print ~mk_variant:mk_variant_print ()
let gen_print_obj =
  gen_object ~kind:Iter ~mk_tuple:mk_tuple_print ~base:"printbase"
    ~class_name:"print" ~names:["fmt"] ~mk_record:mk_record_print
    ~mk_variant:mk_variant_print ()
let _ =
  [("Print", gen_print); ("OPrint", gen_print_obj)] |>
    (List.iter Typehook.register)
let mk_variant_iter _cons params =
  (match params with
   | [] -> `Id (_loc, (`Uid (_loc, "()")))
   | _ ->
       let lst =
         params |>
           (List.map
              (fun { name_exp; id_exp;_}  -> `App (_loc, name_exp, id_exp))) in
       seq_sem lst : exp )
let mk_tuple_iter params = (mk_variant_iter "" params : exp )
let mk_record_iter cols =
  let lst =
    cols |>
      (List.map
         (fun { re_info = { name_exp; id_exp;_};_}  ->
            `App (_loc, name_exp, id_exp))) in
  seq_sem lst
let gen_iter =
  gen_object ~kind:Iter ~base:"iterbase" ~class_name:"iter" ~names:[]
    ~mk_tuple:mk_tuple_iter ~mk_record:mk_record_iter
    ~mk_variant:mk_variant_iter ()
let _ = ("OIter", gen_iter) |> Typehook.register
let generate (module_types : FSig.module_types) =
  (let tbl = Hashtbl.create 30 in
   let aux (_,ty) =
     match (ty : typedecl ) with
     | `TyDcl (_,_,_,`TyEq (_,_,`PolyEq (_,t)),_) ->
         let branches = Ctyp.view_variant t in
         List.iter
           (function
            | `variant (s,ls) ->
                let arity = List.length ls in
                ((try
                    let v = Hashtbl.find tbl s in
                    fun ()  ->
                      if v <> arity
                      then failwithf "%s has diffireent arities" s
                  with | Not_found  -> (fun ()  -> Hashtbl.add tbl s arity)))
                  ()
            | _ -> ()) branches
     | _ ->
         FanLoc.errorf (loc_of ty) "generate module_types %s"
           (Objs.dump_typedecl ty) in
   let _ =
     List.iter
       (function | `Mutual tys -> List.iter aux tys | `Single t -> aux t)
       module_types in
   let case =
     Hashtbl.fold
       (fun key  arity  acc  ->
          if arity = 1
          then
            let case =
              `Case
                (_loc,
                  (`App
                     (_loc, (`Vrn (_loc, key)),
                       (`Id (_loc, (`Lid (_loc, "_loc")))))),
                  (`Id (_loc, (`Lid (_loc, "_loc"))))) in
            match acc with
            | None  -> Some case
            | Some acc -> Some (`Or (_loc, case, acc))
          else
            if arity > 1
            then
              (let pats = (`Id (_loc, (`Lid (_loc, "_loc")))) ::
                 (List.init (arity - 1) (fun _  -> `Any _loc)) in
               let case =
                 `Case
                   (_loc,
                     (`App (_loc, (`Vrn (_loc, key)), (tuple_com pats))),
                     (`Id (_loc, (`Lid (_loc, "_loc"))))) in
               match acc with
               | None  -> Some case
               | Some acc -> Some (`Or (_loc, case, acc)))
            else failwithf "arity=0 key:%s" key) tbl None in
   match case with
   | Some case ->
       `Value
         (_loc, (`ReNil _loc),
           (`Bind
              (_loc, (`Id (_loc, (`Lid (_loc, "loc_of")))),
                (`Fun (_loc, case)))))
   | None  -> failwithf "AstTypeGen.generate null case" : stru )
let _ =
  Typehook.register ~filter:(fun s  -> not (List.mem s ["loc"]))
    ("GenLoc", generate)
let generate (module_types : FSig.module_types) =
  (let tys: string list =
     List.concat_map
       (fun x  ->
          match x with
          | `Mutual tys -> List.map (fun ((x,_) : named_type)  -> x) tys
          | `Single (x,_) -> [x]) module_types in
   let typedecl =
     let x =
       or_of_list (List.map (fun x  -> uid _loc (String.capitalize x)) tys) in
     `Type
       ((FanLoc.of_tuple
           ("src/AstTypeGen.ml", 357, 12160, 12177, 357, 12160, 12197, false)),
         (`TyDcl
            ((FanLoc.of_tuple
                ("src/AstTypeGen.ml", 357, 12160, 12182, 357, 12160, 12197,
                  false)),
              (`Lid
                 ((FanLoc.of_tuple
                     ("src/AstTypeGen.ml", 357, 12160, 12185, 357, 12160,
                       12188, false)), "tag")),
              (`Some
                 ((FanLoc.of_tuple
                     ("src/AstTypeGen.ml", 357, 12160, 12182, 357, 12160,
                       12188, false)),
                   (`Quote
                      ((FanLoc.of_tuple
                          ("src/AstTypeGen.ml", 357, 12160, 12182, 357,
                            12160, 12184, false)),
                        (`Normal
                           (FanLoc.of_tuple
                              ("src/AstTypeGen.ml", 357, 12160, 12182, 357,
                                12160, 12184, false))),
                        (`Lid
                           ((FanLoc.of_tuple
                               ("src/AstTypeGen.ml", 357, 12160, 12183, 357,
                                 12160, 12184, false)), "a")))))),
              (`TyRepr
                 ((FanLoc.of_tuple
                     ("src/AstTypeGen.ml", 357, 12160, 12191, 357, 12160,
                       12197, false)),
                   (`PrNil
                      (FanLoc.of_tuple
                         ("src/AstTypeGen.ml", 357, 12160, 12191, 357, 12160,
                           12197, false))),
                   (`Sum
                      ((FanLoc.of_tuple
                          ("src/AstTypeGen.ml", 357, 12160, 12191, 357,
                            12160, 12197, false)), x)))),
              (`None
                 (FanLoc.of_tuple
                    ("src/AstTypeGen.ml", 357, 12160, 12182, 357, 12160,
                      12197, false)))))) in
   let to_string =
     let case =
       or_of_list
         (List.map
            (fun x  ->
               `Case
                 (_loc, (`Id (_loc, (`Uid (_loc, (String.capitalize x))))),
                   (`Str (_loc, x)))) tys) in
     `Value
       (_loc, (`ReNil _loc),
         (`Bind
            (_loc, (`Id (_loc, (`Lid (_loc, "string_of_tag")))),
              (`Fun (_loc, case))))) in
   let tags =
     List.map
       (fun x  ->
          `Value
            (_loc, (`ReNil _loc),
              (`Bind
                 (_loc, (`Id (_loc, (`Lid (_loc, (x ^ "_tag"))))),
                   (`Constraint
                      (_loc,
                        (`Id (_loc, (`Uid (_loc, (String.capitalize x))))),
                        (`App
                           (_loc, (`Id (_loc, (`Lid (_loc, "tag")))),
                             (`Id (_loc, (`Lid (_loc, x)))))))))))) tys in
   sem_of_list (typedecl :: to_string :: tags) : stru )
let _ =
  Typehook.register
    ~filter:(fun s  -> not (List.mem s ["loc"; "ant"; "nil"]))
    ("DynAst", generate)
let generate (module_types : FSig.module_types) =
  (let aux (f : string) =
     (`Value
        (_loc, (`ReNil _loc),
          (`Bind
             (_loc, (`Id (_loc, (`Lid (_loc, ("map_" ^ f))))),
               (`Fun
                  (_loc,
                    (`Case
                       (_loc, (`Id (_loc, (`Lid (_loc, "f")))),
                         (`Obj
                            (_loc,
                              (`Sem
                                 (_loc,
                                   (`InheritAs
                                      (_loc, (`OvNil _loc),
                                        (`ClassConS
                                           (_loc, (`ViNil _loc),
                                             (`Lid (_loc, "map")))),
                                        (`Lid (_loc, "super")))),
                                   (`CrMthS
                                      (_loc, (`Lid (_loc, f)),
                                        (`Override _loc), (`PrNil _loc),
                                        (`Fun
                                           (_loc,
                                             (`Case
                                                (_loc,
                                                  (`Id
                                                     (_loc,
                                                       (`Lid (_loc, "x")))),
                                                  (`App
                                                     (_loc,
                                                       (`Id
                                                          (_loc,
                                                            (`Lid (_loc, "f")))),
                                                       (`App
                                                          (_loc,
                                                            (`Send
                                                               (_loc,
                                                                 (`Id
                                                                    (_loc,
                                                                    (`Lid
                                                                    (_loc,
                                                                    "super")))),
                                                                 (`Lid
                                                                    (_loc, f)))),
                                                            (`Id
                                                               (_loc,
                                                                 (`Lid
                                                                    (_loc,
                                                                    "x"))))))))))))))))))))))))) : 
     stru ) in
   FSigUtil.stru_from_ty ~f:aux module_types : stru )
let _ = Typehook.register ~filter:(fun _  -> true) ("MapWrapper", generate)
let generate (module_types : FSig.module_types) =
  (let aux (f : string) =
     (`Value
        (_loc, (`ReNil _loc),
          (`Bind
             (_loc, (`Id (_loc, (`Lid (_loc, ("dump_" ^ f))))),
               (`App
                  (_loc,
                    (`Id
                       (_loc,
                         (`Dot
                            (_loc, (`Uid (_loc, "LibUtil")),
                              (`Lid (_loc, "to_string_of_printer")))))),
                    (`Send
                       (_loc, (`Id (_loc, (`Lid (_loc, "dump")))),
                         (`Lid (_loc, f))))))))) : stru ) in
   sem
     (`Value
        (_loc, (`ReNil _loc),
          (`Bind
             (_loc, (`Id (_loc, (`Lid (_loc, "dump")))),
               (`New (_loc, (`Lid (_loc, "print"))))))))
     (FSigUtil.stru_from_ty ~f:aux module_types) : stru )
let _ =
  Typehook.register
    ~filter:(fun s  -> not (List.mem s ["loc"; "ant"; "nil"]))
    ("PrintWrapper", generate)
let generate (module_types : FSig.module_types) =
  (let aux (name,ty) =
     if name <> "ant"
     then
       let obj =
         Objs.map_row_field
           (function
            | `TyVrnOf (_loc,x,`Id (_,`Lid (_,"loc"))) -> `TyVrn (_loc, x)
            | `TyVrnOf (_loc,x,`Tup (_,`Sta (_,`Id (_,`Lid (_,"loc")),y))) ->
                (match y with
                 | `Sta (_loc,_,_) -> `TyVrnOf (_loc, x, (`Tup (_loc, y)))
                 | _ -> `TyVrnOf (_loc, x, y))
            | x -> x) in
       obj#typedecl ty
     else ty in
   (fun x  -> FSigUtil.stru_from_module_types ~f:aux x) module_types : 
  stru )
let _ = Typehook.register ~filter:(fun _  -> true) ("LocType", generate)