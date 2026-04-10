{
  runCommand,
  lib,
  jq,
}:
xs:
runCommand "merged-lock" { } ''
  ${lib.getExe jq} -s '
    reduce .[] as $item ({}; . * $item)
  ' ${builtins.concatStringsSep " " xs} > $out
''
