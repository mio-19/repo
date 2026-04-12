{ lib, runCommand }:
let
  inherit (lib) mapAttrs concatMapStringsSep;
in
{
  checkMavenProvides =
    finalAttrs:
    let
      assumeExist =
        xs:
        concatMapStringsSep "\n" (f: ''
          if [ -f ${f} ]; then
            echo "Found expected file ${f} in mavenProvides"
          else
            echo >&2 "Expected file ${f} does not exist in mavenProvides"
            exit 1
          fi
        '') xs;
      leafValues =
        set:
        builtins.concatLists (
          builtins.map (
            name:
            let
              v = set.${name};
            in
            if builtins.isAttrs v then leafValues v else [ v ]
          ) (builtins.attrNames set)
        );
    in
    builtins.replaceStrings [ "$out" ] [ (placeholder "out") ] (
      assumeExist (leafValues finalAttrs.meta.mavenProvidesInternal)
    );
  exposeMavenProvides =
    finalAttrs:
    mapAttrs (
      group: entry:
      mapAttrs (
        name: value:
        assert builtins.isPath value || builtins.isString value;
        _: builtins.replaceStrings [ "$out" ] [ "${finalAttrs.finalPackage}" ] value
      ) entry
    ) finalAttrs.meta.mavenProvidesInternal;
}
