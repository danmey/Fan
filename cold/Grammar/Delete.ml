open Structure
let delete_rule_in_tree entry =
  let rec delete_in_tree symbols tree =
    match (symbols, tree) with
    | (s::sl,Node ({ node; brother; son } as n)) ->
        if Tools.logically_eq_symbols entry s node
        then
          (match delete_in_tree sl son with
           | Some (Some dsl,DeadEnd ) -> Some ((Some (node :: dsl)), brother)
           | Some (Some dsl,t) ->
               Some ((Some (node :: dsl)), (Node { n with son = t }))
           | Some (None ,t) -> Some (None, (Node { n with son = t }))
           | None  -> None)
        else
          (match delete_in_tree symbols brother with
           | Some (dsl,t) -> Some (dsl, (Node { n with brother = t }))
           | None  -> None)
    | (_::_,_) -> None
    | ([],Node n) ->
        (match delete_in_tree [] n.brother with
         | Some (dsl,t) -> Some (dsl, (Node { n with brother = t }))
         | None  -> None)
    | ([],DeadEnd ) -> None
    | ([],LocAct (_,[])) -> Some ((Some []), DeadEnd)
    | ([],LocAct (_,action::list)) -> Some (None, (LocAct (action, list))) in
  delete_in_tree
let removing _gram _kwd = ()
let rec decr_keyw_use gram =
  function
  | `Skeyword kwd -> removing gram kwd
  | `Smeta (_,sl,_) -> List.iter (decr_keyw_use gram) sl
  | `Slist0 s|`Slist1 s|`Sopt s|`Stry s|`Speek s -> decr_keyw_use gram s
  | `Slist0sep (s1,s2) -> (decr_keyw_use gram s1; decr_keyw_use gram s2)
  | `Slist1sep (s1,s2) -> (decr_keyw_use gram s1; decr_keyw_use gram s2)
  | `Stree t -> decr_keyw_use_in_tree gram t
  | `Sself|`Snext|`Snterm _|`Snterml (_,_)|`Stoken _ -> ()
and decr_keyw_use_in_tree gram =
  function
  | DeadEnd |LocAct (_,_) -> ()
  | Node n ->
      (decr_keyw_use gram n.node;
       decr_keyw_use_in_tree gram n.son;
       decr_keyw_use_in_tree gram n.brother)
let rec delete_rule_in_suffix entry symbols =
  function
  | lev::levs ->
      (match delete_rule_in_tree entry symbols lev.lsuffix with
       | Some (dsl,t) ->
           ((match dsl with
             | Some dsl -> List.iter (decr_keyw_use entry.egram) dsl
             | None  -> ());
            (match t with
             | DeadEnd  when lev.lprefix == DeadEnd -> levs
             | _ -> { lev with lsuffix = t } :: levs))
       | None  ->
           let levs = delete_rule_in_suffix entry symbols levs in lev :: levs)
  | [] -> raise Not_found
let rec delete_rule_in_prefix entry symbols =
  function
  | lev::levs ->
      (match delete_rule_in_tree entry symbols lev.lprefix with
       | Some (dsl,t) ->
           ((match dsl with
             | Some dsl -> List.iter (decr_keyw_use entry.egram) dsl
             | None  -> ());
            (match t with
             | DeadEnd  when lev.lsuffix == DeadEnd -> levs
             | _ -> { lev with lprefix = t } :: levs))
       | None  ->
           let levs = delete_rule_in_prefix entry symbols levs in lev :: levs)
  | [] -> raise Not_found
let delete_rule_in_level_list entry symbols levs =
  match symbols with
  | `Sself::symbols -> delete_rule_in_suffix entry symbols levs
  | (`Snterm e)::symbols when e == entry ->
      delete_rule_in_suffix entry symbols levs
  | _ -> delete_rule_in_prefix entry symbols levs
let delete_rule entry sl =
  match entry.edesc with
  | Dlevels levs ->
      let levs = delete_rule_in_level_list entry sl levs in
      (entry.edesc <- Dlevels levs;
       (let start = Parser.start_parser_of_entry entry in
        let continue = Parser.continue_parser_of_entry entry in
        entry.estart <- start; entry.econtinue <- continue))
  | Dparser _ -> ()