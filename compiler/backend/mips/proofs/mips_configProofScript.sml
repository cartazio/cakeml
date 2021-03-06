open preamble targetSemTheory backendProofTheory
     mips_configTheory mips_targetProofTheory

val _ = new_theory"mips_configProof";

val mips_machine_config_def = Define`
  mips_machine_config = <|target:= mips_target; len_reg:=5  ; ptr_reg := 4 ; callee_saved_regs := [21;22;23]|>`

val names_tac =
  simp[tlookup_bij_iff] \\ EVAL_TAC
  \\ REWRITE_TAC[SUBSET_DEF] \\ EVAL_TAC
  \\ rpt strip_tac \\ rveq \\ EVAL_TAC

val mips_conf_ok = Q.store_thm("mips_conf_ok",`
  conf_ok mips_compiler_config mips_machine_config`,
  simp[conf_ok_def,lower_conf_ok_def]>>rw[]>> TRY(EVAL_TAC>>NO_TAC)
  >- fs[mips_machine_config_def,mips_backend_correct]
  >- names_tac
  >-
    (rw[conf_constraint_def]>>
    TRY(EVAL_TAC>>fs[]>> NO_TAC)>>
    fs[stack_removeTheory.max_stack_alloc_def]
    >-
      (simp[GSYM word_mul_n2w]>>
      srw_tac [wordsLib.WORD_MUL_LSL_ss][]>>
      qpat_abbrev_tac`w = n2w n`>>fs[]>>
      `w <= 255w ∧ 0w ≤ w` by
        (fs[Abbr`w`]>>
        dep_rewrite.DEP_REWRITE_TAC[word_le_n2w]>>
        fs[]>>
        match_mp_tac bitTheory.NOT_BIT_GT_TWOEXP>>fs[])>>
      pop_assum mp_tac>>
      pop_assum mp_tac>>EVAL_TAC>>
      blastLib.BBLAST_PROVE_TAC)
    >-
      (simp[GSYM word_mul_n2w]>>
      srw_tac [wordsLib.WORD_MUL_LSL_ss][]>>
      qpat_abbrev_tac`w = n2w n`>>fs[]>>
      `w <= 255w ∧ 0w ≤ w` by
        (fs[Abbr`w`]>>
        dep_rewrite.DEP_REWRITE_TAC[word_le_n2w]>>
        fs[]>>
        match_mp_tac bitTheory.NOT_BIT_GT_TWOEXP>>fs[])>>
      pop_assum mp_tac>>
      pop_assum mp_tac>>EVAL_TAC>>
      blastLib.BBLAST_PROVE_TAC)
    >>
    fs [stack_removeTheory.store_offset_def,
        stack_removeTheory.store_pos_def]
    \\ every_case_tac \\ fs [] THEN1 EVAL_TAC
    \\ fs [stack_removeTheory.store_list_def]
    \\ fs [INDEX_FIND_CONS_EQ_SOME,EVAL ``INDEX_FIND n f []``]
    \\ rveq \\ fs [] \\ EVAL_TAC)
  >>
  rpt(pop_assum mp_tac)>>
  fs[markerTheory.Abbrev_def]>>
  EVAL_TAC>>
  fs[]);

val _ = export_theory();
