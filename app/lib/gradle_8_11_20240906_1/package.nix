# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/4bff127b7534bb00104c2877f865cf6f38b2e5b5#diff-40640fe1078ece83d7ea8fb67daacd77923a86d13447baf9769660b3b46f2ece
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_20240905_3,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.11-20240906-1";
  rev = "a4ac0c63857dec7c563d9fcaa0a8ff660ba10d77";
  hash = "sha256-Rq2uMjYkdAStNKrt4naFbfmesmz1giSSSsKRC4BjuOc=";
  # [id: 'com.gradle.develocity', version: '3.18']
  lockFile = mergeLock [
    gradle_8_11_20240905_3.unwrapped.passthru.lockFile
    ./more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_11_20240905_3;
}
