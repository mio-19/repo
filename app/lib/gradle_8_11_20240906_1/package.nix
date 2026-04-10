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
