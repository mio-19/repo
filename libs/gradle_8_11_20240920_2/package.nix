# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/833d8dcf4c5500ffcae8196f83723fd5084ed39c
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_20240920_1,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.11-20240920-2";
  rev = "2b50be0d09a3f123924787e1e4117a42bac5d635";
  hash = "sha256-EyxhwVt9hMBVyZhRP6wfKrzbopNiuzQLdHuOfsAaeLI=";
  lockFile = mergeLock [
    gradle_8_11_20240920_1.unwrapped.passthru.lockFile
  ];
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_11_20240920_1;
}
