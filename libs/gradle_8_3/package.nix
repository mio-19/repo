{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_2,
  gradle-packages,
  gradle-from-source,
  mergeLock,
}:
let
  bootstrapGradle =
    (gradle-packages.mkGradle {
      version = "8.3-rc-4";
      hash = "sha256-5NiODmNnmRNBeTdrWwWLDGkeWKHpFQwdCjiY/9QCq6o=";
      defaultJava = jdk21_headless;
    }).wrapped;
in
gradle-from-source {
  version = "8.3";
  hash = "sha256-0MORZqQX5+ZBpUKpf4RNz/57Y3fJe9++8AN35xXw6Sk=";
  lockFile = mergeLock [
    gradle_8_2.unwrapped.passthru.lockFile
    ./gradle.lock
  ];
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  # nix run .#gradle2nix -- --gradle-wrapper=8.3-rc-4
  bootstrapGradle = bootstrapGradle;
}
