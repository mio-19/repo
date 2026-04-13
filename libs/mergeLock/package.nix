{
  runCommand,
  lib,
  jq,
}:
xs:
if !lib.lists.isList xs then
  xs
else if lib.lists.length xs == 1 then
  lib.head xs
else
  runCommand "merged-lock" { } ''
    ${lib.getExe jq} -s '
      reduce .[] as $item ({}; . * $item)
    ' ${builtins.concatStringsSep " " xs} > $out
  ''
