open Format;
open Lib;
module MetaAst = Camlp4Ast.Meta.Make Lib.Meta.MetaGhostLoc ;
module Ast = Camlp4Ast;
open FanGrammar;

let print_warning = eprintf "%a:\n%s@." FanLoc.print;  
let split_ext = ref false;
let prefix = "__camlp4_"  ;  
let meta_action = ref false;
let grammar_module_name = let _loc = FanLoc.ghost in ref {:ident| $(uid:"")|} ;
let gm () = !grammar_module_name;

let mk_entry ~name ~pos ~levels = {name;pos;levels};
let mk_level ~label ~assoc ~rules ={label; assoc;rules};
let mk_rule ~prod ~action = {prod;action};
let mk_symbol  ?(pattern=None)  ~text ~styp = {
  text;styp;pattern
};

let string_of_patt patt = 
  let buf = Buffer.create 42 in
  let () =
    Format.bprintf buf "%a@?"
      (fun fmt p -> AstPrint.pattern fmt (Ast2pt.patt p)) patt in
  let str = Buffer.contents buf in
  if str = "" then assert false else str;

(** FIXME why deprecate such syntax
    It makes
    [OPT STRING] invalid
    You shoud write [OPT [x=STRING -> x] ]
 *)  
let check_not_tok s = (* ('a, 'b) symbol -> unit *)
    match s with
    [ {text = `TXtok (_loc, _, _, _) ;_} ->
        FanLoc.raise _loc (Stream.Error
          ("Deprecated syntax, use a sub rule. "^
           "LIST0 STRING becomes LIST0 [ x = STRING -> x ]"))
    | _ -> () ];
      
let new_type_var = 
  let i = ref 0 in fun () -> begin  incr i; "e__" ^ string_of_int !i end ;
let gensym  =
  let i = ref 0 in fun () -> begin
    incr i;
    i;
  end;

let gen_lid ()=
  prefix^string_of_int (!(gensym ()));
  
(* transform rule list *)  
let retype_rule_list_without_patterns _loc rl =
  try
    List.map(fun
      (* ...; [ "foo" ]; ... ==> ...; (x = [ "foo" ] -> Gram.Token.extract_string x); ... *)
    [ {prod = [({pattern = None; styp = `STtok _ ;_} as s)]; action = None} ->
        {prod = [{ (s) with pattern = Some {:patt| x |} }];
         action = Some {:expr| $(id:gm()).string_of_token x |}}
    (* ...; [ symb ]; ... ==> ...; (x = [ symb ] -> x); ... *)
    | {prod = [({pattern = None; _ } as s)]; action = None} ->
        {prod = [{ (s) with pattern = Some {:patt| x |} }];
         action = Some {:expr| x |}}
    (* ...; ([] -> a); ... *)
    | {prod = []; action = Some _} as r -> r
    | _ -> raise Exit ]) rl
  with
    [ Exit -> rl ];

exception NotneededTyping ;
(*
  translate [styp] into [Ast.ctyp],
  given the assumption that the entry output [tvar] type
 *)
let  make_ctyp  styp tvar = 
  let rec aux  = fun  
    [ `STlid (_loc, s) -> {:ctyp| $lid:s |}
    | `STapp (_loc, t1, t2) -> {:ctyp| $(aux t1) $(aux t2 ) |}
    | `STquo (_loc, s) -> {:ctyp| '$s |}
    | `STself (_loc, x) ->
        if tvar = "" then
          FanLoc.raise _loc
            (Stream.Error ("'" ^ x ^  "' illegal in anonymous entry level"))
        else {:ctyp| '$tvar |}
    | `STtok _loc -> raise NotneededTyping
    | `STtyp t -> t ] in
    try Some (aux styp) with [NotneededTyping -> None ];

(*
  {[ styp generates type constraints which are used to constrain patt ]}
*)    
let make_ctyp_patt styp tvar patt = 
  match make_ctyp styp tvar with
  [ None -> patt (* FIXME *)
  | Some t -> let _loc = Camlp4Ast.loc_of_patt patt in {:patt| ($patt : $t) |} ];

let make_ctyp_expr styp tvar expr = 
  match make_ctyp styp tvar with
  [ None -> expr
  | Some t -> let _loc = Camlp4Ast.loc_of_expr expr in {:expr| ($expr : $t) |} ];

(* transform text to [expr] *)    
let rec make_expr entry tvar =  fun
  [ `TXmeta (_loc, n, tl, e, t) ->
    let el = Expr.mklist _loc (List.map (fun t -> make_expr entry "" t ) tl) in 
    let ns = Expr.mklist _loc (List.map (fun n -> {:expr| $str:n |} ) n) in 
    {:expr| `Smeta ($ns, $el, ($(id:gm()).Action.mk $(make_ctyp_expr t tvar e))) |}
  | `TXlist (_loc, min, t, ts) ->
      let txt = make_expr entry "" t.text in
      match (min, ts) with
      [ (false, None) -> {:expr| `Slist0 $txt |} 
      | (true, None) ->  {:expr| `Slist1 $txt |} 
      | (false, Some s) ->
          let x = make_expr entry tvar s.text in
          {:expr| `Slist0sep ($txt,$x) |}
      | (true, Some s) ->
            let x = make_expr entry tvar s.text in
            {:expr| `Slist1sep ($txt,$x) |} ]
  | `TXnext _loc ->  {:expr| `Snext |}
  | `TXself _loc ->  {:expr| `Sself|}
  | `TXkwd (_loc, kwd) ->  {:expr| `Skeyword $str:kwd |}

  | `TXnterm (_loc, n, lev) ->
      match lev with
      [ Some lab ->
        {:expr| `Snterml
          (($(id:gm()).obj ($(n.expr) : $(id:gm()).t '$(n.tvar))), $str:lab) |} 
      | None ->
          if n.tvar = tvar then {:expr| `Sself|}
          else
            {:expr|
            `Snterm ($(id:gm()).obj ($(n.expr) : $(id:gm()).t '$(n.tvar)))
          |}   ]
  | `TXopt (_loc, t) -> {:expr| `Sopt $(make_expr entry "" t) |}
  | `TXtry (_loc, t) -> {:expr| `Stry $(make_expr entry "" t) |}
  | `TXpeek (_loc, t) -> {:expr| `Speek $(make_expr entry "" t) |}
  | `TXrules (_loc, rl) ->
      {:expr| $(id:gm()).srules $(entry.expr) $(make_expr_rules _loc entry rl "") |}
  | `TXtok (_loc, match_fun, attr, descr) ->
      {:expr| `Stoken ($match_fun, (`$uid:attr, $`str:descr)) |} ]
    
and make_expr_rules _loc n rl tvar =
  List.fold_left
    (fun txt (sl, ac)
      ->
        let sl =
          
          List.fold_right
            (fun t txt ->
              let x = make_expr n tvar t in
              {:expr| [$x :: $txt] |})  sl {:expr| [] |} in   {:expr| [($sl, $ac) :: $txt ] |})
    {:expr| [] |} rl  ;


  
(* generate action, collecting patterns into action  *)
let text_of_action _loc  psl
    (rtvar:string)
    (act:option Ast.expr) (tvar:string) =
  let locid = {:patt| $(lid:!FanLoc.name) |} in (* default is [_loc]*)
  let act = match act with
  [ Some act -> act (* get the action *)
  | None -> {:expr| () |} ] in
  let (tok_match_pl, act, _) =
    List.fold_left
      (fun
        ((tok_match_pl, act, i) as accu)
        -> fun
          [ { pattern = None; _ } -> accu
          | { pattern = Some p ; _} when Camlp4Ast.is_irrefut_patt p -> accu
          | { pattern = Some p; text=`TXtok (_, _,  _, _) ; _ } ->
              let id = prefix ^ string_of_int i in
              (Some
                 (match tok_match_pl with
                 [ None -> ({:expr| $lid:id |}, p)
                 | Some (tok_pl, match_pl) ->
                     ({:expr| $lid:id, $tok_pl |}, {:patt| $p, $match_pl |})]),act,  i+1)
          | _ -> accu ])
      (None, act, 0) psl  in
  let e =
    let e1 = {:expr| ($act : '$rtvar) |} in
    let e2 =
      match tok_match_pl with
      [ None -> e1
      | Some ({:expr| $t1, $t2 |}, {:patt| $p1, $p2 |}) ->
          {:expr|
            match ($t1, $t2) with
            [ ($p1, $p2) -> $e1
            | _ -> assert false ] |}
      | Some (tok, match_) ->
            {:expr|
            match $tok with
            [ $pat:match_ -> $e1
            | _ -> assert false ] |} ] in
    {:expr| fun ($locid : FanLoc.t) -> $e2 |} in (*FIXME hard coded Loc*)
  (* add prefix now *)
  let (txt, _) =
    List.fold_left
      (fun (txt, i) s ->
        match s.pattern with
        [ None | Some {:patt| _ |} -> ({:expr| fun _ -> $txt |}, i)
        | Some {:patt| ($_ $(tup:{:patt| _ |}) as $p) |} ->
            let p = make_ctyp_patt s.styp tvar p in
            ({:expr| fun $p -> $txt |}, i)
        | Some p when Camlp4Ast.is_irrefut_patt p ->
            let p = make_ctyp_patt s.styp tvar p in
            ({:expr| fun $p -> $txt |}, i)
        | Some _ ->
            let p = make_ctyp_patt s.styp tvar
                {:patt| $(lid:prefix^string_of_int i) |} in
            ({:expr| fun $p -> $txt |}, succ i) ])
      (e, 0) psl in
  let txt =
    if !meta_action then
      {:expr| Obj.magic $(MetaAst.Expr.meta_expr _loc txt) |}
    else txt  in
  {:expr| $(id:gm()).mk_action $txt |}  ;
  let srules loc t rl tvar =
    List.map
      (fun r ->
        let sl = [ s.text | s <- r.prod ] in
        let ac = text_of_action loc r.prod t r.action tvar in
        (sl, ac))
      rl ;
    

let expr_of_delete_rule _loc n sl =
  let sl =
    List.fold_right
      (fun s e -> {:expr| [$(make_expr n "" s.text) :: $e ] |}) sl {:expr| [] |}  in
  ({:expr| $(n.expr) |}, sl)  ;

(* given the entry of the name, make a name *)
let mk_name _loc i = {expr = {:expr| $id:i |}; tvar = Ident.tvar_of_ident i; loc = _loc};
  
let slist loc min sep symb = `TXlist loc min symb sep ;
  
let text_of_entry  _loc e = 
  let ent =
    let x = e.name in
    let _loc = e.name.loc in
    {:expr| ($(x.expr) : $(id:gm()).t '$(x.tvar)) |}   in
  let pos =
    match e.pos with
    [ Some pos -> {:expr| Some $pos |}
    | None -> {:expr| None |} ] in
  let txt =
    List.fold_right
      (fun level txt ->
        let lab =
          match level.label with
          [ Some lab -> {:expr| Some $str:lab |}
          | None -> {:expr| None |} ]  in
        let ass =
          match level.assoc with
          [ Some ass -> {:expr| Some $ass |}
          | None -> {:expr| None |} ]  in
        let txt =
          let rl = srules _loc e.name.tvar level.rules e.name.tvar in
          let e = make_expr_rules _loc e.name rl e.name.tvar in
          {:expr| [($lab, $ass, $e) :: $txt] |} in txt) e.levels {:expr| [] |} in
  (ent, pos, txt) ;
  

(* [gl] is the name  list option

   {[
   loc -> ident option ->expr name list option ->
   (expr, 'a) entry list -> expr -> expr
   ]}
   
 *)   
let let_in_of_extend _loc gram gl  default =
  let entry_mk =
    match gram with
    [ Some g -> {:expr| $(id:gm()).mk $id:g |}
    | None   -> {:expr| $(id:gm()).mk |} ] in
  let local_binding_of_name = fun
    [ {expr = {:expr| $lid:i |} ; tvar = x; loc = _loc} ->
      {:binding| $lid:i =  (grammar_entry_create $str:i : $(id:gm()).t '$x) |}
    | _ -> failwith "internal error in the Grammar extension" ]  in
  match gl with
  [ None -> default
  | Some ll -> begin
        match ll with
        [ [] -> default
        | [x::xs] ->
            let locals =
              List.fold_right (fun name acc -> {:binding| $acc and $(local_binding_of_name name) |})
                xs (local_binding_of_name x) in
              {:expr|
            let grammar_entry_create = $entry_mk in
            let $locals in $default |} ] 
  end ]  ;

(* the [gl] is global entry name list,
   [el] is entry list
   [gram] is the grammar
   [gmod] is the [Gram] module true
   generate the extend, the main entrance
 *)
let text_of_functorial_extend _loc  gram gl el = 
  let args =
    let el =
      List.map  (fun e ->
        let (ent, pos, txt) = text_of_entry e.name.loc e in
        {:expr| $(id:gm()).extend $ent  ($pos, $txt) |} ) el  in
    match el with
    [ [] -> {:expr| () |}
    | [e] -> e
    | [e::el] ->
        {:expr| begin  $(List.fold_left (fun acc x -> {:expr| $acc; $x |}) e el) end |}  ]  in
  let_in_of_extend _loc gram gl  args;

let mk_tok _loc ?restrict ~pattern styp =
 match restrict with
    [ None ->
      let p' = Camlp4Ast.wildcarder#patt pattern in
      let match_fun =
        if Camlp4Ast.is_irrefut_patt p'
        then 
          {:expr| fun [ $pat:p' -> true ] |}
        else {:expr| fun [$pat:p' -> true | _ -> false ] |} in 
      let descr = string_of_patt p' in
      let text = `TXtok _loc match_fun "Normal" descr in
      {text; styp; pattern = Some pattern }
    | Some restrict ->
        let p'= Camlp4Ast.wildcarder#patt pattern in
        let match_fun = 
          {:expr| fun [$pat:pattern when $restrict -> true | _ -> false ] |}  in
        let descr = string_of_patt pattern in
        let text = `TXtok _loc match_fun "Antiquot" descr in
        {text; styp; pattern = Some p'} ] ;
   
let sfold ?sep _loc  (ns:list string)  f e s =
  let fs = [("FOLD0","sfold0");("FOLD1","sfold1")] in
  let suffix = match sep with [None -> ""|Some  _ -> "sep"] in
  let n = List.hd ns in 
  let foldfun =
    try List.assoc n fs ^ suffix  with [Not_found -> invalid_arg "sfold"] in
  let styp = `STquo _loc (new_type_var ()) in
  let e = {:expr| $(id:gm()).$lid:foldfun $f $e |} in
  let t = `STapp _loc (`STapp _loc (`STtyp {:ctyp| $(id:gm()).$(lid:"fold"^suffix) _ |}) s.styp) styp in
  let text = `TXmeta _loc ns (match sep with [None -> [s.text] | Some sep -> [s.text;sep.text] ])  e t   in 
  {text ; styp ; pattern = None } ;



















