{
  buildMavenRepository,
  gradle-legacy-bridge,
  gradle_5_1_1,
  jdk11_headless,
}:
let
  kotlinBootstrapRepo = buildMavenRepository {
    dependencies = {
      "org.jetbrains:annotations:13.0:jar" = {
        layout = "org/jetbrains/annotations/13.0/annotations-13.0.jar";
        url = "https://repo1.maven.org/maven2/org/jetbrains/annotations/13.0/annotations-13.0.jar";
        hash = "sha256-rOKhDcji1f00kl7KwD5JiLLA+FFlDJS4zvSbob0RFHg=";
      };
      "org.jetbrains.intellij.deps:trove4j:1.0.20181211:jar" = {
        layout = "org/jetbrains/intellij/deps/trove4j/1.0.20181211/trove4j-1.0.20181211.jar";
        url = "https://repo1.maven.org/maven2/org/jetbrains/intellij/deps/trove4j/1.0.20181211/trove4j-1.0.20181211.jar";
        hash = "sha256-r/t8haPIe9z2n/HbuE3hH2PckxKTk0vAjNerGN4INgE=";
      };
      "org.jetbrains.kotlin:kotlin-stdlib-common:1.3.41:jar" = {
        layout = "org/jetbrains/kotlin/kotlin-stdlib-common/1.3.41/kotlin-stdlib-common-1.3.41.jar";
        url = "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-stdlib-common/1.3.41/kotlin-stdlib-common-1.3.41.jar";
        hash = "sha256-bJHeoX19zl8LVQw94zBXZ+X7RiR7bR637KDKH+GEWN4=";
      };
      "org.jetbrains.kotlin:kotlin-stdlib:1.3.41:jar" = {
        layout = "org/jetbrains/kotlin/kotlin-stdlib/1.3.41/kotlin-stdlib-1.3.41.jar";
        url = "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-stdlib/1.3.41/kotlin-stdlib-1.3.41.jar";
        hash = "sha256-bqPQkhsmkZsobwXL25BiZmZqNvmnwJYZcRT3SVcI/7w=";
      };
      "org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.3.41:jar" = {
        layout = "org/jetbrains/kotlin/kotlin-stdlib-jdk7/1.3.41/kotlin-stdlib-jdk7-1.3.41.jar";
        url = "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-stdlib-jdk7/1.3.41/kotlin-stdlib-jdk7-1.3.41.jar";
        hash = "sha256-JeJAmroOw30v18d3J9eDW1EYed6Nm/SGKvC0k6q7454=";
      };
      "org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.3.41:jar" = {
        layout = "org/jetbrains/kotlin/kotlin-stdlib-jdk8/1.3.41/kotlin-stdlib-jdk8-1.3.41.jar";
        url = "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-stdlib-jdk8/1.3.41/kotlin-stdlib-jdk8-1.3.41.jar";
        hash = "sha256-99u67j4IQXWBh6ITwFI4ik5hnhHIerFvS8Ipz+fOX+0=";
      };
      "org.jetbrains.kotlin:kotlin-reflect:1.3.41:jar" = {
        layout = "org/jetbrains/kotlin/kotlin-reflect/1.3.41/kotlin-reflect-1.3.41.jar";
        url = "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-reflect/1.3.41/kotlin-reflect-1.3.41.jar";
        hash = "sha256-AdRph4xoU6YHuqrfhpx0dLlxq+bdLLdPJEvqD/tFPHY=";
      };
      "org.jetbrains.kotlin:kotlin-script-runtime:1.3.41:jar" = {
        layout = "org/jetbrains/kotlin/kotlin-script-runtime/1.3.41/kotlin-script-runtime-1.3.41.jar";
        url = "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-script-runtime/1.3.41/kotlin-script-runtime-1.3.41.jar";
        hash = "sha256-rBhGEvJYtGC1r0ykf2vuC6sgpG+oGLhml7pB7yliajE=";
      };
      "org.jetbrains.kotlin:kotlin-compiler-embeddable:1.3.41:jar" = {
        layout = "org/jetbrains/kotlin/kotlin-compiler-embeddable/1.3.41/kotlin-compiler-embeddable-1.3.41.jar";
        url = "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-compiler-embeddable/1.3.41/kotlin-compiler-embeddable-1.3.41.jar";
        hash = "sha256-6mqwMoalNKsk8SO4RaEHx6U7Z59u5WvcNLXdGw/XtvQ=";
      };
      "org.jetbrains.kotlin:kotlin-scripting-compiler-embeddable:1.3.41:jar" = {
        layout = "org/jetbrains/kotlin/kotlin-scripting-compiler-embeddable/1.3.41/kotlin-scripting-compiler-embeddable-1.3.41.jar";
        url = "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-scripting-compiler-embeddable/1.3.41/kotlin-scripting-compiler-embeddable-1.3.41.jar";
        hash = "sha256-wtotGfVp6DacL1Wv+g3uX1B3G8NoVpfulI7imhbQw8E=";
      };
      "org.jetbrains.kotlin:kotlin-scripting-compiler-impl-embeddable:1.3.41:jar" = {
        layout = "org/jetbrains/kotlin/kotlin-scripting-compiler-impl-embeddable/1.3.41/kotlin-scripting-compiler-impl-embeddable-1.3.41.jar";
        url = "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-scripting-compiler-impl-embeddable/1.3.41/kotlin-scripting-compiler-impl-embeddable-1.3.41.jar";
        hash = "sha256-hUw5zdcFvgGVZDmucPRKeFzQumY4gpn5i8Cvddsyjyk=";
      };
      "org.jetbrains.kotlin:kotlin-sam-with-receiver-compiler-plugin:1.3.41:jar" = {
        layout = "org/jetbrains/kotlin/kotlin-sam-with-receiver-compiler-plugin/1.3.41/kotlin-sam-with-receiver-compiler-plugin-1.3.41.jar";
        url = "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-sam-with-receiver-compiler-plugin/1.3.41/kotlin-sam-with-receiver-compiler-plugin-1.3.41.jar";
        hash = "sha256-5Wh5ZAHTmQSsoG6iMSfdE7RPoSSDHDPIWV+IOw7INBM=";
      };
      "org.jetbrains.kotlinx:kotlinx-metadata-jvm:0.1.0:jar" = {
        layout = "org/jetbrains/kotlinx/kotlinx-metadata-jvm/0.1.0/kotlinx-metadata-jvm-0.1.0.jar";
        url = "https://repo1.maven.org/maven2/org/jetbrains/kotlinx/kotlinx-metadata-jvm/0.1.0/kotlinx-metadata-jvm-0.1.0.jar";
        hash = "sha256-l1O7Oe/vNZV8XBXfmjy3aaq/LN+nS0evy3dg5RRr47U=";
      };
    };
    pathMap1 = entry: builtins.baseNameOf entry.layout;
  };
in
gradle-legacy-bridge {
  version = "5.6.4";
  tag = "v5.6.4";
  hash = "sha256-sGLAyKn2PVIp4OBe1rvhU7Tact4cHvF9iaIlSZ4bGYE=";
  bootstrapGradle = gradle_5_1_1;
  inherit kotlinBootstrapRepo;
  jdk = jdk11_headless;
  kotlinDslVersion = "1.3.41";
  patches = [
    ./bootstrap-compat.patch
    ./bootstrap-logging-compat.patch
    ./bootstrap-jdk11-compat.patch
  ];
  patchFlags = [ "-p1" ];
  kotlinSourceSubprojects = [
    "kotlin-dsl"
    "kotlin-dsl-tooling-models"
  ];
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
    "language-java"
    "jvm-services"
    "instant-execution"
    "kotlin-dsl"
    "kotlin-dsl-provider-plugins"
    "kotlin-dsl-tooling-builders"
    "kotlin-dsl-tooling-models"
    "language-jvm"
    "launcher"
    "logging"
    "maven"
    "messaging"
    "model-core"
    "model-groovy"
    "native"
    "pineapple"
    "persistent-cache"
    "platform-base"
    "platform-jvm"
    "plugins"
    "plugin-use"
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
    "testing-jvm"
    "tooling-api"
    "tooling-api-builders"
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
    "gradle-instant-execution"
    "gradle-jvm-services"
    "gradle-kotlin-dsl"
    "gradle-kotlin-dsl-tooling-models"
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
    "gradle-language-java"
    "gradle-language-jvm"
    "gradle-maven"
    "gradle-platform-base"
    "gradle-platform-jvm"
    "gradle-plugin-development"
    "gradle-plugin-use"
    "gradle-plugins"
    "gradle-publish"
    "gradle-reporting"
    "gradle-resources-http"
    "gradle-resources-sftp"
    "gradle-test-kit"
    "gradle-testing-base"
    "gradle-testing-jvm"
    "gradle-kotlin-dsl-provider-plugins"
    "gradle-kotlin-dsl-tooling-builders"
    "gradle-tooling-api-builders"
    "gradle-workers"
  ];
  pluginClasspathModules = [ ];
  implementationPluginModules = [
    "gradle-kotlin-dsl-provider-plugins"
    "gradle-kotlin-dsl-tooling-builders"
    "gradle-tooling-api-builders"
  ];
}
