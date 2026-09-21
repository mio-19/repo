{
  asm_9_9,
  asm_tree_9_9,
  asm_analysis_9_9,
  asm_common,
}:
asm_common {
  artifactId = "asm-util";
  version = "9.9";
  srcHash = "sha256-5RigCx0ASDLnLGRINRxIZZcayVp8/nj7AxXXass5OkY=";
  pomHash = "sha256-qYWT/aHFOp5w12YPQWcg4wjSTbjhxFb6F+drp40nK2s=";
  classpath = [
    "${asm_9_9}/asm-9.9.jar"
    "${asm_tree_9_9}/asm-tree-9.9.jar"
    "${asm_analysis_9_9}/asm-analysis-9.9.jar"
  ];
}
