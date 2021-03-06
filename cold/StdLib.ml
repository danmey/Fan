open LibUtil
open Format
let eq_int: int -> int -> bool = ( = )
let eq_int32: int32 -> int32 -> bool = ( = )
let eq_int64: int64 -> int64 -> bool = ( = )
let eq_nativeint: nativeint -> nativeint -> bool = ( = )
let eq_float: float -> float -> bool = ( = )
let eq_string: string -> string -> bool = ( = )
let eq_bool: bool -> bool -> bool = ( = )
let eq_char: char -> char -> bool = ( = )
let eq_unit: unit -> unit -> bool = fun _  _  -> true
let pp_print_int = pp_print_int
let pp_print_int32: Format.formatter -> int32 -> unit =
  fun fmt  a  -> Format.fprintf fmt "%ld" a
let pp_print_int64: Format.formatter -> int64 -> unit =
  fun fmt  a  -> Format.fprintf fmt "%Ld" a
let pp_print_nativeint: Format.formatter -> nativeint -> unit =
  fun fmt  a  -> Format.fprintf fmt "%nd" a
let pp_print_float = pp_print_float
let pp_print_string: Format.formatter -> string -> unit =
  fun fmt  a  -> Format.fprintf fmt "%S" a
let pp_print_bool = pp_print_bool
let pp_print_char = pp_print_char
let pp_print_unit: Format.formatter -> unit -> unit =
  fun fmt  _  -> Format.fprintf fmt "()"
let eq_option mf_a x y =
  match (x, y) with
  | (None ,None ) -> true
  | (Some x,Some y) -> mf_a x y
  | (_,_) -> false
let eq_ref mf_a x y = mf_a x.contents y.contents
let pp_print_option mf_a fmt v =
  match v with
  | None  -> fprintf fmt "None"
  | Some v -> fprintf fmt "Some @[%a@]" mf_a v
let pp_print_ref mf_a fmt v = fprintf fmt "@[{contents=%a}@]" mf_a v.contents
let pp_print_list mf_a fmt lst =
  let open List in
    fprintf fmt "@[<1>[%a]@]"
      (fun fmt  -> iter (fun x  -> fprintf fmt "%a@ " mf_a x)) lst
let pp_print_exn fmt (e : exn) = fprintf fmt "%s" (Printexc.to_string e)
let eq_list mf_a xs ys =
  let rec loop =
    function
    | ([],[]) -> true
    | (x::xs,y::ys) -> (mf_a x y) && (loop (xs, ys))
    | (_,_) -> false in
  loop (xs, ys)
let eq_array mf_a xs ys =
  let lx = Array.length xs and ly = Array.length ys in
  if lx <> ly
  then false
  else
    (let rec loop i =
       if i >= lx
       then true
       else if mf_a (xs.(i)) (ys.(i)) then loop (i + 1) else false in
     loop 0)
let pp_print_array mf_a fmt lst =
  let open Array in
    fprintf fmt "@[<1>[|%a|]@]"
      (fun fmt  -> iter (fun x  -> fprintf fmt "%a@ " mf_a x)) lst
let eq_arrow _mf_a _mf_b _a _b = false
let pp_print_arrow _mf_a _f_b fmt _v = fprintf fmt "<<<function>>>"
class printbase =
  object (self : 'self_type)
    method int = pp_print_int
    method int32 = pp_print_int32
    method int64 = pp_print_int64
    method nativeint = pp_print_nativeint
    method float = pp_print_float
    method string = pp_print_string
    method bool = pp_print_bool
    method char = pp_print_char
    method unit = pp_print_unit
    method list :
      'a . ('self_type -> 'fmt -> 'a -> unit) -> 'fmt -> 'a list -> unit=
      fun mf_a  fmt  lst  -> pp_print_list (fun a  -> mf_a self a) fmt lst
    method array :
      'a . ('self_type -> 'fmt -> 'a -> unit) -> 'fmt -> 'a array -> unit=
      fun mf_a  fmt  array  ->
        pp_print_array (fun a  -> mf_a self a) fmt array
    method option :
      'a . ('self_type -> 'fmt -> 'a -> unit) -> 'fmt -> 'a option -> unit=
      fun mf_a  fmt  o  -> pp_print_option (fun a  -> mf_a self a) fmt o
    method arrow :
      'a 'b .
        ('self_type -> 'fmt -> 'a -> unit) ->
          ('self_type -> 'fmt -> 'b -> unit) -> 'fmt -> ('a -> 'b) -> unit=
      fun _  _  fmt  _v  -> fprintf fmt "<<<function>>>"
    method ref :
      'a . ('self_type -> 'fmt -> 'a -> unit) -> 'fmt -> 'a ref -> unit=
      fun mf_a  fmt  v  -> pp_print_ref (mf_a self) fmt v
    method unknown : 'a . Format.formatter -> 'a -> unit= fun _fmt  _x  -> ()
  end
class mapbase =
  object (self : 'self_type)
    method int : int -> int= fun x  -> x
    method int32 : int32 -> int32= fun x  -> x
    method int64 : int64 -> int64= fun x  -> x
    method nativeint : nativeint -> nativeint= fun x  -> x
    method float : float -> float= fun x  -> x
    method string : string -> string= fun x  -> x
    method bool : bool -> bool= fun x  -> x
    method char : char -> char= fun x  -> x
    method unit : unit -> unit= fun x  -> x
    method list :
      'a0 'b0 . ('self_type -> 'a0 -> 'b0) -> 'a0 list -> 'b0 list=
      fun mf_a  ->
        function | [] -> [] | y::ys -> (mf_a self y) :: (self#list mf_a ys)
    method array :
      'a0 'b0 . ('self_type -> 'a0 -> 'b0) -> 'a0 array -> 'b0 array=
      fun mf_a  arr  -> Array.map (fun x  -> mf_a self x) arr
    method option :
      'a 'b . ('self_type -> 'a -> 'b) -> 'a option -> 'b option=
      fun mf_a  oa  ->
        match oa with | None  -> None | Some x -> Some (mf_a self x)
    method arrow :
      'a0 'a1 'b0 'b1 .
        ('self_type -> 'a0 -> 'b0) ->
          ('self_type -> 'a1 -> 'b1) -> ('a0 -> 'a1) -> 'b0 -> 'b1=
      fun _mf_a  _mf_b  _f  -> failwith "not implemented in map arrow"
    method ref : 'a 'b . ('self_type -> 'a -> 'b) -> 'a ref -> 'b ref=
      fun mf_a  x  -> ref (mf_a self x.contents)
    method unknown : 'a . 'a -> 'a= fun x  -> x
  end
class iterbase =
  object (self : 'self)
    method int : int -> unit= fun _  -> ()
    method int32 : int32 -> unit= fun _  -> ()
    method int64 : int64 -> unit= fun _  -> ()
    method nativeint : nativeint -> unit= fun _  -> ()
    method float : float -> unit= fun _  -> ()
    method string : string -> unit= fun _  -> ()
    method bool : bool -> unit= fun _  -> ()
    method char : char -> unit= fun _  -> ()
    method unit : unit -> unit= fun _  -> ()
    method list : 'a0 . ('self_type -> 'a0 -> 'unit) -> 'a0 list -> unit=
      fun mf_a  ls  -> List.iter (mf_a self) ls
    method array : 'a0 . ('self_type -> 'a0 -> unit) -> 'a0 array -> unit=
      fun mf_a  arr  -> Array.iter (fun x  -> mf_a self x) arr
    method option : 'a . ('self_type -> 'a -> unit) -> 'a option -> unit=
      fun mf_a  oa  -> match oa with | None  -> () | Some x -> mf_a self x
    method arrow :
      'a0 'a1 'b0 'b1 .
        ('self_type -> 'a0 -> unit) ->
          ('self_type -> 'a1 -> unit) -> ('a0 -> 'a1) -> 'b0 -> 'b1=
      fun _mf_a  _mf_b  _f  -> failwith "not implemented in iter arrow"
    method ref : 'a . ('self_type -> 'a -> unit) -> 'a ref -> unit=
      fun mf_a  x  -> mf_a self x.contents
    method unknown : 'a . 'a -> unit= fun _  -> ()
  end
class eqbase =
  object (self : 'self)
    method int : int -> int -> bool= fun x  y  -> x = y
    method int32 : int32 -> int32 -> bool= fun x  y  -> x = y
    method int64 : int64 -> int64 -> bool= fun x  y  -> x = y
    method nativeint : nativeint -> nativeint -> bool= fun x  y  -> x = y
    method float : float -> float -> bool= fun x  y  -> x = y
    method string : string -> string -> bool= fun x  y  -> x = y
    method bool : bool -> bool -> bool= fun x  y  -> x = y
    method char : char -> char -> bool= fun x  y  -> x = y
    method unit : unit -> unit -> bool= fun x  y  -> x = y
    method list :
      'a0 .
        ('self_type -> 'a0 -> 'a0 -> bool) -> 'a0 list -> 'a0 list -> bool=
      fun mf_a  xs  ys  -> List.for_all2 (mf_a self) xs ys
    method array :
      'a0 .
        ('self_type -> 'a0 -> 'a0 -> bool) -> 'a0 array -> 'a0 array -> bool=
      fun mf_a  xs  ys  -> Array.for_all2 (mf_a self) xs ys
    method option :
      'a . ('self_type -> 'a -> 'a -> bool) -> 'a option -> 'a option -> bool=
      fun mf_a  x  y  ->
        match (x, y) with
        | (None ,None ) -> true
        | (Some x,Some y) -> mf_a self x y
        | (_,_) -> false
    method arrow :
      'a0 'a1 'b0 'b1 .
        ('self_type -> 'a0 -> bool) ->
          ('self_type -> 'a1 -> bool) -> ('a0 -> 'a1) -> 'b0 -> 'b1=
      fun _mf_a  _mf_b  _f  -> failwith "not implemented in iter arrow"
    method ref :
      'a . ('self_type -> 'a -> 'a -> bool) -> 'a ref -> 'a ref -> bool=
      fun mf_a  x  y  -> mf_a self x.contents y.contents
    method unknown : 'a . 'a -> 'a -> bool= fun _  _  -> true
  end
class mapbase2 =
  object (self : 'self_type)
    method int : int -> int -> int= fun x  _  -> x
    method int32 : int32 -> int32 -> int32= fun x  _  -> x
    method int64 : int64 -> int64 -> int64= fun x  _  -> x
    method nativeint : nativeint -> nativeint -> nativeint= fun x  _  -> x
    method float : float -> float -> float= fun x  _  -> x
    method string : string -> string -> string= fun x  _  -> x
    method bool : bool -> bool -> bool= fun x  _  -> x
    method char : char -> char -> char= fun x  _  -> x
    method unit : unit -> unit -> unit= fun x  _  -> x
    method list :
      'a0 'b0 .
        ('self_type -> 'a0 -> 'a0 -> 'b0) -> 'a0 list -> 'a0 list -> 'b0 list=
      fun mf_a  x  y  ->
        match (x, y) with
        | ([],[]) -> []
        | (a0::a1,b0::b1) -> (mf_a self a0 b0) :: (self#list mf_a a1 b1)
        | (_,_) -> invalid_arg "map2 failure"
    method array :
      'a0 'b0 .
        ('self_type -> 'a0 -> 'a0 -> 'b0) ->
          'a0 array -> 'a0 array -> 'b0 array=
      fun mf_a  arr1  arr2  ->
        let lx = Array.length arr1 and ly = Array.length arr2 in
        if lx <> ly
        then invalid_arg "map2 array length is not equal"
        else
          (let f = mf_a self in
           let i = f (arr1.(0)) (arr2.(0)) in
           let c = Array.create lx i in
           for i = 1 to lx - 1 do c.(i) <- f (arr1.(i)) (arr2.(i)) done; c)
    method option :
      'a0 'b0 .
        ('self_type -> 'a0 -> 'a0 -> 'b0) ->
          'a0 option -> 'a0 option -> 'b0 option=
      fun mf_a  x  y  ->
        match (x, y) with
        | (Some x,Some y) -> Some (mf_a self x y)
        | (_,_) -> None
    method ref :
      'a0 'b0 .
        ('self_type -> 'a0 -> 'a0 -> 'b0) -> 'a0 ref -> 'a0 ref -> 'b0 ref=
      fun mf_a  x  y  ->
        match (x, y) with | (x,y) -> ref (mf_a self x.contents y.contents)
    method arrow :
      'a0 'b0 'a1 'b1 .
        ('self_type -> 'a0 -> 'a0 -> 'b0) ->
          ('self_type -> 'a1 -> 'a1 -> 'b1) ->
            ('a0 -> 'a1) -> ('a0 -> 'a1) -> 'b0 -> 'b1=
      fun _  _  _  -> invalid_arg "map2 arrow is not implemented"
    method unknown : 'a . 'a -> 'a -> 'a= fun x  _  -> x
  end
class monadbase = mapbase
class monadbase2 = mapbase2
class foldbase =
  object (self : 'self_type)
    method int : int -> 'self_type= fun _  -> self
    method int32 : int32 -> 'self_type= fun _  -> self
    method int64 : int64 -> 'self_type= fun _  -> self
    method nativeint : nativeint -> 'self_type= fun _  -> self
    method float : float -> 'self_type= fun _  -> self
    method string : string -> 'self_type= fun _  -> self
    method bool : bool -> 'self_type= fun _  -> self
    method char : char -> 'self_type= fun _  -> self
    method unit : unit -> 'self_type= fun _  -> self
    method list :
      'a0 . ('self_type -> 'a0 -> 'self_type) -> 'a0 list -> 'self_type=
      fun mf_a  -> List.fold_left (fun self  v  -> mf_a self v) self
    method array :
      'a0 . ('self_type -> 'a0 -> 'self_type) -> 'a0 array -> 'self_type=
      fun mf_a  -> Array.fold_left (fun self  v  -> mf_a self v) self
    method option :
      'a0 . ('self_type -> 'a0 -> 'self_type) -> 'a0 option -> 'self_type=
      fun mf_a  -> function | None  -> self | Some x -> mf_a self x
    method ref :
      'a0 . ('self_type -> 'a0 -> 'self_type) -> 'a0 ref -> 'self_type=
      fun mf_a  x  -> mf_a self x.contents
    method arrow :
      'a0 'a1 .
        ('self_type -> 'a0 -> 'self_type) ->
          ('self_type -> 'a1 -> 'self_type) -> ('a0 -> 'a1) -> 'self_type=
      fun _  _  _  -> invalid_arg "fold arrow is not implemented"
    method unknown : 'a . 'a -> 'self_type= fun _  -> self
  end
class foldbase2 =
  object (self : 'self_type)
    method int : int -> int -> 'self_type= fun _  _  -> self
    method int32 : int32 -> int32 -> 'self_type= fun _  _  -> self
    method int64 : int64 -> int64 -> 'self_type= fun _  _  -> self
    method nativeint : nativeint -> nativeint -> 'self_type=
      fun _  _  -> self
    method float : float -> float -> 'self_type= fun _  _  -> self
    method string : string -> string -> 'self_type= fun _  _  -> self
    method bool : bool -> bool -> 'self_type= fun _  _  -> self
    method char : char -> char -> 'self_type= fun _  _  -> self
    method unit : unit -> unit -> 'self_type= fun _  _  -> self
    method list :
      'a0 .
        ('self_type -> 'a0 -> 'a0 -> 'self_type) ->
          'a0 list -> 'a0 list -> 'self_type=
      fun mf_a  lx  ly  -> List.fold_left2 mf_a self lx ly
    method array :
      'a0 .
        ('self_type -> 'a0 -> 'a0 -> 'self_type) ->
          'a0 array -> 'a0 array -> 'self_type=
      fun mf_a  lx  ly  -> Array.fold_left2 mf_a self lx ly
    method option :
      'a0 .
        ('self_type -> 'a0 -> 'a0 -> 'self_type) ->
          'a0 option -> 'a0 option -> 'self_type=
      fun mf_a  lx  ly  ->
        match (lx, ly) with
        | (Some x,Some y) -> mf_a self x y
        | (_,_) -> self
    method ref :
      'a0 .
        ('self_type -> 'a0 -> 'a0 -> 'self_type) ->
          'a0 ref -> 'a0 ref -> 'self_type=
      fun mf_a  x  y  ->
        match (x, y) with | (a,b) -> mf_a self a.contents b.contents
    method arrow :
      'a0 'a1 .
        ('self_type -> 'a0 -> 'a0 -> 'self_type) ->
          ('self_type -> 'a1 -> 'a1 -> 'self_type) ->
            ('a0 -> 'a1) -> ('a0 -> 'a1) -> 'self_type=
      fun _  _  _  -> invalid_arg "fold2 arrow not implemented"
    method unknown : 'a . 'a -> 'a -> 'self_type= fun _  _  -> self
  end