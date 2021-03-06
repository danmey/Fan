(* Note: when you modify these types you must increment
   ast magic numbers defined in FanConfig.ml.
   Todo:
   add phantom type to track some type invariants?
 *)
(** Signature for OCaml syntax trees. *) (*

    It provides:
      - Types for all kinds of structure.
      - Map: A base class for map traversals.
      - Map classes and functions for common kinds.

    == Core language ==
    ctyp               :: Representaion of types
    pat               :: The type of patterns
    exp               :: The type of expessions
    case         :: The type of cases for match/function/try constructions
    ident              :: The type of identifiers (including path like Foo(X).Bar.y)
    binding            :: The type of let bindings
    rec_exp        :: The type of record definitions

    == Modules ==
    module_type        :: The type of module types
    sig_item           :: The type of signature items
    stru           :: The type of structure items
    module_exp        :: The type of module expessions
    module_binding     :: The type of recursive module definitions
    with_constr        :: The type of `with' constraints

    == Classes ==
    class_type         :: The type of class types
    class_sig_item     :: The type of class signature items
    class_exp         :: The type of class expessions
    cstru     :: The type of class structure items
 *)


type nil = [= `Nil ];


type literal =
  [= `Chr of string  | `Int of string   | `Int32 of string
  | `Int64 of string  | `Flo of string  | `NativeInt of string
  | `Str of string];   
type rec_flag =  [= `Recursive   | `ReNil ];
type direction_flag =  [= `To   | `Downto  ];
type mutable_flag =  [= `Mutable   | `MuNil ];
type private_flag =  [= `Private   | `PrNil ];

type virtual_flag =
  [= `Virtual   | `ViNil];

type override_flag =  [= `Override   | `OvNil];

type row_var_flag =  [= `RowVar | `RvNil ];

type position_flag =  [= `Positive  | `Negative  | `Normal ];

type meta_bool =  [=`True   |`False];

type 'a meta_option  =
  [= `None 
  |  `Some of 'a
  | ant];

type 'a meta_list  =
  [= `LNil 
  | `LCons of ('a * meta_list 'a)
  | ant];

type alident =
  [= `Lid of (loc * string)
  | ant];

type auident =
  [= `Uid of (loc * string)
  | ant];

type aident =
  [= alident
  | auident ];

type astring =
  [= `C of (loc * string)
  | ant ];

type uident =
  [= `Dot of (loc * uident * uident)
  | `App of (loc * uident * uident)
  | auident];


(* type uident = *)
(*  [= `Dot of (loc * uident * uident) *)
(*  | `App of (loc * uident * uident) *)
(*  ];    *)
(* {:ident|A.B.C.d|}
      `Dot
      (`Uid "A"
        `Dot (`Uid "B")
           `Dot("C",`Lid "d"))
    *)
type ident =
  [= `Dot of (loc * ident * ident) (* i . i *)
  | `App of (loc * ident * ident) (* i i *)
  | alident
  | auident];

(* type dopath = *)
(*  [= `Dot of (loc * dopath * dopath) *)
(*  | auident ] ; *)

(* A.B.C *)
type dupath =
  [= `Dot of (loc * dupath * dupath)
  | auident];

type dlpath=
  [= `Dot of (loc * dupath * alident)
  | alident];



type sid = [= `Id of (loc * ident)];
type any = [= `Any of loc];

type ctyp =
  [= nil
  | `Alias of (loc * ctyp * alident)
  | any
  | `App of (loc * ctyp * ctyp) (* t t *) (* list 'a *)
  | `Arrow of (loc * ctyp * ctyp)
  | `ClassPath of (loc * ident) (* #i *) (* #point *)
  | `Label of (loc * alident * ctyp) (* ~s:t *)
        (* ?s:t *)
  | `OptLabl of (loc * alident * ctyp )
  | sid
      (* < (t)? (..)? > *) (* < move : int -> 'a .. > as 'a  *)
  | `TyObj of (loc * name_ctyp * row_var_flag )
  | `TyPol of (loc * ctyp * ctyp) (* ! t . t *) (* ! 'a . list 'a -> 'a *)
        
  | `TyTypePol of (loc * ctyp * ctyp) (* type t . t *) (* type a . list a -> a *)
        (*  +'s -'s 's +_ -_ *)      
  | `Quote of (loc * position_flag * meta_option alident)
  | `Tup of (loc * ctyp) (* ( t ) *) (* (int * string) *)
  | `Sta of (loc * ctyp * ctyp) (* t * t *)
  | `PolyEq of (loc * row_field)
  | `PolySup of (loc * row_field )
  | `PolyInf of (loc * row_field)
  | `PolyInfSup of (loc * row_field * tag_names)
        
  | `Package of (loc * module_type) (* (module S) *)
  | ant ]
and type_parameters =
  [= `Com of (loc * type_parameters * type_parameters)
  | `Ctyp of (loc * ctyp)
  | ant
  | nil]  
and row_field =
  [= ant_nil
  | `Or of (loc * row_field * row_field )
  | `TyVrn of (loc * astring)
  | `TyVrnOf of (loc * astring * ctyp)
  |  `Ctyp of (loc * ctyp)]
and tag_names =
  [= ant_nil
  | `App of (loc * tag_names * tag_names)
  | `TyVrn of (loc * astring )]   
and typedecl =
    (* {:stru| type  ('a, 'b, 'c) t = t |} *)
  [= `TyDcl of (loc * alident * list ctyp * type_info * list (ctyp * ctyp))
  | `And of (loc * typedecl * typedecl)
  | ant_nil ]
      (* original syntax
         {[ type v = u = A of int ]}
       revise syntax
       {[ type v = u = [A of int];]} 
     *)
and type_info =        (* FIXME be more preicse *)
  [=
   (* type u = v = [A of int ] *)
   `TyMan of (loc  * ctyp * private_flag  * type_repr)
   (* type u = A.t = {x:int} *)
  | `TyRepr of (loc * private_flag * type_repr)

   (* type u = int *)
  | `TyEq of (loc * private_flag * ctyp)
  | ant
  | nil]  
and type_repr =
  [= `Record of (loc * name_ctyp)
  | `Sum of (loc * or_ctyp)
  | ant
  | nil ]   
and name_ctyp =
  [= `Sem of (loc * name_ctyp * name_ctyp)
  | `TyCol of (loc * sid * ctyp )
  | `TyColMut of (loc * sid * ctyp)
  | ant
  | nil ]
and or_ctyp =
  [= `Or of (loc * or_ctyp * or_ctyp )
  | `TyCol of (loc * sid * ctyp)
  | `Of of (loc * (* ctyp *)sid * ctyp)
  | sid
  | ant_nil]
and of_ctyp =
  [= `Of of (loc * sid * ctyp)
  | sid
  | ant
  | nil]
         
and pat =
  [= nil
  | sid
  | `App of (loc * pat * pat)
  | `Vrn of (loc * string)
  | `Com of (loc * pat * pat)
  | `Sem of (loc * pat * pat)
  | `Tup of (loc * pat )
  | any
  | `Record of (loc * rec_pat)
  | ant
  | literal
      
  | `Alias of (loc * pat * alident)  (* (Node x y as n) *)
  | `Array of (loc * pat) (* [| p |] *)
  | `Label of (loc * alident * pat) (* ~s or ~s:(p) *)
        (* ?s or ?s:(p)  ?s:(p = e) or ?(p = e) *)
  | `PaOlbi of (loc * alident * pat * meta_option exp)
  | `Or of (loc * pat * pat) (* p | p *)
  | `PaRng (* `Range  *)of (loc * pat * pat) (* p .. p *)
  | `Constraint of (loc * pat * ctyp) (* (p : t) *)
  | `ClassPath of (loc * ident) (* #i *)
  | `Lazy of (loc * pat) (* lazy p *)
        (* (module M : ty ) *)      
  | `ModuleUnpack of (loc * auident * meta_option ctyp)]
and rec_pat =
  [= nil
  | `RecBind of (loc * ident * pat)
  | `Sem of (loc  * rec_pat * rec_pat)
  | any
  | ant]  
and exp =
  [= nil
  | sid
  | `App of (loc * exp * exp)
  | `Vrn of (loc * string)
  | `Com of (loc * exp * exp)
  | `Sem of (loc * exp * exp)
  | `Tup of (loc * exp)
  | any
  | `Record of (loc * rec_exp)
  | ant 
  | literal
      (* { (e) with rb }  *)
  | `RecordWith of (loc * rec_exp  * exp)         
  | `Dot of (loc * exp * exp) (* e.e *)
  | `ArrayDot of (loc * exp * exp) (* e.(e) *)
  | `Array of (loc * exp) (* [| e |] *)
  | `ExAsf of loc (* assert `False *)
  | `ExAsr of (loc * exp) (* assert e *)
  | `Assign of (loc * exp * exp) (* e := e *)
        (* for s = e to/downto e do { e } *)
  | `For of (loc * alident * exp * exp * direction_flag * exp)
  | `Fun of (loc * case) (* fun [ mc ] *)
  | `IfThenElse of (loc * exp * exp * exp) (* if e then e else e *)
  | `IfThen of (loc * exp * exp) (* if e then e *)
  | `Label of (loc * alident * exp) (* ~s or ~s:e *)
  | `Lazy of (loc * exp) (* lazy e *)
        (* let b in e or let rec b in e *)
  | `LetIn of (loc * rec_flag * binding * exp)
        (* let module s = me in e *)
  | `LetModule of (loc * auident * module_exp * exp)
        (* match e with [ mc ] *)
  | `Match of (loc * exp * case)
        (* new i *)
  | `New of (loc * ident)
        (* object ((p))? (cst)? end *)
  | `Obj of (loc * pat * cstru)
        (* ?s or ?s:e *)
  | `OptLabl of (loc *alident * exp)
        (* {< rb >} *)
  | `OvrInst of (loc * rec_exp)
        (* do { e } *)
  | `Seq of (loc * exp)
        (* e#s *)
  | `Send of (loc * exp * alident)
        (* e.[e] *)
  | `StringDot of (loc * exp * exp)
        (* try e with [ mc ] *)
  | `Try of (loc * exp * case)
        (* (e : t) *)
  | (* `Constraint *) `Constraint of (loc * exp * ctyp)
  | `Coercion of (loc * exp * ctyp * ctyp) (* (e : t) or (e : t :> t) *)          
        (* while e do { e } *)
  | `While of (loc * exp * exp)
        (* let open i in e *)
  | `LetOpen of (loc * ident * exp)
        (* fun (type t) -> e *)
        (* let f x (type t) y z = e *)
  | `LocalTypeFun of (loc *  alident * exp)
        (* (module ME : S) which is represented as (module (ME : S)) *)
  | `Package_exp of (loc * module_exp) ]
and rec_exp =
  [= nil
       (* rb ; rb *)
  | `Sem of (loc * rec_exp * rec_exp)
        (* i = e *)
  | `RecBind  of (loc * ident * exp)
  | any (* Faked here to be symmertric to rec_pat *)
  | ant (* $s$ *) ]
and module_type =
  [= nil
  | sid
       (* functor (s : mt) -> mt *)
  | `MtFun of (loc * auident * module_type * module_type)
        (* sig sg end *)
  | `Sig of (loc * sig_item)
        (* mt with wc *)
  | `With of (loc * module_type * with_constr)
        (* module type of m *)
  | `ModuleTypeOf of (loc * module_exp)
  | ant  ]
and sig_item =
  [= nil
     (* class cict *)
  | `Class of (loc * class_type)
      (* class type cict *)
  | `ClassType of (loc * class_type)
        (* sg ; sg *)
  | `Sem of (loc * sig_item * sig_item)
        (* # s or # s e *)
  | `Directive of (loc * alident * exp) (* semantics *)
        (* exception t *)
  | `Exception of (loc * of_ctyp)
        (* external s : t = s ... s *)
  | `External of (loc * alident  * ctyp * meta_list string)
  | `Include of (loc * module_type)
        (* module s : mt *)
  | `Module of (loc * auident * module_type)
        (* module rec mb *)
  | `RecModule of (loc * module_binding)
        (* module type s = mt *)
  | `ModuleType of (loc * auident * module_type)
  | `Open of (loc * ident)
  | `Type of (loc * typedecl)
        (* va s : t *)
  |  `Val of (loc * alident * ctyp)
  | ant  ]
          
and with_constr =
  [= nil
     (* type t = t *)
  | `TypeEq of (loc * ctyp * ctyp)
  | `TypeEqPriv of (loc * ctyp * ctyp)
        (* module i = i *)
  | `ModuleEq of (loc * ident * ident)
        (* type t := t *)
  | `TypeSubst of (loc * ctyp * ctyp)
        (* module i := i *)
  | `ModuleSubst of (loc * ident * ident)
  | `And of (loc * with_constr * with_constr)
  | ant  ]
             
             (*
    let-binding	::=	pattern =  exp  
     value-name  { parameter }  [: typexp] =  exp  
    value-name : type  { typeconstr } .  typexp =  exp
    
   *)           
and binding =
  [= nil
  | `And of (loc * binding * binding)
        (* p = e *) (* let pat = exp *)
  | `Bind  of (loc * pat * exp)
  | ant  ]
and module_binding =
  [= nil
     (* mb and mb *) (* module rec (s : mt) = me and (s : mt) = me *)
  | `And of (loc * module_binding * module_binding)
      (* s : mt = me *)
  | `ModuleBind  of (loc *  auident * module_type * module_exp)
      (* s : mt *)
  | `Constraint  of (loc * auident * module_type)
  | ant ]
and case =
  [= nil
  | `Or of (loc * case * case)
        (* p (when e)? -> e *)
  | `Case of (loc * pat * exp * exp)
     (* | `Caseow of loc and pat and option exp and exp (\* FIXME *\) *)
  | ant  ]
and module_exp =
  [= nil
  | sid
      (* me me *)
  | `App of (loc * module_exp * module_exp)
        (* functor (s : mt) -> me *)
  | `Functor of (loc * auident * module_type * module_exp)
  | `Struct of (loc * stru)
        (* (me : mt) *)
  | `Constraint of (loc * module_exp * module_type)
        (* (value e) *)
        (* (value e : S) which is represented as (value (e : S)) *)
  | `PackageModule of (loc * exp)
  | ant  ]
and stru =
  [= nil
     (* class cice *)
  | `Class of (loc * class_exp)
        (* class type cict *)
  | `ClassType of (loc * class_type)
  | `Sem of (loc * stru * stru)
        (* # s or # s e *)
  | `Directive of (loc * alident * exp)
        (* exception t or exception t = i *)
        (* | `Exception of ( loc * ctyp * meta_option(\*FIXME*\) ident) *)
  | `Exception of ( loc * of_ctyp)
        (* TODO ExceptionRebind
           http://caml.inria.fr/pub/docs/manual-ocaml/manual016.html
         *)     
        (* e *)
  | `StExp of (loc * exp)
        (* external s : t = s ... s *)
  | `External of (loc * alident  * ctyp * meta_list string)
        (* include me *)
  | `Include of (loc * module_exp)
        (* module s = me *)
  | `Module of (loc * auident * module_exp)
        (* module rec mb *)
  | `RecModule of (loc * module_binding)
        (* module type s = mt *)
  | `ModuleType of (loc * (* string *)auident * module_type)
        (* open i *)
  | `Open of (loc * ident)
        (* type t *)
  | `Type of (loc * (* ctyp *)typedecl)
        (* value (rec)? bi *)
  | `Value of (loc * rec_flag * binding)
  | ant (* $s$ *) ]
and class_type =
  [= nil
     (* (virtual)? i ([ t ])? *)
  | `CtCon of (loc * virtual_flag * ident * (* ctyp *) type_parameters)
        (* [t] -> ct *)
  | `CtFun of (loc * ctyp * class_type)
      (* object ((t))? (csg)? end *)
  | `CtSig of (loc * ctyp * class_sig_item)
        (* ct and ct *)
  | `And of (loc * class_type * class_type)
        (* ct : ct *)
  | `CtCol of (loc * class_type * class_type)
        (* ct = ct *)
  | `CtEq  of (loc * class_type * class_type)
  | ant ]
and class_sig_item =
  [= nil
     (* type t = t *)
  | `Eq of (loc * ctyp * ctyp)
        (* csg ; csg *)
  | `Sem of (loc * class_sig_item * class_sig_item)
        (* inherit ct *)
  | `SigInherit of (loc * class_type)
        (* method s : t or method private s : t *)
  | `Method of (loc * alident * private_flag * ctyp)
        (* val (virtual)? (mutable)? s : t *)
  | `CgVal of (loc * alident * mutable_flag * virtual_flag * ctyp)
        (* method virtual (private)? s : t *)
  | `CgVir of (loc *  alident * private_flag * ctyp)
  | ant ]
and class_exp =
  [= nil
      (* ce e *)
  | `CeApp of (loc * class_exp * exp)
      (* (virtual)? i ([ t ])? *)
  | `CeCon of (loc * virtual_flag * ident * (* ctyp *) type_parameters)
      (* fun p -> ce *)
  | `CeFun of (loc * pat * class_exp)
        (* let (rec)? bi in ce *)
  | `CeLet of (loc * rec_flag * binding * class_exp)
        (* object ((p))? (cst)? end *)
  | `Obj of (loc * pat * cstru)
        (* ce : ct *)
  | `CeTyc of (loc * class_exp * class_type)
        (* ce and ce *)
  | `And of (loc * class_exp * class_exp)
        (* ce = ce *)
  | `Eq  of (loc * class_exp * class_exp)
  | ant ]
and cstru =
  [= nil
  | `Sem of (loc * cstru * cstru)
        (* type t = t *)
  | `Eq of (loc * ctyp * ctyp)
        (* inherit(!)? ce (as s)? *)
  | `Inherit of (loc * override_flag * class_exp * meta_option alident)
      (* initializer e *)
  | `Initializer of (loc * exp)
        (* method(!)? (private)? s : t = e or method(!)? (private)? s = e *)
  | `CrMth of (loc * alident * override_flag * private_flag * exp * ctyp)
        (* value(!)? (mutable)? s = e *)
  | `CrVal of (loc *  alident * override_flag * mutable_flag * exp)
        (* method virtual (private)? s : t *)
  | `CrVir of (loc * alident * private_flag * ctyp)
        (* val virtual (mutable)? s : t *)
  | `CrVvr of (loc * alident * mutable_flag * ctyp)
  | ant  ]; 




(* Any is necessary, since sometimes you want to [meta_loc_pat] to [_]
   Faked here to make a common subtyp of exp pat to be expessive enough *)
type ep =
  [= nil
  | sid
  | `App of (loc * ep * ep)
  | `Vrn of (loc * string)
  | `Com of (loc * ep * ep)
  | `Sem of (loc * ep * ep)
  | `Tup of (loc * ep)
  | any
  | `Array of (loc * ep )
  | `Record of (loc * rec_bind)
  | literal
  | ant ]
and rec_bind =
  [= nil
  | `RecBind of (loc * ident * ep)
  | `Sem of (loc * rec_bind * rec_bind)
  | any
  | ant];
      
      
(* let _loc = FanLoc.ghost; *)
(* #filter "serialize";; *)
