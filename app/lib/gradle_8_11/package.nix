# this is before gradle_12_rc1. before commit https://github.com/gradle/gradle/commit/864ddaf0a289b122e804046ab4a0e618dce9b8e7
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_M1,
  gradle-from-source,
  runCommand,
  jq,
}:
gradle-from-source {
  version = "8.11";
  hash = "sha256-E1+O/bVAw/YP9vJRFP5L3fje7gKnLdTXcCJlPq4ecaw=";
  lockFile =
    runCommand "merged-lock"
      {
        nativeBuildInputs = [ jq ];
      }
      ''
        jq -s '
          reduce .[] as $item ({}; . * $item)
          | del(.["gradle:gradle:8.11"])
        ' ${../gradle_8_11_20240807/gradle.lock} ${../gradle_8_11_1/gradle.lock} > $out
      '';
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  # nix-shell -p javaPackages.compiler.openjdk11-bootstrap
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.11-milestone-1
  bootstrapGradle = gradle_8_11_M1;
}
