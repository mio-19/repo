{
  overrides-fromsrc-bare,
  deepMerge,
  overrides-fromsrc,
}:
let
  updates = import ./updates.nix {
    self = result;
  };
  result = deepMerge overrides-fromsrc updates;
in
result
