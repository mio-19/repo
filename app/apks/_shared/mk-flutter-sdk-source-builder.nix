# Build the `sdkSourceBuilders.flutter` attr expected by buildDartApplication
# for Flutter SDK packages that live under packages/ or bin/cache/pkg/.
#
# Usage:
#   sdkSourceBuilders = {
#     flutter = import ../_shared/mk-flutter-sdk-source-builder.nix {
#       inherit runCommand;
#       flutter = flutter338;
#     };
#   };
{
  runCommand,
  flutter,
}:
name:
runCommand "flutter-sdk-${name}" { passthru.packageRoot = "."; } ''
  for path in \
    '${flutter}/packages/${name}' \
    '${flutter}/bin/cache/pkg/${name}'; do
    if [ -d "$path" ]; then
      ln -s "$path" "$out"
      break
    fi
  done
  if [ ! -e "$out" ]; then
    echo 1>&2 'The Flutter SDK does not contain the requested package: ${name}!'
    exit 1
  fi
''
