{
  asm_9_9,
  asm_tree_9_9,
  asm_common,
}:
asm_common {
  artifactId = "asm-commons";
  version = "9.9";
  srcHash = "sha256-IYu7ZI4kV4o4XLa2ohzv8iKiqPiy1faiVqgJndM23HY=";
  pomHash = "sha256-GKXT7xN351RLPKMhDyYTlrmH9gEO9ZHThyra5jEZ7kM=";
  classpath = [
    "${asm_9_9}/asm-9.9.jar"
    "${asm_tree_9_9}/asm-tree-9.9.jar"
  ];
}
