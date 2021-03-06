open preamble astTheory;

val _ = new_theory "modLang";

val _ = set_grammar_ancestry ["ast"];

(* The first intermediate language modLang. Removes modules, and introduces
 * special variable references for referring to top-level bindings.  Also
 * removes andalso and orelse and replaces them with if.
 *
 * The AST of modLang differs from the source language by having two variable
 * reference forms, one to reference local bindings (still by name) and one to
 * reference global bindings (by index). At the top level, modules are gone.
 * However a Prompt is introduced to group declarations whose bindings should
 * all be installed by the REPL only if none of them encounters an exception
 * (one of the functions that modules perform in the source language).
 * Top-level lets and letrecs no longer bind names (or have patterns), and the
 * lets come with just a number indicating how many bindings to install in the
 * global environment.
 *)

(* Copied from the semantics, but with AallocEmpty missing *)
val _ = Datatype `
 op =
  (* Operations on integers *)
    Opn opn
  | Opb opb
  (* Operations on words *)
  | Opw word_size opw
  | Shift word_size shift num
  | Equality
  (* Function application *)
  | Opapp
  (* Reference operations *)
  | Opassign
  | Opref
  | Opderef
  (* Word8Array operations *)
  | Aw8alloc
  | Aw8sub
  | Aw8length
  | Aw8update
  (* Word/integer conversions *)
  | WordFromInt word_size
  | WordToInt word_size
  (* Char operations *)
  | Ord
  | Chr
  | Chopb opb
  (* String operations *)
  | Implode
  | Strsub
  | Strlen
  (* Vector operations *)
  | VfromList
  | Vsub
  | Vlength
  (* Array operations *)
  | Aalloc
  | Asub
  | Alength
  | Aupdate
  (* Call a given foreign function *)
  | FFI string`;

val _ = Datatype`
 exp =
    Raise exp
  | Handle exp ((pat # exp) list)
  | Lit lit
  | Con (((modN,conN) id) option) (exp list)
  | Var_local varN
  | Var_global num
  | Fun varN exp
  | App op (exp list)
  | If exp exp exp
  | Mat exp ((pat # exp) list)
  | Let (varN option) exp exp
  | Letrec ((varN # varN # exp) list) exp`;

val exp_size_def = definition"exp_size_def";

val exp6_size_APPEND = Q.store_thm("exp6_size_APPEND[simp]",
  `modLang$exp6_size (e ++ e2) = exp6_size e + exp6_size e2`,
  Induct_on`e`>>simp[exp_size_def])

val exp6_size_REVERSE = Q.store_thm("exp6_size_REVERSE[simp]",
  `modLang$exp6_size (REVERSE es) = exp6_size es`,
  Induct_on`es`>>simp[exp_size_def])


val _ = Datatype`
 dec =
    (* The num is how many top-level variables this declaration binds *)
    Dlet num exp
  | Dletrec ((varN # varN # exp) list)
  | Dtype (modN list) type_def
  | Dexn (modN list) conN (t list)`;


(* A prompt is a list of declarations that must execute `atomically'; it
 * corresponds to a module body in the source language. If any of the
 * declarations results in an exception reaching the prompt's top level, none
 * of the declaration binding are installed. *)
val _ = Datatype`
 prompt =
    Prompt (modN option) (dec list)`;

val _ = export_theory ();
