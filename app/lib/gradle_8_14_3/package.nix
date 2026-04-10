{
  jdk11_headless,
  jdk21_headless,
  gradle_8_14,
  gradle-from-source,
  runCommand,
  jq,
  lib,
}:
gradle-from-source {
  version = "8.14.3";
  hash = "sha256-k9j9/w3HEBZc2z2dOgpAm+338hhIjh/WxvAE28viOVk=";
  lockFile =
    runCommand "merged-lock"
      {
        nativeBuildInputs = [ jq ];
      }
      ''
          jq -s '
          reduce .[] as $item ({}; . * $item)
          | del(.["gradle:gradle:8.14.3"])
        ' ${../gradle_8_14/gradle.lock} ${../gradle_8_14_4/gradle.lock} > $out
      '';
  defaultJava = jdk21_headless;
  buildJdk = jdk11_headless;
  # nix run github:tadfisher/gradle2nix/53672d5e875235c34dee1a4c012b0269ba76e440  -- --gradle-wrapper=8.14
  bootstrapGradle = gradle_8_14;
}
