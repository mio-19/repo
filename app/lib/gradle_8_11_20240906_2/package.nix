# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/fabfa88bbf12b1c7258147962161fc5c2729ff6d
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_1,
  gradle-from-source,runCommand,jq,
}:
gradle-from-source {
  version = "8.11-20240906-2";
  rev = "4bff127b7534bb00104c2877f865cf6f38b2e5b5";
  hash = "";
  lockFile =
    runCommand "merged-lock"
      {
        nativeBuildInputs = [ jq ];
      }
      ''
        jq -s '.[0] * .[1]' ${../gradle_8_11_20240807/gradle.lock} ${../gradle_8_11_1/gradle.lock} > $out
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
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.10.2
  bootstrapGradle = gradle_8_11_1;
}
