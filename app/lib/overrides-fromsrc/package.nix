{
  overrides-fromsrc-bare,
  deepMerge,
}:
let
  patches = import ./patches.nix {
    self = result;
  };
  result = deepMerge overrides-fromsrc-bare patches;
in
result
