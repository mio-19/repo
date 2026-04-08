{
  lib,
  pkgs,
  gradle_9_3_1,
}:
let
  upstream = pkgs.gradle-packages;
  wrapKnown =
    args:
    let
      wrapped = gradle_9_3_1.override {
        java = args.defaultJava;
      };
    in
    {
      inherit wrapped;
      unwrapped = wrapped.unwrapped;
    };
in
rec {
  inherit (upstream) wrapGradle;

  inherit gradle_9_3_1;

  mkGradle =
    args:
    if args.version == "9.3.1" then
      wrapKnown args
    else
      upstream.mkGradle args;

  gradle_9 = upstream.gradle_9;
  gradle_8 = upstream.gradle_8;
  gradle_7 = upstream.gradle_7;
  gradle = upstream.gradle;
}
