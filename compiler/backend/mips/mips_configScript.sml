open preamble backendTheory mips_targetTheory mips_targetLib

val _ = new_theory"mips_config";

val mips_names_def = Define `
  mips_names =
    (* source can use 25 regs (r2-r24,r30-r31),
       target's r0 must be avoided (hardcoded to 0),
       target's r1 must be avoided (used by encoder in asm),
       target's r25 and r28 are used to set up PIC
       target's r29 must be avoided (stack pointer),
       target's r26-r27 avoided (reserved for OS kernel),
       source 0 must represent r31 (link register),
       source 1 2 must be r4, r5 (1st 2 args),
       top 3 (22-24) must be callee-saved (in 16-23, 28, 30) *)
    (insert 0 31 o
     insert 1 4 o
     insert 2 5 o
     insert 22 21 o
     insert 23 22 o
     insert 24 23 o
     (* the rest just ensures that the mapping is well-formed *)
     insert 4 2 o
     insert 21 24 o
     insert 5 30 o
     insert 31 0 o
     insert 30 1) LN:num num_map`

val mips_names_def = save_thm("mips_names_def",
  CONV_RULE (RAND_CONV EVAL) mips_names_def);

val source_conf = rconc(EVAL``prim_config.source_conf``)
val mod_conf = rconc(EVAL``prim_config.mod_conf``)
val clos_conf = rconc (EVAL ``clos_to_bvl$default_config``)
val bvl_conf = rconc (EVAL``bvl_to_bvi$default_config``)
val word_to_word_conf = ``<| reg_alg:=3; col_oracle := λn. NONE |>``
val mips_data_conf = ``<| tag_bits:=4; len_bits:=4; pad_bits:=2; len_size:=32; has_div:=T; has_longdiv:=F; gc_kind:=Simple|>``
val mips_word_conf = ``<| bitmaps := []:64 word list |>``
val mips_stack_conf = ``<|reg_names:=mips_names;max_heap:=1000000|>``
val mips_lab_conf = ``<|labels:=LN;asm_conf:=mips_config;init_clock:=5|>``

val mips_backend_config_def = Define`
  mips_backend_config =
             <|source_conf:=^(source_conf);
               mod_conf:=^(mod_conf);
               clos_conf:=^(clos_conf);
               bvl_conf:=^(bvl_conf);
               data_conf:=^(mips_data_conf);
               word_to_word_conf:=^(word_to_word_conf);
               word_conf:=^(mips_word_conf);
               stack_conf:=^(mips_stack_conf);
               lab_conf:=^(mips_lab_conf)
               |>`;

val _ = export_theory();
