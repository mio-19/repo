{
  jdk17_headless,
  jdk21_headless,
  gradle_8_12_rc1,
  gradle-from-source,
  stdenv,
  gradle-packages,
}:
if stdenv.isDarwin then
  # darwin only: w: Configure scripting: unable to process classpath entry /nix/var/nix/builds/nix-82557-795482488/tmp.yAOSnH1ntA/caches/8.12-rc-1/transforms/8b83ebbdc509908836b9875da2cd5e1c/transformed/original/kotlin-daemon-embeddable-2.0.21.jar: java.util.zip.ZipException: zip file is empty
  (gradle-packages.mkGradle {
    version = "8.12.1";
    hash = "sha256-jZepeYT2y9K4X+TGCnQ0QKNHVEvxiBgEjmEfUojUbJQ=";
    defaultJava = jdk21_headless;
  }).wrapped
else
  gradle-from-source {
    version = "8.12.1";
    hash = "sha256-C7VaoZf70/FK0Oz/H9vUrdn+JuypgB77TjOVEBHVYHU=";
    lockFile = ./gradle.lock;
    defaultJava = jdk21_headless;
    buildJdk = jdk17_headless;
    # nix-shell -p javaPackages.compiler.openjdk17-bootstrap
    # nix run github:tadfisher/gradle2nix/53672d5e875235c34dee1a4c012b0269ba76e440  -- --gradle-wrapper=8.12-rc-1
    bootstrapGradle = gradle_8_12_rc1;
    postPatch =
      let
        # grep -rl 'vendor = JvmVendorSpec.ADOPTIUM' . | sed 's/.*/"&"/'
        files = [
          "./platforms/documentation/docs/src/snippets/java/toolchain-filters/kotlin/build.gradle.kts"
          "./platforms/documentation/docs/src/snippets/java/toolchain-filters/groovy/build.gradle"
          "./platforms/jvm/language-java/src/integTest/groovy/org/gradle/jvm/toolchain/JavaToolchainDownloadIntegrationTest.groovy"
          "./build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild/commons/JavaPluginExtensions.kt"
          "./build-logic-commons/settings.gradle.kts"
          "./build-logic-settings/build-environment/build.gradle.kts"
          "./build-logic/jvm/src/main/kotlin/gradlebuild.unittest-and-compile.gradle.kts"
        ];
      in
      ''
        substituteInPlace ${builtins.concatStringsSep " " files} \
          --replace-fail 'vendor = JvmVendorSpec.ADOPTIUM' ""

        substituteInPlace gradle/gradle-daemon-jvm.properties \
          --replace-fail 'toolchainVendor=adoptium' ""
      '';
  }
