(* camlp4r *)
(****************************************************************************)
(*                                                                          *)
(*                                   OCaml                                  *)
(*                                                                          *)
(*                            INRIA Rocquencourt                            *)
(*                                                                          *)
(*  Copyright  2006   Institut National de Recherche  en  Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed under   *)
(*  the terms of the GNU Library General Public License, with the special   *)
(*  exception on linking described in LICENSE at the top of the OCaml       *)
(*  source tree.                                                            *)
(*                                                                          *)
(****************************************************************************)

(* Authors:
 * - Daniel de Rauglaudre: initial version
 * - Nicolas Pouillard: refactoring
 *)



(** Camlp4 signature repository *)

(** {6 Basic signatures} *)

(** Signature with just a type. *)
module type Type = sig
  type t;
end;


(** A signature for extensions identifiers. *)
module type Id = sig

  (** The name of the extension, typically the module name. *)
  value name    : string;

  (** The version of the extension, typically $ Id$ with a versionning system. *)
  value version : string;

end;

(** A signature for warnings abstract from locations. *)
(* module Warning (Loc : Type) = struct *)
(*   module type S = sig *)
(*     type warning = Loc.t -> string -> unit; *)
(*     value default_warning : warning; *)
(*     value current_warning : ref warning; *)
(*     value print_warning   : warning; *)
(*   end; *)
(* end; *)
module type Warning = sig
  type warning = FanLoc.t -> string -> unit;
  value default_warning: warning;
  value current_warning: ref warning;
  value print_warning: warning;  
end;
  
(** {6 Advanced signatures} *)

(** Abstract syntax tree minimal signature.
    Types of this signature are abstract.
    See the {!Camlp4Ast} signature for a concrete definition. *)
module type Ast = sig

  (** {6 Syntactic categories as abstract types} *)

  type loc;
  type meta_bool;
  type meta_option 'a;
  type meta_list 'a;
  type ctyp;
  type patt;
  type expr;
  type module_type;
  type sig_item;
  type with_constr;
  type module_expr;
  type str_item;
  type class_type;
  type class_sig_item;
  type class_expr;
  type class_str_item;
  type match_case;
  type ident;
  type binding;
  type rec_binding;
  type module_binding;
  type rec_flag;
  type direction_flag;
  type mutable_flag;
  type private_flag;
  type virtual_flag;
  type row_var_flag;
  type override_flag;

  (** {6 Location accessors} *)

  value loc_of_ctyp : ctyp -> loc;
  value loc_of_patt : patt -> loc;
  value loc_of_expr : expr -> loc;
  value loc_of_module_type : module_type -> loc;
  value loc_of_module_expr : module_expr -> loc;
  value loc_of_sig_item : sig_item -> loc;
  value loc_of_str_item : str_item -> loc;
  value loc_of_class_type : class_type -> loc;
  value loc_of_class_sig_item : class_sig_item -> loc;
  value loc_of_class_expr : class_expr -> loc;
  value loc_of_class_str_item : class_str_item -> loc;
  value loc_of_with_constr : with_constr -> loc;
  value loc_of_binding : binding -> loc;
  value loc_of_rec_binding : rec_binding -> loc;
  value loc_of_module_binding : module_binding -> loc;
  value loc_of_match_case : match_case -> loc;
  value loc_of_ident : ident -> loc;

  (** {6 Traversals} *)

  (** This class is the base class for map traversal on the Ast.
      To make a custom traversal class one just extend it like that:

      This example swap pairs expression contents:
      open Camlp4.PreCast;
      [class swap = object
        inherit Ast.map as super;
        method expr e =
          match super#expr e with
          \[ <:expr\@_loc< ($e1$, $e2$) >> -> <:expr< ($e2$, $e1$) >>
          | e -> e \];
      end;
      value _loc = Loc.ghost;
      value map = (new swap)#expr;
      assert (map <:expr< fun x -> (x, 42) >> = <:expr< fun x -> (42, x) >>);]
  *)
  class map : object ('self_type)
    method string : string -> string;
    method list : ! 'a 'b . ('self_type -> 'a -> 'b) -> list 'a -> list 'b;
    method meta_bool : meta_bool -> meta_bool;
    method meta_option : ! 'a 'b . ('self_type -> 'a -> 'b) -> meta_option 'a -> meta_option 'b;
    method meta_list : ! 'a 'b . ('self_type -> 'a -> 'b) -> meta_list 'a -> meta_list 'b;
    method loc : loc -> loc;
    method expr : expr -> expr;
    method patt : patt -> patt;
    method ctyp : ctyp -> ctyp;
    method str_item : str_item -> str_item;
    method sig_item : sig_item -> sig_item;

    method module_expr : module_expr -> module_expr;
    method module_type : module_type -> module_type;
    method class_expr : class_expr -> class_expr;
    method class_type : class_type -> class_type;
    method class_sig_item : class_sig_item -> class_sig_item;
    method class_str_item : class_str_item -> class_str_item;
    method with_constr : with_constr -> with_constr;
    method binding : binding -> binding;
    method rec_binding : rec_binding -> rec_binding;
    method module_binding : module_binding -> module_binding;
    method match_case : match_case -> match_case;
    method ident : ident -> ident;
    method override_flag : override_flag -> override_flag;
    method mutable_flag : mutable_flag -> mutable_flag;
    method private_flag : private_flag -> private_flag;
    method virtual_flag : virtual_flag -> virtual_flag;
    method direction_flag : direction_flag -> direction_flag;
    method rec_flag : rec_flag -> rec_flag;
    method row_var_flag : row_var_flag -> row_var_flag;

    method unknown : ! 'a. 'a -> 'a;
  end;

  (** Fold style traversal *)
  class fold : object ('self_type)
    method string : string -> 'self_type;
    method list : ! 'a . ('self_type -> 'a -> 'self_type) -> list 'a -> 'self_type;
    method meta_bool : meta_bool -> 'self_type;
    method meta_option : ! 'a . ('self_type -> 'a -> 'self_type) -> meta_option 'a -> 'self_type;
    method meta_list : ! 'a . ('self_type -> 'a -> 'self_type) -> meta_list 'a -> 'self_type;
    method loc : loc -> 'self_type;
    method expr : expr -> 'self_type;
    method patt : patt -> 'self_type;
    method ctyp : ctyp -> 'self_type;
    method str_item : str_item -> 'self_type;
    method sig_item : sig_item -> 'self_type;
    method module_expr : module_expr -> 'self_type;
    method module_type : module_type -> 'self_type;
    method class_expr : class_expr -> 'self_type;
    method class_type : class_type -> 'self_type;
    method class_sig_item : class_sig_item -> 'self_type;
    method class_str_item : class_str_item -> 'self_type;
    method with_constr : with_constr -> 'self_type;
    method binding : binding -> 'self_type;
    method rec_binding : rec_binding -> 'self_type;
    method module_binding : module_binding -> 'self_type;
    method match_case : match_case -> 'self_type;
    method ident : ident -> 'self_type;
    method rec_flag : rec_flag -> 'self_type;
    method direction_flag : direction_flag -> 'self_type;
    method mutable_flag : mutable_flag -> 'self_type;
    method private_flag : private_flag -> 'self_type;
    method virtual_flag : virtual_flag -> 'self_type;
    method row_var_flag : row_var_flag -> 'self_type;
    method override_flag : override_flag -> 'self_type;

    method unknown : ! 'a. 'a -> 'self_type;
  end;

end;


(** Signature for OCaml syntax trees. *) (*
    This signature is an extension of {!Ast}
    It provides:
      - Types for all kinds of structure.
      - Map: A base class for map traversals.
      - Map classes and functions for common kinds.

    == Core language ==
    ctyp               :: Representaion of types
    patt               :: The type of patterns
    expr               :: The type of expressions
    match_case         :: The type of cases for match/function/try constructions
    ident              :: The type of identifiers (including path like Foo(X).Bar.y)
    binding            :: The type of let bindings
    rec_binding        :: The type of record definitions

    == Modules ==
    module_type        :: The type of module types
    sig_item           :: The type of signature items
    str_item           :: The type of structure items
    module_expr        :: The type of module expressions
    module_binding     :: The type of recursive module definitions
    with_constr        :: The type of `with' constraints

    == Classes ==
    class_type         :: The type of class types
    class_sig_item     :: The type of class signature items
    class_expr         :: The type of class expressions
    class_str_item     :: The type of class structure items
 *)
module type Camlp4Ast = sig

  (** The inner module for locations *)
  module Loc : module type of FanLoc;

  INCLUDE "src/Camlp4/Camlp4Ast.partial.ml";

  value loc_of_ctyp : ctyp -> loc;
  value loc_of_patt : patt -> loc;
  value loc_of_expr : expr -> loc;
  value loc_of_module_type : module_type -> loc;
  value loc_of_module_expr : module_expr -> loc;
  value loc_of_sig_item : sig_item -> loc;
  value loc_of_str_item : str_item -> loc;
  value loc_of_class_type : class_type -> loc;
  value loc_of_class_sig_item : class_sig_item -> loc;
  value loc_of_class_expr : class_expr -> loc;
  value loc_of_class_str_item : class_str_item -> loc;
  value loc_of_with_constr : with_constr -> loc;
  value loc_of_binding : binding -> loc;
  value loc_of_rec_binding : rec_binding -> loc;
  value loc_of_module_binding : module_binding -> loc;
  value loc_of_match_case : match_case -> loc;
  value loc_of_ident : ident -> loc;

  module Meta : sig
    module type META_LOC = sig
      (* The first location is where to put the returned pattern.
          Generally it's _loc to match with <:patt< ... >> quotations.
          The second location is the one to treat. *)
      value meta_loc_patt : loc -> loc -> patt;
      (* The first location is where to put the returned expression.
          Generally it's _loc to match with <:expr< ... >> quotations.
          The second location is the one to treat. *)
      value meta_loc_expr : loc -> loc -> expr;
    end;
    module MetaLoc : sig
      value meta_loc_patt : loc -> loc -> patt;
      value meta_loc_expr : loc -> loc -> expr;
    end;
    module MetaGhostLoc : sig
      value meta_loc_patt : loc -> 'a -> patt;
      value meta_loc_expr : loc -> 'a -> expr;
    end;
    module MetaLocVar : sig
      value meta_loc_patt : loc -> 'a -> patt;
      value meta_loc_expr : loc -> 'a -> expr;
    end;
    module Make (MetaLoc : META_LOC) : sig
      module Expr : sig
        value meta_string : loc -> string -> expr;
        value meta_int : loc -> string -> expr;
        value meta_float : loc -> string -> expr;
        value meta_char : loc -> string -> expr;
        value meta_bool : loc -> bool -> expr;
        value meta_list : (loc -> 'a -> expr) -> loc -> list 'a -> expr;
        value meta_binding : loc -> binding -> expr;
        value meta_rec_binding : loc -> rec_binding -> expr;
        value meta_class_expr : loc -> class_expr -> expr;
        value meta_class_sig_item : loc -> class_sig_item -> expr;
        value meta_class_str_item : loc -> class_str_item -> expr;
        value meta_class_type : loc -> class_type -> expr;
        value meta_ctyp : loc -> ctyp -> expr;
        value meta_expr : loc -> expr -> expr;
        value meta_ident : loc -> ident -> expr;
        value meta_match_case : loc -> match_case -> expr;
        value meta_module_binding : loc -> module_binding -> expr;
        value meta_module_expr : loc -> module_expr -> expr;
        value meta_module_type : loc -> module_type -> expr;
        value meta_patt : loc -> patt -> expr;
        value meta_sig_item : loc -> sig_item -> expr;
        value meta_str_item : loc -> str_item -> expr;
        value meta_with_constr : loc -> with_constr -> expr;
        value meta_rec_flag : loc -> rec_flag -> expr;
        value meta_mutable_flag : loc -> mutable_flag -> expr;
        value meta_virtual_flag : loc -> virtual_flag -> expr;
        value meta_private_flag : loc -> private_flag -> expr;
        value meta_row_var_flag : loc -> row_var_flag -> expr;
        value meta_override_flag : loc -> override_flag -> expr;
        value meta_direction_flag : loc -> direction_flag -> expr;
      end;
      module Patt : sig
        value meta_string : loc -> string -> patt;
        value meta_int : loc -> string -> patt;
        value meta_float : loc -> string -> patt;
        value meta_char : loc -> string -> patt;
        value meta_bool : loc -> bool -> patt;
        value meta_list : (loc -> 'a -> patt) -> loc -> list 'a -> patt;
        value meta_binding : loc -> binding -> patt;
        value meta_rec_binding : loc -> rec_binding -> patt;
        value meta_class_expr : loc -> class_expr -> patt;
        value meta_class_sig_item : loc -> class_sig_item -> patt;
        value meta_class_str_item : loc -> class_str_item -> patt;
        value meta_class_type : loc -> class_type -> patt;
        value meta_ctyp : loc -> ctyp -> patt;
        value meta_expr : loc -> expr -> patt;
        value meta_ident : loc -> ident -> patt;
        value meta_match_case : loc -> match_case -> patt;
        value meta_module_binding : loc -> module_binding -> patt;
        value meta_module_expr : loc -> module_expr -> patt;
        value meta_module_type : loc -> module_type -> patt;
        value meta_patt : loc -> patt -> patt;
        value meta_sig_item : loc -> sig_item -> patt;
        value meta_str_item : loc -> str_item -> patt;
        value meta_with_constr : loc -> with_constr -> patt;
        value meta_rec_flag : loc -> rec_flag -> patt;
        value meta_mutable_flag : loc -> mutable_flag -> patt;
        value meta_virtual_flag : loc -> virtual_flag -> patt;
        value meta_private_flag : loc -> private_flag -> patt;
        value meta_row_var_flag : loc -> row_var_flag -> patt;
        value meta_override_flag : loc -> override_flag -> patt;
        value meta_direction_flag : loc -> direction_flag -> patt;
      end;
    end;
  end;

  (** See {!Ast.map}. *)
  class map : object ('self_type)
    method string : string -> string;
    method list : ! 'a 'b . ('self_type -> 'a -> 'b) -> list 'a -> list 'b;
    method meta_bool : meta_bool -> meta_bool;
    method meta_option : ! 'a 'b . ('self_type -> 'a -> 'b) -> meta_option 'a -> meta_option 'b;
    method meta_list : ! 'a 'b . ('self_type -> 'a -> 'b) -> meta_list 'a -> meta_list 'b;
    method loc : loc -> loc;
    method expr : expr -> expr;
    method patt : patt -> patt;
    method ctyp : ctyp -> ctyp;
    method str_item : str_item -> str_item;
    method sig_item : sig_item -> sig_item;

    method module_expr : module_expr -> module_expr;
    method module_type : module_type -> module_type;
    method class_expr : class_expr -> class_expr;
    method class_type : class_type -> class_type;
    method class_sig_item : class_sig_item -> class_sig_item;
    method class_str_item : class_str_item -> class_str_item;
    method with_constr : with_constr -> with_constr;
    method binding : binding -> binding;
    method rec_binding : rec_binding -> rec_binding;
    method module_binding : module_binding -> module_binding;
    method match_case : match_case -> match_case;
    method ident : ident -> ident;
    method mutable_flag : mutable_flag -> mutable_flag;
    method private_flag : private_flag -> private_flag;
    method virtual_flag : virtual_flag -> virtual_flag;
    method direction_flag : direction_flag -> direction_flag;
    method rec_flag : rec_flag -> rec_flag;
    method row_var_flag : row_var_flag -> row_var_flag;
    method override_flag : override_flag -> override_flag;

    method unknown : ! 'a. 'a -> 'a;
  end;

  (** See {!Ast.fold}. *)
  class fold : object ('self_type)
    method string : string -> 'self_type;
    method list : ! 'a . ('self_type -> 'a -> 'self_type) -> list 'a -> 'self_type;
    method meta_bool : meta_bool -> 'self_type;
    method meta_option : ! 'a . ('self_type -> 'a -> 'self_type) -> meta_option 'a -> 'self_type;
    method meta_list : ! 'a . ('self_type -> 'a -> 'self_type) -> meta_list 'a -> 'self_type;
    method loc : loc -> 'self_type;
    method expr : expr -> 'self_type;
    method patt : patt -> 'self_type;
    method ctyp : ctyp -> 'self_type;
    method str_item : str_item -> 'self_type;
    method sig_item : sig_item -> 'self_type;
    method module_expr : module_expr -> 'self_type;
    method module_type : module_type -> 'self_type;
    method class_expr : class_expr -> 'self_type;
    method class_type : class_type -> 'self_type;
    method class_sig_item : class_sig_item -> 'self_type;
    method class_str_item : class_str_item -> 'self_type;
    method with_constr : with_constr -> 'self_type;
    method binding : binding -> 'self_type;
    method rec_binding : rec_binding -> 'self_type;
    method module_binding : module_binding -> 'self_type;
    method match_case : match_case -> 'self_type;
    method ident : ident -> 'self_type;
    method rec_flag : rec_flag -> 'self_type;
    method direction_flag : direction_flag -> 'self_type;
    method mutable_flag : mutable_flag -> 'self_type;
    method private_flag : private_flag -> 'self_type;
    method virtual_flag : virtual_flag -> 'self_type;
    method row_var_flag : row_var_flag -> 'self_type;
    method override_flag : override_flag -> 'self_type;

    method unknown : ! 'a. 'a -> 'self_type;
  end;
  class clean_ast :  object ('c)
    method binding : binding -> binding;
    method class_expr : class_expr -> class_expr;
    method class_sig_item : class_sig_item -> class_sig_item;
    method class_str_item : class_str_item -> class_str_item;
    method class_type : class_type -> class_type;
    method ctyp : ctyp -> ctyp;
    method direction_flag : direction_flag -> direction_flag;
    method expr : expr -> expr;
    method ident : ident -> ident;
    method list : ('c -> 'a -> 'b) -> list 'a -> list 'b;
    method loc : loc -> loc;
    method match_case : match_case -> match_case;
    method meta_bool : meta_bool -> meta_bool;
    method meta_list :
      ('c -> 'a -> 'b) -> meta_list 'a -> meta_list 'b;
    method meta_option :
      ('c -> 'a -> 'b) -> meta_option 'a -> meta_option 'b;
    method module_binding : module_binding -> module_binding;
    method module_expr : module_expr -> module_expr;
    method module_type : module_type -> module_type;
    method mutable_flag : mutable_flag -> mutable_flag;
    method override_flag : override_flag -> override_flag;
    method patt : patt -> patt;
    method private_flag : private_flag -> private_flag;
    method rec_binding : rec_binding -> rec_binding;
    method rec_flag : rec_flag -> rec_flag;
    method row_var_flag : row_var_flag -> row_var_flag;
    method sig_item : sig_item -> sig_item;
    method str_item : str_item -> str_item;
    method string : string -> string;
    method unknown : 'a -> 'a;
    method virtual_flag : virtual_flag -> virtual_flag;
    method with_constr : with_constr -> with_constr;
  end;


  value map_expr : (expr -> expr) -> map;
  value map_patt : (patt -> patt) -> map;
  value map_ctyp : (ctyp -> ctyp) -> map;
  value map_str_item : (str_item -> str_item) -> map;
  value map_sig_item : (sig_item -> sig_item) -> map;
  value map_loc : (loc -> loc) -> map;

  value ident_of_expr : expr -> ident;
  value ident_of_patt : patt -> ident;
  value ident_of_ctyp : ctyp -> ident;

  value biAnd_of_list : list binding -> binding;
  value rbSem_of_list : list rec_binding -> rec_binding;
  value paSem_of_list : list patt -> patt;
  value paCom_of_list : list patt -> patt;
  value tyOr_of_list : list ctyp -> ctyp;
  value tyAnd_of_list : list ctyp -> ctyp;
  value tyAmp_of_list : list ctyp -> ctyp;
  value tySem_of_list : list ctyp -> ctyp;
  value tyCom_of_list : list ctyp -> ctyp;
  value tySta_of_list : list ctyp -> ctyp;
  value stSem_of_list : list str_item -> str_item;
  value sgSem_of_list : list sig_item -> sig_item;
  value crSem_of_list : list class_str_item -> class_str_item;
  value cgSem_of_list : list class_sig_item -> class_sig_item;
  value ctAnd_of_list : list class_type -> class_type;
  value ceAnd_of_list : list class_expr -> class_expr;
  value wcAnd_of_list : list with_constr -> with_constr;
  value meApp_of_list : list module_expr -> module_expr;
  value mbAnd_of_list : list module_binding -> module_binding;
  value mcOr_of_list : list match_case -> match_case;
  value idAcc_of_list : list ident -> ident;
  value idApp_of_list : list ident -> ident;
  value exSem_of_list : list expr -> expr;
  value exCom_of_list : list expr -> expr;

  value list_of_ctyp : ctyp -> list ctyp -> list ctyp;
  value list_of_binding : binding -> list binding -> list binding;
  value list_of_rec_binding : rec_binding -> list rec_binding -> list rec_binding;
  value list_of_with_constr : with_constr -> list with_constr -> list with_constr;
  value list_of_patt : patt -> list patt -> list patt;
  value list_of_expr : expr -> list expr -> list expr;
  value list_of_str_item : str_item -> list str_item -> list str_item;
  value list_of_sig_item : sig_item -> list sig_item -> list sig_item;
  value list_of_class_sig_item : class_sig_item -> list class_sig_item -> list class_sig_item;
  value list_of_class_str_item : class_str_item -> list class_str_item -> list class_str_item;
  value list_of_class_type : class_type -> list class_type -> list class_type;
  value list_of_class_expr : class_expr -> list class_expr -> list class_expr;
  value list_of_module_expr : module_expr -> list module_expr -> list module_expr;
  value list_of_module_binding : module_binding -> list module_binding -> list module_binding;
  value list_of_match_case : match_case -> list match_case -> list match_case;
  value list_of_ident : ident -> list ident -> list ident;

  (** Like [String.escape] but takes care to not
      escape antiquotations strings. *)
  value safe_string_escaped : string -> string;

  (** Returns True if the given pattern is irrefutable. *)
  value is_irrefut_patt : patt -> bool;

  value is_constructor : ident -> bool;
  value is_patt_constructor : patt -> bool;
  value is_expr_constructor : expr -> bool;

  value ty_of_stl : (Loc.t * string * list ctyp) -> ctyp;
  value ty_of_sbt : (Loc.t * string * bool * ctyp) -> ctyp;
  value bi_of_pe : (patt * expr) -> binding;
  value pel_of_binding : binding -> list (patt * expr);
  value binding_of_pel : list (patt * expr) -> binding;
  value sum_type_of_list : list (Loc.t * string * list ctyp) -> ctyp;
  value record_type_of_list : list (Loc.t * string * bool * ctyp) -> ctyp;
end;

(** This functor is a restriction functor.
    It takes a Camlp4Ast module and gives the Ast one.
    Typical use is for [with] constraints.
    Example: ... with module Ast = Camlp4.Sig.Camlp4AstToAst Camlp4Ast *)
module Camlp4AstToAst (M : Camlp4Ast) : Ast
  with type loc = M.loc
   and type meta_bool = M.meta_bool
   and type meta_option 'a = M.meta_option 'a
   and type meta_list 'a = M.meta_list 'a
   and type ctyp = M.ctyp
   and type patt = M.patt
   and type expr = M.expr
   and type module_type = M.module_type
   and type sig_item = M.sig_item
   and type with_constr = M.with_constr
   and type module_expr = M.module_expr
   and type str_item = M.str_item
   and type class_type = M.class_type
   and type class_sig_item = M.class_sig_item
   and type class_expr = M.class_expr
   and type class_str_item = M.class_str_item
   and type binding = M.binding
   and type rec_binding = M.rec_binding
   and type module_binding = M.module_binding
   and type match_case = M.match_case
   and type ident = M.ident
   and type rec_flag = M.rec_flag
   and type direction_flag = M.direction_flag
   and type mutable_flag = M.mutable_flag
   and type private_flag = M.private_flag
   and type virtual_flag = M.virtual_flag
   and type row_var_flag = M.row_var_flag
   and type override_flag = M.override_flag
= M;

(** Concrete definition of Camlp4 ASTs abstracted from locations.
    Since the Ast contains locations, this functor produces Ast types
    for a given location type. *)
module MakeCamlp4Ast (Loc : Type) = struct
  INCLUDE "src/Camlp4/Camlp4Ast.partial.ml";
end;

(** {6 Filters} *)

(** A type for stream filters. *)
type stream_filter 'a 'loc = Stream.t ('a * 'loc) -> Stream.t ('a * 'loc);

(** Registerinng and folding of Ast filters.
    Two kinds of filters must be handled:
      - Implementation filters: str_item -> str_item.
      - Interface filters: sig_item -> sig_item. *)
module type AstFilters = sig

  module Ast : Camlp4Ast with module Loc = FanLoc;

  type filter 'a = 'a -> 'a;

  value register_sig_item_filter : (filter Ast.sig_item) -> unit;
  value register_str_item_filter : (filter Ast.str_item) -> unit;
  value register_topphrase_filter : (filter Ast.str_item) -> unit;

  value fold_interf_filters : ('a -> filter Ast.sig_item -> 'a) -> 'a -> 'a;
  value fold_implem_filters : ('a -> filter Ast.str_item -> 'a) -> 'a -> 'a;
  value fold_topphrase_filters : ('a -> filter Ast.str_item -> 'a) -> 'a -> 'a;

end;

(** ASTs as one single dynamic type *)
module type DynAst = sig
  module Ast : Ast;
  type tag 'a;

  value ctyp_tag : tag Ast.ctyp;
  value patt_tag : tag Ast.patt;
  value expr_tag : tag Ast.expr;
  value module_type_tag : tag Ast.module_type;
  value sig_item_tag : tag Ast.sig_item;
  value with_constr_tag : tag Ast.with_constr;
  value module_expr_tag : tag Ast.module_expr;
  value str_item_tag : tag Ast.str_item;
  value class_type_tag : tag Ast.class_type;
  value class_sig_item_tag : tag Ast.class_sig_item;
  value class_expr_tag : tag Ast.class_expr;
  value class_str_item_tag : tag Ast.class_str_item;
  value match_case_tag : tag Ast.match_case;
  value ident_tag : tag Ast.ident;
  value binding_tag : tag Ast.binding;
  value rec_binding_tag : tag Ast.rec_binding;
  value module_binding_tag : tag Ast.module_binding;

  value string_of_tag : tag 'a -> string;

  module Pack (X : sig type t 'a; end) : sig
    type pack;
    value pack : tag 'a -> X.t 'a -> pack;
    value unpack : tag 'a -> pack -> X.t 'a;
    value print_tag : Format.formatter -> pack -> unit;
  end;
end;


(** {6 Quotation operations} *)

(** The signature for a quotation expander registery. *)
module type Quotation = sig
  module Ast : Ast;
  module DynAst : DynAst with module Ast = Ast;
  open Ast;

  (** The [loc] is the initial location. The option string is the optional name
      for the location variable. The string is the quotation contents. *)
  type expand_fun 'a = loc -> option string -> string -> 'a;

  (** [add name exp] adds the quotation [name] associated with the
      expander [exp]. *)
  value add : string -> DynAst.tag 'a -> expand_fun 'a -> unit;

  (** [find name] returns the expander of the given quotation name. *)
  value find : string -> DynAst.tag 'a -> expand_fun 'a;

  (** [default] holds the default quotation name. *)
  value default : ref string;

  (** [default_tbl] mapping position to the default quotation name
      it has higher precedence over default
   *)  
  value default_tbl : Hashtbl.t string string ;

  (** [default_at_pos] set the default quotation name for specific pos*)  
  value default_at_pos: string -> string -> unit;
      
  (** [parse_quotation_result parse_function loc position_tag quotation quotation_result]
      It's a parser wrapper, this function handles the error reporting for you. *)
    
  value parse_quotation_result :
    (loc -> string -> 'a) -> loc -> FanSig.quotation -> string -> string -> 'a;

  (** function translating quotation names; default = identity *)
  value translate : ref (string -> string);

  value expand : loc -> FanSig.quotation -> DynAst.tag 'a -> 'a;

  (** [dump_file] optionally tells Camlp4 to dump the
      result of an expander if this result is syntactically incorrect.
      If [None] (default), this result is not dumped. If [Some fname], the
      result is dumped in the file [fname]. *)
  value dump_file : ref (option string);

  module Error : FanSig.Error;

end;

(** {6 Tokens} *)


(** {6 Dynamic loaders} *)


(* (\** A signature for lexers. *\) *)
(* module type Lexer = sig *)
(*   module Loc : FanSig.Loc; *)
(*   module Token : FanSig.Token with module Loc = Loc; *)
(*   module Error : FanSig.Error; *)

(*   (\** The constructor for a lexing function. The character stream is the input *)
(*       stream to be lexed. The result is a stream of pairs of a token and *)
(*       a location. *)
(*       The lexer do not use global (mutable) variables: instantiations *)
(*       of [Lexer.mk ()] do not perturb each other. *\) *)
(*   value mk : unit -> (Loc.t -> Stream.t char -> Stream.t (Token.t * Loc.t)); *)
(* end; *)


(** A signature for parsers abstract from ASTs. *)
module Parser (Ast : Ast) = struct
  module type SIMPLE = sig
    (** The parse function for expressions.
        The underlying expression grammar entry is generally "expr; EOI". *)
    value parse_expr : FanLoc.t -> string -> Ast.expr;

    (** The parse function for patterns.
        The underlying pattern grammar entry is generally "patt; EOI". *)
    value parse_patt : FanLoc.t -> string -> Ast.patt;
  end;

  module type S = sig

    (** Called when parsing an implementation (ml file) to build the syntax
        tree; the returned list contains the phrases (structure items) as a
        single "declare" node (a list of structure items);   if  the parser
        encounter a directive it stops (since the directive may change  the
        syntax), the given [directive_handler] function  evaluates  it  and
        the parsing starts again. *)
    value parse_implem : ?directive_handler:(Ast.str_item -> option Ast.str_item) ->
                        FanLoc.t -> Stream.t char -> Ast.str_item;

    (** Same as {!parse_implem} but for interface (mli file). *)
    value parse_interf : ?directive_handler:(Ast.sig_item -> option Ast.sig_item) ->
                        FanLoc.t -> Stream.t char -> Ast.sig_item;
  end;
end;

(** A signature for printers abstract from ASTs. *)
module Printer (Ast : Ast) = struct
  module type S = sig

    value print_interf : ?input_file:string -> ?output_file:string ->
                        Ast.sig_item -> unit;
    value print_implem : ?input_file:string -> ?output_file:string ->
                        Ast.str_item -> unit;

  end;
end;

(** A syntax module is a sort of constistent bunch of modules and values.
   In such a module you have a parser, a printer, and also modules for
   locations, syntax trees, tokens, grammars, quotations, anti-quotations.
   There is also the main grammar entries. *)
module type Syntax = sig
  (* module Loc            : FanSig.Loc; *)
  module Ast            : Ast (* with type loc = Loc.t *) ;
  module Token          : FanSig.Token (* with module Loc = Loc *);
  module Gram           : FanSig.Grammar.Static with (* module Loc = Loc and *)
                          module Token = Token;
  module Quotation      : Quotation with module Ast = Ast;

  module AntiquotSyntax : (Parser Ast).SIMPLE;

  (* include (Warning FanLoc).S; *)
  include Warning;
  include (Parser  Ast).S;
  include (Printer Ast).S;
end;

(** A syntax module is a sort of constistent bunch of modules and values.
    In such a module you have a parser, a printer, and also modules for
    locations, syntax trees, tokens, grammars, quotations, anti-quotations.
    There is also the main grammar entries. *)
module type Camlp4Syntax = sig
  (* module Loc            : FanSig.Loc; *)

  module Ast            : Camlp4Ast with module Loc = FanLoc;
  module Token          : FanSig.Camlp4Token (* with module Loc = Loc *);

  module Gram           : FanSig.Grammar.Static with  module Loc = Ast.Loc and 
                          module Token = Token;
  module Quotation      : Quotation with module Ast = Camlp4AstToAst Ast;

  module AntiquotSyntax : (Parser Ast).SIMPLE;

  module Ast2pt         : sig
    value patt: Ast.patt -> Parsetree.pattern;
    value expr:  Ast.expr -> Parsetree.expression;
    value sig_item : Ast.sig_item -> Parsetree.signature;
    value str_item : Ast.str_item -> Parsetree.structure;
    value phrase : Ast.str_item -> Parsetree.toplevel_phrase;
  end;
  (* include (Warning FanLoc).S; *)
  include Warning;  
  include (Parser  Ast).S;
  include (Printer Ast).S;

  value interf : Gram.Entry.t (list Ast.sig_item * option FanLoc.t);
  value implem : Gram.Entry.t (list Ast.str_item * option FanLoc.t);
  value top_phrase : Gram.Entry.t (option Ast.str_item);
  value use_file : Gram.Entry.t (list Ast.str_item * option FanLoc.t);
  value a_CHAR : Gram.Entry.t string;
  value a_FLOAT : Gram.Entry.t string;
  value a_INT : Gram.Entry.t string;
  value a_INT32 : Gram.Entry.t string;
  value a_INT64 : Gram.Entry.t string;
  value a_LABEL : Gram.Entry.t string;
  value a_LIDENT : Gram.Entry.t string;
  value a_NATIVEINT : Gram.Entry.t string;
  value a_OPTLABEL : Gram.Entry.t string;
  value a_STRING : Gram.Entry.t string;
  value a_UIDENT : Gram.Entry.t string;
  value a_ident : Gram.Entry.t string;
  value amp_ctyp : Gram.Entry.t Ast.ctyp;
  value and_ctyp : Gram.Entry.t Ast.ctyp;
  value match_case : Gram.Entry.t Ast.match_case;
  value match_case0 : Gram.Entry.t Ast.match_case;
  value match_case_quot : Gram.Entry.t Ast.match_case;
  value binding : Gram.Entry.t Ast.binding;
  value binding_quot : Gram.Entry.t Ast.binding;
  value rec_binding_quot : Gram.Entry.t Ast.rec_binding;
  value class_declaration : Gram.Entry.t Ast.class_expr;
  value class_description : Gram.Entry.t Ast.class_type;
  value class_expr : Gram.Entry.t Ast.class_expr;
  value class_expr_quot : Gram.Entry.t Ast.class_expr;
  value class_fun_binding : Gram.Entry.t Ast.class_expr;
  value class_fun_def : Gram.Entry.t Ast.class_expr;
  value class_info_for_class_expr : Gram.Entry.t Ast.class_expr;
  value class_info_for_class_type : Gram.Entry.t Ast.class_type;
  value class_longident : Gram.Entry.t Ast.ident;
  value class_longident_and_param : Gram.Entry.t Ast.class_expr;
  value class_name_and_param : Gram.Entry.t (string * Ast.ctyp);
  value class_sig_item : Gram.Entry.t Ast.class_sig_item;
  value class_sig_item_quot : Gram.Entry.t Ast.class_sig_item;
  value class_signature : Gram.Entry.t Ast.class_sig_item;
  value class_str_item : Gram.Entry.t Ast.class_str_item;
  value class_str_item_quot : Gram.Entry.t Ast.class_str_item;
  value class_structure : Gram.Entry.t Ast.class_str_item;
  value class_type : Gram.Entry.t Ast.class_type;
  value class_type_declaration : Gram.Entry.t Ast.class_type;
  value class_type_longident : Gram.Entry.t Ast.ident;
  value class_type_longident_and_param : Gram.Entry.t Ast.class_type;
  value class_type_plus : Gram.Entry.t Ast.class_type;
  value class_type_quot : Gram.Entry.t Ast.class_type;
  value comma_ctyp : Gram.Entry.t Ast.ctyp;
  value comma_expr : Gram.Entry.t Ast.expr;
  value comma_ipatt : Gram.Entry.t Ast.patt;
  value comma_patt : Gram.Entry.t Ast.patt;
  value comma_type_parameter : Gram.Entry.t Ast.ctyp;
  value constrain : Gram.Entry.t (Ast.ctyp * Ast.ctyp);
  value constructor_arg_list : Gram.Entry.t Ast.ctyp;
  value constructor_declaration : Gram.Entry.t Ast.ctyp;
  value constructor_declarations : Gram.Entry.t Ast.ctyp;
  value ctyp : Gram.Entry.t Ast.ctyp;
  value ctyp_quot : Gram.Entry.t Ast.ctyp;
  value cvalue_binding : Gram.Entry.t Ast.expr;
  value direction_flag : Gram.Entry.t Ast.direction_flag;
  value direction_flag_quot : Gram.Entry.t Ast.direction_flag;
  value dummy : Gram.Entry.t unit;
  value eq_expr : Gram.Entry.t (string -> Ast.patt -> Ast.patt);
  value expr : Gram.Entry.t Ast.expr;
  value expr_eoi : Gram.Entry.t Ast.expr;
  value expr_quot : Gram.Entry.t Ast.expr;
  value field_expr : Gram.Entry.t Ast.rec_binding;
  value field_expr_list : Gram.Entry.t Ast.rec_binding;
  value fun_binding : Gram.Entry.t Ast.expr;
  value fun_def : Gram.Entry.t Ast.expr;
  value ident : Gram.Entry.t Ast.ident;
  value ident_quot : Gram.Entry.t Ast.ident;
  value ipatt : Gram.Entry.t Ast.patt;
  value ipatt_tcon : Gram.Entry.t Ast.patt;
  value label : Gram.Entry.t string;
  value label_declaration : Gram.Entry.t Ast.ctyp;
  value label_declaration_list : Gram.Entry.t Ast.ctyp;
  value label_expr : Gram.Entry.t Ast.rec_binding;
  value label_expr_list : Gram.Entry.t Ast.rec_binding;
  value label_ipatt : Gram.Entry.t Ast.patt;
  value label_ipatt_list : Gram.Entry.t Ast.patt;
  value label_longident : Gram.Entry.t Ast.ident;
  value label_patt : Gram.Entry.t Ast.patt;
  value label_patt_list : Gram.Entry.t Ast.patt;
  value labeled_ipatt : Gram.Entry.t Ast.patt;
  value let_binding : Gram.Entry.t Ast.binding;
  value meth_list : Gram.Entry.t (Ast.ctyp * Ast.row_var_flag);
  value meth_decl : Gram.Entry.t Ast.ctyp;
  value module_binding : Gram.Entry.t Ast.module_binding;
  value module_binding0 : Gram.Entry.t Ast.module_expr;
  value module_binding_quot : Gram.Entry.t Ast.module_binding;
  value module_declaration : Gram.Entry.t Ast.module_type;
  value module_expr : Gram.Entry.t Ast.module_expr;
  value module_expr_quot : Gram.Entry.t Ast.module_expr;
  value module_longident : Gram.Entry.t Ast.ident;
  value module_longident_with_app : Gram.Entry.t Ast.ident;
  value module_rec_declaration : Gram.Entry.t Ast.module_binding;
  value module_type : Gram.Entry.t Ast.module_type;
  value package_type : Gram.Entry.t Ast.module_type;
  value module_type_quot : Gram.Entry.t Ast.module_type;
  value more_ctyp : Gram.Entry.t Ast.ctyp;
  value name_tags : Gram.Entry.t Ast.ctyp;
  value opt_as_lident : Gram.Entry.t string;
  value opt_class_self_patt : Gram.Entry.t Ast.patt;
  value opt_class_self_type : Gram.Entry.t Ast.ctyp;
  value opt_comma_ctyp : Gram.Entry.t Ast.ctyp;
  value opt_dot_dot : Gram.Entry.t Ast.row_var_flag;
  value row_var_flag_quot : Gram.Entry.t Ast.row_var_flag;
  value opt_eq_ctyp : Gram.Entry.t Ast.ctyp;
  value opt_expr : Gram.Entry.t Ast.expr;
  value opt_meth_list : Gram.Entry.t Ast.ctyp;
  value opt_mutable : Gram.Entry.t Ast.mutable_flag;
  value mutable_flag_quot : Gram.Entry.t Ast.mutable_flag;
  value opt_override : Gram.Entry.t Ast.override_flag;
  value override_flag_quot : Gram.Entry.t Ast.override_flag;
  value opt_polyt : Gram.Entry.t Ast.ctyp;
  value opt_private : Gram.Entry.t Ast.private_flag;
  value private_flag_quot : Gram.Entry.t Ast.private_flag;
  value opt_rec : Gram.Entry.t Ast.rec_flag;
  value rec_flag_quot : Gram.Entry.t Ast.rec_flag;
  value opt_virtual : Gram.Entry.t Ast.virtual_flag;
  value virtual_flag_quot : Gram.Entry.t Ast.virtual_flag;
  value opt_when_expr : Gram.Entry.t Ast.expr;
  value patt : Gram.Entry.t Ast.patt;
  value patt_as_patt_opt : Gram.Entry.t Ast.patt;
  value patt_eoi : Gram.Entry.t Ast.patt;
  value patt_quot : Gram.Entry.t Ast.patt;
  value patt_tcon : Gram.Entry.t Ast.patt;
  value phrase : Gram.Entry.t Ast.str_item;
  value poly_type : Gram.Entry.t Ast.ctyp;
  value row_field : Gram.Entry.t Ast.ctyp;
  value sem_expr : Gram.Entry.t Ast.expr;
  value sem_expr_for_list : Gram.Entry.t (Ast.expr -> Ast.expr);
  value sem_patt : Gram.Entry.t Ast.patt;
  value sem_patt_for_list : Gram.Entry.t (Ast.patt -> Ast.patt);
  value semi : Gram.Entry.t unit;
  value sequence : Gram.Entry.t Ast.expr;
  value do_sequence : Gram.Entry.t Ast.expr;
  value sig_item : Gram.Entry.t Ast.sig_item;
  value sig_item_quot : Gram.Entry.t Ast.sig_item;
  value sig_items : Gram.Entry.t Ast.sig_item;
  value star_ctyp : Gram.Entry.t Ast.ctyp;
  value str_item : Gram.Entry.t Ast.str_item;
  value str_item_quot : Gram.Entry.t Ast.str_item;
  value str_items : Gram.Entry.t Ast.str_item;
  value type_constraint : Gram.Entry.t unit;
  value type_declaration : Gram.Entry.t Ast.ctyp;
  value type_ident_and_parameters : Gram.Entry.t (string * list Ast.ctyp);
  value type_kind : Gram.Entry.t Ast.ctyp;
  value type_longident : Gram.Entry.t Ast.ident;
  value type_longident_and_parameters : Gram.Entry.t Ast.ctyp;
  value type_parameter : Gram.Entry.t Ast.ctyp;
  value type_parameters : Gram.Entry.t (Ast.ctyp -> Ast.ctyp);
  value typevars : Gram.Entry.t Ast.ctyp;
  value val_longident : Gram.Entry.t Ast.ident;
  value value_let : Gram.Entry.t unit;
  value value_val : Gram.Entry.t unit;
  value with_constr : Gram.Entry.t Ast.with_constr;
  value with_constr_quot : Gram.Entry.t Ast.with_constr;
  value prefixop : Gram.Entry.t Ast.expr;
  value infixop0 : Gram.Entry.t Ast.expr;
  value infixop1 : Gram.Entry.t Ast.expr;
  value infixop2 : Gram.Entry.t Ast.expr;
  value infixop3 : Gram.Entry.t Ast.expr;
  value infixop4 : Gram.Entry.t Ast.expr;
end;

(** A signature for syntax extension (syntax -> syntax functors). *)
module type SyntaxExtension = functor (Syn : Syntax)
                    -> (Syntax with (* module Loc            = Syn.Loc
                                and *) module Ast            = Syn.Ast
                                and module Token          = Syn.Token
                                and module Gram           = Syn.Gram
                                and module Quotation      = Syn.Quotation);
(** Camlp4Syntax with module [AstFilter] added *)                      
(* module type FilterSyntax = sig
 *   include Camlp4Syntax;
 *   module AstFilters:AstFilters with module Ast = Ast; 
 * end ; *)


module type PLUGIN = functor (Unit:sig end) -> sig end;
    
module type OCAML_SYNTAX_EXTENSION = functor (Syn:Camlp4Syntax) -> Camlp4Syntax ;

module type SYNTAX_PLUGIN = functor (Syn:Syntax) -> sig end ;
module type PRINTER_PLUGIN = functor (Syn:Syntax) -> (Printer Syn.Ast).S;   
module type OCAML_PRINTER_PLUGIN =
    functor (Syn:Camlp4Syntax) ->  (Printer Syn.Ast).S;
module type PARSER = functor (Ast:Camlp4Ast) -> (Parser Ast).S;
module type OCAML_PARSER = functor (Ast:Camlp4Ast) -> (Parser Ast).S ;
module type ASTFILTER_PLUGIN  = functor (F:AstFilters) -> sig end ;
module type LEXER = functor (Token: FanSig.Camlp4Token) -> FanSig.Lexer
  with (* module Loc = Token.Loc and *) module Token = Token;



module type PRECAST = sig
  type token = FanSig.camlp4_token ;
  (* module Loc        : FanSig.Loc; *)
  module Ast        : Camlp4Ast with  module Loc = FanLoc ;
  module Token      : FanSig.Token  with (* module Loc = Loc and *)
                      type t = FanSig.camlp4_token;
  module Lexer      : FanSig.Lexer  with (* module Loc = Loc and *)
                      module Token = Token;
  module Gram       : FanSig.Grammar.Static  with module Loc = FanLoc and
                      module Token = Token;
  module Quotation  : Quotation with module Ast = Camlp4AstToAst Ast;
  (* module DynLoader  : DynLoader; *)
  module AstFilters : AstFilters with module Ast = Ast;
  module Syntax     : Camlp4Syntax with (* module Loc = Loc and *)
                       module Token   = Token
                       and module Ast     = Ast
                       and module Gram    = Gram
                       and module Quotation = Quotation;
      
  module Printers : sig
    module OCaml         : (Printer Ast).S;
    module DumpOCamlAst  : (Printer Ast).S;
    module DumpCamlp4Ast : (Printer Ast).S;
    module Null          : (Printer Ast).S;
  end;
  (* module MakeGram (Lexer : FanSig.Lexer (\* with module Loc = Loc *\) ) : *)
  (*     FanSig.Grammar.Static with (\* module Loc = Loc and *\) module Token = Lexer.Token; *)

  module MakeSyntax (U : sig end) : Syntax;

  (* parser signature *)  
  type parser_fun 'a =
      ?directive_handler:('a -> option 'a) -> FanLoc.t -> Stream.t char -> 'a;
  type printer_fun 'a =
      ?input_file:string -> ?output_file:string -> 'a -> unit;
  value loaded_modules : ref (list string);
  value iter_and_take_callbacks : ((string * (unit -> unit)) -> unit) -> unit ;  
  value register_str_item_parser : parser_fun Ast.str_item -> unit;
  value register_sig_item_parser : parser_fun Ast.sig_item -> unit;
  value register_parser :
      parser_fun Ast.str_item -> parser_fun Ast.sig_item -> unit;
  value current_parser :
      unit -> (parser_fun Ast.str_item * parser_fun Ast.sig_item);

  value plugin : (module Id) -> (module PLUGIN) -> unit ;      
  value syntax_plugin : (module Id) -> (module SYNTAX_PLUGIN) -> unit ;
  value syntax_extension : (module Id) -> (module SyntaxExtension) -> unit;
  value ocaml_syntax_extension : (module Id) ->
    (module OCAML_SYNTAX_EXTENSION) -> unit ;

  value parser_plugin : (module Id) -> (module PARSER) -> unit;
  value ocaml_parser_plugin : (module Id) -> (module OCAML_PARSER) -> unit;
  value ocaml_precast_parser_plugin : (module Id) ->
    (module (Parser Syntax.Ast).S) -> unit ;


  value register_str_item_printer : printer_fun Ast.str_item -> unit;
  value register_sig_item_printer : printer_fun Ast.sig_item -> unit;
  value register_printer :
      printer_fun Ast.str_item -> printer_fun Ast.sig_item -> unit;
  value current_printer :
      unit -> (printer_fun Ast.str_item * printer_fun Ast.sig_item);
        
  value printer : (module Id) -> (module PRINTER_PLUGIN) -> unit ;
  value ocaml_printer : (module Id) -> (module OCAML_PRINTER_PLUGIN) -> unit;
  value ocaml_precast_printer : (module Id) ->
    (module (Printer Syntax.Ast).S) -> unit ;

  value ast_filter : (module Id)-> (module ASTFILTER_PLUGIN) -> unit ;

  value declare_dyn_module : string -> (unit -> unit) -> unit  ;

  module CurrentParser : (Parser Ast).S;
  module CurrentPrinter : (Printer Ast).S;

  value enable_ocaml_printer : unit -> unit;
  (* value enable_ocamlr_printer : unit -> unit; *)
  value enable_null_printer : unit -> unit;
  value enable_dump_ocaml_ast_printer : unit -> unit;
  value enable_dump_camlp4_ast_printer : unit -> unit;
  value enable_auto : (unit -> bool) -> unit ;  

end ;


(* for dynamic loading *)  
module type PRECAST_PLUGIN = sig
  value apply : (module PRECAST) -> unit;
end; 
