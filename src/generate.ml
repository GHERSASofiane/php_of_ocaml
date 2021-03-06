
open Typedtree
open Asttypes
open Types
open Ident
open Location
open Path

(* à definir *)
type etatVar =
  { mutable name : string ; 
    mutable id : int
  }

let boolMultVars = ref false
let refVar = ref ""
let tab_print = ref["print_char";"print_int";"print_float";"print_string";"print_endline";"print_newline"]
let tab_conv  = ref["int_of_float";"float_of_int";"int_of_char";"char_of_int";"string_of_bool";"bool_of_string";"int_of_string";"float_of_string";"string_of_int";"string_of_float"] 
let tab_op    = ref["+";"+.";"-";"-.";"*";"*.";"/";"/.";"<";"<=";">";">=";"=";"==";"<>";"!="] 
  

exception Not_implemented_yet of string
(* initialize a list to store function names *)
let l = ref []
let is_prem = ref true 
let is_fusion = ref false
let is_concat = ref false 

let pvEnd = ref false
let pvEnd2= ref false
let pvEnd3 = ref false

let boolApply = ref false
let boolLet = ref false

let noise = ref false
let alterP = ref false
let alterP2 = ref false
let dotBool = ref false
let pidentBool=ref false
let fromPatVar = ref false
let paramBool = ref false
let fromApply=ref true
let unitFunc = ref false
let temp = ref 0
let data = ref 0
(* let varTable = [] *)

(* Generate Constant   ******************************************************************************************************* *)

and generate_constant fmt cst =
  match cst with
  | Const_int i -> Format.fprintf fmt "%d" i 
  | Const_char c -> Format.fprintf fmt "'%c'" c 
  | Const_string (s_01 , s_02) -> begin
    if s_01 = "\n" then Format.fprintf fmt "\"\\n\"" else  Format.fprintf fmt "%c%s%c" '"' s_01 '"' 
                                    
                                  end 
  | Const_float f -> Format.fprintf fmt "%s" f 
  | _ -> raise (Not_implemented_yet "generate_constant_error")


 (* Generate Function  ******************************************************************************************************* *)
and generation_of_parameter fmt pattern_desc = (* generate parameter *)
  match pattern_desc with
  | Tpat_var (i,loc) ->  Format.fprintf fmt " $%s" loc.txt
  | Tpat_construct (a,b,c) -> Format.fprintf fmt ""

  | Tpat_any -> Format.fprintf fmt "generation_of_parameter_any \n"
  | Tpat_alias (a,b,c) -> Format.fprintf fmt " generation_of_parameter_alias \n"
  | Tpat_constant a -> Format.fprintf fmt " generation_of_parameter_canst \n"
  | Tpat_tuple a -> Format.fprintf fmt " generation_of_parameter_tuple \n"
  | Tpat_variant (a,b,c) -> Format.fprintf fmt " generation_of_parameter_variant \n"
  | Tpat_record (a,b) -> Format.fprintf fmt "  generation_of_parameter_record\n"
  | Tpat_array a -> Format.fprintf fmt " generation_of_parameter_array \n"
  | Tpat_or (a,b,c) -> Format.fprintf fmt " generation_of_parameter_or "
  | Tpat_lazy a -> Format.fprintf fmt " generation_of_parameter_lazy \n"
  |_ ->  Format.fprintf fmt "ERROR_generation_of_parameter"


 (* Print args of functions  ***************************************************************************************************)

let rec generate_args fmt case =
  match case with
  |[] ->  Format.fprintf fmt ""
  |arg::[] ->  if arg.c_rhs.exp_loc.loc_ghost then begin

    (* generate function parameters *)
    generation_of_parameter fmt arg.c_lhs.pat_desc ;
    Format.fprintf fmt ",";
    match arg.c_rhs.exp_desc with
    | Texp_function (label,case,partial) ->  Format.fprintf fmt "%a"  generate_args case 
    | _ -> Format.fprintf fmt "ERROR_generate_args__match"
  end 
    else begin
      generation_of_parameter fmt arg.c_lhs.pat_desc ; 
      Format.fprintf fmt " ){\n  " ; 
                begin
                   match arg.c_rhs.exp_desc with
                          | Texp_constant cst -> Format.fprintf fmt " return "; generate_expression fmt arg.c_rhs.exp_desc ; 
                                                                     Format.fprintf fmt ";\n }\n"
                          | Texp_array ary ->  Format.fprintf fmt " return "; generate_expression fmt arg.c_rhs.exp_desc ; 
                                                                     Format.fprintf fmt "\n }\n"
                          | Texp_tuple tup ->  Format.fprintf fmt " return "; generate_expression fmt arg.c_rhs.exp_desc ; 
                                                                     Format.fprintf fmt "\n }\n"
                          | Texp_ident (path,long,typ)    ->  Format.fprintf fmt " return "; generate_expression fmt arg.c_rhs.exp_desc ; 
                                                                     Format.fprintf fmt "\n }\n"
                          | Texp_construct (long_id,cd,exp_list) ->  Format.fprintf fmt " return "; generate_expression fmt arg.c_rhs.exp_desc ; 
                                                                     Format.fprintf fmt "\n }\n"
                          | Texp_apply (exp,l_exp) -> begin
                            let tab_op= ["+";"+.";"-";"-.";"*";"*.";"/";"/.";"<";"<=";">";">=";"=";"==";"<>";"!="] in
                                                      match exp.exp_desc with
                                                      | Texp_ident (path,long,typ) -> begin
                                                        match path with
                                                        | Pdot (t,str,i) -> if (List.mem str !tab_print) 
                                                          then begin 
                                                                   generate_expression fmt arg.c_rhs.exp_desc ; Format.fprintf fmt "\n }\n";
                                                               end 
                                                          else if (List.mem str tab_op)  then 
                                                                    begin
                                                                      Format.fprintf fmt " return "; generate_expression fmt arg.c_rhs.exp_desc ; 
                                                                         Format.fprintf fmt ";\n }\n\n";
                                                                    end
                                                           else  if (List.length l_exp) != 1 then begin
                                                            match str with
                                                                | "&&" ->Format.fprintf fmt " return "; generate_expression fmt arg.c_rhs.exp_desc ; 
                                                                         Format.fprintf fmt ";\n }\n\n";
                                                                | "&" -> Format.fprintf fmt " return "; generate_expression fmt arg.c_rhs.exp_desc ; 
                                                                         Format.fprintf fmt ";\n }\n\n";
                                                                | "||" -> Format.fprintf fmt " return "; generate_expression fmt arg.c_rhs.exp_desc ; 
                                                                         Format.fprintf fmt ";\n }\n\n";
                                                                | "mod" ->Format.fprintf fmt " return "; generate_expression fmt arg.c_rhs.exp_desc ; 
                                                                         Format.fprintf fmt ";\n }\n\n";
                                                                | "**" ->Format.fprintf fmt " return "; generate_expression fmt arg.c_rhs.exp_desc ; 
                                                                         Format.fprintf fmt ";\n }\n\n";
                                                                | "^" -> Format.fprintf fmt " return "; generate_expression fmt arg.c_rhs.exp_desc ; 
                                                                         Format.fprintf fmt ";\n }\n\n";
                                                                | _ -> generate_expression fmt arg.c_rhs.exp_desc  ; 
                                                                       Format.fprintf fmt ";\n }\n";
                                                          
                                                            
                                                          end
                                                          else  begin  (* uniry operator *)
                                                            Format.fprintf fmt " return "; generate_expression fmt arg.c_rhs.exp_desc ; 
                                                            Format.fprintf fmt ";\n }\n";
                                                          end
                                                        | _ -> begin 
                                                                   generate_expression fmt arg.c_rhs.exp_desc ; Format.fprintf fmt "\n }\n";
                                                               end
                                                      end 
                                                      | _ -> generate_expression fmt arg.c_rhs.exp_desc ; Format.fprintf fmt "\n }\n";
                                                        
                                                        
                                                    end
                          | _ -> generate_expression fmt arg.c_rhs.exp_desc ; Format.fprintf fmt "\n }\n" 
                end;
    end
  | _ -> Format.fprintf fmt "ERROR_generate_args"  
    
(* Generate Array and tuple  ******************************************************************************************************* *)
and  generate_array_and_tuple fmt tpl =
  let arr_of_tpl = Array.of_list tpl in
  let taille = Array.length arr_of_tpl - 1 in
  for i = 0 to taille  do 
    if i == taille then begin
      (* (...,E) the last element*)
      generate_expression fmt (Array.get arr_of_tpl taille).exp_desc  
    end  
    else begin
      (* (E,E,E,...) *)
      generate_expression fmt (Array.get arr_of_tpl i).exp_desc ; Format.fprintf fmt " , " 
    end
  done

(* Generate records ***************************************************************************************************************** *)
 and generate_records fmt rcd=
 match rcd with
               | [] -> Format.fprintf fmt   "\n " ; 
               | hd::[] ->
                  let (_,lb,exp) = hd in
                             Format.fprintf fmt "\t \t \'%s\' => " lb.lbl_name ;
                             generate_expression fmt exp.exp_desc;
                             Format.fprintf fmt   "\n ";
               | hd::rst ->
                  let (_,lb,exp) = hd in  
                             Format.fprintf fmt "\t \t \'%s\' => " lb.lbl_name ;
                             generate_expression fmt exp.exp_desc;
                             Format.fprintf fmt   ",\n ";
                             generate_records fmt rst;
               | _ -> Format.fprintf fmt   " " ; 
(* ********************************************************************************************************************************* *)

(* get a constant *)
and gen_of_constant = function
  | Const_int       n     -> string_of_int n
  | Const_char      c     -> String.make 1 c
  | Const_string   (s, _) -> "\"" ^ s ^ "\""
  | Const_float     f     -> f
  | Const_int32     n     -> Int32.to_string n
  | Const_int64     n     -> Int64.to_string n
  | Const_nativeint n     -> Nativeint.to_string n



(* Generate Expression   ******************************************************************************************************* *)

    
and generate_expression fmt exp_desc = 
  
  match exp_desc with
  | Texp_constant cst -> generate_constant fmt cst 
  | Texp_array ary -> Format.fprintf fmt "array ( " ; generate_array_and_tuple fmt ary ; Format.fprintf fmt ")"
  | Texp_tuple tup -> Format.fprintf fmt "array ( " ; generate_array_and_tuple fmt tup ; Format.fprintf fmt " ) "
  | Texp_function (label,case,partial) ->  Format.fprintf fmt " ( "; generate_args fmt case
  | Texp_ifthenelse (cond,trait,alt) -> begin

    Format.fprintf fmt   "\tif ( " ;generate_expression fmt cond.exp_desc ; 
    Format.fprintf fmt   " ) {\n " ;
                begin
                   match trait.exp_desc with
                          | Texp_constant cst -> Format.fprintf fmt " return "; generate_expression fmt trait.exp_desc ; 
                                                 Format.fprintf fmt   ";\n }" 
                          | Texp_array ary ->  Format.fprintf fmt " return "; generate_expression fmt trait.exp_desc ; 
                                                 Format.fprintf fmt   ";\n }" 
                          | Texp_tuple tup ->  Format.fprintf fmt " return "; generate_expression fmt trait.exp_desc ; 
                                                 Format.fprintf fmt   ";\n }" 
                          | Texp_ident (path,long,typ)    ->  Format.fprintf fmt " return "; generate_expression fmt trait.exp_desc ; 
                                                 Format.fprintf fmt   ";\n }" 
                          | Texp_construct (long_id,cd,exp_list) ->  Format.fprintf fmt " return "; generate_expression fmt trait.exp_desc ; 
                                                 Format.fprintf fmt   ";\n }" 
                          | Texp_apply (exp,l_exp) -> begin
                            let tab_op= ["+";"+.";"-";"-.";"*";"*.";"/";"/.";"<";"<=";">";">=";"=";"==";"<>";"!="] in
                                                      match exp.exp_desc with

                                                      | Texp_ident (path,long,typ) -> begin
                                                        match path with
                                                        | Pdot (t,str,valds) ->
                                                        if(str = "raise") then 
                                                        begin
                                                                
                                                                let (lab,exp2,jj) = (List.nth l_exp 0) in 
                                                                match exp2 with

                                                                | Some aa -> begin
                                                                          match aa.exp_desc with
                                                                          | Texp_construct (loc,cdes,exp) -> begin
                                                                            if(cdes.cstr_name = "End_of_file") then 
                                                                            Format.fprintf fmt " throw new ParseError(\"%s\");\n \t \t }\n" cdes.cstr_name
                                                                          else
                                                                          if (cdes.cstr_name = "Exit") then 
                                                                            Format.fprintf fmt " throw new ErrorException(\"%s\");\n \t \t }\n" cdes.cstr_name
                                                                          else 
                                                                          Format.fprintf fmt " throw new Exception(\"%s\");\n \t \t }\n" cdes.cstr_name
                                                                          end
                                                                          | _ -> Format.fprintf fmt " ____IF____EXCEPTION_____"
                                                                            end
                                                                | None -> Format.fprintf fmt "___ NONE ___"
                                                          
                                                        end
                                                              else
                                                         if (List.mem str !tab_print) 
                                                          then begin 
                                                                   generate_expression fmt trait.exp_desc  ; Format.fprintf fmt "\n }\n";
                                                               end 
                                                          else if (List.mem str tab_op)  then 
                                                                    begin
                                                                      Format.fprintf fmt " return "; generate_expression fmt trait.exp_desc ; 
                                                                         Format.fprintf fmt ";\n }\n\n";
                                                                    end
                                                           else  if (List.length l_exp) != 1 then begin
                                                            match str with
                                                                | "&&" ->Format.fprintf fmt " return "; generate_expression fmt trait.exp_desc ; 
                                                                         Format.fprintf fmt ";\n }\n\n";
                                                                | "&" -> Format.fprintf fmt " return "; generate_expression fmt trait.exp_desc ; 
                                                                         Format.fprintf fmt ";\n }\n\n";
                                                                | "||" -> Format.fprintf fmt " return "; generate_expression fmt trait.exp_desc ; 
                                                                         Format.fprintf fmt ";\n }\n\n";
                                                                | "mod" ->Format.fprintf fmt " return "; generate_expression fmt trait.exp_desc ; 
                                                                         Format.fprintf fmt ";\n }\n\n";
                                                                | "**" ->Format.fprintf fmt " return "; generate_expression fmt trait.exp_desc ; 
                                                                         Format.fprintf fmt ";\n }\n\n";
                                                                | "^" -> Format.fprintf fmt " return "; generate_expression fmt trait.exp_desc ; 
                                                                         Format.fprintf fmt ";\n }\n\n";
                                                                | _ -> generate_expression fmt trait.exp_desc  ; 
                                                                       Format.fprintf fmt "\n }\n";
                                                          
                                                            
                                                          end
                                                          else  begin  (* uniry operator *)
                                                            Format.fprintf fmt " return "; generate_expression fmt trait.exp_desc  ; 
                                                            Format.fprintf fmt ";\n }\n";
                                                          end
                                                        | _ -> begin 
                                                                   generate_expression fmt trait.exp_desc  ; Format.fprintf fmt ");\n }\n";
                                                               end
                                                      end 
                                                      | _ -> generate_expression fmt trait.exp_desc  ; Format.fprintf fmt "°°°°\n }\n";
                                                        
                                                        
                                                    end
                          | _ -> generate_expression fmt trait.exp_desc ;  Format.fprintf fmt   "\n }" 
                end;
         
    
    match alt with 
    | Some z-> Format.fprintf fmt "\telse{\n "; 
          begin
             match z.exp_desc with
                    | Texp_constant cst -> Format.fprintf fmt " return "; generate_expression fmt z.exp_desc ; 
                                           Format.fprintf fmt   ";\n }\n\n" 
                    | Texp_array ary ->  Format.fprintf fmt " return "; generate_expression fmt z.exp_desc ; 
                                           Format.fprintf fmt   ";\n }\n\n" 
                    | Texp_tuple tup ->  Format.fprintf fmt " return "; generate_expression fmt z.exp_desc ; 
                                           Format.fprintf fmt   ";\n }\n\n" 
                    | Texp_ident (path,long,typ)    ->  Format.fprintf fmt " return "; generate_expression fmt z.exp_desc ; 
                                           Format.fprintf fmt   ";\n }\n\n" 
                    | Texp_construct (long_id,cd,exp_list) -> 
                              begin
                                  let vv = cd.cstr_name in 
                                    if vv = "()" then
                                    Format.fprintf fmt   "\n }\n\n" 
                                     else begin
                                       
                                    Format.fprintf fmt " return %s " vv ; generate_expression fmt z.exp_desc ; 
                                    Format.fprintf fmt   ";\n }\n\n" 
                                     end
                              end 
                    | Texp_apply (exp,l_exp) -> begin
                      let tab_op= ["+";"+.";"-";"-.";"*";"*.";"/";"/.";"<";"<=";">";">=";"=";"==";"<>";"!="] in
                            match exp.exp_desc with
                            | Texp_ident (path,long,typ) -> begin
                              match path with
                              | Pdot (t,str,i) -> 
                              if(str = "raise") then 
                                                        begin
                                                                let (lab,exp2,jj) = (List.nth l_exp 0) in 
                                                                match exp2 with

                                                                | Some aa -> begin
                                                                          match aa.exp_desc with
                                                                          | Texp_construct (loc,cdes,exp) -> begin
                                                                            if(cdes.cstr_name = "End_of_file") then 
                                                                            Format.fprintf fmt " throw new ParseError(\"%s\");\n \t \t }\n" cdes.cstr_name
                                                                          else
                                                                          if (cdes.cstr_name = "Exit") then 
                                                                            Format.fprintf fmt " throw new ErrorException(\"%s\");\n \t \t }\n" cdes.cstr_name
                                                                          else 
                                                                          Format.fprintf fmt " throw new Exception(\"%s\");\n \t \t }\n" cdes.cstr_name
                                                                          end
                                                                          | _ -> Format.fprintf fmt " ____IF____EXCEPTION_____"
                                                                            end
                                                                | None -> Format.fprintf fmt "___ NONE ___"
                                                          
                                                        end
                              else
                              if (List.mem str !tab_print) 
                                then begin
                                  generate_expression fmt z.exp_desc ; Format.fprintf fmt "\n }\n\n"
                                end else if (List.mem str tab_op)  then 
                                          begin
                                            Format.fprintf fmt " return "; generate_expression fmt z.exp_desc ; 
                                               Format.fprintf fmt ";\n }\n\n";
                                          end
                                 else if (List.length l_exp) != 1 then begin
                                  match str with
                                      | "&&" ->Format.fprintf fmt " return "; generate_expression fmt z.exp_desc ; 
                                               Format.fprintf fmt ";\n }\n\n";
                                      | "&" -> Format.fprintf fmt " return "; generate_expression fmt z.exp_desc ; 
                                               Format.fprintf fmt ";\n }\n\n";
                                      | "||" -> Format.fprintf fmt " return "; generate_expression fmt z.exp_desc ; 
                                               Format.fprintf fmt ";\n }\n\n";
                                      | "mod" ->Format.fprintf fmt " return "; generate_expression fmt z.exp_desc ; 
                                               Format.fprintf fmt ";\n }\n\n";
                                      | "**" ->Format.fprintf fmt " return "; generate_expression fmt z.exp_desc ; 
                                               Format.fprintf fmt ";\n }\n\n";
                                      | "^" -> Format.fprintf fmt " return "; generate_expression fmt z.exp_desc ; 
                                               Format.fprintf fmt ";\n }\n\n";
                                      | _ -> generate_expression fmt z.exp_desc  ; 
                                             Format.fprintf fmt "\n }\n";
                                
                                  
                                end
                                else begin  (* uniry operator *)
                                  Format.fprintf fmt " return "; generate_expression fmt z.exp_desc ; 
                                  Format.fprintf fmt ";\n }\n\n";
                                end
                              | _ -> begin 
                                         generate_expression fmt z.exp_desc ; 
                                        if(!paramBool) then paramBool :=false else
                                         Format.fprintf fmt ");\n }\n\n";
                                     end
                            end 
                            | _ -> generate_expression fmt z.exp_desc  ; Format.fprintf fmt "\n }\n\n";
                              
                              
                          end
                    | _ -> generate_expression fmt z.exp_desc ;  Format.fprintf fmt   "\n }\n\n" 
          end;
    | None -> Format.fprintf fmt   "\n\n";
  end

  | Texp_apply (exp,l_exp) ->
  (* Format.fprintf fmt "apply ===> " ; *)
  (* fromApply:=true; *)
 
   if (List.length l_exp) = 1 then 
      begin 

        match exp.exp_desc with
        | Texp_ident (path,long,typ) -> begin
          match path with
          | Pdot (t,str,i) -> 
          if (List.mem str !tab_print) 
            then begin (* echo *) 
              Format.fprintf fmt "echo  ";
              Format.fprintf fmt " ( ";
              if str = "print_newline" then 
                Format.fprintf fmt "\" \\n \""
              else 
                generate_param fmt (List.nth l_exp 0);
              if str = "print_endline" then Format.fprintf fmt ".\" \\n \"" 
              else Format.fprintf fmt "";
              
              
              Format.fprintf fmt " ); \n";
            end  
            else begin  (* uniry operator *)

              (* MATCH ALWAYS WITH TEXP_IDENT AND ANYTHING *)
              generate_expression fmt exp.exp_desc;
              (* Format.fprintf fmt "\n \t \t +++++ \n \n"; *)
             
                
                  match exp.exp_desc with
                  | Texp_ident (path,long,typ)    -> begin

                                                        match path with (*  Les fonctions de conversions *) 
                                                        | Pdot (t,str,i) -> 
                                                        if str = "string_of_bool" then begin
                                                         Format.fprintf fmt "("; 
                                                                               Format.fprintf fmt "\""; generate_param fmt (List.nth l_exp 0); 
                                                                               Format.fprintf fmt "\" )"; 
                                                                            end 
                                                                            else 
                                                                            begin
                                                                                
                                                  match exp.exp_desc with
                                                  | Texp_ident (path,long,typ)    -> begin
                                                                                          match path with (*  Les fonctions de conversions *) 
                                                                                          | Pdot (t,str,i) -> begin
                                                                                            (* ///////////////////////////////////////////////////////////////////// *)
                                                                                                                   if str = "open_in" then
                                                                                                                       begin
                                                                                                                         Format.fprintf fmt "("; 
                                                                                                                          generate_param fmt (List.nth l_exp 0);
                                                                                                                           Format.fprintf fmt " , \"r\" )";
                                                                                                                       end
                                                                                                                  else if str = "open_out" then
                                                                                                                       begin
                                                                                                                         Format.fprintf fmt "("; 
                                                                                                                          generate_param fmt (List.nth l_exp 0);
                                                                                                                           Format.fprintf fmt " , \"w\" )"; 
                                                                                                                       end
                                                                                                                  else  if str = "close_out" then
                                                                                                                       begin
                                                                                                                         Format.fprintf fmt "("; 
                                                                                                                          generate_param fmt (List.nth l_exp 0);  Format.fprintf fmt ");";
                                                                                                                       end
                                                                                                                  else if str = "length" then
                                                                                                                       begin
                                                                                                                         Format.fprintf fmt "("; 
                                                                                                                        generate_param fmt (List.nth l_exp 0); Format.fprintf fmt ")";
                                                                                                                       end
                                                                                                                  else  if str = "close_in" then
                                                                                                                       begin
                                                                                                                         Format.fprintf fmt "("; 
                                                                                                                          generate_param fmt (List.nth l_exp 0);  Format.fprintf fmt ");";
                                                                                                                       end
                                                                                                                  else if str = "ref" then
                                                                                                                       begin
                                                                                                                         let (lab,exp,op) = (List.nth l_exp 0) in
                                                                                                                              match exp with
                                                                                                                              | Some b -> begin
                                                                                                                                (* ///////////////////////////////////////////////////////////////////// *)
                                                                                                                                              match b.exp_desc with
                                                                                                                                              | Texp_construct (long_id,cd,exp_list) -> Format.fprintf fmt "array()"
                                                                                                                                              | Texp_constant cst -> Format.fprintf fmt "\"\""
                                                                                                                                              | Texp_array ary -> Format.fprintf fmt "(array ( " ; generate_array_and_tuple fmt ary ; Format.fprintf fmt "))"
                                                                                                                                              | Texp_tuple tup -> Format.fprintf fmt "(array ( " ; generate_array_and_tuple fmt tup ; Format.fprintf fmt " )) "
                                                                                                                                              | Texp_ident (path,long,typ) -> Format.fprintf fmt "(";  generate_path fmt path;Format.fprintf fmt ")"
                                                                                                                                              | _ -> generate_expression fmt b.exp_desc
                                                                                                                                              
                                                                                                                                          end
                                                                                                                                                                    
                                                                                                                              | None -> Format.fprintf fmt ""
                                                      
                                                                                                                       end
                                                                                                                  else
                                                                                                                  
                                                                                                                  
                                                                                                                       begin
                                                                                                                         Format.fprintf fmt "("; 
                                                                                                                          alterP:=true;
                                                                                                                          generate_param fmt (List.nth l_exp 0);
                                                                                                                          if(!fromApply) then
                                                                                                                          begin
                                                                                                                           Format.fprintf fmt ")"; (* Format.fprintf fmt " '''"; *)
                                                                                                                        alterP:=false;
                                                                                                                        alterP2:=false;
                                                                                                                          end
                                                                                                                            else
                                                                                                                            begin
                                                                                                                            	if (!alterP2) then
                                                                                                                              begin
                                                                                                                                if(!pvEnd3) then
                                                                                                                              Format.fprintf fmt ")"
                                                                                                                            else Format.fprintf fmt ");\n"
                                                                                                                              end
                                                                                                                          else Format.fprintf fmt ")"
                                                                                                                            end

                                                                                                                       end
                                                                                                              end   
                                                                                          | _ ->  Format.fprintf fmt "("; generate_param fmt (List.nth l_exp 0); Format.fprintf fmt ")"; Format.fprintf fmt ")";
                                                                                     end
 
                                                  | _ ->  Format.fprintf fmt "("; generate_param fmt (List.nth l_exp 0); Format.fprintf fmt ")"; Format.fprintf fmt ")";
                                                          
                                                  
                                                                            end 
                                                        | _ ->  Format.fprintf fmt "("; generate_param fmt (List.nth l_exp 0); Format.fprintf fmt ")"; 
                                                     end
                  | _ -> begin
                          generate_param fmt (List.nth l_exp 0); Format.fprintf fmt ")"; 
                         end 
             
            end
          | _ -> begin

          (* CALL REC FUNCTIONS *)

            generate_expression fmt exp.exp_desc;
            boolApply:=true;
            pvEnd2:=true;
            generate_param fmt (List.nth l_exp 0); 
            
          end
        end 
        | _ -> Format.fprintf fmt " a_traite_en_generate_expression_Texp_apply_2  ";
        
        end  
    else begin
      fromApply:=true;
      generate_predefined_function fmt exp l_exp;
      fromApply:=false;
    end 
   
    
  | Texp_ident (path,long,typ)    -> begin
                                        match path with (*  Les fonctions de conversions *) 
                                        | Pdot (t,str,i) ->  if (List.mem str !tab_conv)  then  
                                                                begin

                                                                  if str = "int_of_char" then Format.fprintf fmt "ord" 
                                                                  else if str = "int_of_float" then Format.fprintf fmt "intval" 
                                                                  else if str = "char_of_int" then Format.fprintf fmt "chr"  
                                                                  else if str = "bool_of_string" then Format.fprintf fmt "(bool)"
                                                                  else if str = "string_of_int" then Format.fprintf fmt "strval"
                                                                  else if str = "int_of_string" then Format.fprintf fmt "intval" 
                                                                  else Format.fprintf fmt "";
                                                                end
                                                              else generate_path fmt path;
(* ERROOR *)
                                                              (*   Format.fprintf fmt "\t /////\n"; *)
                                        | _ -> generate_path fmt path
                                        
                                    end 
  
    
     
  (* ===================================   generate a constructor ================================================================= *)
  | Texp_construct (long_id,cd,exp_list) -> 
    let vv = cd.cstr_name in
    (* generate boolean *)
    if (List.mem vv ["true" ; "false"]) then Format.fprintf fmt "%s " vv else
      begin
        let p = cd.cstr_res.desc in 
        match p with
        | Tconstr (path,typ_exp_lst,abrv_mem)-> 
    let idnt = path in 
    begin
      match idnt with
      | Pident ident_t -> 
        begin
    let x = ident_t.name in

    (* in case of function without parameters *)
    if x = "unit" then 
    begin
    if (!unitFunc) then
    begin
     Format.fprintf fmt "()";
     unitFunc := false;
    end
      
  else
    Format.fprintf fmt ""  
    end
  else 
    
    (* in case of construct *)
      if x = "list" then

                                                 if cd.cstr_name = "::" && !is_concat then 
                                                                            begin
                                                                              is_concat := false;
                                                                              (* ///////////////////////////////////////////////////////////////////// *)
                                                                               if !is_fusion then begin
                                                                                 generate_expression fmt (List.nth exp_list 0).exp_desc ;
                                                                                 is_fusion := false;
                                                                               end 
                                                                               else begin
                                                                               Format.fprintf fmt " array_unshift( ";
                                                                               generate_expression fmt (List.nth exp_list 1).exp_desc;
                                                                               Format.fprintf fmt " , ";
                                                                               generate_expression fmt (List.nth exp_list 0).exp_desc;
                                                                               Format.fprintf fmt " ) "
                                                                             end 
                                                                           end
                                                    else
                                                    if !is_prem = true then begin

                                                                            is_prem := false;
                                                                            generate_construct fmt exp_list
                                                                            end 
                                                    else
                                                    if cd.cstr_name = "[]" then
                                                                            Format.fprintf fmt "" 
                                                    else  
                                                    
                                                                             begin
                                                                                Format.fprintf fmt "," ;
                                                                                generate_construct fmt exp_list
                                                                             end
                                                   
        end
      | _ -> Format.fprintf fmt "Cunstruct Path.t error";
    end
        | _ -> Format.fprintf fmt " construct_description ERROR"
      end     

(* generate for ***********************)
  | Texp_for  (id,c, st, ed, fl, body) -> 
    let fl_to_string = function
      | Upto   -> "++"
      | Downto -> "--" in
    let fl_to_symbl = function
      | Upto   -> "<="
      | Downto -> ">=" in
    Format.fprintf fmt "\tfor ("; 
    Format.fprintf fmt "$%s" id.name; 
    Format.fprintf fmt "=" ;            
    generate_expression fmt st.exp_desc;
    Format.fprintf fmt "; $%s " id.name;
    Format.fprintf fmt "%s " (fl_to_symbl fl);
    generate_expression fmt ed.exp_desc;
    
    Format.fprintf fmt "; $%s" id.name;
    Format.fprintf fmt "%s" (fl_to_string fl);
    Format.fprintf fmt ") \n \t { \n \t \t";
    generate_expression fmt body.exp_desc;
    Format.fprintf fmt "\t }\n";         
  | Texp_let (rec_flag,val_binds,exp) ->
  boolLet:=true; 
  (* Format.fprintf fmt "let ===> " ; *)
    begin 
      match rec_flag with
      | Nonrecursive -> List.iter (generate_value_binding fmt) val_binds 
      | Recursive -> 
        begin
           (* in order to update the list  *)
          l:= [];
          List.iter (generate_value_binding fmt) val_binds ;
        end (* Format.fprintf fmt "rec here \n" *)
    end;
    generate_expression fmt exp.exp_desc

  (* Format.fprintf fmt  "generate_expression--generate_let\n" *)
  | Texp_match (a,b,[],f) ->

  (* VARIABLE IN CASE OF TEXP_CONSTRUCT *)
      let exp_tpe = ref false in
  begin

          begin
            let type_exp = a.exp_type.desc in 
            match type_exp with

            | Tunivar str -> Format.fprintf fmt  "Tunivar"
            | Tvar str_op -> Format.fprintf fmt  "Tvar"
            | Ttuple typ_exprlst -> Format.fprintf fmt  "Ttuple"
            | Tconstr (path,typ_exprlst,abbrev_mem) -> Format.fprintf fmt  ""; exp_tpe:= true; 
            | _ -> 
                  begin
                  match (List.nth b 0).c_lhs.pat_desc with
                        | Tpat_construct (loc,cons_desc,patt )  ->
                                          Format.fprintf fmt  "";     

                        | Tpat_constant cnst -> Format.fprintf fmt  "\t switch (";
                                          generate_expression fmt a.exp_desc;  
                                          Format.fprintf fmt ") { \n \n " ;  

                        | _ -> Format.fprintf fmt  "\t switch (";
                                          generate_expression fmt a.exp_desc;  
                                          Format.fprintf fmt ") { \n \n " ;  

                  end
        (* MATH THE CASE WHERE ANY MATH AND a IS TYPE OF CONSTRUCT BUT ITS A VAR IDENT LOOK AT CSV.ML *)

          end;
                            let x = (List.nth b 0).c_guard in 
                            begin
                              match x with
                            | None -> Format.fprintf fmt  " ";
                            | Some a ->generate_expression fmt a.exp_desc; 
                              end;
                            for i = 0 to List.length b-1 do
                            

                            (* generate_expression fmt (List.nth b i).c_rhs.exp_desc; *)

                            match (List.nth b i).c_lhs.pat_desc with
                            | Tpat_any -> if (!exp_tpe) then 
                            begin
                                          Format.fprintf fmt "\t";
                                          generate_expression fmt (List.nth b i).c_rhs.exp_desc;
                            end
                              else
                              begin
                                          Format.fprintf fmt "\n \t default : ";
                                          generate_expression fmt (List.nth b i).c_rhs.exp_desc;
                                          Format.fprintf fmt ";";
                              end
                            | Tpat_var (a,b) -> Format.fprintf fmt "of Ident.t * string loc\n"
                                  (** x *)
                            | Tpat_alias (a,b,c) -> Format.fprintf fmt "of pattern * Ident.t * string loc\n"
                                  (** P as a *)
                            | Tpat_constant a -> Format.fprintf fmt "\n \t case  " ; 
                                                generate_constant fmt a ;
                                                Format.fprintf fmt " : \t";
                                                generate_expression fmt (List.nth b i).c_rhs.exp_desc;
                                                Format.fprintf fmt ";";
                                  (** 1, 'a', "true", 1.0, 1l, 1L, 1n *)
                            | Tpat_tuple l -> Format.fprintf fmt "of pattern list\n"
                            | Tpat_construct (loc,cons_desc,patt ) -> begin
                                                              Format.fprintf fmt "\n \t if " ;
                                                                      temp:= 0;
                                                                      data := 0; 
                                                                     (* gen_rec_pattrn fmt patt; *)
                                                              
                                                                     gen_rec_pattrn fmt patt;
                                                                     if(!data = 0 ) then 
                                                                     begin
                                                                     Format.fprintf fmt "(sizeof(";
                                                                      generate_expression fmt a.exp_desc;
                                                                     Format.fprintf fmt ") >= %d) {"  (!temp-1);
                                                                    
                                                                     end
                                                                   else 
                                                                   begin
                                                                      Format.fprintf fmt "(sizeof(";
                                                                      generate_expression fmt a.exp_desc;
                                                                     Format.fprintf fmt ") == %d) {"  (!temp);
                                                                     
                                                                     end
                                                                      end;

                                                                      Format.fprintf fmt "\n \t";
                                                                        
                                                                      generate_expression fmt (List.nth b i).c_rhs.exp_desc;
                                                                      Format.fprintf fmt "\n \t }else{";
                                                                     
                            | _-> Format.fprintf fmt "OO********";
                            
                            done;

                  if(!exp_tpe) then
                  begin
                  for i = 1 to (List.length b) -1 do
                  if (i=1) then 
                  Format.fprintf fmt  "\n \t \t }" 
                else
                if (i = (List.length b -1)) then
                Format.fprintf fmt  " } \n \n"
              else
                Format.fprintf fmt  " }";
                done;  
                  end
              else
              begin
              Format.fprintf fmt  "\n \t \t }\n "
              end
end

   | Texp_try (a,b) -> 
Format.fprintf fmt   "\n \t try{ \n ";
  generate_expression fmt a.exp_desc;
  Format.fprintf fmt   "\n \t }";
begin

  for i = 0 to (List.length b -1) do
    begin
      match (List.nth b i).c_lhs.pat_desc with
      |Tpat_any -> Format.fprintf fmt   "ANY\n";
      | Tpat_constant a -> Format.fprintf fmt   "CONSTANT\n";
      | Tpat_var (a,b) -> Format.fprintf fmt  "Tpat_varHHHHH\n";
      | Tpat_alias (a,b,c) -> Format.fprintf fmt  "Tpat_varHHHHH\n";
      | Tpat_or (a,b,c) -> Format.fprintf fmt  "Tpat_varHHHHH\n";
      | Tpat_construct (a,b0,c) -> 
            begin
             
                    if (b0.cstr_name = "Exit") then 

                                 begin
                                  Format.fprintf fmt  "\n \t \t catch(ErrorException $e){ \n \t";
                                  generate_expression fmt (List.nth b i).c_rhs.exp_desc;
                                  Format.fprintf fmt  "\n \t \t } \n";
                                 end

                    else
                    begin
                           if(b0.cstr_name = "End_of_file") then  

                           begin
                                     Format.fprintf fmt  "\n \t \t  catch(ParseError $e){ \n \t";
                                     generate_expression fmt (List.nth b i).c_rhs.exp_desc;
                                     Format.fprintf fmt  "\n \t \t } \n";
                                 
                                 
                           end

                            else
                                  begin
                                      Format.fprintf fmt  "\n \t \t catch(Exception $e){ \n \t";
                                      generate_expression fmt (List.nth b i).c_rhs.exp_desc;
                                      Format.fprintf fmt  "\n \t \t } \n";
                                  end
                     end

            end 
      | _ -> Format.fprintf fmt  "------------\n";

end
  done
    end

  (* Format.fprintf fmt   "\n \t \t \t} \n "; *)


  | Texp_variant (d,f) -> Format.fprintf fmt   "generate_expression--generate_variant"
  | Texp_field (a,b,d) -> 
                          generate_expression fmt a.exp_desc;
                          Format.fprintf fmt  "[" ;
                          Format.fprintf fmt  "'%s'"  d.lbl_name;
                          Format.fprintf fmt  "]" ;

  | Texp_setfield (a,b,d,f) -> Format.fprintf fmt  "\n ";
                              generate_expression fmt a.exp_desc;
                              Format.fprintf fmt  "['%s']"  d.lbl_name;
                              Format.fprintf fmt  "=";
                              generate_expression fmt f.exp_desc;
                              Format.fprintf fmt  "; \n";

    (* generate sequence ****)
  | Texp_sequence (e1,e2) -> 
     generate_expression fmt e1.exp_desc;
    
    
begin

       match e2.exp_desc with
       | Texp_sequence (e1,e3)  -> generate_expression fmt e2.exp_desc;

       | Texp_apply (exp,l_exp) -> if (List.length l_exp) = 1 then begin
                match exp.exp_desc with
                | Texp_ident (path,long,typ) -> begin
                  match path with
                  | Pdot (t,str,i) -> begin

                                      let mylist = ref ["ref" ;"open_in"; "open_out" ; "close_out" ;"length" ; "close_in"] in 
                                       if  (List.mem str !mylist) || (List.mem str !tab_print) then
                                       generate_expression fmt e2.exp_desc
                                     else 
                                     begin
                                       Format.fprintf fmt "\n \t return ";generate_expression fmt e2.exp_desc;Format.fprintf fmt " ; ";
                                     end
                                      end 
                  | _ ->generate_expression fmt e2.exp_desc;
                end
                | _ -> generate_expression fmt e2.exp_desc;
               
               end
         else generate_expression fmt e2.exp_desc
      
       | _ -> generate_expression fmt e2.exp_desc;
      
     end

    (* generate while *******)
  | Texp_while (a,b) -> 
    Format.fprintf fmt "\twhile (" ;
    generate_expression fmt a.exp_desc;
    Format.fprintf fmt " )" ;
    Format.fprintf fmt "\n \t {\n \t \t" ;
    generate_expression fmt b.exp_desc;
    Format.fprintf fmt "\n \t }\n"; 


  | Texp_send (a,b,d) -> Format.fprintf fmt   "generate_expression--generate_send"
  | Texp_new (a,b,d) -> Format.fprintf fmt   "generate_expression--generate_new"
  | Texp_instvar (a,b,d) -> Format.fprintf fmt   "generate_expression--generate_instvar"
  | Texp_setinstvar (a,b,d,f) -> Format.fprintf fmt   "generate_expression--generate_setinstvar"
  | Texp_letmodule (a,b,d,f) -> Format.fprintf fmt   "generate_expression--generate_letmodule"
  | Texp_assert q -> Format.fprintf fmt   "generate_expression--generate_assert"
  | Texp_lazy q -> Format.fprintf fmt   "generate_expression--generate_lazy"
  | Texp_object (a,b)  -> Format.fprintf fmt  "generate_expression--generate_object"
  | Texp_pack h -> Format.fprintf fmt   "generate_expression--generate_pack"
  | Texp_override _ -> Format.fprintf fmt   "generate_expression--generate_override"

  | Texp_record (llde,_)-> Format.fprintf fmt   "\n \t[ \n" ;
                          generate_records fmt llde;
                          Format.fprintf fmt   " \t] " ;


(* GENERATE PATTERN MATCH *)
and gen_rec_pattrn fmt patt =
match patt with
| [] ->temp:= !temp + 0;data := 1
| a :: rst -> begin
                match (List.nth rst 0).pat_desc with
                | Tpat_construct (loc,cons_desc,patt ) -> temp:= !temp + 1 ; gen_rec_pattrn fmt patt 
                | _ ->temp:= !temp + 2; data := 0 ;
              end


(* generate construct [[E;E;..];[E;E;..];[E;E;..]] *)
and generate_construct fmt tab =
   match tab with
   | []-> Format.fprintf fmt ""
   | elem::[] ->  generate_expression fmt elem.exp_desc
   | frst::rest ->  generate_expression fmt frst.exp_desc ;  generate_construct fmt rest
   | _ -> Format.fprintf fmt " Error_generate_contruct "

 (* ************************** generate Path.t ************************** *)
and generate_path fmt path =
   begin

    match path with
    | Pident ident_t ->
                            (* if the function name exits in the list *)
      if(List.mem ident_t.name !l) 
      then 
        begin
          unitFunc :=true;

          Format.fprintf fmt "\t%s" ident_t.name;
        end
      else
        begin
          (********* rename variables ************************************)
          let strVar = (string_of_int ident_t.stamp) in
          let strt = (String.length strVar)-2 in 
          let nm = String.sub (string_of_int ident_t.stamp) strt 2 in
          let varname=ident_t.name in
          if(!pvEnd && !pvEnd2 && !pvEnd3) then
          begin
            if (!boolLet && !boolApply) then
            begin
          Format.fprintf fmt "($%s)" varname;
          pvEnd3:=false; pvEnd2:=false; pvEnd:=false;
          boolLet:=false;boolApply:=false;
            end
          else
            if ((not !boolLet) && !boolApply) then 
            begin
              if (!alterP) then
              begin
              	(* if () then 
              	begin *)
                alterP2:=true;
                if(!pvEnd2 & (not !noise)) then 
          Format.fprintf fmt "($%s);\n" varname
        else
         Format.fprintf fmt "($%s)" varname;
          pvEnd3:=false; pvEnd2:=false; pvEnd:=false;
          boolLet:=false;boolApply:=false;
              	(* end
              		else
              		begin
              			
              		end *)
              end
                else
                begin
          Format.fprintf fmt "($%s);\n" varname;
          pvEnd3:=false; pvEnd2:=false; pvEnd:=false;
          boolLet:=false;boolApply:=false;
              end
            end
          end
        else
          Format.fprintf fmt "$%s" varname
        end
        (* ///////////////////////////////////////////////////////////////////// *)
    | Pdot (t,str,i) ->
    let idd= (Path.head t) in 
    let ss = idd.name in
     if (String.length str) > 1 && str.[1]='.'  then 
        Format.fprintf fmt " %c " str.[0] 
      else if (String.length str) > 1 && str.[1]='-' then
        Format.fprintf fmt " %c " str.[1]
      else if str = "ref" then Format.fprintf fmt "" else 
      if str = "not" then Format.fprintf fmt "!"   else 
      if str = "length" then 
      begin
        if ss = "String" then Format.fprintf fmt "strlen" else 
        if ss = "List" then Format.fprintf fmt "sizeof" else Format.fprintf fmt ""
      end    else 
      if str = "open_in" then Format.fprintf fmt "fopen"   else
      if str = "open_out" then Format.fprintf fmt "fopen"   else
       if str = "close_out" then Format.fprintf fmt "fclose"   else
      if str = "close_in" then Format.fprintf fmt "fclose"   else
      if str = "input_line" then Format.fprintf fmt "fgets"   else
      if str = "!" then Format.fprintf fmt ""   else Format.fprintf fmt "%s " str

    | Papply (t_1,t_2) -> Format.fprintf fmt " == Papply (regarde dans /typing/path.ml)"
    | _-> Format.fprintf fmt "error_generate_path \n"
  end

(* ===================================================================== *)
and generate_predefined_function fmt exp l_exp =
  match exp.exp_desc with
  | Texp_ident (path,long,typ) -> begin
    match path with
    | Pdot (t,str,i) ->begin
      if (List.mem str !tab_op)  then 
        begin
          Format.fprintf fmt "(";generate_param fmt (List.nth l_exp 0);
          generate_operateur fmt str;
          generate_param fmt (List.nth l_exp 1);Format.fprintf fmt ")";
        end
       
      else begin

                (*************************** traitement sur les operateur binaire  *)
                dotBool:=true;
        match str with
        | "min" -> Format.fprintf fmt " min("; generate_param fmt (List.nth l_exp 0);
          Format.fprintf fmt " , "; generate_param fmt (List.nth l_exp 1); Format.fprintf fmt " )";
        | "max" -> Format.fprintf fmt " max("; generate_param fmt (List.nth l_exp 0);
          Format.fprintf fmt " , "; generate_param fmt (List.nth l_exp 1); Format.fprintf fmt " )";
        | "&&" -> Format.fprintf fmt " ("; generate_param fmt (List.nth l_exp 0);
          Format.fprintf fmt " && "; generate_param fmt (List.nth l_exp 1); Format.fprintf fmt ")\n";
        | "&" -> Format.fprintf fmt " ("; generate_param fmt (List.nth l_exp 0);
          Format.fprintf fmt " && "; generate_param fmt (List.nth l_exp 1); Format.fprintf fmt ")\n";
        | "||" -> Format.fprintf fmt " ("; generate_param fmt (List.nth l_exp 0);
          Format.fprintf fmt " || "; generate_param fmt (List.nth l_exp 1); Format.fprintf fmt ")\n";
        | "mod" -> Format.fprintf fmt " ("; generate_param fmt (List.nth l_exp 0);Format.fprintf fmt "%c" '%';
          generate_param fmt (List.nth l_exp 1);Format.fprintf fmt ")\n";
        | "**" ->Format.fprintf fmt "pow(";generate_param fmt (List.nth l_exp 0);Format.fprintf fmt ",";
          generate_param fmt (List.nth l_exp 1); Format.fprintf fmt ")\n";
        | "^" -> Format.fprintf fmt "("; generate_param fmt (List.nth l_exp 0);Format.fprintf fmt ".";
          generate_param fmt (List.nth l_exp 1);Format.fprintf fmt ") "; 
(* ///////////////////////////////////////////////////////////////////// *)
        | ":=" ->
        begin
          let (lab,exp,op) = (List.nth l_exp 1) in
           match exp with
          | Some b ->
          begin

             match b.exp_desc with
          | Texp_construct (a,b,c)-> begin
                                         let (lab1,exp1,op1) = (List.nth l_exp 1) in
                                          match exp1 with
                                          | Some b -> begin
                                            (* ///////////////////////////////////////////////////////////////////// *)
                                                          match b.exp_desc with
                                                          | Texp_construct (long_id,cd,exp_list) -> if cd.cstr_name = "[]" then begin
                                                                                                                                  generate_param fmt (List.nth l_exp 0);Format.fprintf fmt " = array ()"
                                                                                                                                end
                                                                                                    else  generate_param fmt (List.nth l_exp 1);Format.fprintf fmt ";\n ";
                                                          | _ ->  generate_param fmt (List.nth l_exp 1);Format.fprintf fmt " ;\n ";
                                                      end
                                                                               
                                          | None ->  generate_param fmt (List.nth l_exp 1);Format.fprintf fmt "";

                                      end  
      
           
          | Texp_apply (a,b)-> 
          
                begin
                    let (lab1,exp1,op1) = (List.nth l_exp 1) in
                    match exp1 with
                    | Some b1 ->  begin
                      (* ///////////////////////////////////////////////////////////////////// *)
                                    match b1.exp_desc with
                                    | Texp_apply (exp,l_exp1) -> 
                                        begin
                                           match exp.exp_desc with
                                          | Texp_ident (path,long,typ) -> 
                                            begin
                                            match path with
                                            | Pdot (t,str,i) ->
                                                    begin
                                                      match str with
                                                      | "append" -> generate_param fmt (List.nth l_exp 1);Format.fprintf fmt " ;"
                                                                    
                                                      | _ -> Format.fprintf fmt " ( "; generate_param fmt (List.nth l_exp 0);Format.fprintf fmt " %c " '=';
                                generate_param fmt (List.nth l_exp 1);Format.fprintf fmt " );\n ";
                                                    end
                                          (*   | Pident ident_t -> Format.fprintf fmt "  " *)
                                            | _ ->  Format.fprintf fmt " ( "; generate_param fmt (List.nth l_exp 0);Format.fprintf fmt " %c " '=';
                                generate_param fmt (List.nth l_exp 1);Format.fprintf fmt " );\n ";
                                            end
                                          | _ -> Format.fprintf fmt " ( "; generate_param fmt (List.nth l_exp 0);Format.fprintf fmt " %c " '=';
                                generate_param fmt (List.nth l_exp 1);Format.fprintf fmt " );\n ";
                                           
                                         end  
                                    
                                    | _ -> Format.fprintf fmt " ( "; generate_param fmt (List.nth l_exp 0);Format.fprintf fmt " %c " '=';
                                generate_param fmt (List.nth l_exp 1);Format.fprintf fmt " );\n ";
                                end
                                                         
                    | None -> Format.fprintf fmt " ( "; generate_param fmt (List.nth l_exp 0);Format.fprintf fmt " %c " '=';
                                generate_param fmt (List.nth l_exp 1);Format.fprintf fmt " );\n ";
                end
          

          (* 
Format.fprintf fmt " ( "; generate_param fmt (List.nth l_exp 0);Format.fprintf fmt " %c " '=';
                                generate_param fmt (List.nth l_exp 1);Format.fprintf fmt " );\n ";
           *)
          | _ -> Format.fprintf fmt " ( "; generate_param fmt (List.nth l_exp 0);Format.fprintf fmt " %c " '=';
                                generate_param fmt (List.nth l_exp 1);Format.fprintf fmt " );\n ";
          end
          | None -> Format.fprintf fmt ""

        end 
        | "get" -> Format.fprintf fmt " ("; generate_param fmt (List.nth l_exp 0);Format.fprintf fmt "[";
          generate_param fmt (List.nth l_exp 1);Format.fprintf fmt "]) ";
        | "make" -> Format.fprintf fmt " ("; generate_param fmt (List.nth l_exp 1);Format.fprintf fmt ")";
        
        | "output_string" ->
                            Format.fprintf fmt "\nfputs";  Format.fprintf fmt "("; 
                            generate_param fmt (List.nth l_exp 0);
                            Format.fprintf fmt ",";
                            generate_param fmt (List.nth l_exp 1);
                            Format.fprintf fmt ");\n";

       | "nth" -> Format.fprintf fmt ""; 
                              generate_param fmt (List.nth l_exp 0);
                              Format.fprintf fmt "[";
                              generate_param fmt (List.nth l_exp 1);
                              Format.fprintf fmt "]";

         | "@" -> Format.fprintf fmt "array_merge("; generate_param fmt (List.nth l_exp 0);

                      Format.fprintf fmt ","; is_prem := true; generate_param fmt (List.nth l_exp 1); Format.fprintf fmt ")";


        | "append" ->  Format.fprintf fmt "array_unshift("; generate_param fmt (List.nth l_exp 0);
                      Format.fprintf fmt ","; is_prem := true; is_fusion := true ; generate_param fmt (List.nth l_exp 1); Format.fprintf fmt ")";
       
        | _ -> Format.fprintf fmt "\n \t \t<< %s >> \n" str;
      end  

  (* ERROOR *)
    end 
    | Pident ident_t -> begin

      let taille_l_exp = (List.length l_exp) in
      Format.fprintf fmt "%s" ident_t.name;
      
      if taille_l_exp > 1 then 
        begin
        pidentBool:=true;
          paramBool :=true;
          Format.fprintf fmt "(";
          
        for i = 0 to taille_l_exp- 1 do
        if(List.length l_exp-1 = i) then
          generate_param fmt (List.nth l_exp i)
      else
      begin
        generate_param fmt (List.nth l_exp i);
        Format.fprintf fmt "," ;
      end
        done;

        if(!fromPatVar && !pidentBool) then
        begin
          if(!dotBool) then 
          begin
        Format.fprintf fmt ");\n";
        fromPatVar:=false;
        pidentBool:=false;
        dotBool := false
          end
            else
            begin
             Format.fprintf fmt ")";
        fromPatVar:=false;
        pidentBool:=false;
        dotBool := false 
            end
        end
      else
      begin
        Format.fprintf fmt ")"
      	
      end
          
        end
      else if taille_l_exp = 1 then
      begin
        (* Format.fprintf fmt ">>>>#####"; *) 
        generate_param fmt (List.nth l_exp 0)
      end
      
      else 
      Format.fprintf fmt ")";
    end
      
    | _ -> Format.fprintf fmt " generate_Texp_apply_1 ";
  end
  | _ ->  Format.fprintf fmt " generate_Texp_apply_2 "; 
(* 
and is_unshift fmt param_op =
let result = ref false in
let (lab,exp,op) = param_op in
  match exp with
  | Some b ->  begin
    (* ///////////////////////////////////////////////////////////////////// *)
                  match b.exp_desc with
                  | Texp_apply (exp,l_exp) -> 
                      begin
                         match exp.exp_desc with
                        | Texp_ident (path,long,typ) -> 
                          begin
                          match path with
                          | Pdot (t,str,i) ->
                                  begin
                                    match str with
                                    | "append" -> result := true
                                    | _ -> result := false
                                  end
                          | Pident ident_t -> result := false
                          | _ ->  result := false
                          end
                        | _ ->  result := false 
                         
                       end  
                  
                  | _ ->  result := false
              end
                                       
  | None -> result := false;

 !result

 *)
 

(* WE WON'T INITIALIZE THE RECORD TYPE IN PHP **************************************)

(* and generate_init_record fmt lab_decl =
  for i = 0 to List.length lab_decl -1 do
  if (i= List.length lab_decl - 1) then 
  Format.fprintf fmt "\t \'%s\' => NULL \n" (List.nth lab_decl i).ld_name.txt
  else
    Format.fprintf fmt "\t \'%s\' => NULL, \n" (List.nth lab_decl i).ld_name.txt
  done *)


(* generate a List of Texp_construct ++++++++++++++++++++++++++++++++++++++++++++ *)
and construct_const fmt ex_lst=
  let l = ref ex_lst in
  match !l with
  | [] -> Format.fprintf fmt "[] "
  | hd::rst -> 
    begin
      match hd.exp_desc with
      | Texp_constant c -> 
        let x = gen_of_constant c in Format.fprintf fmt "%s" x; 
        for i = 0 to (List.length rst)-1 do
          construct_const fmt rst;  
        done
          
      | Texp_construct (a,b,c)-> construct_const fmt rst;  
        
        
      | _ -> Format.fprintf fmt "CONSTRUCT"

    end

and generate_operateur fmt str=             
  if (String.length str) > 1 && str.[1]='.'  then 
    Format.fprintf fmt " %c " str.[0] 
  else if (String.length str) > 1 && str.[1]='-' then
    Format.fprintf fmt " %c " str.[1]
  else if (String.length str) = 1 && str.[0]='='
  then Format.fprintf fmt " =%s " str
  else if str = "not" then Format.fprintf fmt "! "
  else if str = "succ" then Format.fprintf fmt "(1) + "
  else if str = "pred" then Format.fprintf fmt "--"
  else if str = "abs" then Format.fprintf fmt " abs  "
  else Format.fprintf fmt "%s" str


and generate_param fmt param_op =
  let (lab,exp,op) = param_op in
  match exp with
  | Some b -> begin
    (* ///////////////////////////////////////////////////////////////////// *)
                  match b.exp_desc with
                  | Texp_apply (exp,l_exp) -> noise:= true; generate_expression fmt b.exp_desc; is_concat := true;noise:= false;
                  | Texp_ident (path,long,typ) ->pvEnd3 :=true; generate_path fmt path;



                  | _ ->  generate_expression fmt b.exp_desc
              end
                                       
  | None -> Format.fprintf fmt ""
   
  
(* GENERATE BINDINGS *************************************************************************************************************)
(* LET X =                                                    ==> (SUSPEND THE $X)
            LET Y = E                                       ==>  $Y = <E>   
               LET Z = E IN ...                               ==>  $Z = <Z>
                              IN (TEXP_APPLY)                 ==>  [< $X = >]? <(TEXP_APPLY)> *)


    and gen_let_apply fmt exp l_exp varname= 
(***************************************************** CASE : ( E operator E ) ***************************************************)
  match exp.exp_desc with
  | Texp_ident (path,long,typ) -> begin
    match path with
    | Pdot (t,str,i) ->begin
      if (List.mem str !tab_op)  then 
        begin
(***************************************************** CASE : LET IDENT = E .. ***************************************************)
          Format.fprintf fmt "$%s = " !refVar;
          Format.fprintf fmt " (";generate_param fmt (List.nth l_exp 0);
          generate_operateur fmt str;
          generate_param fmt (List.nth l_exp 1);Format.fprintf fmt "); \n \n";
          boolMultVars:=false;
        end
       
      else begin
        Format.fprintf fmt "$%s = " varname;
        match str with
        | "min" -> Format.fprintf fmt " min( "; generate_param fmt (List.nth l_exp 0);
          Format.fprintf fmt " , "; generate_param fmt (List.nth l_exp 1); Format.fprintf fmt " );\n";
        | "max" -> Format.fprintf fmt " max( "; generate_param fmt (List.nth l_exp 0);
          Format.fprintf fmt " , "; generate_param fmt (List.nth l_exp 1); Format.fprintf fmt " );\n";
        | "&&" -> Format.fprintf fmt " ( "; generate_param fmt (List.nth l_exp 0);
          Format.fprintf fmt " && "; generate_param fmt (List.nth l_exp 1); Format.fprintf fmt ");\n";
        | "&" -> Format.fprintf fmt " ( "; generate_param fmt (List.nth l_exp 0);
          Format.fprintf fmt " && "; generate_param fmt (List.nth l_exp 1); Format.fprintf fmt ");\n";
        | "||" -> Format.fprintf fmt " ( "; generate_param fmt (List.nth l_exp 0);
          Format.fprintf fmt " || "; generate_param fmt (List.nth l_exp 1); Format.fprintf fmt ");\n";
        | "mod" -> Format.fprintf fmt " ( "; generate_param fmt (List.nth l_exp 0);Format.fprintf fmt " %c " '%';
          generate_param fmt (List.nth l_exp 1);Format.fprintf fmt ");";
        | "**" ->Format.fprintf fmt "pow(";generate_param fmt (List.nth l_exp 0);Format.fprintf fmt " , ";
          generate_param fmt (List.nth l_exp 1); Format.fprintf fmt ");";
        | "^" -> Format.fprintf fmt " ( "; generate_param fmt (List.nth l_exp 0);Format.fprintf fmt " . ";
          generate_param fmt (List.nth l_exp 1);Format.fprintf fmt ");\n \n  ";
         | ":=" ->  Format.fprintf fmt " ( "; generate_param fmt (List.nth l_exp 0);Format.fprintf fmt " %c " '=';
          generate_param fmt (List.nth l_exp 1);Format.fprintf fmt " );\n \n ";

        | "output_string" ->
                            Format.fprintf fmt "\nfputs";  Format.fprintf fmt "("; 
                            generate_param fmt (List.nth l_exp 0);
                            Format.fprintf fmt ",";
                            generate_param fmt (List.nth l_exp 1);
                            Format.fprintf fmt ");\n";

        | "nth" ->  
                              generate_param fmt (List.nth l_exp 0);
                              Format.fprintf fmt "[";
                              generate_param fmt (List.nth l_exp 1);
                              Format.fprintf fmt "]";
        | _ -> Format.fprintf fmt "\n \t \t<< %s >> \n" str;
      end    
    end 
    | Pident ident_t -> begin
      let taille_l_exp = (List.length l_exp) in
      Format.fprintf fmt "%s(" ident_t.name;
      
      if taille_l_exp > 1 then 
        begin
          for i = 0 to taille_l_exp - 2 do
            generate_param fmt (List.nth l_exp i);
            Format.fprintf fmt ",";
          done;
          generate_param fmt (List.nth l_exp (taille_l_exp - 1));
        end
      else if taille_l_exp = 1 then
        generate_param fmt (List.nth l_exp 0)
      else 
      Format.fprintf fmt ")";
    end
      
    | _ -> Format.fprintf fmt " generate_Texp_apply_1 ";
  end
  | _ ->  Format.fprintf fmt " generate_Texp_apply_2 "; 


(* GENERATE BINDINGS *************************************************************************************************************)
    
and generate_txpApply_of_let fmt varname exp l_exp =
if (List.length l_exp) = 1 then 
      begin
        match exp.exp_desc with
        | Texp_ident (path,long,typ) -> begin
          match path with
          | Pdot (t,str,i) -> if (List.mem str !tab_print) 
            then begin (* echo *) 
              Format.fprintf fmt "echo  ";
              Format.fprintf fmt " ( ";
              if str = "print_newline" then 
                Format.fprintf fmt "\" \\n \""
              else 
                generate_param fmt (List.nth l_exp 0);
              if str = "print_endline" then Format.fprintf fmt ".\" \\n \"" 
              else Format.fprintf fmt " ";
              
              
              Format.fprintf fmt " ); \n \n";
            end  
            else begin  (* uniry operator *)
              Format.fprintf fmt "("; 
              generate_expression fmt exp.exp_desc;
              Format.fprintf fmt "( "; 
                
                  match exp.exp_desc with
                  | Texp_ident (path,long,typ)    -> begin
                                                        match path with (*  Les fonctions de conversions *) 
                                                        | Pdot (t,str,i) -> if str = "string_of_bool" then begin
                                                                               Format.fprintf fmt "\""; generate_param fmt (List.nth l_exp 0); 
                                                                               Format.fprintf fmt "\""; 
                                                                            end 
                                                                            else generate_param fmt (List.nth l_exp 0); Format.fprintf fmt ")"; Format.fprintf fmt ")";
                                                        | _ -> generate_param fmt (List.nth l_exp 0); Format.fprintf fmt ")"; Format.fprintf fmt ")";
                                                     end
                  | _ -> begin
                          generate_param fmt (List.nth l_exp 0); Format.fprintf fmt ")"; Format.fprintf fmt ")";
                         end 
            end
          | _ -> begin 

            generate_expression fmt exp.exp_desc;
            generate_param fmt (List.nth l_exp 0);
          end
        end 
        | _ -> Format.fprintf fmt " a_traite_en_generate_expression_Texp_apply_generateApply_FOR_let";
          
          
      end
else
    begin
      gen_let_apply fmt exp l_exp varname;
    end
      
(*** GENERATE BINDINGS ******************************************************************************************************* *)
and gen_multiple_let fmt exp loc varname=
  begin                            
       match exp.exp_desc with
       |  Texp_let (rec_flag,val_binds,exp) -> (* ... LET Y= E IN ... *)
                                               List.iter (generate_value_binding fmt) val_binds; 
                                               (* ... IN (THE REST)...*)
                                               gen_multiple_let fmt exp loc varname;
                                               (* Format.fprintf fmt " %s\n" varname *)
       | _ ->
              begin
                    match exp.exp_desc with
                   | Texp_apply (ex,l_exp) -> generate_txpApply_of_let fmt varname ex l_exp 
                   | _ -> generate_expression fmt exp.exp_desc
              end
  end 

and generate_tab fmt exp =

     begin
      is_prem := true;
                              match exp.exp_desc with
                              | Texp_construct (long_id,cd,exp_list) -> 
                                        begin
                                          match cd.cstr_res.desc with
                                          | Tconstr (path,typ_exp_lst,abrv_mem)-> 
                                              let (idnt) = path in 
                                              begin
                                                 match idnt with
                                                 | Pident ident_t -> 
                                                    begin
                                                        if(ident_t.name="unit") then Format.fprintf fmt "(); \n"
                                                        else (* generate_expression fmt exp.exp_desc *)
                                                         begin
                                                          Format.fprintf fmt "array (";
                                                            (* gen_arr_rec fmt exp_list; *)
                                                            begin
                                                            match (List.nth exp_list 0).exp_desc with

      (* Construct of constructs ******************************************** *)
                                                            | Texp_construct (long_id,cd,ex_ls) ->
                                                                              begin
                                                                                 Format.fprintf fmt "array (";
                                                                                 generate_expression fmt (List.nth exp_list 0).exp_desc;
                                                                                 Format.fprintf fmt ")";gen_construct_rec fmt (List.nth exp_list 1)
                                                                              end

                                                            
      (* Construct of simple type ******************************************** *)
                                                            | _ -> generate_expression fmt exp.exp_desc
                                                            end; 
                                                            
                                                          (* generate_expression fmt (List.nth exp_list 0).exp_desc ;Format.fprintf fmt " );\n   " *)
                                                          Format.fprintf fmt " );\n  "
                                                         end
                                                    end
                                                  |_ -> Format.fprintf fmt " Error_generate_structure_item_0"
                                              end
                                          |_ -> Format.fprintf fmt " Error_generate_structure_item_1"
                                        end

                                | _ -> generate_expression fmt exp.exp_desc
                            end 
(* Generate Value Binding    *************************************************************************************************** *)
    
and generate_value_binding fmt value_binding =
  let {vb_pat; vb_expr; vb_attributes; vb_loc} = value_binding in

    match vb_pat.pat_desc with
  | Tpat_var (ident, loc) -> begin
                    let varname=loc.txt in
                    match vb_expr.exp_desc with
                    (* LET X = E *)
                    | Texp_construct (long_id,cd,ex_ls) -> Format.fprintf fmt "   $%s = " varname; generate_tab fmt vb_expr
                    | Texp_constant cst -> 
                    if (varname = !refVar && !boolMultVars) then
                    begin
                    refVar:=!refVar ^ "1";
                  Format.fprintf fmt "\t$%s = %a;\n" varname  generate_expression vb_expr.exp_desc  
                  end
                  else
                  begin
                    Format.fprintf fmt "\t$%s = %a;\n" varname  generate_expression vb_expr.exp_desc
                   end
                    | Texp_ident (path,long,typ) -> Format.fprintf fmt "&&&&";generate_path fmt path;  
(* ERROOR *)
                    (* Format.fprintf fmt "\t /////\n"; *)
                    | Texp_function (label,case,partial) -> 
                    begin 
                    (* add the Function name to the list *)
                          l:=loc.txt::!l;
                          Format.fprintf fmt "\n\t function %s %a\n\n"  loc.txt  generate_expression vb_expr.exp_desc ;

                    end 
                    | Texp_let (rec_flag,val_binds,exp) -> 
                        begin
                          boolMultVars:=true;
            (* LET X = LET Y = E IN ... *)
            refVar:=loc.txt; 
            let varname=loc.txt in  
            gen_multiple_let fmt vb_expr loc varname;

(* let strVar =(string_of_int ident.stamp) in
            let strt = (String.length strVar)-2 in 
            let nm = String.sub (string_of_int ident.stamp) strt 2 in
            (* LET X = LET Y = E IN ... *) 
            let varname=loc.txt^nm in  
            gen_multiple_let fmt vb_expr loc varname; *)            
                        end(* 
                  |Texp_apply (ex,lexp)-> Format.fprintf fmt "apply\n"
                  |Texp_sequence (a,b) -> Format.fprintf fmt "sequence\n" *)
            
            | Texp_apply (exp,l_exp) -> 


              if(List.length l_exp!=1) then 
              begin
                pvEnd:=true;

                fromPatVar:=true;
                  Format.fprintf fmt "\t$%s = %a;\n" varname  generate_expression vb_expr.exp_desc;
                  boolApply:=false;
                  boolLet:=false;
                  dotBool:=false;
                  pidentBool:=false;
              end
            else
              begin
                pvEnd:=true; 
                  Format.fprintf fmt "\t $%s =%a; \n" varname  generate_expression vb_expr.exp_desc;
                  boolApply:=false;
                  boolLet:=false;
              end


            | _ ->pvEnd:=true; 
                  Format.fprintf fmt "\t$%s =%a;\n" varname  generate_expression vb_expr.exp_desc;
                  boolApply:=false;
                  boolLet:=false;
                                end  
                            
  | Tpat_any -> Format.fprintf fmt "generate_value_binding_any \n"
  | Tpat_alias (a,b,c) -> Format.fprintf fmt " generate_value_binding_alias \n"
  | Tpat_constant a -> Format.fprintf fmt " generate_value_binding_canst \n"
  | Tpat_tuple a -> Format.fprintf fmt " generate_value_binding_tuple \n"
  | Tpat_construct (a,b,c) -> Format.fprintf fmt " generate_value_binding_construct \n"
  | Tpat_variant (a,b,c) -> Format.fprintf fmt " generate_value_binding_variant \n"
  | Tpat_record (a,b) -> Format.fprintf fmt "  generate_value_binding_record\n"
  | Tpat_array a -> Format.fprintf fmt " generate_value_binding_array \n"
  | Tpat_or (a,b,c) -> Format.fprintf fmt " generate_value_binding_or "
  | Tpat_lazy a -> Format.fprintf fmt " generate_value_binding_lazy \n"
      
(* Generate Structure Item   *************************************************************************************************** *)

 and gen_construct_rec fmt arr =
    begin
      match arr.exp_desc with

      (* Construct of constructs ******************************************** *)
      | Texp_construct (long_id,cd,ex_ls) ->
                        begin
                          if cd.cstr_name = "[]" then Format.fprintf fmt "" else 
                          begin
                            (* ///////////////////////////////////////////////////////////////////// *)
                            is_prem := true;
                            Format.fprintf fmt " , ";
                            Format.fprintf fmt "array (";
                            generate_expression fmt (List.nth ex_ls 0).exp_desc;
                            Format.fprintf fmt ")";gen_construct_rec fmt (List.nth ex_ls 1)
                          end
                           
                        end

      | _ -> Format.fprintf fmt ""
      end;  

and generate_structure_item fmt item =

  let { str_desc; _ } = item in
  match str_desc with
  | Tstr_value (rec_flag, val_binds) -> begin 
                                           match rec_flag with
                                           | Nonrecursive -> List.iter (generate_value_binding fmt) val_binds; 
                                           | Recursive -> 
                                           begin
                                            (* in order to update the list  *)
                                           
                                           List.iter (generate_value_binding fmt) val_binds ;
                                           end (* Format.fprintf fmt "rec here \n" *)
                                        end 

  | Tstr_eval (exp,att) ->  generate_tab fmt exp 
  | Tstr_primitive a -> Format.fprintf fmt " generate_structure_item_primitiv  \n"
  
  | Tstr_type decl -> begin (* list of type_declaration *)

               (* seek for a type of this declaration type *)
                            match (List.nth decl 0).typ_kind with
                              | Ttype_abstract -> Format.fprintf fmt " Ttype_abstract \n"
                              | Ttype_variant constr_decl -> Format.fprintf fmt " Ttype_variant \n"
                              | Ttype_record lab_decl ->  Format.fprintf fmt "" ; (*** EMPTY ***)
                              | Ttype_open -> Format.fprintf fmt " Ttype_open \n"
                        
                      end
                      
  | Tstr_typext a -> Format.fprintf fmt " generate_structure_item_typex  \n"
  | Tstr_exception a -> Format.fprintf fmt " generate_structure_item_exeption  \n"
  | Tstr_module a -> Format.fprintf fmt " generate_structure_item_module  \n"
  | Tstr_recmodule a-> Format.fprintf fmt " generate_structure_item_recmodule  \n"
  | Tstr_modtype a -> Format.fprintf fmt " generate_structure_item_modtype  \n"
  | Tstr_open a-> Format.fprintf fmt "\n" (***** IGNORE THIS CASE IN PHP *****)
  | Tstr_class a -> Format.fprintf fmt " generate_structure_item_class  \n"
  | Tstr_class_type e -> Format.fprintf fmt " generate_structure_item_class_type  \n"
  | Tstr_include a -> Format.fprintf fmt " generate_structure_item_include  \n"
  | Tstr_attribute a -> Format.fprintf fmt " generate_structure_item_attribut  \n" 
      
(* Generate From Structure  *************************************************************************************************** *)
     
let generate_from_structure fmt structure =
  let {str_items; str_type; str_final_env} = structure in

  l:= [];
  (* Php header *)
  Format.fprintf fmt "<?php\n\n";
  
  List.iter (generate_structure_item fmt) str_items;

  (* Flushing the output *)
  Format.fprintf fmt "\n?>\n%!";
  ()
