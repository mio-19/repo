# this is before gradle v8.11.0-M1. between gradle_8_11_20240905_2 and gradle_8_11_20240906_1
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_20240905_2,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.11-20240905-3";
  rev = "a6c46252b26d640847fd1c2dc29d59907b9890ad";
  hash = "sha256-mwSneanwndpuV637WniIscC3oI8xwEdhsVz39FZq1KM=";
  lockFile = mergeLock [
    gradle_8_11_20240905_2.unwrapped.passthru.lockFile
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
  bootstrapGradle = gradle_8_11_20240905_2;
  postPatch = ''
    substituteInPlace build-logic/jvm/src/main/kotlin/gradlebuild.strict-compile.gradle.kts --replace-fail 'val strictCompilerArgs = listOf("-Werror", "-Xlint:all", "-Xlint:-options", "-Xlint:-serial", "-Xlint:-classfile", "-Xlint:-try")' 'val strictCompilerArgs = listOf("-Xlint:all", "-Xlint:-options", "-Xlint:-serial", "-Xlint:-classfile", "-Xlint:-try")'
  '';
}
