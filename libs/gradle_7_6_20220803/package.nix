# before commit https://github.com/gradle/gradle/commit/0c667cf65b0b6fe397de7a5a7d0479f158da37d4
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk17_headless,
  gradle_7_6_20220721,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "7.6.0-20220803";
  rev = "b7aed4fb93d9aaeb2e1d24d60eab4150cc39d997";
  hash = "sha256-MAGjV3BXsTMwe1qHxzdqEkFct5UvXre2YIo9sSS1TrI=";
  lockFile = mergeLock [
    gradle_7_6_20220721.unwrapped.passthru.lockFile
  ];
  defaultJava = jdk17_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  # read https://github.com/tadfisher/gradle2nix/pull/88
  /*
    nix-shell -p javaPackages.compiler.openjdk11-bootstrap
    rm gradle/verification-*
    nix run github:tadfisher/gradle2nix/6c0f9601ac41a1af04df09d8377ab706d07a4cf4  -- --gradle-wrapper=7.5-rc-1
  */
  bootstrapGradle = gradle_7_6_20220721;
}
