# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/61c49a2eeb032508adf2a2e22c90bfb9ac09d77e
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
  version = "8.11-20240809";
  rev = "d40cb09ed3c2f557ee731dd88dde0cae2f3f0ce1";
  hash = "sha256-xt5RLWbM1YAgg0IAl7OttqV1qjxpWzyRmQdGKjTXmr0=";
  # TODO: org.gradle.kotlin.kotlin-dsl:org.gradle.kotlin.kotlin-dsl.gradle.plugin:5.1.0 org.jetbrains.kotlin:kotlin-gradle-plugin:2.0.10
  lockFile =
    runCommand "merged-lock"
      {
        nativeBuildInputs = [ jq ];
      }
      ''
        jq -s '.[0] * .[1]' ${../gradle_8_11_20240807/gradle.lock} ${../gradle_8_11/gradle.lock} > $out
      '';
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  # nix-shell -p javaPackages.compiler.openjdk17-bootstrap
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-home=/nix/store/7mcaacs8xrp4n7nglp870b2rb3jh8sx5-gradle-8.11-20240807/libexec/gradle
  bootstrapGradle = gradle_8_11_20240807;
}
