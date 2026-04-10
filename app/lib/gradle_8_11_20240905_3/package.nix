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
  /*
    e: warnings found and -Werror specified
    w: file:///build/source/build-logic/kotlin-dsl-shared-runtime/src/main/kotlin/org/gradle/kotlin/dsl/internal/sharedruntime/codegen/ApiTypeProvider.kt:320:25 Non-public primary constructor is exposed via the generated 'copy()' method of the 'data' class.

    The generated 'copy()' will change its visibility in future releases.

    To suppress the warning do one of the following:
    - Annotate the data class with the '@ConsistentCopyVisibility' annotation.
    - Use the '-Xconsistent-data-class-copy-visibility' compiler flag.
    - Annotate the data class with the '@ExposedCopyVisibility' annotation
      (Discouraged, but can be used to keep binary compatibility).

    To learn more, see the documentation of the '@ConsistentCopyVisibility' and '@ExposedCopyVisibility' annotations.

    This will become an error in Kotlin 2.1.
    w: file:///build/source/build-logic/kotlin-dsl-shared-runtime/src/main/kotlin/org/gradle/kotlin/dsl/internal/sharedruntime/codegen/ApiTypeProvider.kt:361:33 Non-public primary constructor is exposed via the generated 'copy()' method of the 'data' class.

    The generated 'copy()' will change its visibility in future releases.

    To suppress the warning do one of the following:
    - Annotate the data class with the '@ConsistentCopyVisibility' annotation.
    - Use the '-Xconsistent-data-class-copy-visibility' compiler flag.
    - Annotate the data class with the '@ExposedCopyVisibility' annotation
      (Discouraged, but can be used to keep binary compatibility).

    To learn more, see the documentation of the '@ConsistentCopyVisibility' and '@ExposedCopyVisibility' annotations.

    This will become an error in Kotlin 2.1.
    Problems report is available at: file:///build/source/build/reports/problems/3che9jh3te8w5hx1ymyiqzffw/problem-report.html

    FAILURE: Build failed with an exception.

    * What went wrong:
    Execution failed for task ':build-logic:kotlin-dsl-shared-runtime:compileKotlin'.
    > A failure occurred while executing org.jetbrains.kotlin.compilerRunner.GradleCompilerRunnerWithWorkers$GradleKotlinCompilerWorkAction
    > Compilation error. See log for more details
  */
  postPatch = ''
    substituteInPlace build-logic/jvm/src/main/kotlin/gradlebuild.strict-compile.gradle.kts --replace-fail 'val strictCompilerArgs = listOf("-Werror", "-Xlint:all", "-Xlint:-options", "-Xlint:-serial", "-Xlint:-classfile", "-Xlint:-try")' 'val strictCompilerArgs = listOf("-Xconsistent-data-class-copy-visibility")'
  '';
}
