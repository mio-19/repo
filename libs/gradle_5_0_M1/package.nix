{
  gradle-legacy-bridge,
  gradle_4_10_3,
  jdk11_headless,
}:
gradle-legacy-bridge {
  version = "5.0-milestone-1";
  tag = "v5.0.0-M1";
  hash = "sha256-hmbktwjXBX04Y0n3pD8x9e4ZeOyX2va+tN/3R3Nkh30=";
  bootstrapGradle = gradle_4_10_3;
  jdk = jdk11_headless;
  patches = [
    ./bootstrap-compat.patch
    ./bootstrap-jdk11-compat.patch
  ];
  patchFlags = [ "-p1" ];

  preBuild = ''
    # Fix NativePlatformBackedSymlink.java
    sed -i 's/PosixFile.Type.Symlink/FileInfo.Type.Symlink/g' subprojects/native/src/main/java/org/gradle/internal/nativeintegration/filesystem/services/NativePlatformBackedSymlink.java
    sed -i 's/import net.rubygrapefruit.platform.PosixFile;/import net.rubygrapefruit.platform.FileInfo;/g' subprojects/native/src/main/java/org/gradle/internal/nativeintegration/filesystem/services/NativePlatformBackedSymlink.java

    # Fix AnsiConsoleUtil.java
    sed -i 's/CLibrary.CLIBRARY.isatty/isatty/g' subprojects/logging/src/main/java/org/gradle/internal/logging/sink/AnsiConsoleUtil.java
    sed -i '/import org.fusesource.jansi.internal.CLibrary;/a import static org.fusesource.jansi.internal.CLibrary.isatty;' subprojects/logging/src/main/java/org/gradle/internal/logging/sink/AnsiConsoleUtil.java

    # Fix ResolveExceptionAnalyzer.java
    sed -i '/import org.gradle.internal.resource.transport.http.HttpErrorStatusCodeException;/d' subprojects/dependency-management/src/main/java/org/gradle/internal/resolve/ResolveExceptionAnalyzer.java
    sed -i 's/.*rootCause instanceof HttpErrorStatusCodeException.*/return false;/g' subprojects/dependency-management/src/main/java/org/gradle/internal/resolve/ResolveExceptionAnalyzer.java

    # Disable problematic buildSrc subprojects and their usages
    find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i 's/include("performance")/\/\/include("performance")/g' {} +
    find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i 's/include("buildquality")/\/\/include("buildquality")/g' {} +
    find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i '/project(":performance")/d' {} +
    find . -type f \( -name "*.kts" -o -name "*.gradle" \) -exec sed -i '/project(":buildquality")/d' {} +

    # Fix Gradle API mismatch when compiling buildSrc with Gradle 4.10.3 runner
    sed -i 's/require("1.4.01")/prefer("1.4.01")/g' buildSrc/subprojects/configuration/src/main/kotlin/org/gradle/gradlebuild/dependencies/DependenciesMetadataRulesPlugin.kt

    # Wipe out failing GenerateDefaultImportsTask
    if [ -f buildSrc/subprojects/build/src/main/groovy/org/gradle/build/docs/dsl/source/GenerateDefaultImportsTask.java ]; then
      echo "package org.gradle.build.docs.dsl.source; import org.gradle.api.DefaultTask; public class GenerateDefaultImportsTask extends DefaultTask {}" > buildSrc/subprojects/build/src/main/groovy/org/gradle/build/docs/dsl/source/GenerateDefaultImportsTask.java
    fi

    # Disable tests and checks in buildSrc to avoid groovy version conflicts
    echo 'allprojects { tasks.matching { it.name.toLowerCase().contains("test") || it.name.toLowerCase().contains("check") || it.name.contains("ktlint") }.all { enabled = false } }' >> buildSrc/build.gradle.kts
  '';

  sourceSubprojects = [
    "api-metadata"
    "base-services"
    "base-services-groovy"
    "build-cache"
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
    "gradle-build-option"
    "gradle-cli"
    "gradle-core"
    "gradle-core-api"
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
  apiPluginModules = [
    "gradle-announce"
    "gradle-api-metadata"
    "gradle-base-services"
    "gradle-base-services-groovy"
    "gradle-build-cache"
    "gradle-build-cache-http"
    "gradle-build-cache-packaging"
    "gradle-build-comparison"
    "gradle-build-init"
    "gradle-build-option"
    "gradle-cli"
    "gradle-code-quality"
    "gradle-composite-builds"
    "gradle-core"
    "gradle-core-api"
    "gradle-dependency-management"
    "gradle-diagnostics"
    "gradle-ear"
    "gradle-execution"
    "gradle-files"
    "gradle-ide"
    "gradle-ide-native"
    "gradle-ide-play"
    "gradle-installation-beacon"
    "gradle-ivy"
    "gradle-jacoco"
    "gradle-javascript"
    "gradle-jvm-services"
    "gradle-language-groovy"
    "gradle-language-java"
    "gradle-language-jvm"
    "gradle-language-native"
    "gradle-language-scala"
    "gradle-launcher"
    "gradle-logging"
    "gradle-maven"
    "gradle-messaging"
    "gradle-model-core"
    "gradle-model-groovy"
    "gradle-native"
    "gradle-osgi"
    "gradle-persistent-cache"
    "gradle-platform-base"
    "gradle-platform-jvm"
    "gradle-platform-native"
    "gradle-platform-play"
    "gradle-plugin-development"
    "gradle-plugin-use"
    "gradle-plugins"
    "gradle-process-services"
    "gradle-publish"
    "gradle-reporting"
    "gradle-resources"
    "gradle-resources-gcs"
    "gradle-resources-http"
    "gradle-resources-s3"
    "gradle-resources-sftp"
    "gradle-scala"
    "gradle-signing"
    "gradle-snapshots"
    "gradle-testing-base"
    "gradle-testing-junit-platform"
    "gradle-testing-jvm"
    "gradle-testing-native"
    "gradle-tooling-api"
    "gradle-tooling-native"
    "gradle-version-control"
    "gradle-workers"
    "gradle-wrapper"
  ];
  implementationPluginModules = [ "gradle-tooling-api-builders" ];
}
