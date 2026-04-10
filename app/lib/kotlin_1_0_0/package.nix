# github.com/ebourg/kotlin-bootstrapping
{
  ant,
  fetchFromGitHub,
  fetchgit,
  fetchurl,
  git,
  gnumake,
  jdk8_headless,
  lib,
  makeWrapper,
  stdenv,
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

  kotlinSrc = fetchgit {
    url = "https://github.com/JetBrains/kotlin";
    rev = "8549ec7645ff6db4d5fede2c43034be66683561a";
    fetchTags = true;
    fetchSubmodules = false;
    leaveDotGit = true;
    hash = lib.fakeHash;
  };

  intellij133Src = fetchFromGitHub {
    owner = "JetBrains";
    repo = "intellij-community";
    tag = "133";
    hash = "sha256-9Vr0/PJ+OA+dGB0fj2LJT0voFNE1Fw6P+nj425APi0w=";
  };

  intellij134Src = fetchFromGitHub {
    owner = "JetBrains";
    repo = "intellij-community";
    rev = "1168c7b8cb4dc8318b8d24037b372141730a0d1f";
    hash = "sha256-aa3AWnZOMB4nf5STjk9oyQFK4SiNNW0SL3b3SXCNuOc=";
  };

  intellij135Src = fetchFromGitHub {
    owner = "JetBrains";
    repo = "intellij-community";
    tag = "135";
    hash = "sha256-qgAxjSbseEGQiiGW3Sf8dEmHdmWF7mqlzWN8ah2mp7c=";
  };

  intellij138Src = fetchFromGitHub {
    owner = "JetBrains";
    repo = "intellij-community";
    rev = "070c64f86da3bfd3c86f151c75aefeb4f67870c8";
    hash = "sha256-4+KHVA7rFMqp5f519D5PX1+9pPL61dUnJK5ksZP+6gE=";
  };

  intellij139Src = fetchFromGitHub {
    owner = "JetBrains";
    repo = "intellij-community";
    rev = "26e72feacf91bfb222bec00b3139ed05aa3084b5";
    hash = "sha256-TsdwIrXQvO8xDPQ1Hk2KhCBbd29FqFa9prOztkUVAVc=";
  };

  intellij141Src = fetchFromGitHub {
    owner = "JetBrains";
    repo = "intellij-community";
    tag = "141";
    hash = "sha256-9rRoWxELfusNsnPefV5hPrpw2ZBypCFNjtEAezQZur4=";
  };

  intellij143Src = fetchFromGitHub {
    owner = "JetBrains";
    repo = "intellij-community";
    tag = "143";
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
    git
    gnumake
    jdk8_headless
    makeWrapper
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export JAVA_HOME=${jdk8_headless}
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
    install -Dm644 ${finalAttrs.jansiJar} dependencies/jansi.jar
    install -Dm644 ${finalAttrs.jlineJar} dependencies/jline.jar
    install -Dm644 ${ant}/lib/ant.jar dependencies/ant-1.8/lib/ant.jar

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

    "''${JAVA_HOME}/bin/jar" cf dependencies/native-platform-uberjar.jar \
      -C dependencies/download/native-platform .

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
        ant
        rm -rf out/classes out/dist.win.ce out/dist.mac.ce out/dist.all.ce/plugins
        rm -f out/artifacts/*.zip out/artifacts/*.tar.gz
        mv out "../build/$outName"
      )

      rm -rf intellij-community
    }

    build_intellij ${finalAttrs.intellij133Src} sdk-133.patch intellij-community-133 1
    build_intellij ${finalAttrs.intellij134Src} sdk-134.patch intellij-community-134 0
    build_intellij ${finalAttrs.intellij135Src} sdk-135.patch intellij-community-135 0
    build_intellij ${finalAttrs.intellij138Src} sdk-138.patch intellij-community-138 0
    build_intellij ${finalAttrs.intellij139Src} sdk-139.patch intellij-community-139 0
    build_intellij ${finalAttrs.intellij141Src} sdk-141.patch intellij-community-141 0
    build_intellij ${finalAttrs.intellij143Src} sdk-143.patch intellij-community-143 0

    make build/kotlin-1.0.0

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

    mkdir -p "$out/bin"
    makeWrapper "$out/libexec/kotlinc/bin/kotlinc" "$out/bin/kotlinc" --set-default JAVA_HOME ${jdk8_headless}
    if [ -x "$out/libexec/kotlinc/bin/kotlin" ]; then
      makeWrapper "$out/libexec/kotlinc/bin/kotlin" "$out/bin/kotlin" --set-default JAVA_HOME ${jdk8_headless}
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
