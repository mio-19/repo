{
  fetchurl,
  gradle-legacy-bridge,
  jdk11_headless,
  runCommand,
  unzip,
}:
let
  antlr = fetchurl {
    url = "https://repo1.maven.org/maven2/antlr/antlr/2.7.7/antlr-2.7.7.jar";
    hash = "sha256-iPvaS5Ellrn1bo4S5YDMlUus+1F3bs/d0+GPwc9W3Ew=";
  };
  bootstrapGradle =
    runCommand "gradle-5.6.4-bootstrap"
      {
        src = fetchurl {
          url = "https://services.gradle.org/distributions/gradle-5.6.4-bin.zip";
          hash = "sha256-HzBnBzBBvERVTQ7+XUAqM7w9PJPMOatoTzCFhtcyqA0=";
        };
        nativeBuildInputs = [ unzip ];
      }
      ''
        mkdir -p "$out/libexec/gradle"
        unzip -q "$src"
        cp -a gradle-5.6.4/lib "$out/libexec/gradle/"
      '';
in
gradle-legacy-bridge {
  version = "5.6.4";
  tag = "v5.6.4";
  hash = "sha256-sGLAyKn2PVIp4OBe1rvhU7Tact4cHvF9iaIlSZ4bGYE=";
  inherit bootstrapGradle;
  jdk = jdk11_headless;
  extraLibs = [ antlr ];
  sourceSubprojects = [
    "antlr"
    "api-metadata"
    "base-services"
    "base-services-groovy"
    "bootstrap"
    "build-cache"
    "build-cache-packaging"
    "build-comparison"
    "build-init"
    "build-option"
    "cli"
    "composite-builds"
    "core"
    "core-api"
    "dependency-management"
    "diagnostics"
    "ear"
    "execution"
    "file-collections"
    "files"
    "hashing"
    "installation-beacon"
    "ivy"
    "jacoco"
    "javascript"
    "jvm-services"
    "language-jvm"
    "logging"
    "maven"
    "messaging"
    "model-core"
    "model-groovy"
    "native"
    "persistent-cache"
    "platform-base"
    "platform-jvm"
    "plugin-use"
    "plugins"
    "process-services"
    "publish"
    "reporting"
    "resources"
    "resources-http"
    "resources-sftp"
    "runtime-api-info"
    "snapshots"
    "test-kit"
    "testing-base"
    "tooling-api"
    "tooling-api-builders"
    "version-control"
    "worker-processes"
    "workers"
    "wrapper"
  ];
  builtRuntimeModules = [
    "gradle-api-metadata"
    "gradle-base-services"
    "gradle-base-services-groovy"
    "gradle-build-cache"
    "gradle-build-cache-packaging"
    "gradle-build-option"
    "gradle-cli"
    "gradle-core"
    "gradle-core-api"
    "gradle-execution"
    "gradle-file-collections"
    "gradle-files"
    "gradle-hashing"
    "gradle-installation-beacon"
    "gradle-jvm-services"
    "gradle-logging"
    "gradle-messaging"
    "gradle-model-core"
    "gradle-model-groovy"
    "gradle-native"
    "gradle-persistent-cache"
    "gradle-process-services"
    "gradle-resources"
    "gradle-runtime-api-info"
    "gradle-tooling-api"
    "gradle-version-control"
    "gradle-worker-processes"
    "gradle-wrapper"
  ];
  builtPluginModules = [
    "gradle-antlr"
    "gradle-build-comparison"
    "gradle-build-init"
    "gradle-composite-builds"
    "gradle-dependency-management"
    "gradle-diagnostics"
    "gradle-ear"
    "gradle-ivy"
    "gradle-jacoco"
    "gradle-javascript"
    "gradle-language-jvm"
    "gradle-maven"
    "gradle-platform-base"
    "gradle-platform-jvm"
    "gradle-plugin-use"
    "gradle-publish"
    "gradle-reporting"
    "gradle-resources-http"
    "gradle-resources-sftp"
    "gradle-test-kit"
    "gradle-testing-base"
    "gradle-tooling-api-builders"
    "gradle-workers"
  ];
  implementationPluginModules = [ "gradle-tooling-api-builders" ];
}
