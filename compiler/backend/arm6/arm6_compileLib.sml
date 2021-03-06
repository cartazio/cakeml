structure arm6_compileLib =
struct

open HolKernel boolLib bossLib

val _ = ParseExtras.temp_loose_equality()

open arm6_targetLib asmLib;
open backendComputeLib;
open configTheory

val cmp = wordsLib.words_compset ()
val () = computeLib.extend_compset
    [computeLib.Extenders
      [backendComputeLib.add_backend_compset
      ,arm6_targetLib.add_arm6_encode_compset
      ,asmLib.add_asm_compset
      ],
     computeLib.Defs
      [configTheory.arm_compiler_config_def
      ,configTheory.arm_names_def]
    ] cmp

val eval = computeLib.CBV_CONV cmp

end
