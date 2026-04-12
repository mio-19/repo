{
  overrides-fromsrc-bare,
  deepMerge,
  overrides-fromsrc,
  callPackage,
}:
let
  updates = import ./updates.nix {
    self = result;
  };
  result = deepMerge overrides-fromsrc updates;
  noAsc = callPackage ../overrides-fromsrc-bare/noAsc.nix { };
in
noAsc result
