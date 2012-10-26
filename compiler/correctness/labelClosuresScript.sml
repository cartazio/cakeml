open HolKernel boolLib boolSimps bossLib quantHeuristicsLib pairTheory listTheory alistTheory prim_recTheory whileTheory
open relationTheory arithmeticTheory rich_listTheory finite_mapTheory pred_setTheory state_transformerTheory lcsymtacs
open SatisfySimps miscTheory intLangTheory compileTerminationTheory
val _ = new_theory"labelClosures"

(*
val label_closures_state_component_equality = DB.fetch"Compile""label_closures_state_component_equality"

val label_closures_empty = store_thm("label_closures_empty",
  ``(∀e s e' s'. (label_closures e (s with <| lcode_env := [] |>) = (e',s')) ⇒
            (label_closures e s = (e', s' with <| lcode_env := s'.lcode_env ++ s.lcode_env |>))) ∧
    (∀ds ac s ds' s'. (label_defs ac ds (s with <| lcode_env := [] |>) = (ds', s')) ⇒
            (label_defs ac ds s = (ds', s' with <| lcode_env := s'.lcode_env ++ s.lcode_env |>))) ∧
    (∀x:def. T) ∧ (∀x:(Cexp + num). T) ∧
    (∀es s es' s'. (label_closures_list es (s with <| lcode_env := [] |>) = (es',s')) ⇒
            (label_closures_list es s = (es', s' with <| lcode_env := s'.lcode_env ++ s.lcode_env |>)))``,
  ho_match_mp_tac (TypeBase.induction_of``:Cexp``) >>
  rw[label_closures_def,label_defs_def,UNIT_DEF,BIND_DEF] >>
  rw[label_closures_state_component_equality] >>
  TRY (full_split_pairs_tac P >> fs[] >> rfs[] >> rw[] >> res_tac >> fs[] >> NO_TAC) >>
  TRY (Cases_on `x` >> Cases_on `r` >> fs[label_defs_def,BIND_DEF,UNIT_DEF])
  fs[UNCURRY] >>
  full_split_pairs_tac P >>
  fs[] >> rw[] >> rfs[] >> rw[] >>
  res_tac >> fs[] >> rw[]

  >> res_tac >> fs[] >> NO_TAC) >>
*)

fun full_split_pairs_tac P (g as (asl,w)) = let
  fun Q tm = P tm
             andalso can(pairSyntax.dest_prod o type_of)tm
             andalso (not (pairSyntax.is_pair tm))
  val tms = List.foldl (fn(t,s)=>(union s (find_terms Q t))) (mk_set(find_terms Q w)) asl
  in MAP_EVERY (STRIP_ASSUME_TAC o Lib.C ISPEC pair_CASES) tms end g

fun P tm = mem (fst (strip_comb tm)) [``label_closures``,rator ``mapM label_closures``]

(* labels in an expression (but not recursively) *)
val free_labs_def0 = tDefine "free_labs"`
  (free_labs (CDecl xs) = {}) ∧
  (free_labs (CRaise er) = {}) ∧
  (free_labs (CVar x) = {}) ∧
  (free_labs (CLit li) = {}) ∧
  (free_labs (CCon cn es) = (BIGUNION (IMAGE (free_labs) (set es)))) ∧
  (free_labs (CTagEq e n) = (free_labs e)) ∧
  (free_labs (CProj e n) = (free_labs e)) ∧
  (free_labs (CLet xs es e) = BIGUNION (IMAGE (free_labs) (set (e::es)))) ∧
  (free_labs (CLetfun b ns defs e) = (IMAGE (OUTR o SND) (set (FILTER (ISR o SND) defs)))∪(free_labs e)) ∧
  (free_labs (CFun xs (INL _)) = {}) ∧
  (free_labs (CFun xs (INR l)) = {l}) ∧
  (free_labs (CCall e es) = BIGUNION (IMAGE (free_labs) (set (e::es)))) ∧
  (free_labs (CPrim2 op e1 e2) = (free_labs e1)∪(free_labs e2)) ∧
  (free_labs (CIf e1 e2 e3) = (free_labs e1)∪(free_labs e2)∪(free_labs e3))`(
  WF_REL_TAC `measure Cexp_size` >>
  srw_tac[ARITH_ss][Cexp4_size_thm] >>
  Q.ISPEC_THEN `Cexp_size` imp_res_tac SUM_MAP_MEM_bound >>
  fsrw_tac[ARITH_ss][])
val _ = overload_on("free_labs_defs",``λdefs. IMAGE (OUTR o SND) (set (FILTER (ISR o SND) defs))``)
val _ = overload_on("free_labs_list",``λes. BIGUNION (IMAGE free_labs (set es))``)
val free_labs_def = save_thm("free_labs_def",SIMP_RULE(std_ss++ETA_ss)[]free_labs_def0)
val _ = export_rewrites["free_labs_def"]

(* bodies in an expression (but not recursively) *)
val free_bods_def = tDefine "free_bods"`
  (free_bods (CDecl xs) = []) ∧
  (free_bods (CRaise er) = []) ∧
  (free_bods (CVar x) = []) ∧
  (free_bods (CLit li) = []) ∧
  (free_bods (CCon cn es) = (FLAT (MAP (free_bods) es))) ∧
  (free_bods (CTagEq e n) = (free_bods e)) ∧
  (free_bods (CProj e n) = (free_bods e)) ∧
  (free_bods (CLet xs es e) = FLAT (MAP free_bods es) ++ free_bods e) ∧
  (free_bods (CLetfun b ns defs e) = (MAP (OUTL o SND) (FILTER (ISL o SND) defs))++(free_bods e)) ∧
  (free_bods (CFun xs (INL cb)) = [cb]) ∧
  (free_bods (CFun xs (INR _)) = []) ∧
  (free_bods (CCall e es) = FLAT (MAP (free_bods) (e::es))) ∧
  (free_bods (CPrim2 op e1 e2) = (free_bods e1)++(free_bods e2)) ∧
  (free_bods (CIf e1 e2 e3) = (free_bods e1)++(free_bods e2)++(free_bods e3))`(
  WF_REL_TAC `measure Cexp_size` >>
  srw_tac[ARITH_ss][Cexp4_size_thm] >>
  Q.ISPEC_THEN `Cexp_size` imp_res_tac SUM_MAP_MEM_bound >>
  fsrw_tac[ARITH_ss][])
val _ = export_rewrites["free_bods_def"]

(* replace labels by bodies from code env (but not recursively) *)
val subst_lab_cb_def = Define`
  (subst_lab_cb c (INL b) = INL b) ∧
  (subst_lab_cb c (INR l) = case FLOOKUP c l of SOME b => INL b
                                              | NONE   => INR l)`

val subst_labs_def = tDefine "subst_labs"`
  (subst_labs c (CDecl xs) = CDecl xs) ∧
  (subst_labs c (CRaise er) = CRaise er) ∧
  (subst_labs c (CVar x) = (CVar x)) ∧
  (subst_labs c (CLit li) = (CLit li)) ∧
  (subst_labs c (CCon cn es) = CCon cn (MAP (subst_labs c) es)) ∧
  (subst_labs c (CTagEq e n) = CTagEq (subst_labs c e) n) ∧
  (subst_labs c (CProj e n) = CProj (subst_labs c e) n) ∧
  (subst_labs c (CLet xs es e) = CLet xs (MAP (subst_labs c) es) (subst_labs c e)) ∧
  (subst_labs c (CLetfun b ns defs e) = CLetfun b ns (MAP (λ(xs,cb). (xs,subst_lab_cb c cb)) defs) (subst_labs c e)) ∧
  (subst_labs c (CFun xs cb) = CFun xs (subst_lab_cb c cb)) ∧
  (subst_labs c (CCall e es) = CCall (subst_labs c e) (MAP (subst_labs c) es)) ∧
  (subst_labs c (CPrim2 op e1 e2) = CPrim2 op (subst_labs c e1) (subst_labs c e2)) ∧
  (subst_labs c (CIf e1 e2 e3) = CIf (subst_labs c e1)(subst_labs c e2)(subst_labs c e3))`(
  WF_REL_TAC `measure (Cexp_size o SND)` >>
  srw_tac[ARITH_ss][Cexp4_size_thm] >>
  Q.ISPEC_THEN `Cexp_size` imp_res_tac SUM_MAP_MEM_bound >>
  fsrw_tac[ARITH_ss][])
val _ = export_rewrites["subst_lab_cb_def","subst_labs_def"]

val subst_labs_ind = theorem"subst_labs_ind"

(* TODO: move?
         use for Cevaluate_any_env?*)
val DRESTRICT_FUNION_SUBSET = store_thm("DRESTRICT_FUNION_SUBSET",
  ``s2 ⊆ s1 ⇒ ∃h. (DRESTRICT f s1 ⊌ g = DRESTRICT f s2 ⊌ h)``,
  strip_tac >>
  qexists_tac `DRESTRICT f s1 ⊌ g` >>
  match_mp_tac EQ_SYM >>
  REWRITE_TAC[GSYM SUBMAP_FUNION_ABSORPTION] >>
  rw[SUBMAP_DEF,DRESTRICT_DEF,FUNION_DEF] >>
  fs[SUBSET_DEF])

val DRESTRICT_SUBSET_SUBMAP_gen = store_thm("DRESTRICT_SUBSET_SUBMAP_gen",
  ``!f1 f2 s t. DRESTRICT f1 s ⊑ DRESTRICT f2 s ∧ t ⊆ s
    ==> DRESTRICT f1 t ⊑ DRESTRICT f2 t``,
  rw[SUBMAP_DEF,DRESTRICT_DEF,SUBSET_DEF])

val SUBSET_DIFF_EMPTY = store_thm("SUBSET_DIFF_EMPTY",
  ``!s t. (s DIFF t = {}) = (s SUBSET t)``,
  SRW_TAC[][EXTENSION,SUBSET_DEF] THEN PROVE_TAC[])

val DIFF_INTER_SUBSET = store_thm("DIFF_INTER_SUBSET",
  ``!r s t. r SUBSET s ==> (r DIFF s INTER t = r DIFF t)``,
  SRW_TAC[][EXTENSION,SUBSET_DEF] THEN PROVE_TAC[])

val UNION_DIFF_2 = store_thm("UNION_DIFF_2",
  ``!s t. (s UNION (s DIFF t) = s)``,
  SRW_TAC[][EXTENSION] THEN PROVE_TAC[])

val DRESTRICT_FUNION_SAME = store_thm("DRESTRICT_FUNION_SAME",
  ``!fm s. FUNION (DRESTRICT fm s) fm = fm``,
  SRW_TAC[][GSYM SUBMAP_FUNION_ABSORPTION])

val subst_labs_any_env = store_thm("subst_labs_any_env",
  ``∀c e c'. (DRESTRICT c (free_labs e) = DRESTRICT c' (free_labs e)) ⇒
             (subst_labs c e = subst_labs c' e)``,
  ho_match_mp_tac subst_labs_ind >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- (
    srw_tac[ETA_ss][MAP_EQ_f] >>
    first_x_assum (match_mp_tac o MP_CANON) >> rw[] >>
    match_mp_tac DRESTRICT_SUBSET >>
    qmatch_assum_abbrev_tac`DRESTRICT c s0 = DRESTRICT c' s0` >>
    qexists_tac `s0` >> rw[] >>
    unabbrev_all_tac >>
    srw_tac[DNF_ss][SUBSET_DEF,MEM_FLAT,MEM_MAP] >>
    metis_tac[] ) >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- (
    srw_tac[ETA_ss][MAP_EQ_f] >>
    first_x_assum (match_mp_tac o MP_CANON) >> rw[] >>
    match_mp_tac DRESTRICT_SUBSET >>
    qmatch_assum_abbrev_tac`DRESTRICT c s0 = DRESTRICT c' s0` >>
    qexists_tac `s0` >> rw[] >>
    unabbrev_all_tac >>
    srw_tac[DNF_ss][SUBSET_DEF,MEM_FLAT,MEM_MAP] >>
    metis_tac[] ) >>
  strip_tac >- (
    srw_tac[ETA_ss][MAP_EQ_f] >>
    TRY (
      PairCases_on `e'` >> fs[] >>
      Cases_on `e'1` >> rw[] >>
      qmatch_assum_abbrev_tac`DRESTRICT c s = DRESTRICT c' s` >>
      `FDOM c INTER s = FDOM c' INTER s` by (
        fs[GSYM fmap_EQ_THM,FDOM_DRESTRICT] ) >>
      fsrw_tac[DNF_ss,QUANT_INST_ss[std_qp]][Abbr`s`,EXTENSION,MEM_MAP,MEM_FILTER,FLOOKUP_DEF,DRESTRICT_DEF,FUNION_DEF] >>
      rw[] >> (TRY (metis_tac[])) >>
      fsrw_tac[QUANT_INST_ss[std_qp]][GSYM fmap_EQ_THM,MEM_MAP,MEM_FILTER,DRESTRICT_DEF,FUNION_DEF] ) >>
    first_x_assum (match_mp_tac o MP_CANON) >> rw[] >>
    match_mp_tac DRESTRICT_SUBSET >>
    qmatch_assum_abbrev_tac`DRESTRICT c s0 = DRESTRICT c' s0` >>
    qexists_tac `s0` >> rw[] >>
    unabbrev_all_tac >>
    srw_tac[DNF_ss][SUBSET_DEF,MEM_FLAT,MEM_MAP] ) >>
  strip_tac >- (
    Cases_on `cb` >> rw[FLOOKUP_DEF,DRESTRICT_DEF,FUNION_DEF,GSYM fmap_EQ_THM] >>
    rw[EXTENSION] >> metis_tac[] ) >>
  strip_tac >- (
    srw_tac[ETA_ss][MAP_EQ_f] >>
    first_x_assum (match_mp_tac o MP_CANON) >> rw[] >>
    match_mp_tac DRESTRICT_SUBSET >>
    qmatch_assum_abbrev_tac`DRESTRICT c s0 = DRESTRICT c' s0` >>
    qexists_tac `s0` >> rw[] >>
    unabbrev_all_tac >>
    srw_tac[DNF_ss][SUBSET_DEF,MEM_FLAT,MEM_MAP] >>
    metis_tac[] ) >>
  strip_tac >- (
    srw_tac[ETA_ss][MAP_EQ_f] >>
    first_x_assum (match_mp_tac o MP_CANON) >> rw[] >>
    match_mp_tac DRESTRICT_SUBSET >>
    qmatch_assum_abbrev_tac`DRESTRICT c s0 = DRESTRICT c' s0` >>
    qexists_tac `s0` >> rw[] >>
    unabbrev_all_tac >>
    srw_tac[DNF_ss][SUBSET_DEF,MEM_FLAT,MEM_MAP] >>
    metis_tac[] ) >>
  strip_tac >- (
    srw_tac[ETA_ss][MAP_EQ_f] >>
    first_x_assum (match_mp_tac o MP_CANON) >> rw[] >>
    match_mp_tac DRESTRICT_SUBSET >>
    qmatch_assum_abbrev_tac`DRESTRICT c s0 = DRESTRICT c' s0` >>
    qexists_tac `s0` >> rw[] >>
    unabbrev_all_tac >>
    srw_tac[DNF_ss][SUBSET_DEF,MEM_FLAT,MEM_MAP] >>
    metis_tac[] ))

val subst_lab_cb_any_env = store_thm("subst_lab_cb_any_env",
  ``(ISR cb ⇒ (DRESTRICT c {OUTR cb} = DRESTRICT c' {OUTR cb})) ⇒
    (subst_lab_cb c cb = subst_lab_cb c' cb)``,
  Cases_on `cb` >>
  rw[FLOOKUP_DEF,DRESTRICT_DEF,GSYM fmap_EQ_THM,EXTENSION] >>
  metis_tac[])

(* TODO: move *)
val REVERSE_ZIP = store_thm("REVERSE_ZIP",
  ``!l1 l2. (LENGTH l1 = LENGTH l2) ==>
    (REVERSE (ZIP (l1,l2)) = ZIP (REVERSE l1, REVERSE l2))``,
  Induct THEN SRW_TAC[][LENGTH_NIL_SYM] THEN
  Cases_on `l2` THEN FULL_SIMP_TAC(srw_ss())[] THEN
  SRW_TAC[][GSYM ZIP_APPEND])

val LENGTH_o_REVERSE = store_thm("LENGTH_o_REVERSE",
  ``(LENGTH o REVERSE = LENGTH) /\
    (LENGTH o REVERSE o f = LENGTH o f)``,
  SRW_TAC[][FUN_EQ_THM])

val REVERSE_o_REVERSE = store_thm("REVERSE_o_REVERSE",
  ``(REVERSE o REVERSE o f = f)``,
  SRW_TAC[][FUN_EQ_THM])

val GENLIST_PLUS_APPEND = store_thm("GENLIST_PLUS_APPEND",
  ``GENLIST ($+ a) n1 ++ GENLIST ($+ (n1 + a)) n2 = GENLIST ($+ a) (n1 + n2)``,
  rw[Once ADD_SYM,SimpRHS] >>
  srw_tac[ARITH_ss][GENLIST_APPEND] >>
  srw_tac[ETA_ss][ADD_ASSOC])

val count_add = store_thm("count_add",
  ``!n m. count (n + m) = count n UNION IMAGE ($+ n) (count m)``,
  SRW_TAC[ARITH_ss][EXTENSION,EQ_IMP_THM] THEN
  Cases_on `x < n` THEN SRW_TAC[ARITH_ss][] THEN
  Q.EXISTS_TAC `x - n` THEN
  SRW_TAC[ARITH_ss][])

val plus_compose = store_thm("plus_compose",
  ``!n:num m. $+ n o $+ m = $+ (n + m)``,
  SRW_TAC[ARITH_ss][FUN_EQ_THM])

val LIST_TO_SET_GENLIST = store_thm("LIST_TO_SET_GENLIST",
  ``!f n. LIST_TO_SET (GENLIST f n) = IMAGE f (count n)``,
  SRW_TAC[][EXTENSION,MEM_GENLIST] THEN PROVE_TAC[])

val DRESTRICT_EQ_DRESTRICT_SAME = store_thm("DRESTRICT_EQ_DRESTRICT_SAME",
  ``(DRESTRICT f1 s = DRESTRICT f2 s) =
    (s INTER FDOM f1 = s INTER FDOM f2) /\
    (!x. x IN FDOM f1 /\ x IN s ==> (f1 ' x = f2 ' x))``,
  SRW_TAC[][DRESTRICT_EQ_DRESTRICT,SUBMAP_DEF,DRESTRICT_DEF,EXTENSION] THEN
  PROVE_TAC[])

val MEM_ZIP_MEM_MAP = store_thm("MEM_ZIP_MEM_MAP",
  ``(LENGTH (FST ps) = LENGTH (SND ps)) /\ MEM p (ZIP ps)
    ==> MEM (FST p) (FST ps) /\ MEM (SND p) (SND ps)``,
  Cases_on `p` >> Cases_on `ps` >> SRW_TAC[][] >>
  REV_FULL_SIMP_TAC(srw_ss())[MEM_ZIP,MEM_EL] THEN
  PROVE_TAC[])

val subst_labs_SUBMAP = store_thm("subst_labs_SUBMAP",
  ``(free_labs e) ⊆ FDOM c ∧ c ⊑ c' ⇒ (subst_labs c e = subst_labs c' e)``,
  rw[] >>
  match_mp_tac subst_labs_any_env >>
  rw[DRESTRICT_EQ_DRESTRICT] >- (
    match_mp_tac DRESTRICT_SUBMAP_gen >>
    first_assum ACCEPT_TAC )
  >- (
    fs[SUBMAP_DEF,DRESTRICT_DEF,SUBSET_DEF] ) >>
  fs[EXTENSION,SUBSET_DEF,SUBMAP_DEF] >>
  metis_tac[])

val _ = overload_on("free_bods_defs",``λdefs. MAP (OUTL o SND) (FILTER (ISL o SND) defs)``)

val DISJOINT_GENLIST_PLUS = store_thm("DISJOINT_GENLIST_PLUS",
  ``DISJOINT x (set (GENLIST ($+ n) (a + b))) ==>
    DISJOINT x (set (GENLIST ($+ n) a)) /\
    DISJOINT x (set (GENLIST ($+ (n + a)) b))``,
  rw[GSYM GENLIST_PLUS_APPEND] >>
  metis_tac[DISJOINT_SYM,ADD_SYM])

val label_closures_thm = store_thm("label_closures_thm",
  ``(∀e s e' s'. (label_closures e s = (e',s')) ⇒
       let c = REVERSE (ZIP (GENLIST ($+ s.lnext_label) (LENGTH (free_bods e)), free_bods e)) in
       (s'.lcode_env = c ++ s.lcode_env) ∧
       (s'.lnext_label = s.lnext_label + LENGTH (free_bods e)) ∧
       (free_labs e' = set (MAP FST c) ∪ free_labs e) ∧
       (DISJOINT (free_labs e) (set (MAP FST c))
         ⇒ (subst_labs (alist_to_fmap c) e' = e))) ∧
    (∀ds ac s ac' s'. (label_defs ac ds s = (ac',s')) ⇒
       let c = REVERSE (
         ZIP (GENLIST ($+ s.lnext_label) (LENGTH (FILTER (ISL o SND) ds)),
              free_bods_defs ds)) in
       (s'.lcode_env = c ++ s.lcode_env) ∧
       (s'.lnext_label = s.lnext_label + LENGTH (FILTER (ISL o SND) ds)) ∧
       ∃ds'. (ac' = ds'++ac) ∧
       (free_labs_defs ds' = set (MAP FST c) ∪ free_labs_defs ds) ∧
       (DISJOINT (free_labs_defs ds) (set (MAP FST c)) ⇒
        (MAP (λ(xs,cb). (xs,subst_lab_cb (alist_to_fmap c) cb)) (REVERSE ds') = ds))) ∧
    (∀(d:def). T) ∧ (∀(b:Cexp+num). T) ∧
    (∀es s es' s'. (label_closures_list es s = (es',s')) ⇒
       let c = REVERSE (
           ZIP (GENLIST ($+ s.lnext_label) (LENGTH (FLAT (MAP free_bods es))),
                FLAT (MAP free_bods es))) in
       (s'.lcode_env = c ++ s.lcode_env) ∧
       (s'.lnext_label = s.lnext_label + LENGTH (FLAT (MAP free_bods es))) ∧
       (free_labs_list es' =  set (MAP FST c) ∪ free_labs_list es) ∧
       (DISJOINT (free_labs_list es) (set (MAP FST c))
         ⇒ (MAP (subst_labs (alist_to_fmap c)) es' = es)))``,
  ho_match_mp_tac(TypeBase.induction_of(``:Cexp``)) >>
  strip_tac >- (rw[label_closures_def,UNIT_DEF,BIND_DEF] >> rw[]) >>
  strip_tac >- (rw[label_closures_def,UNIT_DEF,BIND_DEF] >> rw[]) >>
  strip_tac >- (rw[label_closures_def,UNIT_DEF,BIND_DEF] >> rw[]) >>
  strip_tac >- (rw[label_closures_def,UNIT_DEF,BIND_DEF] >> rw[]) >>
  strip_tac >- (
    fs[label_closures_def,UNIT_DEF,BIND_DEF] >>
    rpt gen_tac >> strip_tac >> rpt gen_tac >> strip_tac >>
    qabbrev_tac`p = mapM label_closures es s` >> PairCases_on `p` >> fs[] >>
    rpt BasicProvers.VAR_EQ_TAC >>
    first_x_assum (qspecl_then [`s`,`p0`,`p1`] mp_tac) >>
    srw_tac[ETA_ss][REVERSE_ZIP,LET_THM]) >>
  strip_tac >- (
    fs[label_closures_def,UNIT_DEF,BIND_DEF] >>
    rpt gen_tac >> strip_tac >> rpt gen_tac >> strip_tac >>
    qabbrev_tac`p = label_closures e s` >> PairCases_on `p` >> fs[] >>
    rpt BasicProvers.VAR_EQ_TAC >>
    first_x_assum (qspecl_then [`s`,`p0`,`p1`] mp_tac) >> rw[]) >>
  strip_tac >- (
    fs[label_closures_def,UNIT_DEF,BIND_DEF] >>
    rpt gen_tac >> strip_tac >> rpt gen_tac >> strip_tac >>
    qabbrev_tac`p = label_closures e s` >> PairCases_on `p` >> fs[] >>
    rpt BasicProvers.VAR_EQ_TAC >>
    first_x_assum (qspecl_then [`s`,`p0`,`p1`] mp_tac) >> rw[]) >>
  strip_tac >- (
    fs[label_closures_def,UNIT_DEF,BIND_DEF] >>
    rpt gen_tac >> strip_tac >> rpt gen_tac >> strip_tac >>
    qabbrev_tac`p = mapM label_closures es s` >> PairCases_on `p` >> fs[] >>
    qabbrev_tac`q = label_closures e p1` >> PairCases_on `q` >> fs[] >>
    rpt BasicProvers.VAR_EQ_TAC >>
    first_x_assum (qspecl_then [`p1`,`q0`,`q1`] mp_tac) >>
    first_x_assum (qspecl_then [`s`,`p0`,`p1`] mp_tac) >>
    srw_tac[ARITH_ss,ETA_ss,DNF_ss][REVERSE_ZIP,ZIP_APPEND,LET_THM] >>
    TRY (
      AP_TERM_TAC  >> rw[] >>
      simp_tac(std_ss)[GSYM REVERSE_APPEND] >>
      AP_TERM_TAC >> rw[] >>
      rw[GENLIST_PLUS_APPEND] >>
      NO_TAC ) >>
    TRY (
      simp[MAP_ZIP,GSYM GENLIST_PLUS_APPEND] >>
      qmatch_abbrev_tac `A = B UNION C` >>
      metis_tac[ADD_SYM,UNION_ASSOC,UNION_COMM] ) >>
    fs[MAP_ZIP] >>
    qabbrev_tac`les = free_labs_list es` >>
    qabbrev_tac`bes = FLAT (MAP free_bods es)` >>
    qabbrev_tac`le = (free_labs e)` >>
    qabbrev_tac`be = (free_bods e)` >>
    TRY (
      qmatch_abbrev_tac `subst_labs c1 q0 = e` >>
      qmatch_assum_abbrev_tac `P ==> (subst_labs c2 q0 = e)` >>
      `P` by (
        unabbrev_all_tac >>
        qmatch_abbrev_tac `DISJOINT X Y` >>
        qpat_assum `DISJOINT X Z` mp_tac >>
        simp[MAP_ZIP,Abbr`Y`,GSYM GENLIST_PLUS_APPEND] >>
        rw[DISJOINT_SYM] ) >>
      qunabbrev_tac`P` >>
      qsuff_tac `subst_labs c1 q0 = subst_labs c2 q0` >- PROVE_TAC[] >>
      match_mp_tac subst_labs_any_env >>
      match_mp_tac EQ_SYM >>
      REWRITE_TAC[DRESTRICT_EQ_DRESTRICT_SAME] >>
      `FDOM c2 = IMAGE ($+ (s.lnext_label + LENGTH bes)) (count (LENGTH be))` by (
        unabbrev_all_tac >>
        srw_tac[ARITH_ss][MAP_ZIP,LIST_TO_SET_GENLIST] ) >>
      `free_labs q0 = FDOM c2 ∪ le` by (
        srw_tac[ARITH_ss][LIST_TO_SET_GENLIST] ) >>
      `FDOM c1 = FDOM c2 ∪ IMAGE ($+ s.lnext_label) (count (LENGTH bes))` by (
        unabbrev_all_tac >>
        srw_tac[ARITH_ss][MAP_ZIP,LIST_TO_SET_GENLIST,count_add,GSYM IMAGE_COMPOSE,plus_compose,UNION_COMM]) >>
      `DISJOINT le (FDOM c2)` by (
        fsrw_tac[ARITH_ss][LIST_TO_SET_GENLIST] ) >>
      `DISJOINT le (IMAGE ($+ s.lnext_label) (count (LENGTH bes)))` by (
        fs[LIST_TO_SET_GENLIST,count_add] >> PROVE_TAC[DISJOINT_SYM] ) >>
      conj_tac >- (
        rw[INTER_UNION,GSYM INTER_OVER_UNION] >>
        fs[DISJOINT_DEF] ) >>
      rw[Abbr`c1`,Abbr`c2`] >>
      rw[GSYM GENLIST_PLUS_APPEND] >>
      rw[GSYM REVERSE_ZIP] >>
      rw[GSYM ZIP_APPEND] >>
      rw[REVERSE_APPEND] >>
      rw[FUNION_DEF,MAP_ZIP,REVERSE_ZIP,MEM_GENLIST] >>
      fsrw_tac[ARITH_ss][] ) >>
    TRY (
      qmatch_abbrev_tac `MAP (subst_labs c1) p0 = es` >>
      qmatch_assum_abbrev_tac `P ==> (MAP (subst_labs c2) p0 = es)` >>
      `P` by metis_tac[DISJOINT_GENLIST_PLUS] >>
      qunabbrev_tac`P` >>
      qsuff_tac `MAP (subst_labs c1) p0 = MAP (subst_labs c2) p0` >- PROVE_TAC[] >>
      simp[MAP_EQ_f] >> qx_gen_tac `ee` >> strip_tac >>
      match_mp_tac subst_labs_any_env >>
      match_mp_tac EQ_SYM >>
      REWRITE_TAC[DRESTRICT_EQ_DRESTRICT_SAME] >>
      `FDOM c2 = IMAGE ($+ s.lnext_label) (count (LENGTH bes))` by (
        unabbrev_all_tac >>
        srw_tac[ARITH_ss][MAP_ZIP,LIST_TO_SET_GENLIST] ) >>
      `free_labs_list p0 = FDOM c2 ∪ les` by (
        rw[LIST_TO_SET_GENLIST] ) >>
      `free_labs ee ⊆ FDOM c2 ∪ les` by (
        match_mp_tac SUBSET_TRANS >>
        qexists_tac `free_labs_list p0` >>
        conj_tac >- (
          simp[SUBSET_DEF,MEM_FLAT,MEM_MAP] >>
          PROVE_TAC[] ) >>
        rw[] ) >>
      `FDOM c1 = FDOM c2 ∪ IMAGE ($+ (s.lnext_label + LENGTH bes)) (count (LENGTH be))` by (
        rw[Abbr`c1`] >>
        rw[MAP_ZIP,GSYM REVERSE_APPEND,LIST_TO_SET_GENLIST,count_add,GSYM IMAGE_COMPOSE,plus_compose]) >>
      `DISJOINT les (IMAGE ($+ (s.lnext_label + LENGTH bes)) (count (LENGTH be)))` by (
        fs[LIST_TO_SET_GENLIST,count_add,GSYM IMAGE_COMPOSE,plus_compose,Abbr`les`] >>
        PROVE_TAC[DISJOINT_SYM] ) >>
      conj_tac >- (
        rw[] >>
        match_mp_tac EQ_SYM >>
        qmatch_abbrev_tac `a INTER (b UNION c) = a INTER b` >>
        simp[UNION_OVER_INTER] >>
        simp[Once UNION_COMM] >>
        simp[GSYM SUBSET_UNION_ABSORPTION] >>
        fs[SUBSET_DEF,IN_DISJOINT] >>
        PROVE_TAC[] ) >>
      rw[Abbr`c1`,Abbr`c2`] >>
      rw[GSYM GENLIST_PLUS_APPEND] >>
      rw[REVERSE_APPEND] >>
      rw[GSYM ZIP_APPEND] >>
      rw[FUNION_DEF,MAP_ZIP,REVERSE_ZIP,MEM_GENLIST] >>
      fsrw_tac[ARITH_ss][] )) >>
  strip_tac >- (
    fs[label_closures_def,UNIT_DEF,BIND_DEF] >>
    rpt gen_tac >> strip_tac >> rpt gen_tac >> strip_tac >>
    qabbrev_tac`p = label_defs [] ds s` >> PairCases_on `p` >> fs[] >>
    qabbrev_tac`q = label_closures e p1` >> PairCases_on `q` >> fs[] >>
    rpt BasicProvers.VAR_EQ_TAC >>
    first_x_assum (qspecl_then [`p1`,`q0`,`q1`] mp_tac) >>
    first_x_assum (qspecl_then [`[]`,`s`,`p0`,`p1`] mp_tac) >>
    srw_tac[ARITH_ss][REVERSE_ZIP,ZIP_APPEND,LET_THM] >>
    TRY (
      AP_TERM_TAC  >> rw[] >>
      simp_tac(std_ss)[GSYM REVERSE_APPEND] >>
      AP_TERM_TAC >> rw[] >>
      srw_tac[ARITH_ss][GENLIST_PLUS_APPEND] ) >>
    TRY (
      rw[MAP_REVERSE,FILTER_REVERSE,MAP_ZIP,REVERSE_APPEND] >>
      rw[GSYM GENLIST_PLUS_APPEND] >>
      qmatch_abbrev_tac `(a UNION d) UNION (b UNION c) = h UNION (d UNION c)` >>
      qsuff_tac `a UNION b = h` >- ( rw[EXTENSION] >> PROVE_TAC[] ) >>
      unabbrev_all_tac >>
      REWRITE_TAC[UNION_APPEND] >>
      REWRITE_TAC[GENLIST_PLUS_APPEND] >>
      srw_tac[ARITH_ss][] ) >>
    fs[MAP_ZIP] >>
    qabbrev_tac`le = free_labs e` >>
    qabbrev_tac`be = free_bods e` >>
    qabbrev_tac`lfd = LENGTH (FILTER (ISL o SND) ds)` >>
    TRY (
      qmatch_abbrev_tac `subst_labs c1 q0 = e` >>
      qmatch_assum_abbrev_tac `P ==> (subst_labs c2 q0 = e)` >>
      `P` by (
        unabbrev_all_tac >>
        qmatch_abbrev_tac `DISJOINT X Y` >>
        qpat_assum `DISJOINT X Z` mp_tac >>
        simp[MAP_ZIP,Abbr`Y`,LIST_TO_SET_GENLIST] >>
        CONV_TAC(LAND_CONV(REWRITE_CONV[Once ADD_SYM])) >>
        simp[count_add,GSYM IMAGE_COMPOSE,plus_compose] >>
        rw[DISJOINT_SYM]) >>
      qunabbrev_tac`P` >>
      qsuff_tac `subst_labs c1 q0 = subst_labs c2 q0` >- PROVE_TAC[] >>
      match_mp_tac subst_labs_any_env >>
      match_mp_tac EQ_SYM >>
      REWRITE_TAC[DRESTRICT_EQ_DRESTRICT_SAME] >>
      `FDOM c2 = IMAGE ($+ (s.lnext_label + lfd)) (count (LENGTH be))` by (
        unabbrev_all_tac >>
        srw_tac[ARITH_ss][MAP_ZIP,LIST_TO_SET_GENLIST] ) >>
      `(free_labs q0) = FDOM c2 ∪ le` by (
        srw_tac[ARITH_ss][LIST_TO_SET_GENLIST,MAP_ZIP] ) >>
      `FDOM c1 = FDOM c2 ∪ IMAGE ($+ s.lnext_label) (count lfd)` by (
        unabbrev_all_tac >>
        srw_tac[ARITH_ss][MAP_ZIP,LIST_TO_SET_GENLIST] >>
        CONV_TAC(LAND_CONV(REWRITE_CONV[Once ADD_SYM])) >>
        srw_tac[ARITH_ss][count_add,GSYM IMAGE_COMPOSE,plus_compose,UNION_COMM]) >>
      `DISJOINT le (FDOM c2)` by (
        fsrw_tac[ARITH_ss][LIST_TO_SET_GENLIST,MAP_ZIP] ) >>
      `DISJOINT le (IMAGE ($+ s.lnext_label) (count lfd))` by (
        fsrw_tac[ARITH_ss][LIST_TO_SET_GENLIST,count_add,MAP_ZIP] >>
        PROVE_TAC[DISJOINT_SYM] ) >>
      conj_tac >- (
        rw[INTER_UNION,GSYM INTER_OVER_UNION] >>
        fs[DISJOINT_DEF] ) >>
      rw[Abbr`c1`,Abbr`c2`] >>
      rw[Q.SPEC`LENGTH be`ADD_SYM] >>
      rw[GSYM GENLIST_PLUS_APPEND] >>
      rw[REVERSE_APPEND] >>
      rw[GSYM ZIP_APPEND] >>
      rw[FUNION_DEF] ) >>
    TRY (
      qmatch_abbrev_tac `MAP A pp = ds` >>
      qmatch_assum_abbrev_tac `P ==> (MAP B pp = ds)` >>
      `P` by (
        qunabbrev_tac`P` >>
        fsrw_tac[ARITH_ss][MAP_ZIP] >>
        qmatch_abbrev_tac `DISJOINT X Y` >>
        qpat_assum `DISJOINT X Z` mp_tac >>
        rw[GSYM GENLIST_PLUS_APPEND,Abbr`Y`,DISJOINT_SYM] ) >>
      qunabbrev_tac`P` >>
      qsuff_tac `MAP A pp = MAP B pp` >- PROVE_TAC[] >>
      simp[MAP_EQ_f] >>
      qx_gen_tac `d` >>
      PairCases_on `d` >>
      rw[Abbr`A`,Abbr`B`] >>
      rw[Q.SPEC`LENGTH be`ADD_SYM] >>
      rw[GSYM GENLIST_PLUS_APPEND] >>
      rw[REVERSE_APPEND] >>
      rw[GSYM ZIP_APPEND] >>
      match_mp_tac subst_lab_cb_any_env >>
      Cases_on `d1` >> simp[] >>
      qmatch_abbrev_tac`DRESTRICT (f1 ⊌ f2) {y} = DRESTRICT f2 {y}` >>
      qsuff_tac `y ∉ FDOM f1` >- (
        rw[DRESTRICT_EQ_DRESTRICT_SAME,EXTENSION,FUNION_DEF] >>
        PROVE_TAC[] ) >>
      `y ∈ (free_labs_defs p0)` by (
        simp[MEM_MAP,MEM_FILTER] >>
        srw_tac[QUANT_INST_ss[std_qp]][] >>
        fs[Abbr`pp`] >> PROVE_TAC[] ) >>
      pop_assum mp_tac >> ASM_REWRITE_TAC[] >>
      REWRITE_TAC[IN_UNION] >>
      strip_tac >- (
        fsrw_tac[ARITH_ss][MEM_GENLIST,Abbr`f1`,MAP_ZIP] ) >>
      qpat_assum `DISJOINT ((free_labs_defs ds)) (set (MAP FST Y))` mp_tac >>
      REWRITE_TAC[IN_DISJOINT] >>
      REWRITE_TAC[Q.SPEC`LENGTH be`ADD_SYM] >>
      fs[MAP_ZIP,Abbr`f1`,GSYM GENLIST_PLUS_APPEND] >>
      PROVE_TAC[] )
    ) >>
  strip_tac >- (
    rw[label_closures_def,UNIT_DEF,BIND_DEF] >>
    Cases_on `b` >> fs[label_defs_def,UNIT_DEF,BIND_DEF,LET_THM] >>
    unabbrev_all_tac >>
    rw[] ) >>
  strip_tac >- (
    fs[label_closures_def,UNIT_DEF,BIND_DEF] >>
    rpt gen_tac >> strip_tac >> rpt gen_tac >> strip_tac >>
    qabbrev_tac`p = label_closures e s` >> PairCases_on `p` >> fs[] >>
    qabbrev_tac`q = mapM label_closures es p1` >> PairCases_on `q` >> fs[] >>
    rpt BasicProvers.VAR_EQ_TAC >>
    first_x_assum (qspecl_then [`p1`,`q0`,`q1`] mp_tac) >>
    first_x_assum (qspecl_then [`s`,`p0`,`p1`] mp_tac) >>
    srw_tac[DNF_ss,ARITH_ss,ETA_ss][REVERSE_ZIP,ZIP_APPEND,LET_THM] >>
    TRY (
      AP_TERM_TAC  >> rw[] >>
      simp_tac(std_ss)[GSYM REVERSE_APPEND] >>
      AP_TERM_TAC >> rw[] >>
      srw_tac[ARITH_ss][GENLIST_PLUS_APPEND] ) >>
    TRY (
      CONV_TAC(RAND_CONV(REWRITE_CONV[Once ADD_SYM])) >>
      simp[MAP_ZIP,GSYM GENLIST_PLUS_APPEND] >>
      qmatch_abbrev_tac`A = B UNION C` >>
      metis_tac[ADD_SYM,UNION_ASSOC,UNION_COMM] ) >>
    fs[MAP_ZIP] >>
    qabbrev_tac`les = free_labs_list es` >>
    qabbrev_tac`bes = FLAT (MAP free_bods es)` >>
    qabbrev_tac`le = free_labs e` >>
    qabbrev_tac`be = (free_bods e)` >>
    TRY (
      qmatch_abbrev_tac `subst_labs c1 p0 = e` >>
      qmatch_assum_abbrev_tac `P ==> (subst_labs c2 p0 = e)` >>
      `P` by (
        unabbrev_all_tac >>
        qmatch_abbrev_tac `DISJOINT X Y` >>
        qpat_assum `DISJOINT X Z` mp_tac >>
        CONV_TAC(LAND_CONV(REWRITE_CONV[Once ADD_SYM])) >>
        simp[MAP_ZIP,Abbr`Y`,GSYM GENLIST_PLUS_APPEND] >>
        rw[DISJOINT_SYM] ) >>
      qunabbrev_tac`P` >>
      qsuff_tac `subst_labs c1 p0 = subst_labs c2 p0` >- PROVE_TAC[] >>
      match_mp_tac subst_labs_any_env >>
      match_mp_tac EQ_SYM >>
      REWRITE_TAC[DRESTRICT_EQ_DRESTRICT_SAME] >>
      `FDOM c2 = IMAGE ($+ s.lnext_label) (count (LENGTH be))` by (
        unabbrev_all_tac >>
        srw_tac[ARITH_ss][MAP_ZIP,LIST_TO_SET_GENLIST] ) >>
      `(free_labs p0) = FDOM c2 ∪ le` by (
        srw_tac[ARITH_ss][LIST_TO_SET_GENLIST] ) >>
      `FDOM c1 = FDOM c2 ∪ IMAGE ($+ (s.lnext_label + LENGTH be)) (count (LENGTH bes))` by (
        unabbrev_all_tac >>
        srw_tac[ARITH_ss][MAP_ZIP] >>
        CONV_TAC(LAND_CONV(REWRITE_CONV[Once ADD_SYM])) >>
        srw_tac[ARITH_ss][LIST_TO_SET_GENLIST,count_add,GSYM IMAGE_COMPOSE,plus_compose] ) >>
      `DISJOINT le (FDOM c2)` by (
        fsrw_tac[ARITH_ss][LIST_TO_SET_GENLIST] ) >>
      `DISJOINT le (IMAGE ($+ (s.lnext_label + LENGTH be)) (count (LENGTH bes)))` by (
        fsrw_tac[ARITH_ss][MAP_ZIP,LIST_TO_SET_GENLIST,count_add,GSYM IMAGE_COMPOSE,plus_compose] >>
        PROVE_TAC[DISJOINT_SYM] ) >>
      conj_tac >- (
        rw[INTER_UNION,GSYM INTER_OVER_UNION] >>
        fs[DISJOINT_DEF] ) >>
      simp_tac(srw_ss()++DNF_ss)[Abbr`c1`,Abbr`c2`,MAP_ZIP,MEM_GENLIST] >>
      gen_tac >> strip_tac >>
      CONV_TAC(RAND_CONV(REWRITE_CONV[Once ADD_SYM])) >>
      rw[GSYM GENLIST_PLUS_APPEND] >>
      rw[REVERSE_APPEND] >>
      rw[GSYM ZIP_APPEND] >>
      rw[FUNION_DEF,MAP_ZIP,MEM_GENLIST] >>
      fsrw_tac[ARITH_ss][] ) >>
    TRY (
      qmatch_abbrev_tac `MAP (subst_labs c1) q0 = es` >>
      qmatch_assum_abbrev_tac `P ==> (MAP (subst_labs c2) q0 = es)` >>
      `P` by (
        unabbrev_all_tac >>
        fsrw_tac[ARITH_ss][MAP_ZIP] >>
        metis_tac[DISJOINT_GENLIST_PLUS,DISJOINT_SYM,ADD_SYM] ) >>
      qunabbrev_tac`P` >>
      qsuff_tac `MAP (subst_labs c1) q0 = MAP (subst_labs c2) q0` >- PROVE_TAC[] >>
      simp[MAP_EQ_f] >> qx_gen_tac `ee` >> strip_tac >>
      match_mp_tac subst_labs_any_env >>
      match_mp_tac EQ_SYM >>
      REWRITE_TAC[DRESTRICT_EQ_DRESTRICT_SAME] >>
      `FDOM c2 = IMAGE ($+ (s.lnext_label + LENGTH be)) (count (LENGTH bes))` by (
        unabbrev_all_tac >>
        srw_tac[ARITH_ss][MAP_ZIP,LIST_TO_SET_GENLIST] ) >>
      `free_labs_list q0 = FDOM c2 ∪ les` by (
        srw_tac[ARITH_ss][LIST_TO_SET_GENLIST] ) >>
      `free_labs ee ⊆ FDOM c2 ∪ les` by (
        match_mp_tac SUBSET_TRANS >>
        qexists_tac `free_labs_list q0` >>
        conj_tac >- (
          simp[SUBSET_DEF,MEM_FLAT,MEM_MAP] >>
          PROVE_TAC[] ) >>
        rw[] ) >>
      `FDOM c1 = FDOM c2 ∪ IMAGE ($+ s.lnext_label) (count (LENGTH be))` by (
        rw[Abbr`c1`] >>
        rw[MAP_ZIP] >>
        CONV_TAC(LAND_CONV(REWRITE_CONV[Once ADD_SYM])) >>
        rw[LIST_TO_SET_GENLIST,count_add,GSYM IMAGE_COMPOSE,plus_compose,UNION_COMM] ) >>
      `DISJOINT les (IMAGE ($+ s.lnext_label) (count (LENGTH be)))` by (
        fsrw_tac[ARITH_ss][MAP_ZIP,LIST_TO_SET_GENLIST,count_add,GSYM IMAGE_COMPOSE,plus_compose,Abbr`les`] >>
        PROVE_TAC[DISJOINT_SYM] ) >>
      conj_tac >- (
        rw[] >>
        match_mp_tac EQ_SYM >>
        qmatch_abbrev_tac `a INTER (b UNION c) = a INTER b` >>
        simp[UNION_OVER_INTER] >>
        simp[Once UNION_COMM] >>
        simp[GSYM SUBSET_UNION_ABSORPTION] >>
        fs[SUBSET_DEF,IN_DISJOINT] >>
        PROVE_TAC[] ) >>
      rw[Abbr`c1`,Abbr`c2`] >>
      CONV_TAC(RAND_CONV(REWRITE_CONV[Once ADD_SYM])) >>
      rw[GSYM GENLIST_PLUS_APPEND] >>
      rw[REVERSE_APPEND] >>
      rw[GSYM ZIP_APPEND] >>
      rw[FUNION_DEF,MAP_ZIP,REVERSE_ZIP,MEM_GENLIST] )) >>
  strip_tac >- (
    fs[label_closures_def,UNIT_DEF,BIND_DEF] >>
    rpt gen_tac >> strip_tac >> rpt gen_tac >> strip_tac >>
    qabbrev_tac`p = label_closures e s` >> PairCases_on `p` >> fs[] >>
    qabbrev_tac`q = label_closures e' p1` >> PairCases_on `q` >> fs[] >>
    rpt BasicProvers.VAR_EQ_TAC >>
    first_x_assum (qspecl_then [`p1`,`q0`,`q1`] mp_tac) >>
    first_x_assum (qspecl_then [`s`,`p0`,`p1`] mp_tac) >>
    srw_tac[ARITH_ss,ETA_ss][REVERSE_ZIP,ZIP_APPEND,LET_THM] >>
    TRY (
      AP_TERM_TAC  >> rw[] >>
      simp_tac(std_ss)[GSYM REVERSE_APPEND] >>
      AP_TERM_TAC >> rw[] >>
      srw_tac[ARITH_ss][GENLIST_PLUS_APPEND] ) >>
    TRY (
      simp[MAP_ZIP,GSYM GENLIST_PLUS_APPEND] >>
      qmatch_abbrev_tac `A = B UNION C` >>
      metis_tac[ADD_SYM,UNION_ASSOC,UNION_COMM] ) >>
    fsrw_tac[ARITH_ss][MAP_ZIP] >>
    qabbrev_tac`be = (free_bods e)` >>
    qabbrev_tac`be' = (free_bods e')` >>
    qabbrev_tac`le = (free_labs e)` >>
    qabbrev_tac`le' = (free_labs e')` >>
    TRY (
      qmatch_abbrev_tac `subst_labs c1 p0 = e` >>
      qmatch_assum_abbrev_tac `P ==> (subst_labs c2 p0 = ee)` >>
      `P` by (
        qunabbrev_tac`P` >>
        fs[GSYM GENLIST_PLUS_APPEND] >>
        PROVE_TAC[DISJOINT_SYM] ) >>
      qunabbrev_tac`P` >>
      qsuff_tac `subst_labs c2 p0 = subst_labs c1 p0` >- PROVE_TAC[] >>
      match_mp_tac subst_labs_any_env >>
      REWRITE_TAC[DRESTRICT_EQ_DRESTRICT_SAME] >>
      `FDOM c2 = IMAGE ($+ s.lnext_label) (count (LENGTH be))` by (
        rw[Abbr`c2`,MAP_ZIP,LIST_TO_SET_GENLIST] ) >>
      `FDOM c1 = FDOM c2 ∪ IMAGE ($+ (s.lnext_label + LENGTH be)) (count (LENGTH be'))` by (
        rw[Abbr`c1`,MAP_ZIP,LIST_TO_SET_GENLIST,count_add,GSYM IMAGE_COMPOSE,plus_compose,UNION_COMM] ) >>
      `(free_labs p0) = FDOM c2 ∪ le` by rw[LIST_TO_SET_GENLIST] >>
      `DISJOINT le (IMAGE ($+ (s.lnext_label + LENGTH be)) (count (LENGTH be')))` by (
        fs[LIST_TO_SET_GENLIST,count_add,GSYM IMAGE_COMPOSE,plus_compose] >>
        PROVE_TAC[DISJOINT_SYM] ) >>
      conj_tac >- (
        rw[INTER_UNION,GSYM INTER_OVER_UNION] >>
        fs[DISJOINT_DEF] ) >>
      rw[Abbr`c1`,Abbr`c2`] >>
      rw[GSYM GENLIST_PLUS_APPEND] >>
      rw[REVERSE_APPEND] >>
      rw[GSYM ZIP_APPEND] >>
      rw[FUNION_DEF,MAP_ZIP,MEM_GENLIST] >>
      fsrw_tac[ARITH_ss][] ) >>
    TRY (
      qmatch_abbrev_tac `subst_labs c1 q0 = e'` >>
      qmatch_assum_abbrev_tac `P ==> (subst_labs c2 q0 = e')` >>
      `P` by (
        qunabbrev_tac`P` >>
        fs[GSYM GENLIST_PLUS_APPEND] >>
        PROVE_TAC[DISJOINT_SYM] ) >>
      qunabbrev_tac`P` >>
      qsuff_tac `subst_labs c2 q0 = subst_labs c1 q0` >- PROVE_TAC[] >>
      match_mp_tac subst_labs_any_env >>
      REWRITE_TAC[DRESTRICT_EQ_DRESTRICT_SAME] >>
      `FDOM c2 = IMAGE ($+ (s.lnext_label + LENGTH be)) (count (LENGTH be'))` by (
        srw_tac[ARITH_ss][Abbr`c2`,MAP_ZIP,LIST_TO_SET_GENLIST] ) >>
      `FDOM c1 = FDOM c2 ∪ IMAGE ($+ s.lnext_label) (count (LENGTH be))` by (
        rw[Abbr`c1`,MAP_ZIP,LIST_TO_SET_GENLIST,count_add,GSYM IMAGE_COMPOSE,plus_compose,UNION_COMM] ) >>
      `(free_labs q0) = FDOM c2 ∪ le'` by srw_tac[ARITH_ss][LIST_TO_SET_GENLIST] >>
      `DISJOINT le' (IMAGE ($+ s.lnext_label) (count (LENGTH be)))` by (
        fs[LIST_TO_SET_GENLIST,count_add,GSYM IMAGE_COMPOSE,plus_compose] >>
        PROVE_TAC[DISJOINT_SYM] ) >>
      conj_tac >- (
        rw[INTER_UNION,GSYM INTER_OVER_UNION] >>
        fs[DISJOINT_DEF] ) >>
      rw[Abbr`c1`,Abbr`c2`] >>
      rw[GSYM GENLIST_PLUS_APPEND] >>
      rw[REVERSE_APPEND] >>
      rw[GSYM ZIP_APPEND] >>
      rw[FUNION_DEF,MAP_ZIP,MEM_GENLIST] )) >>
  strip_tac >- (
    fs[label_closures_def,UNIT_DEF,BIND_DEF] >>
    rpt gen_tac >> strip_tac >> rpt gen_tac >> strip_tac >>
    qabbrev_tac`p = label_closures e s` >> PairCases_on `p` >> fs[] >>
    qabbrev_tac`q = label_closures e' p1` >> PairCases_on `q` >> fs[] >>
    qabbrev_tac`r = label_closures e'' q1` >> PairCases_on `r` >> fs[] >>
    rpt BasicProvers.VAR_EQ_TAC >>
    first_x_assum (qspecl_then [`q1`,`r0`,`r1`] mp_tac) >>
    first_x_assum (qspecl_then [`p1`,`q0`,`q1`] mp_tac) >>
    first_x_assum (qspecl_then [`s`,`p0`,`p1`] mp_tac) >>
    srw_tac[ARITH_ss,ETA_ss][REVERSE_ZIP,ZIP_APPEND,LET_THM] >>
    TRY (
      AP_TERM_TAC  >> rw[] >>
      simp_tac(std_ss)[GSYM REVERSE_APPEND] >>
      AP_TERM_TAC >> rw[] >>
      srw_tac[ARITH_ss][GENLIST_PLUS_APPEND] >>
      PROVE_TAC[GENLIST_PLUS_APPEND,ADD_ASSOC,ADD_SYM]) >>
    TRY (
      simp[MAP_ZIP,GSYM GENLIST_PLUS_APPEND] >>
      qmatch_abbrev_tac`A = B UNION C` >>
      metis_tac[ADD_SYM,UNION_ASSOC,UNION_COMM] ) >>
    fsrw_tac[ARITH_ss][MAP_ZIP] >>
    qabbrev_tac`le = (free_labs e)` >>
    qabbrev_tac`be = (free_bods e)` >>
    qabbrev_tac`le' = (free_labs e')` >>
    qabbrev_tac`be' = (free_bods e')` >>
    qabbrev_tac`le'' = (free_labs e'')` >>
    qabbrev_tac`be'' = (free_bods e'')` >>
    TRY (
      qmatch_abbrev_tac `subst_labs c1 p0 = e` >>
      qmatch_assum_abbrev_tac `P ==> (subst_labs c2 p0 = e)` >>
      `P` by (
        qunabbrev_tac`P` >>
        fs[GSYM GENLIST_PLUS_APPEND] >>
        PROVE_TAC[DISJOINT_SYM] ) >>
      qunabbrev_tac`P` >>
      qsuff_tac`subst_labs c2 p0 = subst_labs c1 p0` >- PROVE_TAC[] >>
      match_mp_tac subst_labs_any_env >>
      REWRITE_TAC[DRESTRICT_EQ_DRESTRICT_SAME] >>
      `FDOM c2 = IMAGE ($+ s.lnext_label) (count (LENGTH be))` by
        rw[Abbr`c2`,MAP_ZIP,LIST_TO_SET_GENLIST] >>
      `FDOM c1 = FDOM c2 ∪ IMAGE ($+ (s.lnext_label + LENGTH be)) (count (LENGTH be' + LENGTH be''))` by (
        srw_tac[ARITH_ss][Abbr`c1`,MAP_ZIP,LIST_TO_SET_GENLIST,count_add,GSYM IMAGE_COMPOSE,plus_compose] ) >>
      `(free_labs p0) = FDOM c2 ∪ le` by
        rw[LIST_TO_SET_GENLIST] >>
      `DISJOINT le (IMAGE ($+ (s.lnext_label + LENGTH be)) (count (LENGTH be' + LENGTH be'')))` by (
        fsrw_tac[ARITH_ss][MAP_ZIP,LIST_TO_SET_GENLIST,count_add,GSYM IMAGE_COMPOSE,plus_compose] ) >>
      conj_tac >- (
        rw[INTER_UNION,GSYM INTER_OVER_UNION] >>
        fs[DISJOINT_DEF] ) >>
      rw[Abbr`c1`,Abbr`c2`] >>
      rw[GSYM GENLIST_PLUS_APPEND] >>
      rw[REVERSE_APPEND] >>
      rw[GSYM ZIP_APPEND] >>
      rw[FUNION_DEF,MAP_ZIP,MEM_GENLIST] >>
      fsrw_tac[ARITH_ss][] ) >>
    TRY (
      qmatch_abbrev_tac `subst_labs c1 q0 = e'` >>
      qmatch_assum_abbrev_tac `P ==> (subst_labs c2 q0 = e')` >>
      `P` by (
        qunabbrev_tac`P` >>
        fs[GSYM GENLIST_PLUS_APPEND] >>
        PROVE_TAC[DISJOINT_SYM] ) >>
      qunabbrev_tac`P` >>
      qsuff_tac`subst_labs c2 q0 = subst_labs c1 q0` >- PROVE_TAC[] >>
      match_mp_tac subst_labs_any_env >>
      REWRITE_TAC[DRESTRICT_EQ_DRESTRICT_SAME] >>
      `FDOM c2 = IMAGE ($+ (s.lnext_label + LENGTH be)) (count (LENGTH be'))` by
        srw_tac[ARITH_ss][Abbr`c2`,MAP_ZIP,LIST_TO_SET_GENLIST] >>
      `FDOM c1 = FDOM c2 ∪ IMAGE ($+ s.lnext_label) (count (LENGTH be)) ∪ IMAGE ($+ (s.lnext_label + LENGTH be + LENGTH be')) (count (LENGTH be''))` by (
        srw_tac[ARITH_ss][Abbr`c1`,MAP_ZIP,LIST_TO_SET_GENLIST,count_add,GSYM IMAGE_COMPOSE,plus_compose] >>
        metis_tac[UNION_COMM,UNION_ASSOC]) >>
      `(free_labs q0) = FDOM c2 ∪ le'` by
        srw_tac[ARITH_ss][LIST_TO_SET_GENLIST] >>
      qmatch_assum_abbrev_tac `FDOM c1 = FDOM c2 ∪ es1 ∪ es2` >>
      `DISJOINT le' (es1 ∪ es2)` by (
        fsrw_tac[ARITH_ss][MAP_ZIP,LIST_TO_SET_GENLIST,count_add,GSYM IMAGE_COMPOSE,plus_compose] ) >>
      conj_tac >- (
        rw[INTER_UNION,GSYM INTER_OVER_UNION] >>
        qabbrev_tac `ess = es1 ∪ es2` >>
        CONV_TAC(RAND_CONV(RAND_CONV(REWRITE_CONV[Once (GSYM UNION_ASSOC)]))) >>
        rw[GSYM INTER_OVER_UNION] >>
        fs[DISJOINT_DEF] ) >>
      rw[Abbr`c1`,Abbr`c2`] >>
      rw[GSYM GENLIST_PLUS_APPEND] >>
      rw[REVERSE_APPEND] >>
      rw[GSYM ZIP_APPEND] >>
      rw[FUNION_DEF,MAP_ZIP,MEM_GENLIST] >>
      fsrw_tac[ARITH_ss][] ) >>
    TRY (
      qmatch_abbrev_tac `subst_labs c1 r0 = e''` >>
      qmatch_assum_abbrev_tac `P ==> (subst_labs c2 r0 = e'')` >>
      `P` by (
        qunabbrev_tac`P` >>
        fsrw_tac[ARITH_ss][GSYM GENLIST_PLUS_APPEND] >>
        PROVE_TAC[DISJOINT_SYM] ) >>
      qunabbrev_tac`P` >>
      qsuff_tac`subst_labs c2 r0 = subst_labs c1 r0` >- PROVE_TAC[] >>
      match_mp_tac subst_labs_any_env >>
      REWRITE_TAC[DRESTRICT_EQ_DRESTRICT_SAME] >>
      `FDOM c2 = IMAGE ($+ (s.lnext_label + LENGTH be + LENGTH be')) (count (LENGTH be''))` by
        srw_tac[ARITH_ss][Abbr`c2`,MAP_ZIP,LIST_TO_SET_GENLIST] >>
      `FDOM c1 = FDOM c2 ∪ IMAGE ($+ s.lnext_label) (count (LENGTH be + LENGTH be'))` by (
        srw_tac[ARITH_ss][Abbr`c1`,MAP_ZIP,LIST_TO_SET_GENLIST,count_add,GSYM IMAGE_COMPOSE,plus_compose] >>
        metis_tac[UNION_COMM,UNION_ASSOC]) >>
      `(free_labs r0) = FDOM c2 ∪ le''` by
        srw_tac[ARITH_ss][LIST_TO_SET_GENLIST] >>
      qmatch_assum_abbrev_tac `FDOM c1 = FDOM c2 ∪ ess` >>
      `DISJOINT le'' ess` by (
        fsrw_tac[ARITH_ss][Abbr`ess`,MAP_ZIP,LIST_TO_SET_GENLIST,count_add,GSYM IMAGE_COMPOSE,plus_compose] ) >>
      conj_tac >- (
        rw[INTER_UNION,GSYM INTER_OVER_UNION] >>
        fs[DISJOINT_DEF] ) >>
      rw[Abbr`c1`,Abbr`c2`] >>
      rw[GSYM GENLIST_PLUS_APPEND] >>
      rw[REVERSE_APPEND] >>
      rw[GSYM ZIP_APPEND] >>
      rw[FUNION_DEF,MAP_ZIP,MEM_GENLIST] >>
      fsrw_tac[ARITH_ss][] ) ) >>
  strip_tac >- rw[label_defs_def,UNIT_DEF] >>
  strip_tac >- (
    qx_gen_tac `d` >> PairCases_on `d` >> fs[] >>
    rpt gen_tac >> strip_tac >> rpt gen_tac >> strip_tac >>
    fsrw_tac[ARITH_ss][MAP_ZIP,LET_THM,REVERSE_ZIP] >>
    Cases_on `d1` >> fs[label_defs_def,UNIT_DEF,BIND_DEF] >>
    qmatch_assum_abbrev_tac `label_defs aa ds ss = (ds',s')` >>
    first_x_assum (qspecl_then [`aa`,`ss`,`ds'`,`s'`] mp_tac) >>
    unabbrev_all_tac >> srw_tac[ARITH_ss][] >>
    TRY (
      rw[GENLIST_CONS] >>
      rw[GSYM ZIP_APPEND] >>
      AP_TERM_TAC >> AP_THM_TAC >> AP_TERM_TAC >>
      AP_TERM_TAC >> AP_THM_TAC >> AP_TERM_TAC >>
      srw_tac[ARITH_ss][FUN_EQ_THM] ) >>
    TRY (
      rw[APPEND_LENGTH_EQ,FILTER_APPEND] >>
      TRY (
        rw[REWRITE_RULE[Once ADD_SYM]ADD1] >>
        rw[GSYM GENLIST_PLUS_APPEND] >>
        qmatch_abbrev_tac`A UNION B = C` >>
        metis_tac[ADD_SYM,INSERT_SING_UNION,UNION_COMM,UNION_ASSOC] ) >>
      TRY (
        Q.PAT_ABBREV_TAC`p = ALOOKUP (al:(num,Cexp)alist) s.lnext_label` >>
        qsuff_tac `p = SOME x` >- rw[] >>
        qunabbrev_tac`p` >>
        match_mp_tac ALOOKUP_ALL_DISTINCT_MEM >>
        simp[MAP_ZIP,GENLIST_CONS,GSYM ZIP_APPEND] >>
        simp[ALL_DISTINCT_APPEND,ALL_DISTINCT_REVERSE,MEM_GENLIST] >>
        simp[ALL_DISTINCT_GENLIST] ) >>
      TRY (
        Q.PAT_ABBREV_TAC`p = ALOOKUP (al:(num,Cexp)alist) y` >>
        qsuff_tac `p = NONE` >- rw[] >>
        qunabbrev_tac`p` >>
        rw[ALOOKUP_FAILS] >>
        spose_not_then strip_assume_tac >>
        imp_res_tac MEM_ZIP_MEM_MAP >>
        fs[] ) >>
      TRY (
        qmatch_abbrev_tac `MAP f1 xx = ds` >>
        qmatch_assum_abbrev_tac `P ==> (MAP f2 xx = ds)` >>
        `P` by (
          qunabbrev_tac`P` >>
          fs[GENLIST_CONS,Once DISJOINT_SYM] >>
          qmatch_abbrev_tac `DISJOINT s1 s2` >>
          qmatch_assum_abbrev_tac `DISJOINT s3 s2` >>
          qsuff_tac `s1 = s3` >- rw[] >>
          srw_tac[ARITH_ss][Abbr`s1`,Abbr`s3`,EXTENSION,MEM_GENLIST,ADD1] ) >>
        qunabbrev_tac`P` >>
        qsuff_tac `MAP f1 xx = MAP f2 xx` >- PROVE_TAC[] >>
        simp[MAP_EQ_f] >>
        qx_gen_tac `d` >>
        PairCases_on `d` >>
        rw[Abbr`f1`,Abbr`f2`] >>
        match_mp_tac subst_lab_cb_any_env >>
        Cases_on `d1` >> simp[] >>
        simp[GENLIST_CONS,GSYM ZIP_APPEND] >>
        qmatch_abbrev_tac`DRESTRICT (f1 ⊌ f3) {y} = DRESTRICT f2 {y}` >>
        `f1 = f2` by (
          unabbrev_all_tac >>
          ntac 3 (rpt AP_TERM_TAC >> rpt AP_THM_TAC) >>
          srw_tac[ARITH_ss][FUN_EQ_THM] ) >>
        rw[] >>
      qsuff_tac `y ∉ FDOM f1 ⇒ y ∉ FDOM f3` >- (
        rw[DRESTRICT_EQ_DRESTRICT_SAME,EXTENSION,FUNION_DEF] >>
        PROVE_TAC[] ) >>
      `y ∈ (free_labs_defs ds')` by (
        simp[MEM_MAP,MEM_FILTER] >>
        srw_tac[QUANT_INST_ss[std_qp]][] >>
        fs[Abbr`xx`] >> PROVE_TAC[] ) >>
      pop_assum mp_tac >> ASM_REWRITE_TAC[] >>
      REWRITE_TAC[IN_UNION] >>
      strip_tac >- (
        fsrw_tac[ARITH_ss][MEM_GENLIST,Abbr`f1`,MAP_ZIP] ) >>
      fs[IN_DISJOINT,MEM_GENLIST,Abbr`f3`] >>
      metis_tac[LESS_0,ADD_0] ) ) ) >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- (rw[UNIT_DEF] >> rw[Abbr`c`]) >>
  fs[label_closures_def,BIND_DEF,UNIT_DEF] >>
  rpt gen_tac >> strip_tac >> rpt gen_tac >> strip_tac >>
  qabbrev_tac`p = label_closures e s` >> PairCases_on `p` >> fs[] >>
  qabbrev_tac`q = mapM label_closures es p1` >> PairCases_on `q` >> fs[] >>
  rpt BasicProvers.VAR_EQ_TAC >>
  first_x_assum (qspecl_then [`p1`,`q0`,`q1`] mp_tac) >>
  first_x_assum (qspecl_then [`s`,`p0`,`p1`] mp_tac) >>
  srw_tac[ARITH_ss,ETA_ss][REVERSE_ZIP,ZIP_APPEND,LET_THM] >>
  TRY (
    AP_TERM_TAC  >> rw[] >>
    simp_tac(std_ss)[GSYM REVERSE_APPEND] >>
    AP_TERM_TAC >> rw[] >>
    srw_tac[ARITH_ss][GENLIST_PLUS_APPEND]) >>
  TRY (
    srw_tac[ARITH_ss][MAP_ZIP] >>
    CONV_TAC(RAND_CONV(REWRITE_CONV[Once ADD_SYM])) >>
    rw[GSYM GENLIST_PLUS_APPEND] >>
    qmatch_abbrev_tac`A = B UNION C` >>
    metis_tac[UNION_ASSOC,UNION_COMM] ) >>
  fsrw_tac[ARITH_ss][MAP_ZIP] >>
  qabbrev_tac`les = free_labs_list es` >>
  qabbrev_tac`bes = FLAT (MAP free_bods es)` >>
  qabbrev_tac`le = (free_labs e)` >>
  qabbrev_tac`be = (free_bods e)` >>
  TRY (
    qmatch_abbrev_tac `subst_labs c1 p0 = e` >>
    qmatch_assum_abbrev_tac `P ==> (subst_labs c2 p0 = e)` >>
    `P` by (
      metis_tac[DISJOINT_GENLIST_PLUS,ADD_SYM] ) >>
    qunabbrev_tac`P` >>
    qsuff_tac`subst_labs c2 p0 = subst_labs c1 p0` >- PROVE_TAC[] >>
    match_mp_tac subst_labs_any_env >>
    REWRITE_TAC[DRESTRICT_EQ_DRESTRICT_SAME] >>
    `FDOM c2 = IMAGE ($+ s.lnext_label) (count (LENGTH be))` by
      rw[Abbr`c2`,MAP_ZIP,LIST_TO_SET_GENLIST] >>
    `FDOM c1 = FDOM c2 ∪ IMAGE ($+ (s.lnext_label + LENGTH be)) (count (LENGTH bes))` by (
      rw[Abbr`c1`] >>
      REWRITE_TAC[Once ADD_SYM] >>
      srw_tac[ARITH_ss][MAP_ZIP,GSYM GENLIST_PLUS_APPEND,LIST_TO_SET_GENLIST] ) >>
    `(free_labs p0) = FDOM c2 ∪ le` by
      rw[LIST_TO_SET_GENLIST] >>
    qmatch_assum_abbrev_tac `FDOM c1 = FDOM c2 ∪ ss` >>
    `DISJOINT le ss` by (
      fsrw_tac[DNF_ss][] >>
      metis_tac[DISJOINT_GENLIST_PLUS,ADD_SYM,DISJOINT_SYM,LIST_TO_SET_GENLIST] ) >>
    conj_tac >- (
      rw[INTER_UNION,GSYM INTER_OVER_UNION] >>
      fs[DISJOINT_DEF] ) >>
    simp_tac(srw_ss()++DNF_ss)[Abbr`c1`,Abbr`c2`,MAP_ZIP,MEM_GENLIST] >>
    gen_tac >> strip_tac >>
    CONV_TAC(RAND_CONV(REWRITE_CONV[Once ADD_SYM])) >>
    rw[REVERSE_APPEND,GSYM GENLIST_PLUS_APPEND] >>
    rw[GSYM ZIP_APPEND] >>
    rw[FUNION_DEF,MAP_ZIP,MEM_GENLIST] >>
    fsrw_tac[ARITH_ss][] ) >>
  TRY (
    qmatch_abbrev_tac `MAP f1 q0 = es` >>
    qmatch_assum_abbrev_tac `P ==> (MAP f2 q0 = es)` >>
    `P` by (
      metis_tac[DISJOINT_GENLIST_PLUS,ADD_SYM] ) >>
    qunabbrev_tac`P` >>
    qsuff_tac `MAP f2 q0 = MAP f1 q0` >- PROVE_TAC[] >>
    simp[MAP_EQ_f] >>
    qx_gen_tac `ee` >>
    rw[Abbr`f1`,Abbr`f2`] >>
    qmatch_abbrev_tac`subst_labs c2 ee = subst_labs c1 ee` >>
    match_mp_tac subst_labs_any_env >>
    REWRITE_TAC[DRESTRICT_EQ_DRESTRICT_SAME] >>
    `FDOM c2 = IMAGE ($+ (s.lnext_label + LENGTH be)) (count (LENGTH bes))` by
      srw_tac[ARITH_ss][Abbr`c2`,MAP_ZIP,LIST_TO_SET_GENLIST] >>
    `FDOM c1 = FDOM c2 ∪ IMAGE ($+ s.lnext_label) (count (LENGTH be))` by (
      rw[Abbr`c1`,MAP_ZIP,LIST_TO_SET_GENLIST] >>
      REWRITE_TAC[Once ADD_SYM] >>
      rw[count_add,GSYM IMAGE_COMPOSE,plus_compose] >>
      PROVE_TAC[UNION_COMM] ) >>
    `free_labs_list q0 = FDOM c2 ∪ les` by
      srw_tac[ARITH_ss][LIST_TO_SET_GENLIST] >>
    `(free_labs ee) ⊆ FDOM c2 ∪ les` by (
      match_mp_tac SUBSET_TRANS >>
      qexists_tac `(free_labs_list q0)` >>
      conj_tac >- (
        rw[SUBSET_DEF,MEM_FLAT,MEM_MAP] >>
        PROVE_TAC[] ) >>
      rw[] ) >>
    `DISJOINT les (IMAGE ($+ s.lnext_label) (count (LENGTH be)))` by (
      rw[Abbr`les`] >>
      metis_tac[DISJOINT_GENLIST_PLUS,ADD_SYM,DISJOINT_SYM,LIST_TO_SET_GENLIST] ) >>
    conj_tac >- (
      rw[] >>
      match_mp_tac EQ_SYM >>
      qmatch_abbrev_tac `a INTER (b UNION c) = a INTER b` >>
      simp[UNION_OVER_INTER] >>
      simp[Once UNION_COMM] >>
      simp[GSYM SUBSET_UNION_ABSORPTION] >>
      fs[SUBSET_DEF,IN_DISJOINT] >>
      PROVE_TAC[] ) >>
    rw[Abbr`c1`,Abbr`c2`] >>
    CONV_TAC(RAND_CONV(REWRITE_CONV[Once ADD_SYM])) >>
    rw[GSYM GENLIST_PLUS_APPEND,REVERSE_APPEND] >>
    rw[GSYM ZIP_APPEND] >>
    rw[FUNION_DEF]))

(*
val label_closures_subst_labs = store_thm("label_closure_subst_labs",
  ``DISJOINT (set (free_labs e)) (IMAGE ($+ s.lnext_label) (count (LENGTH (free_bods e)))) ∧
    (label_closures e s = (e',s')) ==>
    (subst_labs (alist_to_fmap s'.lcode_env) e' = e)``
*)

(* TODO: move *)
val o_f_cong = store_thm("o_f_cong",
  ``!f fm f' fm'.
    (fm = fm') /\
    (!v. v IN FRANGE fm ==> (f v = f' v))
    ==> (f o_f fm = f' o_f fm')``,
  SRW_TAC[DNF_ss][GSYM fmap_EQ_THM,FRANGE_DEF])
val _ = DefnBase.export_cong"o_f_cong"

val subst_labs_v_def = tDefine "subst_labs_v"`
  (subst_labs_v c (CLitv l) = CLitv l) ∧
  (subst_labs_v c (CConv cn vs) = CConv cn (MAP (subst_labs_v c) vs)) ∧
  (subst_labs_v c (CRecClos env ns defs n) =
    CRecClos
      (subst_labs_v c o_f env) ns
      (MAP (λ(xs,cb). (xs, subst_lab_cb c cb)) defs)
      n)`(
   WF_REL_TAC `measure (Cv_size o SND)` >>
   srw_tac[ARITH_ss][Cvs_size_thm] >>
   Q.ISPEC_THEN`Cv_size`imp_res_tac SUM_MAP_MEM_bound >>
   srw_tac[ARITH_ss][] >>
   qmatch_abbrev_tac `(q:num) < x + (y + (w + (z + 1)))` >>
   qsuff_tac `q ≤ z` >- fsrw_tac[ARITH_ss][] >>
   unabbrev_all_tac >>
   rw[fmap_size_def] >>
   fs[FRANGE_DEF] >> rw[] >>
   qmatch_abbrev_tac `y <= SIGMA f (FDOM env)` >>
   match_mp_tac LESS_EQ_TRANS >>
   qexists_tac `f x` >>
   conj_tac >- srw_tac[ARITH_ss][o_f_FAPPLY,Abbr`y`,Abbr`f`] >>
   match_mp_tac SUM_IMAGE_IN_LE >>
   rw[])

val free_labs_v_def = tDefine "free_labs_v"`
  (free_labs_v (CLitv l) = {}) ∧
  (free_labs_v (CConv cn vs) = BIGUNION (IMAGE (free_labs_v) (set vs))) ∧
  (free_labs_v (CRecClos env ns defs n) = BIGUNION (IMAGE (free_labs_v) (FRANGE env)) ∪ set (free_labs_defs defs))`(
   WF_REL_TAC `measure (Cv_size)` >>
   srw_tac[ARITH_ss][Cvs_size_thm] >>
   Q.ISPEC_THEN`Cv_size`imp_res_tac SUM_MAP_MEM_bound >>
   srw_tac[ARITH_ss][] >>
   qmatch_abbrev_tac `(q:num) < x + (y + (w + (z + 1)))` >>
   qsuff_tac `q ≤ z` >- fsrw_tac[ARITH_ss][] >>
   unabbrev_all_tac >>
   rw[fmap_size_def] >>
   fs[FRANGE_DEF] >> rw[] >>
   qmatch_abbrev_tac `y <= SIGMA f (FDOM env)` >>
   match_mp_tac LESS_EQ_TRANS >>
   qexists_tac `f x` >>
   conj_tac >- srw_tac[ARITH_ss][o_f_FAPPLY,Abbr`y`,Abbr`f`] >>
   match_mp_tac SUM_IMAGE_IN_LE >>
   rw[])

val fixpoint_def = Define`
  fixpoint f = OWHILE (λx. f x ≠ x) f`

val _ = overload_on("subst_all_labs",``λc. fixpoint (subst_labs c)``)
val _ = overload_on("subst_all_labs_v",``λc. fixpoint (subst_labs_v c)``)

val has_fixpoint_def = Define`
  has_fixpoint f x = ∃n. f (FUNPOW f n x) = FUNPOW f n x`

val slf = WHILE_INDUCTION
|> Q.ISPEC`λe. ~DISJOINT (set (free_labs e)) (FDOM (c:num|->Cexp))`
|> Q.ISPEC`subst_labs c`
|> Q.ISPEC`measure (λe. CARD ((set (free_labs e)) INTER FDOM (c:num|->Cexp)))`
|> SIMP_RULE(srw_ss())[]

set_goal([],fst(dest_imp(concl slf)))

val subst_labs_removes_labs = store_thm("subst_labs_removes_labs",
  fst(dest_imp(concl slf)),
  qid_spec_tac `c` >>
  ho_match_mp_tac subst_labs_ind >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- (
    srw_tac[ETA_ss][MAP_MAP_o,combinTheory.o_DEF] >>
    DB.match[]``CARD (set x)``
  rw[]

val subst_labs_has_fixpoints = store_thm("subst_labs_has_fixpoints",
  ``∀c x. has_fixpoint (subst_labs c) x``,
  gen_tac >>
  ho_match_mp_tac (WHILE_INDUCTION)

val subst_all_labs_rws = save_thm("subst_all_labs_rws",
  LIST_CONJ (
  List.map (fn tm =>
    subst_all_labs_def |> SPEC_ALL
    |> REWRITE_RULE[FUN_EQ_THM]
    |> SPEC tm
    |> SIMP_RULE(srw_ss())[Once WHILE] )
  [``CRaise error``
  ,``CLit l``
  ,``CVar x``
  ,``CDecl xs``
  ]))
val _ = export_rewrites["subst_all_labs_rws"]


val Cevaluate_subst_labs = store_thm("Cevaluate_subst_labs",
  ``∀c env e res. Cevaluate c env e res ⇒
     ∀e'. (subst_all_labs c e = subst_all_labs c e') ⇒
       ∃res'. Cevaluate c env e' res' ∧
              (map_result (subst_all_labs_v c) res =
               map_result (subst_all_labs_v c) res')``,
  ho_match_mp_tac Cevaluate_nice_ind >>
  strip_tac


(*
val subst_labs_free_bods = store_thm("subst_labs_free_bods",
  ``∀e e'. subst_labs
  subst_labs_any_env
  subst_labs_ind
  ``(∀e s e' s'. (label_closures e s = (e',s')) ⇒
       ∃c. (s'.lcode_env = c++s.lcode_env) ∧
         (subst_labs (alist_to_fmap c) e' = e))``,
  rw[] >>
  imp_res_tac label_closures_thm >>
  rw[] >>
  DB.match [] ``alist_to_fmap (ZIP ls)``
  DB.find"alist_to_fmap"

val slexp_def = Define`
  slexp c = EQC (λe1 e2. e1 = subst_labs c e2)`

val (sldef_rules,sldef_ind,sldef_cases) = Hol_reln`
  (slexp c b1 b2 ∧
   (b1 = case cb1 of INL b => b | INR l => c ' l) ∧
   (b2 = case cb2 of INL b => b | INR l => c ' l)
   ⇒ sldef c (xs,cb1) (xs,cb2))`

val (sleq_rules,sleq_ind,sleq_cases) = Hol_reln`
  (sleq c (CLitv l) (CLitv l)) ∧
  (EVERY2 (sleq c) vs1 vs2
   ⇒ sleq c (CConv cn vs1) (CConv cn vs2)) ∧
  (fmap_rel (sleq c) env1 env2 ∧
   LIST_REL (sldef c) defs1 defs2
   ⇒ sleq c (CRecClos env1 ns defs1 n) (CRecClos env2 ns defs2 n))`

val slexp_refl = store_thm("slexp_refl",
  ``∀c e. slexp c e e``,
  rw[slexp_def])
val _ = export_rewrites["slexp_refl"]

val sldef_refl = store_thm("sldef_refl",
  ``∀c def. sldef c def def``,
  gen_tac >> Cases >> rw[sldef_cases])
val _ = export_rewrites["sldef_refl"]

val sleq_refl_full = store_thm("sleq_refl_full",
  ``(∀v c. sleq c v v) ∧
    (∀(env:string|->Cv) c. fmap_rel (sleq c) env env) ∧
    (∀vs c. EVERY2 (sleq c) vs vs)``,
  ho_match_mp_tac(TypeBase.induction_of``:Cv``) >>
  rw[] >> TRY (rw[sleq_cases] >> NO_TAC) >>
  rw[sleq_cases] >- (
    match_mp_tac quotient_listTheory.LIST_REL_REFL
    prove all of them are an equivalence in one theorem each?

val sleq_refl = store_thm("sleq_refl",
  ``!c v. sleq c v v``,
  gen_tac >> Induct >> rw[sleq_cases]
  rw[sleq_def])
val _ = export_rewrites["sleq_refl"]

val sleq_sym = store_thm("sleq_sym",
  ``!c v1 v2. sleq c v1 v2 ==> sleq c v2 v1``,
  rw[sleq_def]>>
  metis_tac[EQC_SYM])

val sleq_trans = store_thm("sleq_trans",
  ``!c v1 v2 v3. sleq c v1 v2 ∧ sleq c v2 v3 ⇒ sleq c v1 v3``,
  rw[sleq_def] >>
  metis_tac[EQC_TRANS])

val sleq_CConv = store_thm("sleq_CConv",
  ``sleq c (CConv cn vs) v2 =
    ∃vs'. (v2 = CConv cn vs') ∧
          (EVERY2 (sleq c) vs vs')``,
  rw[sleq_def] >>
  EQ_TAC >> rw[] >- (
    qid_spec_tac `vs` >>
    Induct_on `n` >- (
      rw[EVERY2_EVERY,EVERY_MEM,MEM_ZIP,UNCURRY] >>
      rw[] ) >>
    rw[FUNPOW_SUC] >>
    fs[subst_labs_v_def]
    DB.find"FUNPOW"

val Cevaluate_subst_labs = store_thm("Cevaluate_subst_labs",
  ``∀c env exp res. Cevaluate c env exp res
    ⇒ ∃res'. Cevaluate c env (subst_labs c exp) res' ∧
             result_rel (sleq c) res res'``,
  ho_match_mp_tac Cevaluate_nice_ind >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- (
    rw[Cevaluate_con,Cevaluate_list_with_Cevaluate,
       Cevaluate_list_with_value,EL_MAP] >>
    fsrw_tac[DNF_ss][]

       ) >>
  strip_tac >- (
    rw[Cevaluate_con,Cevaluate_list_with_Cevaluate,
       Cevaluate_list_with_error] >>
    qexists_tac `n` >>
    fsrw_tac[ETA_ss,DNF_ss,ARITH_ss][EL_MAP] ) >>
  strip_tac >- (
    rw[Cevaluate_tageq] >> PROVE_TAC[] ) >>
  strip_tac >- rw[Cevaluate_tageq] >>
  strip_tac >- (
    rw[Cevaluate_proj] >> PROVE_TAC[] ) >>
  strip_tac >- rw[Cevaluate_proj] >>
  strip_tac >- rw[] >>
  strip_tac >- (
    rw[Cevaluate_let_cons] >>
    PROVE_TAC[] ) >>
  strip_tac >- rw[Cevaluate_let_cons] >>
  strip_tac >- (
    rw[] >>
    srw_tac[DNF_ss][Once Cevaluate_cases,MEM_MAP]
*)

val Cevaluate_label_closures = store_thm("Cevaluate_label_closures",
  ``∀c env exp res. Cevaluate c env exp res ⇒
      ∀s. Cevaluate c env (FST (label_closures exp s)) res``,
  ho_match_mp_tac Cevaluate_nice_ind



define a non-monadic version of (half of) label_closures that just collects the bodies in a list
and perhaps another function that substitutes bodies for numbers from a given list

val label_closures_thm1 = store_thm("label_closures_thm1",
  ``(∀e s e' s'. (label_closures e s = (e',s')) ⇒
         ∃ce. (s'.lcode_env = ce++s.lcode_env) ∧
           ∀c env res. Cevaluate c env e res ⇒ Cevaluate (c⊌(alist_to_fmap ce)) env e' res) ∧
    (∀(ds:def list). T) ∧ (∀d:def. T) ∧ (∀(b:Cexp+num). T) ∧
    (∀es s es' s'. (label_closures_list es s = (es',s')) ⇒
         ∃ce. (s'.lcode_env = ce++s.lcode_env) ∧
           ∀c env res. Cevaluate_list c env es res ⇒ Cevaluate_list (c⊌(alist_to_fmap ce)) env es' res)``,
  ho_match_mp_tac(TypeBase.induction_of``:Cexp``) >>
  rw[label_closures_def,UNIT_DEF,BIND_DEF,FUNION_FEMPTY_2] >>
  rw[Cevaluate_raise,Cevaluate_var,Cevaluate_lit] >>
  cheat)

val FUNION_FEMPTY_FUPDATE = store_thm("FUNION_FEMPTY_FUPDATE",
  ``k ∉ FDOM fm ⇒ (fm ⊌ FEMPTY |+ (k,v) = fm |+ (k,v))``,
  rw[FUNION_FUPDATE_2,FUNION_FEMPTY_2])

val repeat_label_closures_thm1 = store_thm("repeat_label_closures_thm1",
  ``(∀e n ac e' n' ac'. (repeat_label_closures e n ac = (e',n',ac')) ⇒
       ∃ce. (ac' = ce++ac) ∧
         ∀c env res. Cevaluate c env e res ⇒ Cevaluate (c⊌(alist_to_fmap ce)) env e' res) ∧
    (∀n ac ls n' ac'. (label_code_env n ac ls = (n',ac')) ⇒
       ∃ce. (ac' = ce++ac) ∧
         ∀c env e res. Cevaluate (c⊌(alist_to_fmap ls)) env e res ⇒ Cevaluate (c⊌(alist_to_fmap ce)) env e res)``,
  ho_match_mp_tac repeat_label_closures_ind >>
  rw[repeat_label_closures_def,FUNION_FEMPTY_2,LET_THM]
  >- (
    qabbrev_tac `p = label_closures e <|lnext_label := n; lcode_env := []|>` >>
    PairCases_on `p` >> fs[] >>
    qabbrev_tac `q = label_code_env p1.lnext_label ac p1.lcode_env` >>
    PairCases_on `q` >> fs[] >> rw[] >>
    first_x_assum match_mp_tac >>
    fs[markerTheory.Abbrev_def] >>
    qmatch_assum_abbrev_tac `(e',s') = label_closures e s` >>
    qspecl_then [`e`,`s`,`e'`,`s'`] mp_tac (CONJUNCT1 label_closures_thm1) >>
    rw[] >> unabbrev_all_tac >> fs[] )
  >- (
    fs[]
    ... need to move to syneq to allow FUPDATE of code_env ...
     )
  >- (
    qabbrev_tac `p = label_closures e <|lnext_label := n; lcode_env := []|>` >>
    PairCases_on `p` >> fs[] >>
    qabbrev_tac `q = label_code_env p1.lnext_label ac p1.lcode_env` >>
    PairCases_on `q` >> fs[] >> rw[] >>

val _ = export_theory()
