open Ast_mapper
open Location
open Parsetree

(* To define a concrete AST rewriter, we can inherit from the generic
   mapper, and redefine the cases we are interested in.  In the
   example below, we insert in the AST some debug statements around
   each module structure. We also keep track of the current "path" in
   the compilation unit.  *)

let trace s =
  SI.eval E.(apply (lid "Pervasives.print_endline") [strconst s])

let tracer =
  object(this)
    inherit Ast_mapper.create as super
    val path = ""

    method! implementation input_name ast =
      let path = String.capitalize (Filename.chop_extension input_name) in
      (input_name, {< path = path >} # structure ast)

    method! structure_item = function
      | {pstr_desc = Pstr_module (s, _); pstr_loc = _loc} as si ->
          [ SI.map {< path = path ^ "." ^ s.txt >} si ]
      | si ->
          [ SI.map this si ]

    method! structure l =
      trace (Printf.sprintf "Entering module %s" path) ::
      (super # structure l) @
      [ trace (Printf.sprintf "Leaving module %s" path) ]
  end

let () = tracer # main
