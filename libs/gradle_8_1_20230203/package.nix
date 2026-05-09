{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_0,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.1-20230203";
  rev = "443ad4b46d5d6f364f5431e9a47eb87d65abf1d6";
  hash = "sha256-KYbibckAHehS3Ebt07ddJ0FGe+LO0mU2yAo6DFFIVaA=";
  patches = [
    ./kotlin-dsl-assignment-compat.patch
  ];
  lockFile = mergeLock [
    gradle_8_0.unwrapped.passthru.lockFile
    ../gradle_8_1/more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_0;
  postPatch = ''
    substituteInPlace subprojects/build-scan-performance/build.gradle.kts \
      --replace-fail \
      'performanceTest.registerTestProject<gradlebuild.performance.generator.tasks.JvmProjectGeneratorTask>("javaProject") {' \
      'performanceTest.registerTestProject("javaProject", gradlebuild.performance.generator.tasks.JvmProjectGeneratorTask::class.java) {'
  '';
}
