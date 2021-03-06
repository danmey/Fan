type node = { 
  id : int; 
  mutable eps : node list; 
  mutable trans : (LexSet.t * node) list;
}

type regexp = private node -> node

type state = node list
      
val chars: LexSet.t -> regexp
val seq: regexp -> regexp -> regexp
val alt: regexp -> regexp -> regexp
val rep: regexp -> regexp
val plus: regexp -> regexp
val eps: regexp

val compile:
    part_tbl:(LexSet.t array, int) Hashtbl.t ->
      regexp array -> (int * int array * bool array) array
val partitions:
    part_tbl:(LexSet.t array, int) Hashtbl.t -> 
      unit -> (int * (int * int * int) list) list

val new_node : unit -> node
val compile_re : (node -> 'a) -> 'a * node
val add_node: state -> node -> state
val add_nodes: state -> node list -> state
val transition: state -> (int * int) list array * state array
val find_alloc: ('a, int) Hashtbl.t -> int ref -> 'a -> int
(* val get_part: LexSet.t array -> int *)
val get_part: part_tbl:(LexSet.t array, int)Hashtbl.t -> LexSet.t array -> int    
val of_string:string -> regexp
    

val named_regexps : (string, regexp) Hashtbl.t
type decision_tree =
    Lte of int * decision_tree * decision_tree
  | Table of int * int array
  | Return of int
val decision : (int * int * int) list -> decision_tree
val limit : int
val decision_table : (int * int * int) list -> decision_tree
val simplify : int -> int -> decision_tree -> decision_tree
    
