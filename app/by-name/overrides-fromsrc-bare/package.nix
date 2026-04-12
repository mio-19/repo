{
  callPackage,
  libs,
  lib,
}:
with callPackage ./utils.nix { };
let
  basic = callPackage ./fromsrc.nix { };
  inherit (lib) mapAttrsToList mapAttrs;
  mavenProvides = mapAttrsToList (_: x: x.meta.mavenProvides or { }) libs;
  adhoc = builtins.foldl' deepMergeUnique { } mavenProvides;
  adhoc' = mapAttrs (
    group: entry:
    mapAttrs (
      name: value:
      assert builtins.isPath value;
      _: value
    ) entry
  ) adhoc;
in
# nix-repl> legacyPackages.x86_64-linux.overrides-fromsrc-bare."antlr:antlr:2.7.7"
# nix-repl> legacyPackages.x86_64-linux.overrides-fromsrc-bare."org.apache.ant:ant:1.10.15"
noAsc (deepMergeUnique basic adhoc')
