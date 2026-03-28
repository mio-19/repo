{ callPackage, androidSdkBuilder, ... }:
let
  lspatch = callPackage ../lspatch/common.nix {
    inherit androidSdkBuilder;
  };
in
lspatch.cli
