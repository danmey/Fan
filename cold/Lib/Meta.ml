module Ast  = Camlp4Ast
module MetaLocVar  : Ast.META_LOC =
  struct
    let meta_loc_patt (_loc) (_) =
      Ast.PaId ((_loc,( Ast.IdLid ((_loc,( FanLoc.name.contents ))) )))
    let meta_loc_expr (_loc) (_) =
      Ast.ExId ((_loc,( Ast.IdLid ((_loc,( FanLoc.name.contents ))) ))) end 
module MetaLoc  : Ast.META_LOC =
  struct
    let meta_loc_patt (_loc) (location) =
      let (a,b,c,d,e,f,g,h) = (FanLoc.to_tuple location) in
      Ast.PaApp
        ((_loc,(
          Ast.PaId
            ((_loc,(
              Ast.IdAcc
                ((_loc,( Ast.IdUid ((_loc,"FanLoc")) ),(
                  Ast.IdLid ((_loc,"of_tuple")) ))) ))) ),(
          Ast.PaTup
            ((_loc,(
              Ast.PaCom
                ((_loc,( Ast.PaStr ((_loc,( (Ast.safe_string_escaped a) )))
                  ),(
                  Ast.PaCom
                    ((_loc,(
                      Ast.PaCom
                        ((_loc,(
                          Ast.PaCom
                            ((_loc,(
                              Ast.PaCom
                                ((_loc,(
                                  Ast.PaCom
                                    ((_loc,(
                                      Ast.PaCom
                                        ((_loc,(
                                          Ast.PaInt
                                            ((_loc,( (string_of_int b) )))
                                          ),(
                                          Ast.PaInt
                                            ((_loc,( (string_of_int c) ))) )))
                                      ),(
                                      Ast.PaInt
                                        ((_loc,( (string_of_int d) ))) )))
                                  ),(
                                  Ast.PaInt ((_loc,( (string_of_int e) ))) )))
                              ),( Ast.PaInt ((_loc,( (string_of_int f) ))) )))
                          ),( Ast.PaInt ((_loc,( (string_of_int g) ))) )))
                      ),(
                      if h then begin
                      Ast.PaId ((_loc,( Ast.IdUid ((_loc,"True")) )))
                      end else begin
                      Ast.PaId ((_loc,( Ast.IdUid ((_loc,"False")) )))
                      end ))) ))) ))) )))
    let meta_loc_expr (_loc) (location) =
      let (a,b,c,d,e,f,g,h) = (FanLoc.to_tuple location) in
      Ast.ExApp
        ((_loc,(
          Ast.ExId
            ((_loc,(
              Ast.IdAcc
                ((_loc,( Ast.IdUid ((_loc,"FanLoc")) ),(
                  Ast.IdLid ((_loc,"of_tuple")) ))) ))) ),(
          Ast.ExTup
            ((_loc,(
              Ast.ExCom
                ((_loc,( Ast.ExStr ((_loc,( (Ast.safe_string_escaped a) )))
                  ),(
                  Ast.ExCom
                    ((_loc,(
                      Ast.ExCom
                        ((_loc,(
                          Ast.ExCom
                            ((_loc,(
                              Ast.ExCom
                                ((_loc,(
                                  Ast.ExCom
                                    ((_loc,(
                                      Ast.ExCom
                                        ((_loc,(
                                          Ast.ExInt
                                            ((_loc,( (string_of_int b) )))
                                          ),(
                                          Ast.ExInt
                                            ((_loc,( (string_of_int c) ))) )))
                                      ),(
                                      Ast.ExInt
                                        ((_loc,( (string_of_int d) ))) )))
                                  ),(
                                  Ast.ExInt ((_loc,( (string_of_int e) ))) )))
                              ),( Ast.ExInt ((_loc,( (string_of_int f) ))) )))
                          ),( Ast.ExInt ((_loc,( (string_of_int g) ))) )))
                      ),(
                      if h then begin
                      Ast.ExId ((_loc,( Ast.IdUid ((_loc,"True")) )))
                      end else begin
                      Ast.ExId ((_loc,( Ast.IdUid ((_loc,"False")) )))
                      end ))) ))) ))) ))) end 
module MetaGhostLoc  : Ast.META_LOC =
  struct
    let meta_loc_patt (_loc) (_) =
      Ast.PaId
        ((_loc,(
          Ast.IdAcc
            ((_loc,( Ast.IdUid ((_loc,"FanLoc")) ),(
              Ast.IdLid ((_loc,"ghost")) ))) )))
    let meta_loc_expr (_loc) (_) =
      Ast.ExId
        ((_loc,(
          Ast.IdAcc
            ((_loc,( Ast.IdUid ((_loc,"FanLoc")) ),(
              Ast.IdLid ((_loc,"ghost")) ))) ))) end 
module MetaLocQuotation  =
  struct let loc_name = (ref None )
    let meta_loc_expr (_loc) (loc) = begin match loc_name.contents with
      | None  ->
          Ast.ExId ((_loc,( Ast.IdLid ((_loc,( FanLoc.name.contents ))) )))
      | Some("here") ->   (MetaLoc.meta_loc_expr _loc loc)
      | Some(x) ->   Ast.ExId ((_loc,( Ast.IdLid ((_loc,x)) ))) end
    let meta_loc_patt (_loc) (_) = Ast.PaAny (_loc) end
module MetaQAst  = (Ast.Meta.Make) (MetaLocQuotation)
module ME  = MetaQAst.Expr
module MP  = MetaQAst.Patt