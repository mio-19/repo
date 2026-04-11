{
  ant,
  fetchFromGitHub,
  fetchurl,
  jdk8,
  lib,
  makeWrapper,
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kotlin";
  version = "0.6.786";

  bootstrapSrc = fetchFromGitHub {
    owner = "ebourg";
    repo = "kotlin-bootstrapping";
    rev = "2328eb7785d0f5537f2888e6813d81e85ca0eac5";
    hash = "sha256-Zu3RDBztCIEg1Jp7CnH7k/Rt89MkbCoG5TCp/6FTYVY=";
  };

  src = fetchFromGitHub {
    owner = "JetBrains";
    repo = "kotlin";
    tag = "build-${finalAttrs.version}";
    hash = "sha256-EeMavn930d/i/sjutW6i1CRaZS+mNw/CkqfZdO/N8kU=";
  };

  intellij133Src = fetchFromGitHub {
    owner = "JetBrains";
    repo = "intellij-community";
    rev = "bc220ce6434e2fb0b0515e068b2c570b9a3a055e";
    hash = "sha256-9Vr0/PJ+OA+dGB0fj2LJT0voFNE1Fw6P+nj425APi0w=";
  };

  jlineJar = fetchurl {
    url = "https://repo1.maven.org/maven2/jline/jline/2.12.1/jline-2.12.1.jar";
    hash = "sha256-wx8dzyzvRvim+K6orlwpXMlpEOj46kxAKRaV1k0ulA8=";
  };

  antContribJar = fetchurl {
    url = "https://repo1.maven.org/maven2/ant-contrib/ant-contrib/1.0b3/ant-contrib-1.0b3.jar";
    hash = "sha256-vjOmmBgxC1xV5B3BHUjNiV9fEp2ksNKML0xsPhy88/w=";
  };

  nativeBuildInputs = [
    ant
    jdk8
    makeWrapper
  ];

  dontConfigure = true;

  buildPhase = ''
        runHook preBuild

        export JAVA_HOME=${jdk8}
        export JDK_16_x64=${jdk8}/lib/openjdk
        export JDK_18_x64=${jdk8}/lib/openjdk
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME" build
        fakeJdk="$TMPDIR/fake-jdk"
        mkdir -p "$fakeJdk/lib"
        cp -a ${jdk8}/lib/openjdk/jre "$fakeJdk/jre"
        chmod -R u+w "$fakeJdk"
        rm -rf "$fakeJdk/jre/bin"
        ln -s ${jdk8}/lib/openjdk/bin "$fakeJdk/jre/bin"
        ln -s ${jdk8}/lib/openjdk/bin "$fakeJdk/bin"
        ln -s ${jdk8}/lib/openjdk/lib/tools.jar "$fakeJdk/lib/tools.jar"
        export _JAVA_OPTIONS="-Djava.home=$fakeJdk/jre"
        ant() {
          ${jdk8}/bin/java -classpath ${ant}/share/ant/lib/ant-launcher.jar org.apache.tools.ant.launch.Launcher "$@"
        }

        cp -a ${finalAttrs.intellij133Src} intellij-community
        chmod -R u+w intellij-community
        (
          cd intellij-community
          patch -p1 < "${finalAttrs.bootstrapSrc}/patches/sdk-133.patch"
          rm -rf plugins/gradle
          cp ${jdk8}/lib/openjdk/lib/tools.jar lib/ant/lib/tools.jar
          substituteInPlace jps/jps-builders/jps-builders.iml \
            --replace-fail '<orderEntry type="inheritedJdk" />' '<orderEntry type="inheritedJdk" />
        <orderEntry type="module-library">
          <library>
            <CLASSES>
              <root url="jar://${jdk8}/lib/openjdk/lib/tools.jar!/" />
            </CLASSES>
            <JAVADOC />
            <SOURCES />
          </library>
        </orderEntry>'
          substituteInPlace jps/model-api/src/org/jetbrains/jps/model/java/JpsJavaSdkType.java \
            --replace-fail 'import org.jetbrains.jps.model.library.sdk.JpsSdk;' 'import org.jetbrains.jps.model.library.sdk.JpsSdk;

    import java.io.File;' \
            --replace-fail 'return sdk.getHomePath() + "/bin/java";' 'String java = sdk.getHomePath() + "/bin/java";
        return new File(java).exists() ? java : sdk.getHomePath() + "/jre/bin/java";'
          substituteInPlace jps/jps-builders/src/org/jetbrains/jps/javac/JavacServerBootstrap.java \
            --replace-fail 'return sdkHome + "/bin/java";' 'String java = sdkHome + "/bin/java";
        return new File(java).exists() ? java : sdkHome + "/jre/bin/java";'
          substituteInPlace plugins/groovy/jps-plugin/src/org/jetbrains/jps/incremental/groovy/GroovyBuilder.java \
            --replace-fail 'return SystemProperties.getJavaHome() + "/bin/java";' 'String java = SystemProperties.getJavaHome() + "/bin/java";
        return new File(java).exists() ? java : SystemProperties.getJavaHome() + "/../bin/java";'
          ant
          rm -rf out/classes out/artifacts/*.zip out/artifacts/*.tar.gz out/dist.win.ce out/dist.mac.ce out/dist.all.ce/plugins
          mv out ../build/intellij-community-133
        )

        cp -a ${finalAttrs.src} kotlin
        chmod -R u+w kotlin
        (
          cd kotlin
          patch -p1 < "${finalAttrs.bootstrapSrc}/patches/kotlin-${finalAttrs.version}.patch"
          substituteInPlace build.xml \
            --replace-fail '<typedef resource="org/jetbrains/jet/buildtools/ant/antlib.xml" classpath="''${boostrap.compiler.home}/lib/kotlin-ant.jar"/>' '<!-- bootstrap seed: no Kotlin Ant task is used -->'
          rm -rf ideaSDK dependencies
          mkdir -p ideaSDK/lib ideaSDK/core ideaSDK/jps dependencies/ant

          cp ../build/intellij-community-133/dist.all.ce/lib/javac2.jar         ideaSDK/lib
          cp ../build/intellij-community-133/dist.all.ce/lib/asm4-all.jar       ideaSDK/lib/jetbrains-asm-debug-all-4.0.jar
          cp ../build/intellij-community-133/dist.all.ce/lib/asm4-all.jar       ideaSDK/jps/jetbrains-asm-debug-all-4.0.jar
          cp ../build/intellij-community-133/dist.all.ce/lib/asm4-all.jar       ideaSDK/core/jetbrains-asm-debug-all-4.0.jar
          cp ../build/intellij-community-133/artifacts/core/annotations.jar     ideaSDK/core/
          cp ../build/intellij-community-133/artifacts/core/guava-14.0.1.jar    ideaSDK/core/
          cp ../build/intellij-community-133/artifacts/core/intellij-core.jar   ideaSDK/core/
          cp ../build/intellij-community-133/artifacts/jps/protobuf-2.5.0.jar   ideaSDK/lib/
          cp ../build/intellij-community-133/artifacts/jps/trove4j.jar          ideaSDK/core/
          cp ../build/intellij-community-133/artifacts/jps/trove4j.jar          ideaSDK/jps/
          cp ../build/intellij-community-133/artifacts/core/cli-parser-1.1.jar  dependencies/cli-parser-1.1.1.jar
          cp ../build/intellij-community-133/artifacts/core/picocontainer.jar   ideaSDK/core/
          cp ${finalAttrs.jlineJar} dependencies/jline.jar
          cp ${finalAttrs.antContribJar} dependencies/ant-contrib.jar
          cp ${ant}/share/ant/lib/ant.jar dependencies/

          ant -Dshrink=false -Dgenerate.javadoc=false
          mkdir -p ../build
          mv dist/kotlinc ../build/kotlin-${finalAttrs.version}
        )

        runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    dist="build/kotlin-${finalAttrs.version}"
    test -d "$dist"

    mkdir -p "$out/libexec"
    cp -a "$dist" "$out/libexec/kotlinc"
    chmod -R u+w "$out/libexec/kotlinc"
    patchShebangs "$out/libexec/kotlinc/bin"

    mkdir -p "$out/bin"
    makeWrapper "$out/libexec/kotlinc/bin/kotlinc-jvm" "$out/bin/kotlinc" --set-default JAVA_HOME ${jdk8}
    makeWrapper "$out/libexec/kotlinc/bin/kotlinc-jvm" "$out/bin/kotlinc-jvm" --set-default JAVA_HOME ${jdk8}
    if [ -x "$out/libexec/kotlinc/bin/kotlinc-js" ]; then
      makeWrapper "$out/libexec/kotlinc/bin/kotlinc-js" "$out/bin/kotlinc-js" --set-default JAVA_HOME ${jdk8}
    fi
    if [ -x "$out/libexec/kotlinc/bin/kotlin" ]; then
      makeWrapper "$out/libexec/kotlinc/bin/kotlin" "$out/bin/kotlin" --set-default JAVA_HOME ${jdk8}
    fi

    install -Dm644 "$out/libexec/kotlinc/lib/kotlin-compiler.jar" "$out/kotlin-compiler-${finalAttrs.version}.jar"
    install -Dm644 "$out/libexec/kotlinc/lib/kotlin-runtime.jar" "$out/kotlin-runtime-${finalAttrs.version}.jar"

    cat > "$out/kotlin-compiler-${finalAttrs.version}.pom" <<EOF
    <project>
      <modelVersion>4.0.0</modelVersion>
      <groupId>org.jetbrains.kotlin</groupId>
      <artifactId>kotlin-compiler</artifactId>
      <version>${finalAttrs.version}</version>
    </project>
    EOF
    cat > "$out/kotlin-runtime-${finalAttrs.version}.pom" <<EOF
    <project>
      <modelVersion>4.0.0</modelVersion>
      <groupId>org.jetbrains.kotlin</groupId>
      <artifactId>kotlin-runtime</artifactId>
      <version>${finalAttrs.version}</version>
    </project>
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "Last Kotlin compiler buildable without an existing Kotlin compiler";
    homepage = "https://github.com/ebourg/kotlin-bootstrapping";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [ fromSource ];
    mainProgram = "kotlinc";
    platforms = platforms.linux;
  };
})
