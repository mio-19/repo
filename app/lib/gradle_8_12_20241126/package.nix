# this is before gradle_12_rc1. before commit https://github.com/gradle/gradle/commit/06e9ee64049155fcdddd08010a0f10bbed19c60a
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_12_20241016_8914,
  gradle-from-source,
  runCommand,
  jq,
}:
gradle-from-source {
  version = "8.12-20241126";
  rev = "6a764a9cc3c07120fb418357adab84d8b1c1fe91";
  hash = "sha256-h0B76hX0FBSYXwbwlCjpXqkFFbJ51iPROgkaiQgXbZY=";
  lockFile =
    runCommand "merged-lock"
      {
        nativeBuildInputs = [ jq ];
      }
      ''
        jq -s '.[0] * .[1]' ${../gradle_8_12_20241015/gradle.lock} ${../gradle_8_12_1/gradle.lock} > $out
      '';
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-17;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  # nix-shell -p javaPackages.compiler.openjdk17-bootstrap
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-home=/nix/store/p0k528kprsib13134wk5wdv4gg14i0z0-gradle-8.12-20241016-8914/libexec/gradle
  bootstrapGradle = gradle_8_12_20241016_8914;
}
