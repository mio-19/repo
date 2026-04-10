# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/833d8dcf4c5500ffcae8196f83723fd5084ed39c
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_20240807,
  gradle-from-source,
  runCommand,
  jq,
}:
gradle-from-source {
  version = "8.11-20240920-2";
  rev = "2b50be0d09a3f123924787e1e4117a42bac5d635";
  hash = "sha256-EyxhwVt9hMBVyZhRP6wfKrzbopNiuzQLdHuOfsAaeLI=";
  lockFile =
    runCommand "merged-lock"
      {
        nativeBuildInputs = [ jq ];
      }
      ''
        jq -s '
          reduce .[] as $item ({}; . * $item)
          | del(.["gradle:gradle:8.10.2"])
        ' ${../gradle_8_11_20240807/gradle.lock} ${../gradle_8_11/gradle.lock} ${./more.gradle.lock} > $out
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
  bootstrapGradle = gradle_8_11_20240807;
}
