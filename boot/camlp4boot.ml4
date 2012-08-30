module Camlp4Parsers = struct INCLUDE "camlp4/Camlp4Parsers/Camlp4Parsers.ml"; end;
module Camlp4Filters = struct INCLUDE "camlp4/Camlp4Filters/Camlp4Filters.ml"; end;

module R = struct INCLUDE "camlp4/Camlp4Parsers/Camlp4OCamlRevisedParser.ml"; end;
module Camlp4QuotationCommon = struct INCLUDE "camlp4/Camlp4Parsers/Camlp4QuotationCommon.ml"; end;
module Q = struct INCLUDE "camlp4/Camlp4Parsers/Camlp4QuotationExpander.ml"; end;
module Rp = struct INCLUDE "camlp4/Camlp4Parsers/Camlp4OCamlRevisedParserParser.ml"; end;
module G = struct INCLUDE "camlp4/Camlp4Parsers/Camlp4GrammarParser.ml"; end;
module M = struct INCLUDE "camlp4/Camlp4Parsers/Camlp4MacroParser.ml"; end;
module D = struct INCLUDE "camlp4/Camlp4Parsers/Camlp4DebugParser.ml"; end;
module L = struct INCLUDE "camlp4/Camlp4Parsers/Camlp4ListComprehension.ml"; end;
module P = struct INCLUDE "camlp4/Camlp4Printers/Camlp4OCamlAstDumper.ml"; end;
module MakeCamlp4Bin = struct INCLUDE "camlp4/MakeCamlp4Bin.ml"; end;
module B = struct INCLUDE "camlp4/Camlp4Bin.ml"; end;
