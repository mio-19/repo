{
  gradle-legacy-bridge,
  gradle_5_0,
  jdk11_headless,
}:
gradle-legacy-bridge {
  version = "5.1.1";
  tag = "v5.1.1";
  hash = "sha256-n5OsljYVVO+JBY1IdVX9FyVD7rZU2Cowdg34thEGH78=";
  bootstrapGradle = gradle_5_0;
  jdk = jdk11_headless;
  patches = [
    ../gradle_5_0/bootstrap-compat.patch
    ../gradle_5_0/bootstrap-jdk11-compat.patch
    ./bootstrap-jdk11-compat.patch
  ];
  patchFlags = [ "-p1" ];
  sourceSubprojects = [
    "antlr"
    "api-metadata"
    "base-services"
    "base-services-groovy"
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
    "files"
    "installation-beacon"
    "ivy"
    "jacoco"
    "javascript"
    "jvm-services"
    "language-jvm"
    "launcher"
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
    "process-services"
    "publish"
    "reporting"
    "resources"
    "resources-sftp"
    "runtime-api-info"
    "snapshots"
    "test-kit"
    "testing-base"
    "tooling-api"
    "tooling-api-builders"
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
    "gradle-files"
    "gradle-installation-beacon"
    "gradle-jvm-services"
    "gradle-launcher"
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
    "gradle-resources-sftp"
    "gradle-test-kit"
    "gradle-testing-base"
    "gradle-tooling-api-builders"
    "gradle-workers"
  ];
  implementationPluginModules = [ "gradle-tooling-api-builders" ];
}
