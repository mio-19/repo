{ ... }:
{
  perSystem =
    {
      lib,
      pkgs,
      libs,
      ...
    }:
    let
      byNameScope = lib.makeScope pkgs.newScope (_: libs);

      byName = lib.filesystem.packagesFromDirectoryRecursive {
        inherit (byNameScope)
          callPackage
          newScope
          ;
        directory = ./by-name;
      };
    in
    {
      packages = lib.filterAttrs (_: lib.isDerivation) byName;
    };
}
