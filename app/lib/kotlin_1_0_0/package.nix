# github.com/ebourg/kotlin-bootstrapping
{
  ant,
  fetchFromGitHub,
  fetchgit,
  fetchurl,
  jdk8,
  lib,
  makeWrapper,
  stdenv,
  unzip,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kotlin";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "ebourg";
    repo = "kotlin-bootstrapping";
    rev = "2328eb7785d0f5537f2888e6813d81e85ca0eac5";
    hash = "sha256-Zu3RDBztCIEg1Jp7CnH7k/Rt89MkbCoG5TCp/6FTYVY=";
  };

  # ebourg/kotlin-bootstrapping uses one Git checkout and `git checkout build-*`
  # for every historical compiler.  Keep this stage as a plain source snapshot;
  # the next bootstrap steps can replace the prebuilt compiler zip with earlier
  # source-built Kotlin outputs.
  kotlinSrc = fetchFromGitHub {
    owner = "JetBrains";
    repo = "kotlin";
    tag = "build-${finalAttrs.version}";
    hash = "sha256-az4maYaBFJFvQ6ik6/qdu840yz3TBPG5nAFNM5sUI3I=";
  };

  kotlinIntellijPluginZip = fetchurl {
    url = "https://teamcity.jetbrains.com/guestAuth/repository/download/Kotlin_Rc_Idea142branch150versionNoTests/1.0.0-release-IJ143-78/kotlin-plugin-1.0.0-release-IJ143-78.zip";
    hash = "sha256-4tTZb2E6hrJSezGBBNHNWDdAHZfPnNSqcsywQMwIzdI=";
  };

  intellij143Src = fetchgit {
    url = "https://github.com/JetBrains/intellij-community";
    rev = "65d73acda17908887bd0cefbac22a2f36c2c7ef2";
    hash = "sha256-xZiKwE9UHXS9Wy75nK4XqkL3FlxwIsQe/DFchISXQdQ=";
  };

  jlineJar = fetchurl {
    url = "https://repo1.maven.org/maven2/jline/jline/2.12.1/jline-2.12.1.jar";
    hash = "sha256-wx8dzyzvRvim+K6orlwpXMlpEOj46kxAKRaV1k0ulA8=";
  };

  jansiJar = fetchurl {
    url = "https://repo1.maven.org/maven2/org/fusesource/jansi/jansi/1.11/jansi-1.11.jar";
    hash = "sha256-noIWPtL8Ylf+YnEyzlVHJueW7e5OXv6dnlI67iF9YLg=";
  };

  jarjarJar = fetchurl {
    url = "https://repo1.maven.org/maven2/org/sonatype/plugins/jarjar-maven-plugin/1.9/jarjar-maven-plugin-1.9.jar";
    hash = "sha256-zBBuZfcC0BHmJgSDBjMeTELNRaGl6z+OfNG8gROPkMU=";
  };

  asmJar = fetchurl {
    url = "https://repo1.maven.org/maven2/org/ow2/asm/asm/5.0.1/asm-5.0.1.jar";
    hash = "sha256-VgV0kMvB7q5iJ+brXG1bMkt3QpuKeNFQJ8d9SR75xnU=";
  };

  asmCommonsJar = fetchurl {
    url = "https://repo1.maven.org/maven2/org/ow2/asm/asm-commons/5.0.1/asm-commons-5.0.1.jar";
    hash = "sha256-+xy3+ifYknEs7Y+/jQJ+tQUuzTmZ26G6R4JDV6zLQOc=";
  };

  closureCompilerZip = fetchurl {
    url = "https://dl.google.com/closure-compiler/compiler-20131014.zip";
    hash = "sha256-6NSMUJeGlv3pA3lbId6fe6KK5MwHwm/wrl7sFRBZm7w=";
  };

  kotlinJdkAnnotationsJar = fetchurl {
    url = "https://teamcity.jetbrains.com/guestAuth/repository/download/Kotlin_KAnnotator_InferJdkAnnotations/shipWithKotlin.tcbuildtag/kotlin-jdk-annotations.jar";
    hash = "sha256-pLCHif/n05A27kNHsbVTmuvdsqevc59c3GSemn+0G2s=";
  };

  kotlinAndroidSdkAnnotationsJar = fetchurl {
    url = "https://teamcity.jetbrains.com/guestAuth/repository/download/Kotlin_KAnnotator_InferJdkAnnotations/shipWithKotlin.tcbuildtag/kotlin-android-sdk-annotations.jar";
    hash = "sha256-68ziQ2ByeaFv1EnQTouv9nkcyurYZDHvm8v7TcPqgq8=";
  };

  nativePlatformCommonJar = fetchurl {
    url = "https://repo.gradle.org/gradle/libs-releases/net/rubygrapefruit/native-platform/0.10/native-platform-0.10.jar";
    hash = "sha256-WwYqIGc54rsrpD6ho55IzVB/GQM//54p+As54j7SqZM=";
  };

  nativePlatformWindowsAmd64Jar = fetchurl {
    url = "https://repo.gradle.org/gradle/libs-releases/net/rubygrapefruit/native-platform-windows-amd64/0.10/native-platform-windows-amd64-0.10.jar";
    hash = "sha256-X9QVpb5MXTOH/6EpZEeoZcdKYy27qzTm6KeQhniWftQ=";
  };

  nativePlatformWindowsI386Jar = fetchurl {
    url = "https://repo.gradle.org/gradle/libs-releases/net/rubygrapefruit/native-platform-windows-i386/0.10/native-platform-windows-i386-0.10.jar";
    hash = "sha256-jktO6d3WVVK45yupdPXc63GlntcJqlEsS/TQ9YSy0jw=";
  };

  nativePlatformOsxAmd64Jar = fetchurl {
    url = "https://repo.gradle.org/gradle/libs-releases/net/rubygrapefruit/native-platform-osx-amd64/0.10/native-platform-osx-amd64-0.10.jar";
    hash = "sha256-fL46h06y4C3xsGIZtc6XM5oHe0GtOAeOf7WHUlfypa8=";
  };

  nativePlatformOsxI386Jar = fetchurl {
    url = "https://repo.gradle.org/gradle/libs-releases/net/rubygrapefruit/native-platform-osx-i386/0.10/native-platform-osx-i386-0.10.jar";
    hash = "sha256-9SaFQWlklsulzTUFFUW2de8UjZmZ7siPNLnqAOOvOjQ=";
  };

  nativePlatformLinuxAmd64Jar = fetchurl {
    url = "https://repo.gradle.org/gradle/libs-releases/net/rubygrapefruit/native-platform-linux-amd64/0.10/native-platform-linux-amd64-0.10.jar";
    hash = "sha256-2uZzlDsSuxrMZo4vWZy/FCc7xSbHVHnBJ2pejCvplvs=";
  };

  nativePlatformLinuxI386Jar = fetchurl {
    url = "https://repo.gradle.org/gradle/libs-releases/net/rubygrapefruit/native-platform-linux-i386/0.10/native-platform-linux-i386-0.10.jar";
    hash = "sha256-6gqfo4dIRaOGJA7hLTTrOI1xHVngiZZZ7BHGq69h1ao=";
  };

  nativePlatformFreebsdAmd64Jar = fetchurl {
    url = "https://repo.gradle.org/gradle/libs-releases/net/rubygrapefruit/native-platform-freebsd-amd64/0.10/native-platform-freebsd-amd64-0.10.jar";
    hash = "sha256-Ctaks2xkcamuifh2MSV9DMfeS4RnQDj1wLW11FQAHns=";
  };

  nativePlatformFreebsdI386Jar = fetchurl {
    url = "https://repo.gradle.org/gradle/libs-releases/net/rubygrapefruit/native-platform-freebsd-i386/0.10/native-platform-freebsd-i386-0.10.jar";
    hash = "sha256-SdgVah6tJ3KTdLhyb5J70lAqRPV88DEEeZ1J7WoTPLM=";
  };

  nativeBuildInputs = [
    ant
    jdk8
    makeWrapper
    unzip
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export JAVA_HOME=${jdk8}
    export JDK_16_x64=${jdk8}/lib/openjdk
    export JDK_18_x64=${jdk8}/lib/openjdk
    export _JAVA_OPTIONS="-Xbootclasspath/a:${jdk8}/lib/openjdk/lib/tools.jar"
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"

    cp -a ${finalAttrs.src}/. .
    chmod -R u+w .
    cp -a ${finalAttrs.kotlinSrc} kotlin
    chmod -R u+w kotlin
    mkdir -p build dependencies/download

    install -Dm644 ${finalAttrs.kotlinJdkAnnotationsJar} dependencies/kotlin-jdk-annotations.jar
    install -Dm644 ${finalAttrs.kotlinAndroidSdkAnnotationsJar} dependencies/kotlin-android-sdk-annotations.jar
    install -Dm644 ${finalAttrs.jarjarJar} dependencies/jarjar.jar
    install -Dm644 ${finalAttrs.asmJar} dependencies/asm.jar
    install -Dm644 ${finalAttrs.asmCommonsJar} dependencies/asm-commons.jar
    install -Dm644 ${finalAttrs.jansiJar} dependencies/jansi.jar
    install -Dm644 ${finalAttrs.jlineJar} dependencies/jline.jar
    install -Dm644 ${ant}/share/ant/lib/ant.jar dependencies/ant-1.8/lib/ant.jar
    unzip -p ${finalAttrs.closureCompilerZip} compiler.jar > dependencies/closure-compiler.jar

    mkdir -p dependencies/jarjar-extra
    (
      cd dependencies/jarjar-extra
      "''${JAVA_HOME}/bin/jar" xf ../asm.jar
      "''${JAVA_HOME}/bin/jar" xf ../asm-commons.jar
      "''${JAVA_HOME}/bin/jar" uf ../jarjar.jar org
    )

    mkdir -p dependencies/download/native-platform
    install -Dm644 ${finalAttrs.nativePlatformCommonJar} dependencies/download/native-platform/native-platform.jar
    install -Dm644 ${finalAttrs.nativePlatformWindowsAmd64Jar} dependencies/download/native-platform/native-platform-windows-amd64.jar
    install -Dm644 ${finalAttrs.nativePlatformWindowsI386Jar} dependencies/download/native-platform/native-platform-windows-i386.jar
    install -Dm644 ${finalAttrs.nativePlatformOsxAmd64Jar} dependencies/download/native-platform/native-platform-osx-amd64.jar
    install -Dm644 ${finalAttrs.nativePlatformOsxI386Jar} dependencies/download/native-platform/native-platform-osx-i386.jar
    install -Dm644 ${finalAttrs.nativePlatformLinuxAmd64Jar} dependencies/download/native-platform/native-platform-linux-amd64.jar
    install -Dm644 ${finalAttrs.nativePlatformLinuxI386Jar} dependencies/download/native-platform/native-platform-linux-i386.jar
    install -Dm644 ${finalAttrs.nativePlatformFreebsdAmd64Jar} dependencies/download/native-platform/native-platform-freebsd-amd64.jar
    install -Dm644 ${finalAttrs.nativePlatformFreebsdI386Jar} dependencies/download/native-platform/native-platform-freebsd-i386.jar

    mkdir -p dependencies/native-platform-uberjar
    (
      cd dependencies/native-platform-uberjar
      for jar in ../download/native-platform/*.jar; do
        "''${JAVA_HOME}/bin/jar" xf "$jar"
      done
      "''${JAVA_HOME}/bin/jar" cf ../native-platform-uberjar.jar .
    )

    build_intellij() {
      local src="$1"
      local patchName="$2"
      local outName="$3"
      local dropGradlePlugin="$4"

      rm -rf intellij-community
      cp -a "$src" intellij-community
      chmod -R u+w intellij-community

      (
        cd intellij-community
        patch -p1 < "${finalAttrs.src}/patches/$patchName"
        if [ "$dropGradlePlugin" = 1 ]; then
          rm -rf plugins/gradle
        fi
        mkdir -p build
        unzip -q ${finalAttrs.kotlinIntellijPluginZip} -d build/kotlin-plugin
        cp -a build/kotlin-plugin/Kotlin/kotlinc build/kotlinc
        chmod -R u+w build/kotlinc
        mkdir -p build/kotlinc/plugin build/kotlinc/jps
        cp -a build/kotlin-plugin/Kotlin build/kotlinc/plugin/Kotlin
        cp -a build/kotlin-plugin/Kotlin/lib/jps/. build/kotlinc/jps/
        mkdir -p community/build
        cp -a build/kotlinc community/build/kotlinc
        cp ${jdk8}/lib/openjdk/lib/tools.jar lib/ant/lib/tools.jar
        ant
        rm -rf out/classes out/dist.win.ce out/dist.mac.ce out/dist.all.ce/plugins
        rm -f out/artifacts/*.zip out/artifacts/*.tar.gz
        mv out "../build/$outName"
      )

      rm -rf intellij-community
    }

    build_intellij ${finalAttrs.intellij143Src} sdk-143.patch intellij-community-143 0

    mkdir -p build/kotlinc-bootstrap
    unzip -q ${finalAttrs.kotlinIntellijPluginZip} -d build/kotlinc-bootstrap-plugin
    cp -a build/kotlinc-bootstrap-plugin/Kotlin/kotlinc/. build/kotlinc-bootstrap/

    rm -rf kotlin
    cp -a ${finalAttrs.kotlinSrc} kotlin
    chmod -R u+w kotlin

    (
      cd kotlin
      rm -rf ideaSDK dependencies
      mkdir -p ideaSDK/lib ideaSDK/core ideaSDK/core-analysis ideaSDK/jps
      mkdir -p dependencies/ant-1.8/lib dependencies/annotations

      cp ../build/intellij-community-143/dist.all.ce/lib/javac2.jar                ideaSDK/lib
      cp ../build/intellij-community-143/dist.all.ce/lib/asm-all.jar               ideaSDK/lib/
      cp ../build/intellij-community-143/dist.all.ce/lib/asm-all.jar               ideaSDK/core/
      cp ../build/intellij-community-143/artifacts/core/annotations.jar            ideaSDK/core/
      cp ../build/intellij-community-143/artifacts/core/guava-17.0.jar             ideaSDK/core/
      cp ../build/intellij-community-143/artifacts/core/intellij-core.jar          ideaSDK/core/
      cp ../build/intellij-community-143/artifacts/core/intellij-core-analysis.jar ideaSDK/core-analysis/
      cp ../build/intellij-community-143/dist.all.ce/lib/jdom.jar                  ideaSDK/core/
      cp ../build/intellij-community-143/dist.all.ce/lib/protobuf-2.5.0.jar        ideaSDK/lib/
      cp ../build/intellij-community-143/dist.all.ce/lib/protobuf-2.5.0.jar        dependencies/protobuf-2.5.0-lite.jar
      cp ../build/intellij-community-143/artifacts/core/trove4j.jar                ideaSDK/core/
      cp ../build/intellij-community-143/artifacts/core/trove4j.jar                ideaSDK/jps/
      cp ../build/intellij-community-143/artifacts/core/cli-parser-1.1.jar         dependencies/cli-parser-1.1.1.jar
      cp ../build/intellij-community-143/artifacts/core/picocontainer.jar          ideaSDK/core/
      cp ../build/intellij-community-143/dist.all.ce/lib/log4j.jar                 ideaSDK/core/
      cp ../build/intellij-community-143/dist.all.ce/lib/log4j.jar                 ideaSDK/jps/
      cp ../build/intellij-community-143/dist.all.ce/lib/jps-model.jar             ideaSDK/jps/
      cp ../build/intellij-community-143/dist.all.ce/lib/jna-platform.jar          ideaSDK/lib/
      cp ../build/intellij-community-143/dist.all.ce/lib/oromatcher.jar            ideaSDK/lib/
      cp ../dependencies/kotlin-*-annotations.jar                                  dependencies/annotations/
      cp ../dependencies/jarjar.jar                                                dependencies/jarjar.jar
      cp ../dependencies/jansi.jar                                                 dependencies/jansi.jar
      cp ../dependencies/jline.jar                                                 dependencies/jline.jar
      cp ../dependencies/closure-compiler.jar                                      dependencies/closure-compiler.jar
      cp ../dependencies/native-platform-uberjar.jar                               dependencies/native-platform-uberjar.jar
      cp ../dependencies/ant-1.8/lib/ant.jar                                       dependencies/ant-1.8/lib/

      ANT_OPTS=-noverify ant \
        -Dshrink=false \
        -Dgenerate.javadoc=false \
        -Dbootstrap.build.no.tests=true \
        -Dbootstrap.compiler.home="$PWD/../build/kotlinc-bootstrap"

      mkdir -p ../build
      mv dist/kotlinc ../build/kotlin-1.0.0
    )

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    dist="build/kotlin-1.0.0"
    test -d "$dist"

    mkdir -p "$out/libexec"
    cp -a "$dist" "$out/libexec/kotlinc"
    chmod -R u+w "$out/libexec/kotlinc"
    patchShebangs "$out/libexec/kotlinc/bin"
    if [ ! -e "$out/libexec/kotlinc/lib/kotlin-stdlib.jar" ]; then
      cp "$out/libexec/kotlinc/lib/kotlin-runtime.jar" "$out/libexec/kotlinc/lib/kotlin-stdlib.jar"
    fi

    mkdir -p "$out/bin"
    makeWrapper "$out/libexec/kotlinc/bin/kotlinc" "$out/bin/kotlinc" --set-default JAVA_HOME ${jdk8}
    if [ -x "$out/libexec/kotlinc/bin/kotlin" ]; then
      makeWrapper "$out/libexec/kotlinc/bin/kotlin" "$out/bin/kotlin" --set-default JAVA_HOME ${jdk8}
    fi

    install -Dm644 "$out/libexec/kotlinc/lib/kotlin-compiler.jar" "$out/kotlin-compiler-${finalAttrs.version}.jar"
    install -Dm644 "$out/libexec/kotlinc/lib/kotlin-runtime.jar" "$out/kotlin-runtime-${finalAttrs.version}.jar"
    install -Dm644 "$out/libexec/kotlinc/lib/kotlin-stdlib.jar" "$out/kotlin-stdlib-${finalAttrs.version}.jar"
    install -Dm644 "$out/libexec/kotlinc/lib/kotlin-reflect.jar" "$out/kotlin-reflect-${finalAttrs.version}.jar"
    install -Dm644 "$out/libexec/kotlinc/lib/kotlin-test.jar" "$out/kotlin-test-${finalAttrs.version}.jar"

    install -Dm644 "${finalAttrs.kotlinSrc}/libraries/tools/kotlin-compiler/pom.xml" "$out/kotlin-compiler-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.kotlinSrc}/libraries/tools/runtime/pom.xml" "$out/kotlin-runtime-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.kotlinSrc}/libraries/stdlib/pom.xml" "$out/kotlin-stdlib-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.kotlinSrc}/libraries/tools/kotlin-reflect/pom.xml" "$out/kotlin-reflect-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.kotlinSrc}/libraries/kotlin.test/shared/pom.xml" "$out/kotlin-test-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.kotlinSrc}/libraries/kotlin.test/junit/pom.xml" "$out/kotlin-test-junit-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.kotlinSrc}/libraries/pom.xml" "$out/kotlin-project-${finalAttrs.version}.pom"
    install -Dm644 "${finalAttrs.kotlinSrc}/libraries/kotlin.test/pom.xml" "$out/kotlin-test-parent-${finalAttrs.version}.pom"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Kotlin 1.0.0 bootstrapped from source via the historical JetBrains compiler ladder";
    homepage = "https://github.com/ebourg/kotlin-bootstrapping";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [ fromSource ];
    mainProgram = "kotlinc";
    platforms = platforms.linux;
  };
})
