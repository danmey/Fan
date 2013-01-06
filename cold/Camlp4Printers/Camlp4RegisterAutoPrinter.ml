open MakeBin
module P : PRINTER_PLUGIN =
  struct
    let apply ((module Register)  : (module MakeRegister.S)) =
      Register.enable_auto (fun ()  -> Unix.isatty Unix.stdout)
  end 
let _ = Hashtbl.replace printers "camlp4autoprinter" (module P)