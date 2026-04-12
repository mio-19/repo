{ lib }:
finalAttrs:
let
  assumeExist =
    xs:
    lib.concatMapStringsSep "\n" (f: ''
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
assumeExist (leafValues finalAttrs.meta.mavenProvides)
