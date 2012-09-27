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
 * - Nicolas Pouillard: initial version
 *)

(* open Camlp4;
 * Register.enable_auto (fun () -> Unix.isatty Unix.stdout); *)
open MakeCamlp4Bin;

module P : PRINTER_PLUGIN = struct
  let apply (module Register:MakeRegister.S) =
    Register.enable_auto (fun () -> Unix.isatty Unix.stdout);
end;

Hashtbl.replace printers "camlp4autoprinter" (module P) ; 




