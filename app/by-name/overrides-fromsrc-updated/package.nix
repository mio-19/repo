{
  overrides-fromsrc-bare,
  deepMerge,
  overrides-fromsrc,
  callPackage,
}:
with callPackage ../overrides-fromsrc-bare/utils.nix { };
let
  updates = import ./updates.nix {
    self = result;
  };
  result = deepMerge overrides-fromsrc updates;
in
noAsc result
