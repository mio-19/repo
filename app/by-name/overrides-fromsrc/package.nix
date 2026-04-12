{
  overrides-fromsrc-bare,
  callPackage,
}:
with callPackage ../overrides-fromsrc-bare/utils.nix { };
let
  patches = import ./patches.nix {
    self = result;
  };
  result = deepMerge overrides-fromsrc-bare patches;
in
noAsc result
