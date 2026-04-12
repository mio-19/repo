{
  overrides-fromsrc-bare,
  deepMerge,
  callPackage,
}:
let
  patches = import ./patches.nix {
    self = result;
  };
  result = deepMerge overrides-fromsrc-bare patches;
  noAsc = callPackage ../overrides-fromsrc-bare/noAsc.nix { };
in
noAsc result
