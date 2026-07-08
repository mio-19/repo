{
  asm_9_9,
  asm_tree_9_9,
  asm_common,
}:
asm_common {
  artifactId = "asm-analysis";
  version = "9.9";
  srcHash = "sha256-/3MdQB6iQHdZ6hm0sCWADTJJWlGpEvJVPZh83dpCR3M=";
  pomHash = "sha256-kJ8kpxDHKODl1kPsC0g0pjyz0wAiEA1YPV3Wom41zaY=";
  classpath = [
    "${asm_9_9}/asm-9.9.jar"
    "${asm_tree_9_9}/asm-tree-9.9.jar"
  ];
}
