{
  callPackage,
  libs,
  lib,
  runCommand,
}:
with callPackage ./utils.nix { };
let
  basic = callPackage ./fromsrc.nix { };
  inherit (lib) mapAttrsToList mapAttrs;
  mavenProvides = mapAttrsToList (_: x: x.meta.mavenProvides or { }) libs;
  adhoc = builtins.foldl' deepMergeUnique { } mavenProvides;
in
# nix-repl> legacyPackages.x86_64-linux.overrides-fromsrc-bare."antlr:antlr:2.7.7"
# nix-repl> legacyPackages.x86_64-linux.overrides-fromsrc-bare."org.apache.ant:ant:1.10.15"
# nix-repl> legacyPackages.x86_64-linux.overrides-fromsrc-bare."org.apache.ant:ant:1.7.0"."ant-1.7.0.pom" null
noAsc (deepMergeUnique adhoc basic)
