{
  ant,
  buildMavenRepository,
  jdk8,
  lib,
  makeWrapper,
  stdenv,
  unzip,
  kotlin-bootstrap,
}:

let
  bootstrapJars = buildMavenRepository {
    dependencies = {
      "jline:jline:2.12.1:jar" = {
        url = "https://repo1.maven.org/maven2/jline/jline/2.12.1/jline-2.12.1.jar";
        hash = "sha256-wx8dzyzvRvim+K6orlwpXMlpEOj46kxAKRaV1k0ulA8=";
        layout = "jline/jline/2.12.1/jline-2.12.1.jar";
      };
      "org.fusesource.jansi:jansi:1.11:jar" = {
        url = "https://repo1.maven.org/maven2/org/fusesource/jansi/jansi/1.11/jansi-1.11.jar";
        hash = "sha256-noIWPtL8Ylf+YnEyzlVHJueW7e5OXv6dnlI67iF9YLg=";
        layout = "org/fusesource/jansi/jansi/1.11/jansi-1.11.jar";
      };
      "org.sonatype.plugins:jarjar-maven-plugin:1.9:jar" = {
        url = "https://repo1.maven.org/maven2/org/sonatype/plugins/jarjar-maven-plugin/1.9/jarjar-maven-plugin-1.9.jar";
        hash = "sha256-zBBuZfcC0BHmJgSDBjMeTELNRaGl6z+OfNG8gROPkMU=";
        layout = "org/sonatype/plugins/jarjar-maven-plugin/1.9/jarjar-maven-plugin-1.9.jar";
      };
      "ant-contrib:ant-contrib:1.0b3:jar" = {
        url = "https://repo1.maven.org/maven2/ant-contrib/ant-contrib/1.0b3/ant-contrib-1.0b3.jar";
        hash = "sha256-vjOmmBgxC1xV5B3BHUjNiV9fEp2ksNKML0xsPhy88/w=";
        layout = "ant-contrib/ant-contrib/1.0b3/ant-contrib-1.0b3.jar";
      };
      "kotlin:kotlin-jdk-annotations:1.0:jar" = {
        url = "https://teamcity.jetbrains.com/guestAuth/repository/download/Kotlin_KAnnotator_InferJdkAnnotations/shipWithKotlin.tcbuildtag/kotlin-jdk-annotations.jar";
        hash = "sha256-pLCHif/n05A27kNHsbVTmuvdsqevc59c3GSemn+0G2s=";
        layout = "kotlin/kotlin-jdk-annotations/1.0/kotlin-jdk-annotations-1.0.jar";
      };
      "kotlin:kotlin-android-sdk-annotations:1.0:jar" = {
        url = "https://teamcity.jetbrains.com/guestAuth/repository/download/Kotlin_KAnnotator_InferJdkAnnotations/shipWithKotlin.tcbuildtag/kotlin-android-sdk-annotations.jar";
        hash = "sha256-68ziQ2ByeaFv1EnQTouv9nkcyurYZDHvm8v7TcPqgq8=";
        layout = "kotlin/kotlin-android-sdk-annotations/1.0/kotlin-android-sdk-annotations-1.0.jar";
      };
      "net.rubygrapefruit:native-platform:0.10:jar" = {
        url = "https://repo.gradle.org/gradle/libs-releases/net/rubygrapefruit/native-platform/0.10/native-platform-0.10.jar";
        hash = "sha256-WwYqIGc54rsrpD6ho55IzVB/GQM//54p+As54j7SqZM=";
        layout = "net/rubygrapefruit/native-platform/0.10/native-platform-0.10.jar";
      };
      "net.rubygrapefruit:native-platform-linux-amd64:0.10:jar" = {
        url = "https://repo.gradle.org/gradle/libs-releases/net/rubygrapefruit/native-platform-linux-amd64/0.10/native-platform-linux-amd64-0.10.jar";
        hash = "sha256-2uZzlDsSuxrMZo4vWZy/FCc7xSbHVHnBJ2pejCvplvs=";
        layout = "net/rubygrapefruit/native-platform-linux-amd64/0.10/native-platform-linux-amd64-0.10.jar";
      };
    };
  };

  buildKotlin =
    {
      version,
      src,
      intellijSdk,
      bootstrapCompiler ? null,
    }:
    stdenv.mkDerivation {
      pname = "kotlin";
      inherit version src;

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
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"

        # Use a fake JDK layout
        fakeJdk="$TMPDIR/fake-jdk"
        mkdir -p "$fakeJdk/lib"
        cp -a ${jdk8}/lib/openjdk/jre "$fakeJdk/jre"
        chmod -R u+w "$fakeJdk"
        rm -rf "$fakeJdk/jre/bin"
        ln -s ${jdk8}/lib/openjdk/bin "$fakeJdk/jre/bin"
        ln -s ${jdk8}/lib/openjdk/bin "$fakeJdk/bin"
        ln -s ${jdk8}/lib/openjdk/lib/tools.jar "$fakeJdk/lib/tools.jar"
        export _JAVA_OPTIONS="-Djava.home=$fakeJdk/jre"

        cp -a $src kotlin
        chmod -R u+w kotlin
        cd kotlin

        if [ -f "${kotlin-bootstrap}/patches/kotlin-''${version}.patch" ]; then
          patch -p1 < "${kotlin-bootstrap}/patches/kotlin-''${version}.patch"
        fi

        # Setup ideaSDK and dependencies as expected by Kotlin's build.xml
        rm -rf ideaSDK dependencies
        mkdir -p ideaSDK/lib ideaSDK/core ideaSDK/core-analysis ideaSDK/jps dependencies/ant dependencies/annotations

        # Most versions use this layout
        cp ${intellijSdk}/dist.all.ce/lib/javac2.jar         ideaSDK/lib/ || cp ${intellijSdk}/lib/javac2.jar ideaSDK/lib/ || true
        cp ${intellijSdk}/dist.all.ce/lib/jdom.jar           ideaSDK/core/ || true
        cp ${intellijSdk}/dist.all.ce/lib/jna-platform.jar   ideaSDK/lib/ || true
        cp ${intellijSdk}/dist.all.ce/lib/oromatcher.jar     ideaSDK/lib/ || true
        cp ${intellijSdk}/dist.all.ce/lib/jps-model.jar      ideaSDK/jps/ || true
        cp ${intellijSdk}/artifacts/core/intellij-core-analysis.jar ideaSDK/core-analysis/ || true
        
        # ASM naming changes between SDK versions
        if [ -f ${intellijSdk}/dist.all.ce/lib/asm4-all.jar ]; then
          cp ${intellijSdk}/dist.all.ce/lib/asm4-all.jar       ideaSDK/lib/jetbrains-asm-debug-all-4.0.jar
          cp ${intellijSdk}/dist.all.ce/lib/asm4-all.jar       ideaSDK/jps/jetbrains-asm-debug-all-4.0.jar
          cp ${intellijSdk}/dist.all.ce/lib/asm4-all.jar       ideaSDK/core/jetbrains-asm-debug-all-4.0.jar
        elif [ -f ${intellijSdk}/dist.all.ce/lib/asm-all.jar ]; then
          cp ${intellijSdk}/dist.all.ce/lib/asm-all.jar       ideaSDK/lib/
          cp ${intellijSdk}/dist.all.ce/lib/asm-all.jar       ideaSDK/core/
        fi

        cp ${intellijSdk}/artifacts/core/annotations.jar     ideaSDK/core/ || true
        cp ${intellijSdk}/artifacts/core/guava-*.jar         ideaSDK/core/ || true
        cp ${intellijSdk}/artifacts/core/intellij-core.jar   ideaSDK/core/ || true
        cp ${intellijSdk}/artifacts/jps/protobuf-2.5.0.jar   ideaSDK/lib/ || cp ${intellijSdk}/dist.all.ce/lib/protobuf-2.5.0.jar ideaSDK/lib/ || true
        cp ${intellijSdk}/artifacts/jps/log4j.jar            ideaSDK/core/ || cp ${intellijSdk}/dist.all.ce/lib/log4j.jar ideaSDK/core/ || true
        cp ${intellijSdk}/artifacts/jps/log4j.jar            ideaSDK/jps/ || cp ${intellijSdk}/dist.all.ce/lib/log4j.jar ideaSDK/jps/ || true
        cp ${intellijSdk}/artifacts/jps/trove4j.jar          ideaSDK/core/ || cp ${intellijSdk}/artifacts/core/trove4j.jar ideaSDK/core/ || cp ${intellijSdk}/dist.all.ce/lib/trove4j.jar ideaSDK/core/ || true
        cp ${intellijSdk}/artifacts/jps/trove4j.jar          ideaSDK/jps/ || cp ${intellijSdk}/dist.all.ce/lib/trove4j.jar ideaSDK/jps/ || true
        cp ${intellijSdk}/artifacts/core/cli-parser-1.1.jar  dependencies/cli-parser-1.1.1.jar || true
        cp ${intellijSdk}/artifacts/core/picocontainer.jar   ideaSDK/core/ || true
        
        cp ${bootstrapJars}/jline/jline/2.12.1/jline-2.12.1.jar dependencies/jline.jar
        cp ${bootstrapJars}/org/fusesource/jansi/jansi/1.11/jansi-1.11.jar dependencies/jansi.jar
        cp ${bootstrapJars}/org/sonatype/plugins/jarjar-maven-plugin/1.9/jarjar-maven-plugin-1.9.jar dependencies/jarjar.jar
        cp ${bootstrapJars}/ant-contrib/ant-contrib/1.0b3/ant-contrib-1.0b3.jar dependencies/ant-contrib.jar
        cp ${bootstrapJars}/kotlin/kotlin-jdk-annotations/1.0/kotlin-jdk-annotations-1.0.jar dependencies/annotations/kotlin-jdk-annotations.jar
        cp ${bootstrapJars}/kotlin/kotlin-android-sdk-annotations/1.0/kotlin-android-sdk-annotations-1.0.jar dependencies/annotations/kotlin-android-sdk-annotations.jar
        
        # Native platform uberjar
        mkdir -p native-platform-tmp
        (
          cd native-platform-tmp
          "''${JAVA_HOME}/bin/jar" xf ${bootstrapJars}/net/rubygrapefruit/native-platform/0.10/native-platform-0.10.jar
          "''${JAVA_HOME}/bin/jar" xf ${bootstrapJars}/net/rubygrapefruit/native-platform-linux-amd64/0.10/native-platform-linux-amd64-0.10.jar
          "''${JAVA_HOME}/bin/jar" cf ../dependencies/native-platform-uberjar.jar .
        )

        cp ${ant}/share/ant/lib/ant.jar dependencies/ant.jar || true
        mkdir -p dependencies/ant-1.7/lib dependencies/ant-1.8/lib
        cp ${ant}/share/ant/lib/ant.jar dependencies/ant-1.7/lib/
        cp ${ant}/share/ant/lib/ant.jar dependencies/ant-1.8/lib/

        # For the very first version (0.6.786), we don't have a bootstrap compiler
        if [ -z "${if bootstrapCompiler == null then "" else "1"}" ]; then
           substituteInPlace build.xml \
            --replace-fail '<typedef resource="org/jetbrains/jet/buildtools/ant/antlib.xml" classpath="''${boostrap.compiler.home}/lib/kotlin-ant.jar"/>' '<!-- bootstrap seed: no Kotlin Ant task is used -->' || true
           ${jdk8}/bin/java -classpath ${ant}/share/ant/lib/ant-launcher.jar org.apache.tools.ant.launch.Launcher -Dshrink=false -Dgenerate.javadoc=false
        else
           # Use bootstrap compiler
           ${jdk8}/bin/java -classpath ${ant}/share/ant/lib/ant-launcher.jar org.apache.tools.ant.launch.Launcher \
             -Dshrink=false \
             -Dgenerate.javadoc=false \
             -Dbootstrap.compiler.home=${if bootstrapCompiler == null then "" else bootstrapCompiler}/libexec/kotlinc \
             -Dbootstrap.build.no.tests=true
        fi

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p "$out/libexec"
        cp -a dist/kotlinc "$out/libexec/kotlinc"
        chmod -R u+w "$out/libexec/kotlinc"
        patchShebangs "$out/libexec/kotlinc/bin"

        mkdir -p "$out/bin"
        # Kotlin < 1.0.0 had different bin names
        if [ -f "$out/libexec/kotlinc/bin/kotlinc-jvm" ]; then
          makeWrapper "$out/libexec/kotlinc/bin/kotlinc-jvm" "$out/bin/kotlinc" --set-default JAVA_HOME ${jdk8}
          makeWrapper "$out/libexec/kotlinc/bin/kotlinc-jvm" "$out/bin/kotlinc-jvm" --set-default JAVA_HOME ${jdk8}
        else
          makeWrapper "$out/libexec/kotlinc/bin/kotlinc" "$out/bin/kotlinc" --set-default JAVA_HOME ${jdk8}
        fi

        if [ -f "$out/libexec/kotlinc/bin/kotlin" ]; then
          makeWrapper "$out/libexec/kotlinc/bin/kotlin" "$out/bin/kotlin" --set-default JAVA_HOME ${jdk8}
        fi

        install -Dm644 "$out/libexec/kotlinc/lib/kotlin-compiler.jar" "$out/kotlin-compiler-''${version}.jar"
        install -Dm644 "$out/libexec/kotlinc/lib/kotlin-runtime.jar" "$out/kotlin-runtime-''${version}.jar" || install -Dm644 "$out/libexec/kotlinc/lib/kotlin-stdlib.jar" "$out/kotlin-stdlib-''${version}.jar"
        if [ -f "$out/libexec/kotlinc/lib/kotlin-stdlib.jar" ]; then
          install -Dm644 "$out/libexec/kotlinc/lib/kotlin-stdlib.jar" "$out/kotlin-stdlib-''${version}.jar"
        fi
        if [ -f "$out/libexec/kotlinc/lib/kotlin-reflect.jar" ]; then
          install -Dm644 "$out/libexec/kotlinc/lib/kotlin-reflect.jar" "$out/kotlin-reflect-''${version}.jar"
        fi
        if [ -f "$out/libexec/kotlinc/lib/kotlin-test.jar" ]; then
          install -Dm644 "$out/libexec/kotlinc/lib/kotlin-test.jar" "$out/kotlin-test-''${version}.jar"
        fi

        # Simple POMs
        for art in compiler runtime stdlib reflect test; do
          if [ -f "$out/kotlin-$art-''${version}.jar" ]; then
            cat > "$out/kotlin-$art-''${version}.pom" <<EOF
<project>
  <modelVersion>4.0.0</modelVersion>
  <groupId>org.jetbrains.kotlin</groupId>
  <artifactId>kotlin-$art</artifactId>
  <version>''${version}</version>
</project>
EOF
          fi
        done

        runHook postInstall
      '';
    };
in
{
  inherit buildKotlin;
}
