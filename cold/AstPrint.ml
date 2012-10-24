(**************************************************************************)
(*                                                                        *)
(*                                OCaml                                   *)
(*                                                                        *)
(*    Thomas Gazagnaire (OCamlPro), Fabrice Le Fessant (INRIA Saclay)     *)
(*                                                                        *)
(*   Copyright 2007 Institut National de Recherche en Informatique et     *)
(*   en Automatique.  All rights reserved.  This file is distributed      *)
(*   under the terms of the Q Public License version 1.0.                 *)
(*                                                                        *)
(**************************************************************************)

(* Original Code from Ber-metaocaml, modified fo 3.12.0 and fixed *)

(* Printing code expressions *)
(* Authors:  Ed Pizzi, Fabrice Le Fessant *)
(* Rewrite: Hongbo Zhang: University of Pennsylvania*)

(* FIXME what kind of error check should we do ?,
   Location for error message
 *)

(*
  label:
        | Ptyp_arrow of label * core_type * core_type
        | Pcty_fun of label * core_type * class_type
        | Pcl_fun of label * expression option * pattern * class_expr
        | Pexp_function of label * expression option * (pattern * expression) list
 *)
open Asttypes
open Format
open Location
open Longident
open Parsetree


let indent    = 1 ;; (* standard indentation increment *)
let bar_on_first_case = true ;;

(* These sets of symbols are taken from the manual. However, it's
   unclear what the sets infix_symbols and prefix_symbols are for, as
   operator_chars, which contains their union seems to be the only set
   useful to determine whether an identifier is prefix or infix.
   The set postfix_chars I added, which is the set of characters allowed
   at the end of an identifier to allow for internal MetaOCaml variable
   renaming. *)

let prefix_symbols  = [ '!'; '?'; '~' ] ;;
let infix_symbols = [ '='; '<'; '>'; '@'; '^'; '|'; '&'; '+'; '-'; '*'; '/'; '$'; '%' ] 
let operator_chars = [ '!'; '$'; '%'; '&'; '*'; '+'; '-'; '.'; '/';
                       ':'; '<'; '='; '>'; '?'; '@'; '^'; '|'; '~' ] 
let numeric_chars  = [ '0'; '1'; '2'; '3'; '4'; '5'; '6'; '7'; '8'; '9' ] 

type fixity =
  | Infix
  | Prefix 

let is_infix  = function 
  | Infix  -> true
  | Prefix -> false 

let special_infix_strings =
  ["asr"; "land"; "lor"; "lsl"; "lsr"; "lxor"; "mod"; "or"; ":="; "!=" ] 

(* determines if the string is an infix string.
   checks backwards, first allowing a renaming postfix ("_102") which
   may have resulted from Pexp -> Texp -> Pexp translation, then checking
   if all the characters in the beginning of the string are valid infix
   characters. *)
let fixity_of_string s =
  if ((List.mem s special_infix_strings) || (List.mem  s.[0] infix_symbols)) then
    Infix
  else Prefix

let fixity_of_longident = function
  | {txt=Lident name;_} -> fixity_of_string name
  | _ -> Prefix 

let fixity_of_exp = function 
  | {pexp_desc = Pexp_ident li;_} -> fixity_of_longident li
  | _ -> Prefix ;;

(* It's not recommended to fill [sep_action] and [sep] simultaneously
   for empty list, [first],[last] still has effect.
   for singleton list, [first], [last],[breakfist],[breaklast] has effect 
    *)
let pp_print_list
    ?(indent=0) ?(breakfirst=false) ?(breaklast=false) ?(space=1)
    ?(sep_action=fun ppf _ -> fprintf ppf "@ ")
    ?sep
    ?(first="")
    ?(last="")
    f ppf xs =
  let rec loop bf ppf  = function
    | [] -> ()
    | [x] -> begin 
        if bf then pp_print_break ppf space indent ;
        fprintf ppf "%a" f x;
        if breaklast then pp_print_break ppf space indent
    end
    | x::xs -> begin
        if bf then pp_print_break ppf space indent ;
        fprintf ppf "%a" f x ;
        (match sep with
        | None -> sep_action ppf ();
        | Some sep -> begin
            sep_action ppf ();
            fprintf ppf "%s" sep;
            sep_action ppf ();
        end);
        loop false ppf xs 
    end in begin
      fprintf ppf "%s%a%s@ " first (loop breakfirst) xs last 
    end
    
let pp_print_option f ppf a = match a with
| None -> ()
| Some x -> fprintf ppf "%a" f x
      
let rec longident ppf  =function
  | Lident s -> fprintf ppf "%s" s
  | Ldot(y,s) -> (match s.[0] with
    | 'a'..'z' | 'A' .. 'Z' ->
        fprintf ppf "%a.%s" longident y s
    | _ ->
        fprintf ppf "%a.(@ %s@ )@ " longident y s)
  | Lapply (y,s)->
        fprintf ppf "%a(%a)" longident y longident s

let longident_loc ppf x = fprintf ppf "%a" longident x.txt;;

let constant ppf  = function
  | Const_int i -> fprintf ppf "%d" i
  | Const_char i -> fprintf ppf "%C"  i 
  | Const_string i -> fprintf ppf "%S" i
  | Const_float  i -> fprintf ppf "%s" i 
  | Const_int32 i -> fprintf ppf "%ldl" i
  | Const_int64 i -> fprintf ppf "%LdL" i
  | Const_nativeint i -> fprintf ppf "%ndn" i

let mutable_flag ppf   = function
  | Immutable -> ()
  | Mutable -> fprintf ppf "mutable@ "
let  virtual_flag ppf  = function
  | Concrete -> ()
  | Virtual -> fprintf ppf "virtual@ "
let rec_flag ppf = function
  | Nonrecursive -> ()
  | Recursive | Default -> fprintf ppf "rec@ "
let direction_flag ppf = function
  | Upto -> fprintf ppf "to@ "
  | Downto -> fprintf ppf "downto@ "
let private_flag ppf = function
  | Public -> ()
  | Private -> fprintf ppf "private@ "

let constant_string ppf s = fprintf ppf "%S" s 
let pp_print_tyvar ppf str = fprintf ppf "'%s@ " str ;;

let pp_print_type_var_option ppf str = 
  match str with
    None -> () 
  | Some {txt;_} -> pp_print_tyvar ppf txt ;;

let class_params_def ppf   = function
  | [] -> ()
  | l -> pp_print_list (fun ppf {txt;_} -> pp_print_tyvar ppf txt)
        ppf l ~sep:"," ~first:"[" ~last:"]"

let is_predef_option = function
  | (Ldot (Lident "*predef*","option")) -> true
  | _ -> false
        
let pp_print_string_quot ppf x =
  fprintf ppf "`%s" x 
(*********************************************************************************)
(***************core_type*********************************************************)
let rec print_type_with_label ppf (label,({ptyp_desc;_}as c) ) = match label with
| "" ->  core_type ppf c
| s  ->
    if s.[0]='?' then 
      match ptyp_desc with
      | Ptyp_constr ({txt;_}, l) -> begin 
          assert (is_predef_option txt);
          fprintf ppf "%s:%a" s (pp_print_list core_type) l 
      end
      | _ -> failwith "invalid input in print_type_with_label"
    else
      fprintf ppf "%s:%a" s core_type c

and core_type ppf ({ptyp_desc;_}:Parsetree.core_type) =
  match ptyp_desc with
  | Ptyp_any -> fprintf ppf "_";       
  | Ptyp_var s -> pp_print_tyvar ppf  s; 
  | Ptyp_arrow (l, ct1, ct2) ->
      fprintf ppf "@[<hov2>(%a@ ->@ %a)@ @]" (* FIXME remove parens later *)
        print_type_with_label (l,ct1) core_type ct2
  | Ptyp_tuple l ->
      fprintf ppf "@[<hov2>(%a)@]" (pp_print_list core_type ~sep:"*") l ;
  | Ptyp_constr (li, l) -> (match l with
    | [] -> longident_loc ppf li
    | _ ->  fprintf ppf "%a@ %a@ " type_constr_list l longident_loc li)
  | Ptyp_variant (l, closed, low) ->
      fprintf ppf "@[<hov2>%a@]" begin fun ppf l -> 
        (match (closed,low) with
        | (true,None)  -> fprintf ppf "[@ " 
        | (true,Some _) -> fprintf ppf "[<@ "
        | (false,_) -> fprintf ppf "[>@ " );
        pp_print_list type_variant_helper ppf l ~sep:"|";
        (match low with
        |Some [] |None -> ()  
        |Some xs -> fprintf ppf ">@ %a" (pp_print_list pp_print_string_quot) xs);
        fprintf ppf "@ ]";
      end l 
  | Ptyp_object l ->
      fprintf ppf "@[<hov2><@ %a@ >@]" (pp_print_list core_field_type ~sep:";") l
        
  | Ptyp_class (li, l, low) ->   (*FIXME*)
      pp_open_hovbox ppf indent ;
      (match l with
      | [] -> ()
      | [x] -> core_type ppf x (* pp_print_tyvar  ppf  x *)
      | _ ->   pp_print_list core_type ppf l ~sep:"," ~first:"(" ~last:")");
      fprintf ppf "#%a@ " longident_loc li;
      (match low with
      |[] -> ()
      | _ ->
          fprintf ppf "[> %a]@ " (pp_print_list pp_print_string_quot ) low );
      pp_close_box ppf ();
  | Ptyp_alias (ct, s) ->               
      fprintf ppf "@[<hov2>(%a @ as@ '%s)@]" core_type ct s
  | Ptyp_poly (sl, ct) ->               
      fprintf ppf "@[<hov2>%a@]" begin fun ppf (sl,ct) ->
        (match sl with 
        |[] -> ()
        | _ ->
            pp_print_list pp_print_tyvar ~breaklast:true  ~last:"." ppf sl);
        core_type ppf ct ;
      end (sl,ct)

  | Ptyp_package (lid, cstrs) ->
      fprintf ppf "@[<hov2>(module %a@ %a)@]" longident_loc lid
        (fun ppf cstrs -> match cstrs with
        | [] -> ()
        | _ -> fprintf ppf "@[<hov2>with@ @]"; string_x_core_type_ands ppf cstrs
        ) cstrs

and core_field_type ppf {pfield_desc;_} =
  match pfield_desc with
  | Pfield (s, ct) ->
      fprintf ppf "@[<hov2>%s@ :%a@ @]" s core_type ct 
  | Pfield_var ->
      fprintf ppf "..";

and type_constr_list ppf  = function
  | [] -> ()
  | [x] ->
      core_type ppf x
  | xs ->
      fprintf ppf "(%a)@ " (pp_print_list core_type ~sep:",") xs
(*********************************************************************************)
(****************************pattern**********************************************)        


and pattern ppf x =
  let rec pattern_list_helper ppf  = function
    | {ppat_desc = Ppat_construct ({ txt = Lident("::") ;_},
                                   Some ({ppat_desc = Ppat_tuple([pat1; pat2]);_}),
                                   _);_}
      ->
        fprintf ppf "%a::%a"
          pattern  pat1
          pattern_list_helper pat2
    | p -> pattern ppf p in
  match x.ppat_desc with
    | Ppat_construct (({txt;_} as li), po, _) -> (* FIXME The third field always false *)
        if txt = Lident "::" then
          fprintf ppf "%a" pattern_list_helper x
        else
          (match po with
          |Some x ->
              fprintf ppf "%a%a"
                longident_loc li
                pattern_in_parens x
          | None -> fprintf ppf "%a@ "longident_loc li )
    | Ppat_any -> fprintf ppf "_";           
    | Ppat_var ({txt = txt;_}) ->
        if (is_infix (fixity_of_string txt)) || List.mem txt.[0] prefix_symbols then
          if txt.[0]='*' then
            fprintf ppf "(@ %s@ )@ " txt
          else
            fprintf ppf "(%s)" txt 
        else
          fprintf ppf "%s" txt;
    | Ppat_alias (p, s) ->                 
        fprintf ppf "@[<hov2>(%a@ as@ %s)@]"
          pattern p
          s.txt
  | Ppat_constant (c) ->                   
      fprintf ppf "%a" constant c;
  | Ppat_tuple (l) ->                      
      fprintf ppf "@[<hov1>(%a)@]"
      (pp_print_list  ~sep:"," pattern)  l;

  | Ppat_variant (l, po) ->
      (match po with
        | None ->
            fprintf ppf "`%s" l;
        | Some (p) ->
            fprintf ppf "@[<hov2>(`%s@ %a)@]" l pattern p)
  | Ppat_record (l, closed) ->
      (match closed with
      |Closed -> 
        fprintf ppf "@[<hov2>{%a}@]"
          (pp_print_list longident_x_pattern ~sep:";") l
      | _ -> 
        fprintf ppf "@[<hov2>{%a;_}@]"
          (pp_print_list longident_x_pattern ~sep:";") l)
  | Ppat_array l ->
      fprintf ppf "@[<hov2>[|%a|]@]"  (pp_print_list pattern ~sep:";") l 
  | Ppat_or (p1, p2) ->
      fprintf ppf "@[<hov2>(%a@ |%a)@]"
        pattern p1
        pattern p2 
  | Ppat_constraint (p, ct) ->
      fprintf ppf "@[<hov2>(%a@ :@ %a)@]" pattern p core_type ct 
  | Ppat_type li ->
      fprintf ppf "#%a" longident_loc li ;
  | Ppat_lazy p ->
      fprintf ppf "@[<hov2>(lazy@ %a)@]" pattern p 
  | Ppat_unpack (s) ->
      fprintf ppf "(module@ %s)@ " s.txt

and simple_expr ppf x =(* FIXME*)
  match x.pexp_desc with
  | Pexp_construct (li, None, _) ->
      fprintf ppf "%a@ " longident_loc li
  | Pexp_ident (li) -> (* was (li, b) *)
      if is_infix (fixity_of_longident li)
        || match li.txt with
          | Lident (li) -> List.mem li.[0] prefix_symbols
          | _ -> false
      then
        fprintf ppf "(%a)" longident_loc li
      else
        fprintf ppf "%a" longident_loc li ;
  | Pexp_constant (c) -> fprintf ppf "%a" constant c;
  | Pexp_pack (me) ->
      fprintf ppf "(module@ %a)"
      module_expr me
  | Pexp_newtype (lid, e) ->
      fprintf ppf "fun (type %s)@ ->@ %a"
        lid
        expression  e
  | Pexp_tuple (l) ->
      fprintf ppf "@[<hov 1>(";
      pp_print_list simple_expr ppf l ~sep:",";
      fprintf ppf ")@]";
  | Pexp_variant (l, eo) -> (match eo with
    | None -> fprintf ppf "`%s" l 
    | Some x ->
        fprintf ppf "`%s@ (%a)" l expression x)
  | Pexp_record (l, eo) ->
      pp_open_hovbox ppf indent ; (* maybe just 1? *)
      fprintf ppf "{" ;
      begin
        match eo with
          None -> ()
        | Some e ->
            expression ppf e;
            fprintf ppf "@ with@ "
      end;
      pp_print_list longident_x_expression ppf l ~sep:";";
      fprintf ppf "}" ;
      pp_close_box ppf () ;
  | Pexp_array (l) ->
      pp_open_hovbox ppf 2 ;
      fprintf ppf "[|" ;
      pp_print_list simple_expr ppf l ~sep:";";
      fprintf ppf "|]" ;
      pp_close_box ppf () ;
  | Pexp_while (e1, e2) ->
      pp_open_hvbox  ppf 0 ;
      pp_open_hovbox ppf indent ;
      fprintf ppf "while@ " ;
      expression ppf e1 ;
      fprintf ppf " do" ;
      pp_close_box ppf () ;
      pp_print_break ppf 1 indent ;
      expression_sequence ppf e2 ~first:false;
      pp_print_break ppf 1 0 ;
      fprintf ppf "done" ;
      pp_close_box ppf () ;
  | Pexp_for (s, e1, e2, df, e3) ->
      pp_open_hvbox  ppf 0 ;
      pp_open_hovbox ppf indent ;
      fprintf ppf "for %s =@ " s.txt ;
      expression ppf e1 ;
      fprintf ppf "@ %a@ " direction_flag df ;
      expression ppf e2 ;
      fprintf ppf " do" ;
      pp_close_box ppf () ;

      pp_print_break ppf 1 indent ;
      expression_sequence ppf ~first:false e3 ;
      pp_print_break ppf 1 0 ;
      fprintf ppf "done" ;
      pp_close_box ppf () ;


  | _ -> (* complex case delegated to expression *)
      fprintf ppf "(@ ";
      expression ppf x;
      fprintf ppf "@ )"
        
and pp_print_label_exp ppf (l,opt,p) =
  if l = "" then
    fprintf ppf "(%a)@ " pattern p (*single case pattern parens needed here *)
  else
    if l.[0] = '?' then 
      let len = String.length l - 1 in 
      let rest = String.sub l 1 len in begin
        match p.ppat_desc with
        | Ppat_var {txt;_} when txt = rest ->
              (match opt with
              |Some o -> fprintf ppf "?(%s=%a)@ " rest  expression o
              | None -> fprintf ppf "?%s@ " rest)
        | _ -> (match opt with
          | Some o -> fprintf ppf "%s:(%a=%a)@ " l pattern p expression o
          | None -> fprintf ppf "%s:(%a)@ " l pattern p  )
      end
    else
      (match p.ppat_desc with
      | Ppat_var {txt;_} when txt = l ->
          fprintf ppf "~%s@ " l 
      | _ ->  fprintf ppf "~%s:(%a)@ " l pattern p )
        
and pp_print_pexp_function ppf e = match e.pexp_desc with 
  | Pexp_function (label,eo,[(p,e')]) ->
      if label="" then  (*normal case single branch *)
        match e'.pexp_desc with
        | Pexp_when _  ->
            fprintf ppf "=@ %a" expression e
        | _ -> 
            fprintf ppf "(%a)@ %a" pattern p pp_print_pexp_function e'
      else
        fprintf ppf "%a@ %a" pp_print_label_exp (label,eo,p) pp_print_pexp_function e'
  | _ -> fprintf ppf "=@ %a" expression e
and sugar_expr ppf e =
  match e.pexp_desc with 
  | Pexp_apply
      ({pexp_desc=
        Pexp_ident
          {txt= Ldot (Lident (("Array"|"String") as s),"get");_};_},[(_,e1);(_,e2)]) -> begin
            if s = "Array" then 
              fprintf ppf "@[<hov>%a.(%a)@]"  expression e1 expression e2
            else
              fprintf ppf "@[<hov>%a.[%a]@]"  expression e1 expression e2;
      true
  end
  |Pexp_apply
      ({pexp_desc=
        Pexp_ident
          {txt= Ldot (Lident (("Array"|"String") as s),
                      "set");_};_},[(_,e1);(_,e2);(_,e3)]) -> begin
                        if s = "Array" then
                          fprintf ppf "@[<hov>%a.(%a)<-%a@]"
                            expression e1
                            expression e2
                            expression e3
                        else
                          fprintf ppf "@[<hov>%a.[%a]<-%a@]"
                            expression e1
                            expression e2
                            expression e3;
                        true
                      end
  | Pexp_apply ({pexp_desc=Pexp_ident {txt=Lident "!";_};_}, [(_,e)]) -> begin
      fprintf ppf "@[<hov>(!(%a))@]" expression e;
      true
  end
  | _ -> false
and expression ppf x =
  match x.pexp_desc with
  | Pexp_let (rf, l, e) ->
      fprintf ppf "@\n@[<hov>let@ %a@ %a@ in@ %a@]" (*no identation here, a new line*)
        rec_flag rf
        pattern_x_expression_def_list l
        expression e 
  | Pexp_function (p, eo, l) ->
     ( match l with
      | [(p',e')] ->
          (match e'.pexp_desc with
          | Pexp_when(e1,e2) ->
              fprintf ppf "@[<hov2>fun@ %a@ ->@ %a@]"
                pattern_with_when (Some e1,p') expression e2
          | _ -> 
              fprintf ppf "@[<hov2>fun@ %a->@ %a@]"
                pp_print_label_exp (p,eo,p') expression e')
      | _ -> 
          fprintf ppf "@\n@[<hov>function@\n%a@]" (* a new line *)
          pattern_x_expression_case_list  l ;)

  | Pexp_apply (e, l) ->
      if not (sugar_expr ppf x) then
        let fixity = (is_infix (fixity_of_exp e)) in
        if not fixity  then
          fprintf ppf "@[<hov2>%a@]" begin fun ppf (e,l) -> 
            fprintf ppf "(%a@ %a)" (fun ppf e ->
              (match e.pexp_desc with
              | Pexp_ident(_) -> expression ppf e ;
              | Pexp_send (_,_) -> expression ppf e ;
              | _ -> fprintf ppf "@[<hov2>%a@]"  expression_in_parens e )) e
              (pp_print_list label_x_expression_param)  l 
          end (e,l)
      else 
          (match l with
          | [ arg1; arg2 ] ->
              fprintf ppf "@[<hov2>(%a@ %a@ %a)@]"
                label_x_expression_param  arg1 
              (fun ppf e -> match e.pexp_desc with
              | Pexp_ident(li) ->
                  fprintf ppf "%a" longident_loc li ;
              | _ -> simple_expr ppf e) e 
              label_x_expression_param arg2
          | _ ->
              fprintf ppf "@[<hov2>(%a %a)@]" simple_expr e 
                (fun ppf l -> pp_print_list label_x_expression_param ~breakfirst:true ppf l)  l)

  | Pexp_match (e, l) ->
      fprintf ppf "@\n@[<hov>(match@ %a@ with@\n@[<hov>%a@])@]" (*a new line*)
        expression e
        pattern_x_expression_case_list  l 
  | Pexp_try (e, l) ->
      fprintf ppf "@\n@[<hov>(try@ %a@ with@\n@[<hov>%a@])@]"
        (fun ppf e -> expression_sequence ~first:false ppf e) e
        pattern_x_expression_case_list l 
  | Pexp_construct (li, eo, _)  ->
      (match li.txt with
        | Lident ("::") ->
            (match view_expression_list x with
            | ls,true ->
                pp_print_list expression ppf ls ~first:"[" ~last:"]" ~sep:";"
            | ls,false -> 
                pp_print_list expression ppf ls ~sep:"::")
        | Lident ("()") -> fprintf ppf "()" ;
        | _ ->
            (match eo with
            | None ->
                fprintf ppf "@[<hov2>%a@]"
                  longident_loc li
            | Some x ->
                fprintf ppf "@[<hov2>%a@ (%a)@]"
                  longident_loc li expression x));
  | Pexp_field (e, li) ->
      fprintf ppf "@[<hov2>%a.%a@]"
      (fun ppf e -> match e.pexp_desc with
        | Pexp_ident (_) ->
            simple_expr ppf e 
        | _ ->
            expression_in_parens ppf e ) e longident_loc li 
  | Pexp_setfield (e1, li, e2) ->
      fprintf ppf "@[<hov2>%a.%a<-@ %a@]"
      (fun ppf e1 -> match e1.pexp_desc with
        | Pexp_ident (_) ->
            simple_expr ppf e1 
        | _ ->
            expression_in_parens ppf e1) e1
        longident_loc li 
      expression e2;

  | Pexp_ifthenelse (e1, e2, eo) ->
      fprintf ppf "@[<hv 0>" ;
      expression_if_common ppf e1 e2 eo;
      fprintf ppf "@]";

  | Pexp_sequence (_e1,_e2) ->
      fprintf ppf "begin@\n%a@\nend" 
      (fun ppf e -> expression_sequence  ppf ~first:false e) x ;

  | Pexp_constraint (e, cto1, cto2) ->
      (match (cto1, cto2) with
        | (None, None) -> expression ppf e ;
        | (Some (x1), Some (x2)) ->
            fprintf ppf "@[<hov2>(%a:@ %a:>@ %a)@]"
              expression e
              core_type x1
              core_type x2 
        | (Some (x), None) ->
            fprintf ppf "@[<hov2>(%a:@ %a)@]"
              expression e
              core_type x 
        | (None, Some (x)) ->
            fprintf ppf "@[<hov2>(%a:>@ %a)@]"
              expression e
              core_type x  )
  | Pexp_when (_e1, _e2) ->
      assert false ;
(* This is a wierd setup. The ocaml phrase
          "pattern when condition -> expression"
          found in pattern matching contexts is encoded as:
          "pattern -> when condition expression"
         Thus, the when clause ("when condition"), which one might expect
          to be part of the pattern, is encoded as part of the expression
          following the pattern.
         A "when clause" should never exist in a vaccum. It should always
          occur in a pattern matching context and be printed as part of the
          pattern (in pattern_x_expression_case_list).
         Thus these Pexp_when expressions are printed elsewhere, and if
          this code is executed, an error has occurred. *)
  | Pexp_send (e, s) ->
      fprintf ppf "@[<hov2>%a#%s@]"
      (fun ppf e -> match e.pexp_desc with
        | Pexp_ident(_) -> expression ppf e;
        | _ -> 
              expression_in_parens ppf e) e s 

  | Pexp_new (li) ->
      fprintf ppf "@[<hov2>new@ %a@]" longident_loc li;

  | Pexp_setinstvar (s, e) ->
      fprintf ppf "@[<hov2>%s@ <-@ %a@]" s.txt expression e
  | Pexp_override l ->
      fprintf ppf "@[<hov2>{<%a>}@]"
        (pp_print_list string_x_expression  ~sep:";"  )  l;
  | Pexp_letmodule (s, me, e) ->
      fprintf ppf "@[<hov2>let@ module@ %s@ =@ %a@ in@ %a@]" s.txt
        module_expr me
        (fun ppf e -> expression_sequence  ~first:false ~indent:0 ppf e ) e 
  | Pexp_assert (e) ->
      fprintf ppf "@[<hov2>assert@ %a@]" expression e 
  | Pexp_assertfalse ->
      fprintf ppf "assert@ false" ;
  | Pexp_lazy (e) ->
      fprintf ppf "@[<hov2>lazy@ %a@]" simple_expr e 
  | Pexp_poly (e, cto) -> (* should this even print by itself?  FIXME this overlaps with Pcf_meth*)
      (match cto with
        | None -> expression ppf e ;
        | Some (ct) ->
            pp_open_hovbox ppf indent ;
            expression ppf e ;
            fprintf ppf "@ (* poly:@ " ;
            core_type ppf ct ;
            fprintf ppf " *)" ;
            pp_close_box ppf () );
  | Pexp_object cs ->
      fprintf ppf "@[<hov2>%a@]" class_structure cs 
  | Pexp_open (lid, e) ->
      fprintf ppf "@[<hov2>let@ open@ %a@ in%a@]" longident_loc lid
        (fun ppf e -> expression_sequence ~first:false ~indent:0 ppf e) e 
  | _ -> simple_expr ppf x


and value_description ppf x =
  fprintf ppf "@[<hov2>%a%a@]"
    core_type x.pval_type
    (fun ppf x ->
      if x.pval_prim<>[] then begin
        fprintf ppf "@ =@ %a" 
        (pp_print_list constant_string)
          x.pval_prim ;
      end ) x


and type_declaration ppf x = begin
  fprintf ppf "@[<hov2>%a%a@ %a@]"
  (fun ppf x -> match (x.ptype_manifest,x.ptype_kind,x.ptype_private) with
     | (None,_,Public) -> ()
     | (None,_,Private) -> fprintf ppf "private@ "
     | (Some y, Ptype_abstract,Private) -> 
         fprintf ppf "private@ %a" core_type y;
     | (Some y, _, Private) -> 
         fprintf ppf "%a@ =@ private@ " core_type y 
     | (Some y,Ptype_abstract, Public) -> 
         core_type ppf y;
     | (Some y, _,Public) -> begin
         fprintf ppf "%a@ =@ " core_type y
     end
  ) x 
  (fun ppf x -> match x.ptype_kind with
    | Ptype_variant (first::rest) -> 
        fprintf ppf "@[<hov2>@[<hv>%a%a@]@]"
          (type_variant_leaf true) first
          type_variant_leaf_list rest
    | Ptype_variant [] ->
        assert false ;
    | Ptype_abstract -> ()
    | Ptype_record l -> 
        fprintf ppf "@[<hov2>{%a}@]"
        (pp_print_list type_record_field ~sep:";" )  l ;
     ) x 
  (pp_print_list typedef_constraint ~breakfirst:true )  x.ptype_cstrs  ;

end
and exception_declaration ppf x =
  match x with
  | [] -> ()
  | _ ->
      fprintf ppf "@ of@ %a"
      (pp_print_list ~sep:"*" core_type)  x 

and class_type ppf x =  match x.pcty_desc with
  | Pcty_signature cs ->
      class_signature ppf cs;
  | Pcty_constr (li, l) ->
      fprintf ppf "@[<hov2>%a%a@]"
      (fun ppf l -> match l with
      | [] -> ()
      | _  -> fprintf ppf "[%a]@ " (pp_print_list core_type ~sep:"," ) l) l 
      longident_loc li 
  | Pcty_fun (l, co, cl) ->
        fprintf ppf "@[<hov2>(%a@ ->@ %a)@ @]" (* FIXME remove parens later *)
        print_type_with_label (l,co) class_type cl;
and class_signature ppf { pcsig_self = ct; pcsig_fields = l ;_} =
  fprintf ppf "object%a@\n%a@\nend"
  (fun ppf ct -> match ct.ptyp_desc with
    | Ptyp_any -> ()
    | _ -> fprintf ppf "@ (%a)" core_type ct) ct
  (pp_print_list ~indent ~breakfirst:true class_type_field) l  ;

and class_type_field ppf x =
  match x.pctf_desc with
  | Pctf_inher (ct) ->      (* todo: test this *)
      fprintf ppf "@[<hov2>inherit@ %a@]"
        class_type ct 
  | Pctf_val (s, mf, vf, ct) ->
      fprintf ppf "@[<hov2>val @ %s%s%s@ :@ %a@]"
        (match mf with
        | Mutable -> "mutable "
        | _       -> "")
      (match vf with
        | Virtual -> "virtual "
        | _       -> "")
      s
      core_type  ct 
  | Pctf_virt (s, pf, ct) ->    (* todo: test this *)
      fprintf ppf "@[<hov2>@[<hov2>method@ %a@ virtual@ %s@]@ :@ %a@]"
        private_flag pf
        s
        core_type ct 
  | Pctf_meth (s, pf, ct) ->
      fprintf ppf "@[<hov2>@[<hov2>method@ %a@ %s@]@ :@ %a@]"
        private_flag pf
        s
        core_type ct 
  | Pctf_cstr (ct1, ct2) ->
      fprintf ppf "@[<hov2>constraint@ %a@ =@ %a@]"
        core_type ct1
        core_type ct2
and class_description ppf ({pci_params=(ls,_);pci_name={txt;_};_} as x) =
  fprintf ppf "@[<hv>@[<hov2>class@ %a%a%s@ :@]@ %a@]"
    virtual_flag x.pci_virt
    class_params_def ls
    txt
    class_type x.pci_expr
    
and class_type_declaration ppf x =
  class_type_declaration_ext ppf true x ;

and class_type_declaration_ext ppf first ({pci_params=(ls,_);pci_name={txt;_};_} as x) =
  fprintf ppf "@[<hv>@[<hov2>%s@ %a%a%s@ =@]@ %a@]"
    (if first then "class type" else "and")
    virtual_flag x.pci_virt
    class_params_def ls
    txt
    class_type x.pci_expr

and class_type_declaration_list ppf ?(first=true) l =
  match l with
  | [] -> () 
  | h :: [] ->
      class_type_declaration_ext ppf first h ;
  | h :: t ->
      class_type_declaration_ext ppf first h ;
      pp_print_space ppf () ;
      class_type_declaration_list ppf ~first:false t ;


and class_expr ppf x =
  match x.pcl_desc with
  | Pcl_structure (cs) ->
      class_structure ppf cs ;
  | Pcl_fun (l, eo, p, e) ->
      fprintf ppf "@[<hov2>fun@ %a@ ->@ %a@]"
        pp_print_label_exp (l,eo,p)
        class_expr e
  | Pcl_let (rf, l, ce) ->
      fprintf ppf "@[<hov>let@ %a@ %a@ in@ %a@]"
        rec_flag rf
        pattern_x_expression_def_list  l
        class_expr ce
  | Pcl_apply (ce, l) ->
      fprintf ppf "@[<hov2>(%a@ %a)@]"
      class_expr  ce
      (pp_print_list label_x_expression_param ~breakfirst:true ) l 
  | Pcl_constr (li, l) ->
      fprintf ppf "@[<hov2>%a%a@]"
      (fun ppf l-> if l <>[] then 
        fprintf ppf "[%a]@ " 
        (pp_print_list core_type  ~sep:"," ) l ) l 
       longident_loc li
  | Pcl_constraint (ce, ct) ->
      fprintf ppf "@[<hov2>(%a@ :@ %a)@]"
        class_expr ce
        class_type ct 
and class_structure ppf { pcstr_pat = p; pcstr_fields =  l } =
  fprintf ppf "@[<hv>@[<hov2>object%a@]%a@ end@]"
  (fun ppf p -> match p.ppat_desc with
    | Ppat_any -> ();
    | _ -> fprintf ppf "@ " ;
        pattern_in_parens ppf p ) p 
  (pp_print_list class_field  ~indent ~breakfirst:true) l 
and override ovf = match ovf with
    Override -> "!"
  | Fresh -> ""
and class_field ppf x =
  match x.pcf_desc with
  | Pcf_inher (ovf, ce, so) ->
      fprintf ppf "@[<hov2>inherit@ %s@ %a%a@]"
        (override ovf)
      class_expr ce
      (fun ppf so -> match so with
        | None -> ();
        | Some (s) -> fprintf ppf "@ as %s" s ) so 
  | Pcf_val (s, mf, ovf, e) ->
      fprintf ppf "@[<hov2>val@ %s@ %a@ %s@ =@ %a@]"
        (override ovf)
        mutable_flag mf
        s.txt 
       (fun ppf e -> expression_sequence  ~indent:0 ppf e) e 

  | Pcf_virt (s, pf, ct) ->
      fprintf ppf "@[<hov2>method@ virtual@ %a@ %s@ :@ %a@]"
        private_flag pf
        s.txt 
        core_type  ct

  | Pcf_valvirt (s, mf, ct) ->
      fprintf ppf "@[<hov2>val@ virtual@ %s@ %s@ :@ %a@]"
        (match mf with
        | Mutable -> "mutable "
        | _       -> "")
        s.txt
        core_type  ct

  | Pcf_meth (s, pf, ovf, e) ->
      fprintf ppf "@[<hov2>method@ %s@ %a@ %s%a@]"
        (override ovf)
        private_flag pf
        s.txt
        (* FIXME special Pexp_poly handling? *)
      (fun ppf e -> match e.pexp_desc with
        | Pexp_poly (e, Some(ct)) ->
            fprintf ppf "@ :@ %a@ =@ %a" 
            core_type  ct 
            expression e
        | _ ->
            fprintf ppf "@ =@ %a" 
            expression  e
      ) e 

  | Pcf_constr (ct1, ct2) ->
      fprintf ppf "@[<hov2>constraint@ %a@ =@ %a@]"
      core_type  ct1
      core_type  ct2

  | Pcf_init (e) ->
      fprintf ppf "@[<hov2>initializer@ %a@]"
      (fun ppf e -> expression_sequence  ~indent:0 ppf e) e 


and class_declaration_list ppf ?(first=true) l =
  match l with
  | [] ->
      if (first = false) then pp_close_box ppf ();
  | cd::l ->
      let s = (if first then begin pp_open_hvbox ppf 0 ; "class" end
          else begin pp_print_space ppf () ; "and" end) in
      class_declaration ppf ~str:s cd ;
      class_declaration_list ppf ~first:false l ;
and pp_print_pexp_class_function _ppf _e = raise Not_found
and class_declaration ppf ?(str="class") (* for the second will be changed to and FIXME*)
    ({pci_params=(ls,_);
      pci_name={txt;_};
      pci_virt;
      pci_expr={pcl_desc;_};
      pci_variance;_ } as x) = (* FIXME pci_variance *)
  let rec  class_fun_helper ppf e = match e.pcl_desc with
  | Pcl_fun (l, eo, p, e) ->
      pp_print_label_exp ppf (l,eo,p);
      class_fun_helper ppf e
  | _ -> e in 
  fprintf ppf "@[<hov2>%s@ %a%a%s@ %a@]"
    str
    virtual_flag pci_virt
    class_params_def ls
    txt 
  (fun ppf _ ->  
    let ce =
      (match pcl_desc with
      | Pcl_fun _ ->
          class_fun_helper ppf x.pci_expr;
      | _ -> x.pci_expr) in
    let ce =
      (match ce.pcl_desc with
      | Pcl_constraint (ce, ct) ->
          fprintf ppf ":@ %a@ " class_type  ct ;
          ce
      | _ -> ce ) in
  fprintf ppf "=@ %a" class_expr ce ) x 
and module_type ppf x =
  match x.pmty_desc with
  | Pmty_ident li ->
      fprintf ppf "%a" longident_loc li;
  | Pmty_signature (s) ->
      fprintf ppf "@[<hov>sig%a@ end@]"
      (pp_print_list signature_item  ~breakfirst:true ~indent) s
  | Pmty_functor (s, mt1, mt2) ->
      fprintf ppf "@[<hov2>functor@ (%s@ :@ %a)@ ->@ %a@]"
        s.txt
        module_type mt1
        module_type mt2 
  | Pmty_with (mt, l) ->
      fprintf ppf "@[<hov2>(%a@ with@ %a)@]"
      module_type  mt 
      (fun ppf  l -> longident_x_with_constraint_list ppf l) l
  | Pmty_typeof me ->
      fprintf ppf "@[<hov2>module@ type@ of@ %a@]"
      module_expr me 
and signature ppf x =  pp_print_list ~sep_action:pp_print_newline signature_item ppf x

and signature_item ppf x :unit= begin
    match x.psig_desc with
    | Psig_type l ->
        string_x_type_def_list ppf l
    | Psig_value (s, vd) ->
        fprintf ppf "@[<hov2>%a@]"
          (fun ppf (s,vd) -> 
            let intro = if vd.pval_prim = [] then "val" else "external" in
            if (is_infix (fixity_of_string s.txt)) || List.mem s.txt.[0] prefix_symbols then
              fprintf ppf "%s@ (@ %s@ )@ :@ " intro s.txt                
            else
              fprintf ppf "%s@ %s@ :@ " intro s.txt;
            value_description ppf vd;) (s,vd)
    | Psig_exception (s, ed) ->
        fprintf ppf "@[<hov2>exception@ %s@ %a@]"
          s.txt
          exception_declaration  ed
    | Psig_class (l) ->
        fprintf ppf "@[<hov2>%a@]"
        (pp_print_list class_description) l 
    | Psig_module (s, mt) ->
        fprintf ppf "@[<hov>module@ %s@ :@ %a@]"
          s.txt
          module_type  mt
    | Psig_open li ->
        fprintf ppf "@[<hov2>open@ %a@]" longident_loc li
    | Psig_include (mt) ->
        fprintf ppf "@[<hov2>include@ %a@]"
        module_type  mt
    | Psig_modtype (s, md) ->
        fprintf ppf "@[<hov2>module@ type@ %s%a@]"
          s.txt
        (fun ppf md -> match md with
          | Pmodtype_abstract -> ()
          | Pmodtype_manifest (mt) ->
              pp_print_space ppf () ;
              fprintf ppf "@ =@ %a"  module_type mt
        ) md 
    | Psig_class_type (l) ->
        class_type_declaration_list ppf l ;
    | Psig_recmodule decls ->
        let rec  string_x_module_type_list ppf ?(first=true) l =
          match l with
          | [] -> () ;
          | (s,mty) :: tl ->
              if not first then
                fprintf ppf "@ @[<hov2>and@ %s:@ %a@]"
                  s.txt module_type mty
              else
                fprintf ppf "@ @[<hov2>module@ rec@ %s:@ %a@]"
                  s.txt module_type mty;
              string_x_module_type_list ppf ~first:false tl  in
        string_x_module_type_list ppf decls
  end
and module_expr ppf x =
  match x.pmod_desc with
  | Pmod_structure (s) ->
      fprintf ppf "@[<hov2>struct%a@ end@]"
      (pp_print_list structure_item  ~breakfirst:true ~indent) s;
  | Pmod_constraint (me, mt) ->
      fprintf ppf "@[<hov2>(%a@ :@ %a)@]"
        module_expr  me
        module_type mt
  | Pmod_ident (li) ->
      fprintf ppf "%a" longident_loc li;
  | Pmod_functor (s, mt, me) ->
      fprintf ppf "@[<hov2>functor@ (%s@ :@ %a)@ ->@ %a@]"
        s.txt  module_type mt  module_expr me
  | Pmod_apply (me1, me2) ->
      fprintf ppf "@[<hov2>(%a)@ (%a)@]" module_expr me1  module_expr  me2
  | Pmod_unpack e ->
      fprintf ppf "@[<hov2>(val@ %a)@]"  expression  e
and structure ppf x = pp_print_list ~sep_action:pp_print_newline structure_item ppf x ;
and structure_item ppf x = begin
    match x.pstr_desc with
    | Pstr_eval (e) ->
        fprintf ppf "@[<hov2>let@ _=@ %a@]"
          (fun ppf e -> expression_sequence ~first:false ~indent:0 ppf e) e 
    | Pstr_type [] -> assert false
    | Pstr_type l  -> string_x_type_def_list ppf l 
    | Pstr_value (rf, l) ->
        fprintf ppf "@[<hov2>let@ %a@ %a@]"
          rec_flag rf
          pattern_x_expression_def_list l ;
    | Pstr_exception (s, ed) ->
        fprintf ppf "@[<hov2>exception@ %s@ %a@]" s.txt exception_declaration ed
    | Pstr_module (s, me) ->
        let rec module_helper me = match me.pmod_desc with
        | Pmod_functor(s,mt,me) ->
            fprintf ppf "(%s:%a)"  s.txt  module_type mt ;
            module_helper me
        | _ -> me in 
        fprintf ppf "@[<hov2>module@ %s@ %a@]"
          s.txt
          (fun ppf me ->
            let me = module_helper me  in
            (match me.pmod_desc with
            | Pmod_constraint
                (me,
                 ({pmty_desc=(Pmty_ident (_)
                 | Pmty_signature (_));_} as mt)) ->
                     fprintf ppf "@ :@ %a@ =@ %a@ "  module_type mt module_expr  me 
            | _ ->
                fprintf ppf "@ =@ %a"  module_expr  me 
        )) me 
    | Pstr_open (li) ->
        fprintf ppf "open %a" longident_loc li;
    | Pstr_modtype (s, mt) ->
        fprintf ppf "@[<hov2>module@ type@ %s@ =@ %a@]" s.txt module_type mt 
    | Pstr_class l ->
        class_declaration_list ppf l;
    | Pstr_class_type (l) ->
        class_type_declaration_list ppf l ;
    | Pstr_primitive (s, vd) ->
        let need_parens =
          match s.txt with
          | "or" | "mod" | "land"| "lor" | "lxor" | "lsl" | "lsr" | "asr" -> true
          | _ -> match s.txt.[0] with
              'a'..'z' -> false | _ -> true in
        fprintf ppf "@[<hov2>external@ %s@ :@ %a"
          (if need_parens then "( "^s.txt^" )" else s.txt)
          value_description  vd
    | Pstr_include me ->
        fprintf ppf "@[<hov2>include@ %a@]"  module_expr  me 
    | Pstr_exn_rebind (s, li) ->        (* todo: check this *)
        fprintf ppf "@[<hov2>exception@ %s@ =@ %a@]" s.txt longident_loc li 
    | Pstr_recmodule decls -> (* 3.07 *)
        let text_x_modtype_x_module ppf (s, mt, me) =
          fprintf ppf "@[<hov2>and@ %s:%a@ =@ %a@]"
            s.txt module_type mt module_expr me
        in match decls with
        | (s,mt,me):: l2 ->
            fprintf ppf "@[<hv>@[<hov2>module@ rec@ %s:%a@ =@ %a@]@ %a@]"
              s.txt
              module_type mt
              module_expr me 
              (fun ppf l2 -> List.iter (text_x_modtype_x_module ppf) l2) l2 
        | _ -> assert false
  end;


    
and  string_x_type_def_list ppf ?(first=true) l = match l with
  | [] -> () ;
  | (s, ({ptype_params;ptype_kind;ptype_manifest;_} as td )) :: tl -> begin

      fprintf ppf "@[<hov2>%s@ %a%s%a@]"
        (if not first then "and"else "type")
      (fun ppf ptype_params -> 
        match ptype_params with
        | [] -> ()
        | [x] -> fprintf ppf "%a@ " pp_print_type_var_option x
        | xs -> fprintf ppf "@[<hov2>(%a)@]"
              (pp_print_list pp_print_type_var_option ~sep:",") xs )
        ptype_params
        s.txt
        (fun ppf td -> begin match ptype_kind, ptype_manifest with
        | Ptype_abstract, None -> ()
        | _ , _ -> fprintf ppf "@ =@ " end;
            fprintf ppf "@ %a" type_declaration td ) td ;
      string_x_type_def_list ppf ~first:false tl 
  end

 
and longident_x_with_constraint_list ?(first=true) ppf l =
  match l with
  | [] -> () ;
  | h :: [] ->
      if not first then fprintf ppf "@ and " ;
      longident_x_with_constraint ppf h ;
  | h :: t  ->
      if not first then fprintf ppf "@ and " ;
      longident_x_with_constraint ppf h ;
      longident_x_with_constraint_list ~first:false ppf t;

and string_x_core_type_ands ?(first=true) (ppf:Format.formatter) l :unit=
  match l with
  | [] -> () ;
  | h :: [] ->
      if not first  then fprintf ppf "@ and " ;
      string_x_core_type ppf h ;
  | h :: t  ->
      if not first  then fprintf ppf "@ and " ;
      string_x_core_type ppf h;
      string_x_core_type_ands ~first:false ppf t;

and string_x_core_type ppf (s, ct) =
  fprintf ppf "type %a@ =@ %a" longident_loc s core_type ct (* bug fix *)

and longident_x_with_constraint ppf (li, wc) =
  match wc with
  | Pwith_type ({ptype_params= ls ;_} as td) ->
      fprintf ppf "type@ %a %a =@ "
        (fun ppf ls ->
          let len = List.length ls in
          if len >= 2 then begin
            fprintf ppf "(";
            pp_print_list pp_print_type_var_option ppf ls ~sep:";";
            fprintf ppf ")";
           end
        else
            pp_print_list pp_print_type_var_option ppf ls ~sep:",";
        ) ls
        longident_loc li;
      type_declaration ppf td ;
  | Pwith_module (li2) ->
      fprintf ppf "module %a =@ %a" longident_loc li longident_loc li2;
  | Pwith_typesubst ({ptype_params=ls;_} as td) -> (* bug fix *)

      fprintf ppf "type@ %a %a :=@ "
        (fun ppf ls ->
          let len = List.length ls in
          if len >= 2 then begin
            fprintf ppf "(";
            pp_print_list pp_print_type_var_option ppf ls ~sep:",";
            fprintf ppf ")";
           end
        else
            pp_print_list pp_print_type_var_option ppf ls ~sep:",";
        ) ls longident_loc li;
      type_declaration ppf td ;
  | Pwith_modsubst (li2) ->
      fprintf ppf "module %a :=@ %a" longident_loc li longident_loc li2;

and typedef_constraint ppf (ct1, ct2, _l) =
  fprintf ppf "@[<hov2>constraint@ %a@ =@ %a@]" core_type ct1 core_type ct2

and type_variant_leaf first ppf  (s, l,_, _)  = (* TODO *)
  if (first) then begin
      pp_print_if_newline ppf ();
      pp_print_string ppf "  ";
    end else begin
      pp_print_space ppf ();
      fprintf ppf "| " ;
    end ;
  pp_open_hovbox ppf indent ;
  fprintf ppf "%s" s.txt ;
  if ((List.length l) > 0) then begin
    fprintf ppf "@ of@ " ;
    pp_print_list core_type ppf l ~sep:"*";
    end ;
  pp_close_box ppf ();

and type_variant_leaf_list ppf list =
  match list with
  | [] -> ()
  | first :: rest ->
      type_variant_leaf false ppf first  ;
      type_variant_leaf_list ppf rest ;

and type_record_field ppf (s, mf, ct,_) =
  pp_open_hovbox ppf indent ;
  fprintf ppf "%a%s:" mutable_flag mf s.txt ;
  core_type ppf ct ;
  pp_close_box ppf () ;

and longident_x_pattern ppf (li, p) =
  pp_open_hovbox ppf indent ;
  fprintf ppf "%a =@ " longident_loc li;
  pattern ppf p;
  pp_close_box ppf () ;


and pattern_with_when ppf (whenclause, x) =
  match whenclause with
  | None -> pattern ppf x ;
  | Some (e) ->
      fprintf ppf "@[<hov2>%a@ when@ %a@]" pattern x expression e 

and pattern_x_expression_case_list  ppf  
  (l:(pattern * expression) list) :unit=
  let loop ppf l = match l with
  | []        -> ()
  | (p,e)::[] -> 
      fprintf ppf "@[<hov2>|@ %a@]" begin fun ppf (p,e) -> 
        let (e,w) =
          (match e with
          | {pexp_desc = Pexp_when (e1, e2);_} -> (e2, Some (e1))
          | _ -> (e, None)) in
        pattern_with_when ppf (w, p) ;
        fprintf ppf "@ ->@ " ;
        expression_sequence ppf ~indent:0 e ;
      end (p,e)
  | (p,e)::r  -> 
      fprintf ppf "@[<hov2>|@ %a@]@\n%a" begin fun ppf (p,e) -> 
        let (e,w) =
          (match e with
          | {pexp_desc = Pexp_when (e1, e2);_} -> (e2, Some (e1))
          | _ -> (e, None)) in
        pattern_with_when ppf (w, p) ;
        fprintf ppf "@ ->@ " ;
        expression_sequence ppf ~indent:0 e
      end (p,e)
        pattern_x_expression_case_list r in
  fprintf ppf "@[<hov>%a@]" loop l (* no indentation here*)
        

and pattern_x_expression_def ppf (p, e) =
  match e.pexp_desc with
  | Pexp_when (e1,e2) ->
      fprintf ppf "=@[<hov2>fun@ %a@ ->@ %a@]"
        pattern_with_when (Some e1,p)
            expression e2 
  | _ -> fprintf ppf "%a@ %a" pattern p pp_print_pexp_function e
(* prints a list of definitions as found in a let statement
   note! breaks "open and close boxes in same function" convention, however
         does always open and close the same number of boxes. (i.e. no "net
         gain or loss" of box depth.                                         *)
and pattern_x_expression_def_list ppf l =
  match l with
  | [] -> ()
  | [x] -> pattern_x_expression_def ppf x 
  | _ ->
   pp_print_list pattern_x_expression_def ~sep:"and" ppf l 


and string_x_expression ppf (s, e) =
   fprintf ppf "@[<hov2>%s@ =@ %a@]" s.txt expression e

and longident_x_expression ppf (li, e) =
   fprintf ppf "@[<hov2>%a@ =@ %a@]" longident_loc li simple_expr e

and label_x_expression_param ppf (l,e) =
  match l with
  | ""  -> simple_expr ppf e ;
  | lbl ->
      if ((String.get lbl 0) = '?') then begin
          fprintf ppf "%s:" lbl ;
          simple_expr ppf e ;
        end else begin
          fprintf ppf "~%s:" lbl ;
          simple_expr ppf e ;
        end ;

and expression_in_parens ppf e =
  let already_has_parens =
    (match e.pexp_desc with
        Pexp_apply ({pexp_desc=Pexp_ident ({ txt = Ldot (
                Lident(modname), funname) ;_});_},_)
        -> (match modname,funname with
            | "Array","get" -> false;
            | "Array","set" -> false;
            | _,_ -> true) ;
      | Pexp_apply ({pexp_desc=Pexp_ident ({ txt = Lident(funname) ;_});_},_)
        -> (match funname with
            | "!" -> false;
            | _ -> true);
      | Pexp_apply (_,_) -> true;
      | Pexp_match (_,_) -> true;
      | Pexp_tuple (_) -> true ;
      | Pexp_constraint (_,_,_) -> true ;
      | _ -> false) in
  if (already_has_parens) then expression ppf e
  else begin
      fprintf ppf "(" ;
      expression ppf e ;
      fprintf ppf ")" ;
    end ;

and pattern_in_parens ppf p =
  let already_has_parens =
    match p.ppat_desc with
    | Ppat_alias (_,_) -> true
    | Ppat_tuple (_) -> true
    | Ppat_or (_,_) -> true
    | Ppat_constraint (_,_) -> true
    | _ -> false in
  if (already_has_parens) then pattern ppf p
  else begin
      fprintf ppf "(" ;
      pattern ppf p ;
      fprintf ppf ")" ;
    end;

and pattern_constr_params_option ppf po =
  match po with
  | None -> ();
  | Some pat ->
      pp_print_space ppf ();
      pattern_in_parens ppf pat;

and type_variant_helper ppf x =
  match x with
  | Rtag (l, _, ctl) ->  (* FIXME the second field *)
   fprintf ppf "@[<hov2>%a%a@]" 
   pp_print_string_quot l
   (fun ppf l -> match l with
   |[] -> ()
   | _ -> begin
   fprintf ppf "@ of@ ";
   pp_print_list core_type ppf ctl ~sep:"&"
   end) ctl
  | Rinherit (ct) ->
      core_type ppf ct


(* end an if statement by printing an else phrase if there is an "else"
   statement in the ast. otherwise just close the box. *)
(* added: special case for "else if" case *)

and expression_eo ppf eo extra =
  match eo with
  | None   -> ();
  | Some x ->
      if extra then fprintf ppf " "
      else fprintf ppf "@ " ;
      match x.pexp_desc with
      | Pexp_ifthenelse (e1, e2, eo) ->   (* ... else if ...*)
          fprintf ppf "else" ;
          expression_elseif ppf (e1, e2, eo)
      | Pexp_sequence (_e1, _e2) ->
          fprintf ppf "else" ;
          expression_ifbegin ppf x;       (* ... else begin ... end*)
      | _ ->                              (* ... else ... *)
          pp_open_hvbox ppf indent ;
          fprintf ppf "else@ " ;
          expression ppf x ;
          pp_close_box ppf () ;

and expression_elseif ppf (e1,e2,eo) =
  fprintf ppf " " ;
  expression_if_common ppf e1 e2 eo ;

and expression_ifbegin ppf e =
  fprintf ppf " begin";
  pp_print_break ppf 1 indent ; (* "@;<1 2>"; *)
  expression_sequence ppf e;
  pp_print_break ppf 1 0 ; (* fprintf ppf "@;<1 0>" *)
  fprintf ppf "end";

and expression_if_common ppf e1 e2 eo =
  match eo, e2.pexp_desc with
  | None, Pexp_sequence (_, _) ->
      fprintf ppf "if@ " ;
      expression ppf e1;
      fprintf ppf "@ then@ " ;
      expression_ifbegin ppf e2
  | None, _ ->
      fprintf ppf "if@ " ;
      expression ppf e1;
      fprintf ppf "@ then@ " ;
      simple_expr ppf e2
  | Some _, Pexp_sequence _ ->
      fprintf ppf "if " ;
      expression ppf e1;
      fprintf ppf "@ then@ " ;
      expression_ifbegin ppf e2;
      expression_eo ppf eo true;   (* ... then begin ... end *)
  | Some _, _ ->
      pp_open_hvbox ppf indent ;
      fprintf ppf "if " ;
      expression ppf e1;
      fprintf ppf " then@ " ;
      simple_expr ppf e2;
      pp_close_box ppf () ;
      expression_eo ppf eo false;

and expression_sequence ppf ?(skip=1) ?(indent=indent) ?(first=true) expr =
  if (first = true) then begin
    pp_open_hvbox ppf 0 ;
    expression_sequence ppf ~skip:skip ~indent:0 ~first:false expr ;
    pp_close_box ppf () ;
  end else
    match expr.pexp_desc with
    | Pexp_sequence (e1, e2) ->
         simple_expr ppf e1 ;
         fprintf ppf ";" ;
         pp_print_break ppf skip indent ; (* "@;<1 2>" ; *)
         expression_sequence ppf ~skip:skip ~indent:indent ~first:false e2 ;
    | _ ->
         expression ppf expr ;

(*
  either a::b::c::d
  or a::b::c::[]
 *)
and view_expression_list (exp:Parsetree.expression) =
   let rec loop exp acc = match exp with
   |{pexp_desc=Pexp_construct ({txt=Lident "[]";_},_,_);_} -> (List.rev acc,true)
   |{pexp_desc=
     Pexp_construct ({txt=Lident "::";_},Some ({pexp_desc= Pexp_tuple([e1;e2]);_}),_);_} ->
   loop e2 (e1::acc)
   | e -> (List.rev (e::acc),false) in loop exp []
   
and expression_is_terminal_list exp =
  match exp with
  | {pexp_desc = Pexp_construct ({ txt = Lident("[]");_}, None, _);_}
     -> true ;
  | {pexp_desc = Pexp_construct ({ txt = Lident("::");_},
                   Some({pexp_desc = Pexp_tuple([_exp1 ; exp2]);_}), _);_}
     -> (expression_is_terminal_list exp2)
  | {pexp_desc = _;_}
     -> false
and expression_list_nonterminal ppf exp =
  match exp with
  | {pexp_desc = Pexp_construct ({ txt = Lident("[]") ;_}, None, _);_}
     -> assert false
  | {pexp_desc = Pexp_construct ({ txt = Lident("::") ;_},
                   Some({pexp_desc = Pexp_tuple([exp1 ; exp2]);_}), _);_}
     -> simple_expr ppf exp1;
        fprintf ppf " ::@ ";
        expression_list_nonterminal ppf exp2;
  | _ -> expression ppf exp;
;
and expression_list_helper ppf exp =
  match exp with
  | {pexp_desc = Pexp_construct ({ txt = Lident("[]") ;_}, None, _);_}
     -> () ;
  | {pexp_desc = Pexp_construct ({ txt = Lident("::") ;_},
                   Some({pexp_desc = Pexp_tuple([exp1 ; exp2]);_}), _);_}
     -> fprintf ppf ";@ " ;
        simple_expr ppf exp1 ;
        expression_list_helper ppf exp2 ;
  | _ -> assert false

and directive_argument ppf x =
  (match x with
  | Pdir_none -> ()
  | Pdir_string (s) -> fprintf ppf "@ \"%s\"" s
  | Pdir_int (i) -> fprintf ppf "@ %d" i
  | Pdir_ident (li) -> fprintf ppf "@ %a" longident li
  | Pdir_bool (b) -> fprintf ppf "@ %s" (string_of_bool b));;




let toplevel_phrase ppf x =
  match x with
  | Ptop_def (s) ->
   pp_open_hvbox ppf 0;
   pp_print_list structure_item ppf s ~breakfirst:false ~indent:0 ;
   pp_close_box ppf ();
  | Ptop_dir (s, da) ->
      pp_open_hovbox ppf indent;
      fprintf ppf "#%s" s;
      directive_argument ppf da;
      pp_close_box ppf () ;;

let expression ppf x =
  fprintf ppf "@[";
  expression ppf x;
  fprintf ppf "@]";;

let string_of_expression x =
  ignore (flush_str_formatter ()) ;
  let ppf = str_formatter in
  expression ppf x ;
  flush_str_formatter () ;;

let top_phrase ppf x =
  pp_print_newline ppf () ;
  toplevel_phrase ppf x;
  fprintf ppf ";;" ;
  pp_print_newline ppf ();;
   
