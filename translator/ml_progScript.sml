open preamble
open astTheory libTheory semanticPrimitivesTheory evaluateTheory;
open evaluatePropsTheory semanticPrimitivesPropsTheory;
open namespacePropsTheory;
open mlstringTheory integerTheory;
open terminationTheory;

val _ = new_theory "ml_prog";


(* --- declarations --- *)

val Decls_def = Define `
  Decls mn env s1 ds env2 s2 =
    ?res_env.
      evaluate_decs mn s1 env ds = (s2,Rval res_env) /\
      env2 = extend_dec_env res_env env`;

val write_def = Define `
  write name v (env : v sem_env) = env with v := nsBind name v env.v`;

val write_rec_def = Define `
  write_rec funs env2 =
    env2 with v := build_rec_env funs env2 env2.v`;

val write_tds_def = Define `
  write_tds mn tds env =
    env with c := nsAppend (build_tdefs mn tds) env.c`;

val write_exn_def = Define `
  write_exn mn n l env =
    env with c := nsBind n (LENGTH l,TypeExn (mk_id mn n)) env.c`;

val Decls_Dtype = store_thm("Decls_Dtype",
  ``!mn env s tds env2 s2.
      Decls mn env s [Dtype tds] env2 s2 <=>
      check_dup_ctors tds /\
      DISJOINT (type_defs_to_new_tdecs mn tds) s.defined_types /\
      ALL_DISTINCT (MAP (\(tvs,tn,ctors). tn) tds) /\
      s2 = s with defined_types := type_defs_to_new_tdecs mn tds UNION s.defined_types /\
      (env2 = write_tds mn tds env)``,
  rw [Decls_def, evaluate_decs_def]
  \\ rw[write_tds_def,sem_env_component_equality, extend_dec_env_def]
  \\ METIS_TAC[]);

val Decls_Dexn = store_thm("Decls_Dexn",
  ``!mn env s n l env2 s2.
      Decls mn env s [Dexn n l] env2 s2 <=>
      TypeExn (mk_id mn n) NOTIN s.defined_types /\
      s2 = s with defined_types := {TypeExn (mk_id mn n)} UNION s.defined_types /\
      env2 = write_exn mn n l env``,
  rw [Decls_def, evaluate_decs_def]
  \\ fs[PULL_EXISTS,write_exn_def,write_tds_def,sem_env_component_equality]
  \\ fs [AC CONJ_COMM CONJ_ASSOC,APPEND, extend_dec_env_def]
  >> metis_tac []);

val Decls_Dtabbrev = store_thm("Decls_Dtabbrev",
  ``!mn env s n l env2 s2.
      Decls mn env s [Dtabbrev x y z] env2 s2 <=> s2 = s /\ env2 = env``,
  rw [Decls_def, evaluate_decs_def]
  \\ rw [sem_env_component_equality] \\ eq_tac \\ fs [extend_dec_env_def]);

val Decls_Dlet = store_thm("Decls_Dlet",
  ``!mn env s1 v e s2 env2.
      Decls mn env s1 [Dlet (Pvar v) e] env2 s2 <=>
      ?x. evaluate s1 env [e] = (s2,Rval [x]) /\
          (env2 = write v x env)``,
  rw [Decls_def, evaluate_decs_def]
  \\ FULL_SIMP_TAC (srw_ss()) [pat_bindings_def,ALL_DISTINCT,MEM, pmatch_def]
  \\ FULL_SIMP_TAC std_ss [PULL_EXISTS] \\ REPEAT STRIP_TAC
  \\ simp[sem_env_component_equality]
  \\ FULL_SIMP_TAC std_ss [write_def,APPEND,
       finite_mapTheory.FUNION_FEMPTY_1,finite_mapTheory.FUNION_FEMPTY_2]
  \\ simp[]
  >> eq_tac
  >> rw []
  >> rw [extend_dec_env_def]
  >> full_case_tac
  >> fs []
  >> full_case_tac
  >> fs []
  >> rw []
  >> drule evaluate_sing
  >> rw []);

val FOLDR_LEMMA = prove(
  ``!xs ys. nsAppend (FOLDR (\(x1,x2,x3) x4. nsBind x1 (f x1 x2 x3) x4) nsEmpty xs) ys =
            FOLDR (\(x1,x2,x3) x4. nsBind x1 (f x1 x2 x3) x4) ys xs``,
  Induct \\ FULL_SIMP_TAC (srw_ss()) [FORALL_PROD]);

val Decls_Dletrec = store_thm("Decls_Dletrec",
  ``!mn env s1 funs s2 env2.
      Decls mn env s1 [Dletrec funs] env2 s2 <=>
      (s2 = s1) /\
      ALL_DISTINCT (MAP (\(x,y,z). x) funs) /\
      (env2 = write_rec funs env)``,
  rw [Decls_def, evaluate_decs_def]
  \\ FULL_SIMP_TAC std_ss [write_def,
       APPEND,write_rec_def,APPEND, extend_dec_env_def,
       build_rec_env_def]
  \\ fs [sem_env_component_equality, FOLDR_LEMMA]
  \\ METIS_TAC []);

val Decls_NIL = store_thm("Decls_NIL",
  ``!s1 s3 mn env1 ds1 ds2 env3.
      Decls mn env1 s1 [] env3 s3 <=> (env3 = env1) /\ (s3 = s1)``,
  rw [Decls_def, evaluate_decs_def, extend_dec_env_def]
  \\ METIS_TAC [sem_env_component_equality]);

val Decls_CONS = store_thm("Decls_CONS",
  ``!s1 s3 mn env1 ds1 ds2 env3.
      Decls mn env1 s1 (d::ds2) env3 s3 =
      ?env2 s2.
         Decls mn env1 s1 [d] env2 s2 /\
         Decls mn env2 s2 ds2 env3 s3``,
  rw [Decls_def, Once evaluate_decs_cons, extend_dec_env_def]
  >> split_pair_case_tac
  >> simp []
  >> rename1 `evaluate_decs _ _ _ _ = (s', r)`
  >> Cases_on `r`
  >> simp []
  >> split_pair_case_tac
  >> simp []
  >> rename1 `evaluate_decs _ _ _ _ = (s'', r)`
  >> rw[EQ_IMP_THM]
  >- (
    rw [extend_dec_env_def]
    >> Cases_on `r`
    >> fs [combine_dec_result_def, extend_dec_env_def]
    >> rw [])
  >- (
    Cases_on `a`
    >> simp [combine_dec_result_def]
    >> rw []
    >> fs []
    >> fs []
    >> rfs [extend_dec_env_def]
    >> `env2 = <| m := env2.m; c := env2.c; v := env2.v |>`
      by rw [sem_env_component_equality]
    >> fs []
    >> metis_tac [PAIR_EQ, result_11, result_distinct]));

val Decls_APPEND = store_thm("Decls_APPEND",
  ``!s1 s3 mn env1 ds1 ds2 env3.
      Decls mn env1 s1 (ds1 ++ ds2) env3 s3 =
      ?env2 s2.
         Decls mn env1 s1 ds1 env2 s2 /\
         Decls mn env2 s2 ds2 env3 s3``,
  Induct_on `ds1` \\ FULL_SIMP_TAC std_ss [APPEND,Decls_NIL]
  \\ ONCE_REWRITE_TAC [Decls_CONS]
  \\ FULL_SIMP_TAC std_ss [PULL_EXISTS,AC CONJ_COMM CONJ_ASSOC]
  \\ METIS_TAC []);

val Decls_SNOC = store_thm("Decls_SNOC",
  ``!s1 s3 mn env1 ds1 d env3.
     Decls mn env1 s1 (SNOC d ds1) env3 s3 =
     ?env2 s2.
       Decls mn env1 s1 ds1 env2 s2 /\
       Decls mn env2 s2 [d] env3 s3``,
  METIS_TAC [SNOC_APPEND, Decls_APPEND]);


(* --- programs --- *)

val Prog_def = Define `
  Prog env1 s1 prog env2 s2 <=>
    ?new_env.
      (evaluate_tops s1 env1 prog =
         (s2,Rval new_env)) /\
      (env2 = extend_dec_env new_env env1)`;

val Prog_NIL = store_thm("Prog_NIL",
  ``!s1 s3 env1 ds1 ds2 env3.
      Prog env1 s1 [] env3 s3 <=> (env3 = env1) /\ (s3 = s1)``,
  rw [Prog_def, evaluate_tops_def, extend_dec_env_def, sem_env_component_equality]
  >> eq_tac >> rw []
  >- metis_tac [nsAppend_nsEmpty]
  >- metis_tac [nsAppend_nsEmpty]
  >> qexists_tac `<| v := nsEmpty; c := nsEmpty |>`
  >> rw []);

val Prog_CONS = store_thm("Prog_CONS",
  ``!s1 s3 env1 d ds2 env3.
      Prog env1 s1 (d::ds2) env3 s3 =
      ?env2 s2.
        Prog env1 s1 [d] env2 s2 /\
        Prog env2 s2 ds2 env3 s3``,
  fs [Prog_def]
  >> rw [Once evaluate_tops_cons, PULL_EXISTS]
  >> eq_tac
  >> rw []
  >- (
    split_pair_case_tac
    >> fs []
    >> rename1 `evaluate_tops s1 env1 [d] = (s',r)`
    >> Cases_on `r`
    >> fs []
    >> rename1 `evaluate_tops s1 env1 [d] = (s',Rval v)`
    >> fs []
    >> split_pair_case_tac
    >> fs [combine_dec_result_def]
    >> Cases_on `r`
    >> fs []
    >> rw [extend_dec_env_def])
  >- (
    split_pair_case_tac
    >> fs [extend_dec_env_def, combine_dec_result_def]));

val Prog_APPEND = store_thm("Prog_APPEND",
  ``!s1 s3 env1 ds1 ds2 env3.
      Prog env1 s1 (ds1 ++ ds2) env3 s3 =
      ?env2 s2.
         Prog env1 s1 ds1 env2 s2 /\
         Prog env2 s2 ds2 env3 s3``,
  Induct_on `ds1` \\ fs [Prog_NIL]
  \\ once_rewrite_tac [Prog_CONS] \\ fs [] \\ metis_tac []);

val Prog_Tdec = store_thm("Prog_Tdec",
  ``Prog env1 s1 [Tdec d] env2 s2 <=>
    Decls [] env1 s1 [d] env2 s2``,
  fs [Prog_def, Decls_def, evaluate_tops_def]
  >> every_case_tac
  >> rw [extend_dec_env_def, sem_env_component_equality]
  >> metis_tac []);

val mod_env_update_def = Define `
  mod_env_update mn (e1,e2) (b1,b2) =
    ((mn,BUTLASTN (LENGTH e2) b2)::e1,e2)`;

val Prog_Tmod = store_thm("Prog_Tmod",
  ``Prog env1 s1 [Tmod mn specs ds] env2 s2 <=>
    mn ∉ s1.defined_mods /\ no_dup_types ds /\
    ?s env.
      Decls [mn] env1 s1 ds env s /\
      s2 = s with defined_mods := {[mn]} ∪ s.defined_mods /\
      env2 = env1 with <| m := (mn,BUTLASTN (LENGTH env1.v) env.v)::env1.m ;
                          c := mod_env_update mn env1.c env.c |>``,
  fs [Prog_def,Decls_def,evaluate_tops_def,PULL_EXISTS, combine_mod_result_def]
  >> every_case_tac
  >> fs [sem_env_component_equality, extend_top_env_def, mod_env_update_def]
  >> eq_tac
  >> rw []
  >> fs [BUTLASTN_LENGTH_APPEND, mod_env_update_def]
  >> Cases_on `env1.c`
  >> fs [merge_alist_mod_env_def, mod_env_update_def, BUTLASTN_LENGTH_APPEND]
  >> qexists_tac `<| m := env1.m; c := (q'',q' ++ r); v := a ++ env1.v |>`
  >> simp [mod_env_update_def, BUTLASTN_LENGTH_APPEND]);

(* The translator and CF tools use the following definition of ML_code
   to build verified ML programs. *)

val ML_code_def = Define `
  (ML_code env1 s1 prog NONE env2 s2 <=>
     Prog env1 s1 prog env2 s2) /\
  (ML_code env1 s1 prog (SOME (mn,ds,env)) env2 s2 <=>
     ?s.
       mn ∉ s.defined_mods /\ no_dup_types ds /\
       Prog env1 s1 prog env s /\
       Decls mn env s ds env2 s2)`

(* an empty program *)

local
  val init_env_tm =
    ``SND (THE (prim_sem_env (ARB:unit ffi_state)))``
    |> SIMP_CONV std_ss [primSemEnvTheory.prim_sem_env_eq]
    |> concl |> rand
  val init_state_tm =
    ``FST(THE (prim_sem_env (ffi:'ffi ffi_state)))``
    |> SIMP_CONV std_ss [primSemEnvTheory.prim_sem_env_eq]
    |> concl |> rand
in
  val init_env_def = Define `
    init_env = ^init_env_tm`;
  val init_state_def = Define `
    init_state ffi = ^init_state_tm`;
end

val ML_code_NIL = store_thm("ML_code_NIL",
  ``ML_code init_env (init_state ffi) [] NONE init_env (init_state ffi)``,
  fs [ML_code_def,Prog_NIL]);

(* opening and closing of modules *)

val ML_code_new_module = store_thm("ML_code_new_module",
  ``ML_code env1 s1 prog NONE env2 s2 ==>
    !mn. mn ∉ s2.defined_mods ==>
         ML_code env1 s1 prog (SOME (mn,[],env2)) env2 s2``,
  fs [ML_code_def] \\ rw [Decls_NIL] \\ EVAL_TAC);

val ML_code_close_module = store_thm("ML_code_close_module",
  ``ML_code env1 s1 prog (SOME (mn,ds,env)) env2 s2 ==>
    !sigs.
      ML_code env1 s1 (SNOC (Tmod mn sigs ds) prog) NONE
        (env with <| m := (mn,BUTLASTN (LENGTH env.v) env2.v)::env.m ;
                     c := mod_env_update mn env.c env2.c |>)
        (s2 with defined_mods := mn INSERT s2.defined_mods)``,
  fs [ML_code_def] \\ rw [] \\ fs [SNOC_APPEND,Prog_APPEND]
  \\ asm_exists_tac \\ fs [Prog_Tmod]
  \\ asm_exists_tac \\ fs []
  \\ AP_THM_TAC \\ rpt AP_TERM_TAC \\ fs [EXTENSION]);

(* appending a Dtype *)

val ML_code_NONE_Dtype = store_thm("ML_code_NONE_Dtype",
  ``ML_code env1 s1 prog NONE env2 s2 ==>
    !tds.
      check_dup_ctors tds ∧
      DISJOINT (type_defs_to_new_tdecs NONE tds) s2.defined_types ∧
      ALL_DISTINCT (MAP (λ(tvs,tn,ctors). tn) tds) ==>
      ML_code env1 s1 (SNOC (Tdec (Dtype tds)) prog) NONE
        (write_tds NONE tds env2)
        (s2 with defined_types :=
                   type_defs_to_new_tdecs NONE tds ∪ s2.defined_types)``,
  fs [ML_code_def,SNOC_APPEND,Prog_APPEND,Prog_Tdec,Decls_Dtype]
  \\ rw [] \\ asm_exists_tac \\ fs []);

val ML_code_SOME_Dtype = store_thm("ML_code_SOME_Dtype",
  ``ML_code env1 s1 prog (SOME (mn,ds,env)) env2 s2 ==>
    !tds.
      check_dup_ctors tds ∧ no_dup_types (SNOC (Dtype tds) ds) /\
      DISJOINT (type_defs_to_new_tdecs (SOME mn) tds) s2.defined_types ∧
      ALL_DISTINCT (MAP (λ(tvs,tn,ctors). tn) tds) ==>
      ML_code env1 s1 prog (SOME (mn,SNOC (Dtype tds) ds,env))
        (write_tds (SOME mn) tds env2)
        (s2 with defined_types :=
                   type_defs_to_new_tdecs (SOME mn) tds ∪ s2.defined_types)``,
  fs [ML_code_def,SNOC_APPEND,Decls_APPEND,Prog_Tdec,Decls_Dtype]
  \\ rw [] \\ asm_exists_tac \\ fs [] \\ asm_exists_tac \\ fs []);

(* appending a Dexn *)

val ML_code_NONE_Dexn = store_thm("ML_code_NONE_Dexn",
  ``ML_code env1 s1 prog NONE env2 s2 ==>
    !n l.
      TypeExn (mk_id NONE n) ∉ s2.defined_types ==>
      ML_code env1 s1 (SNOC (Tdec (Dexn n l)) prog) NONE
        (write_exn NONE n l env2)
        (s2 with defined_types := {TypeExn (mk_id NONE n)} ∪ s2.defined_types)``,
  fs [ML_code_def,SNOC_APPEND,Prog_APPEND,Prog_Tdec,Decls_Dexn]
  \\ rw [] \\ asm_exists_tac \\ fs []);

val ML_code_SOME_Dexn = store_thm("ML_code_SOME_Dexn",
  ``ML_code env1 s1 prog (SOME (mn,ds,env)) env2 s2 ==>
    !n l.
      TypeExn (mk_id (SOME mn) n) ∉ s2.defined_types ==>
      ML_code env1 s1 prog (SOME (mn,SNOC (Dexn n l) ds,env))
        (write_exn (SOME mn) n l env2)
        (s2 with defined_types :=
                   {TypeExn (mk_id (SOME mn) n)} ∪ s2.defined_types)``,
  fs [ML_code_def,SNOC_APPEND,Decls_APPEND,Prog_Tdec,Decls_Dexn]
  \\ rw [] \\ asm_exists_tac \\ fs []
  \\ fs [no_dup_types_def,  decs_to_types_def]
  \\ asm_exists_tac \\ fs []);

(* appending a Dtabbrev *)

val ML_code_NONE_Dtabbrev = store_thm("ML_code_NONE_Dtabbrev",
  ``ML_code env1 s1 prog NONE env2 s2 ==>
    !x y z.
      ML_code env1 s1 (SNOC (Tdec (Dtabbrev x y z)) prog) NONE env2 s2``,
  fs [ML_code_def,SNOC_APPEND,Prog_APPEND,Prog_Tdec,Decls_Dtabbrev]);

val ML_code_SOME_Dtabbrev = store_thm("ML_code_SOME_Dtabbrev",
  ``ML_code env1 s1 prog (SOME (mn,ds,env)) env2 s2 ==>
    !x y z.
      ML_code env1 s1 prog (SOME (mn,SNOC (Dtabbrev x y z) ds,env)) env2 s2``,
  fs [ML_code_def,SNOC_APPEND,Decls_APPEND,Prog_Tdec,Decls_Dtabbrev]
  \\ rw [] \\ asm_exists_tac \\ fs [no_dup_types_def,  decs_to_types_def]);

(* appending a Letrec *)

val ML_code_NONE_Dletrec = store_thm("ML_code_NONE_Dletrec",
  ``ML_code env1 s1 prog NONE env2 s2 ==>
    !fns.
      ALL_DISTINCT (MAP (λ(x,y,z). x) fns) ==>
      ML_code env1 s1 (SNOC (Tdec (Dletrec fns)) prog) NONE
        (write_rec fns env2) s2``,
  fs [ML_code_def,SNOC_APPEND,Prog_APPEND,Prog_Tdec,Decls_Dletrec]
  \\ rw [] \\ asm_exists_tac \\ fs []);

val ML_code_SOME_Dletrec = store_thm("ML_code_SOME_Dletrec",
  ``ML_code env1 s1 prog (SOME (mn,ds,env)) env2 s2 ==>
    !fns.
      ALL_DISTINCT (MAP (λ(x,y,z). x) fns) ==>
      ML_code env1 s1 prog (SOME (mn,SNOC (Dletrec fns) ds,env))
        (write_rec fns env2) s2``,
  fs [ML_code_def,SNOC_APPEND,Decls_APPEND,Prog_Tdec,Decls_Dletrec]
  \\ rw [] \\ asm_exists_tac \\ fs []
  \\ fs [no_dup_types_def,  decs_to_types_def]
  \\ asm_exists_tac \\ fs []);

(* appending a Let *)

val ML_code_NONE_Dlet_var = store_thm("ML_code_NONE_Dlet_var",
  ``ML_code env1 s1 prog NONE env2 s2 ==>
    !e x s3.
      evaluate s2 env2 [e] = (s3,Rval [x]) ==>
      !n.
        ML_code env1 s1 (SNOC (Tdec (Dlet (Pvar n) e)) prog)
          NONE (write n x env2) s3``,
  fs [ML_code_def,SNOC_APPEND,Prog_APPEND,Prog_Tdec,Decls_Dlet]
  \\ rw [] \\ asm_exists_tac \\ fs []
  \\ rw [] \\ asm_exists_tac \\ fs []);

val ML_code_SOME_Dlet_var = store_thm("ML_code_SOME_Dlet_var",
  ``ML_code env1 s1 prog (SOME (mn,ds,env)) env2 s2 ==>
    !e x s3.
      evaluate s2 env2 [e] = (s3,Rval [x]) ==>
      !n.
        ML_code env1 s1 prog (SOME (mn,SNOC (Dlet (Pvar n) e) ds,env))
          (write n x env2) s3``,
  fs [ML_code_def,SNOC_APPEND,Decls_APPEND,Prog_Tdec,Decls_Dlet]
  \\ rw [] \\ asm_exists_tac \\ fs []
  \\ fs [no_dup_types_def,  decs_to_types_def]
  \\ NTAC 2 (rw [] \\ asm_exists_tac \\ fs []));

val ML_code_NONE_Dlet_Fun = store_thm("ML_code_NONE_Dlet_Fun",
  ``ML_code env1 s1 prog NONE env2 s2 ==>
    !n v e.
      ML_code env1 s1 (SNOC (Tdec (Dlet (Pvar n) (Fun v e))) prog)
        NONE (write n (Closure env2 v e) env2) s2``,
  fs [ML_code_def,SNOC_APPEND,Prog_APPEND,Prog_Tdec,Decls_Dlet]
  \\ rw [] \\ asm_exists_tac \\ fs [evaluate_def]);

val ML_code_SOME_Dlet_Fun = store_thm("ML_code_SOME_Dlet_Fun",
  ``ML_code env1 s1 prog (SOME (mn,ds,env)) env2 s2 ==>
    !n v e.
      ML_code env1 s1 prog (SOME (mn,SNOC (Dlet (Pvar n) (Fun v e)) ds,env))
        (write n (Closure env2 v e) env2) s2``,
  fs [ML_code_def,SNOC_APPEND,Decls_APPEND,Prog_Tdec,Decls_Dlet]
  \\ rw [] \\ asm_exists_tac \\ fs []
  \\ fs [no_dup_types_def,  decs_to_types_def]
  \\ rw [] \\ asm_exists_tac \\ fs [evaluate_def]);

(* misc used by automation *)

val DISJOINT_set_simp = store_thm("DISJOINT_set_simp",
  ``DISJOINT (set []) s /\
    (DISJOINT (set (x::xs)) s <=> ~(x IN s) /\ DISJOINT (set xs) s)``,
  fs [DISJOINT_DEF,EXTENSION] \\ metis_tac []);

val _ = export_theory();