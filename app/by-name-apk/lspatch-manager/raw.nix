{ callPackage, androidSdkBuilder, ... }:
let
  lspatch = callPackage ../../by-name/lspatch/common.nix {
    inherit androidSdkBuilder;
  };
in
lspatch.manager
