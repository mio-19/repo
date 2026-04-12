{
  callPackage,
}:
let
  basic = callPackage ./fromsrc.nix { };
  noAsc = callPackage ./noAsc.nix { };
in
noAsc basic
