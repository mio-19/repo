{
  ant,
  jdk8,
  lib,
  stdenv,
  unzip,
  kotlin-bootstrap,
}:

let
  buildIntellij =
    {
      version,
      src,
      patchName ? "sdk-${version}.patch",
      dropGradlePlugin ? true,
    }:
    stdenv.mkDerivation {
      pname = "intellij-community";
      inherit version src;

      nativeBuildInputs = [
        ant
        jdk8
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

        # Use a fake JDK layout for Ant
        fakeJdk="$TMPDIR/fake-jdk"
        mkdir -p "$fakeJdk/lib"
        cp -a ${jdk8}/lib/openjdk/jre "$fakeJdk/jre"
        chmod -R u+w "$fakeJdk"
        rm -rf "$fakeJdk/jre/bin"
        ln -s ${jdk8}/lib/openjdk/bin "$fakeJdk/jre/bin"
        ln -s ${jdk8}/lib/openjdk/bin "$fakeJdk/bin"
        ln -s ${jdk8}/lib/openjdk/lib/tools.jar "$fakeJdk/lib/tools.jar"
        export _JAVA_OPTIONS="-Djava.home=$fakeJdk/jre"

        cp -a $src intellij-community
        chmod -R u+w intellij-community
        cd intellij-community

        if [ -f "${kotlin-bootstrap}/patches/${patchName}" ]; then
          patch -p1 < "${kotlin-bootstrap}/patches/${patchName}"
        fi

        if [ "${toString dropGradlePlugin}" = "1" ]; then
          rm -rf plugins/gradle
        fi

        cp ${jdk8}/lib/openjdk/lib/tools.jar lib/ant/lib/tools.jar

        # Apply common fixes for Nix build environment
        if [ -f jps/jps-builders/jps-builders.iml ]; then
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
        </orderEntry>' || true
        fi

        if [ -f jps/model-api/src/org/jetbrains/jps/model/java/JpsJavaSdkType.java ]; then
          substituteInPlace jps/model-api/src/org/jetbrains/jps/model/java/JpsJavaSdkType.java \
            --replace-fail 'import org.jetbrains.jps.model.library.sdk.JpsSdk;' 'import org.jetbrains.jps.model.library.sdk.JpsSdk;
    import java.io.File;' \
            --replace-fail 'return sdk.getHomePath() + "/bin/java";' 'String java = sdk.getHomePath() + "/bin/java";
        return new File(java).exists() ? java : sdk.getHomePath() + "/jre/bin/java";' || true
        fi

        if [ -f jps/jps-builders/src/org/jetbrains/jps/javac/JavacServerBootstrap.java ]; then
          substituteInPlace jps/jps-builders/src/org/jetbrains/jps/javac/JavacServerBootstrap.java \
            --replace-fail 'return sdkHome + "/bin/java";' 'String java = sdkHome + "/bin/java";
        return new File(java).exists() ? java : sdkHome + "/jre/bin/java";' || true
        fi

        if [ -f plugins/groovy/jps-plugin/src/org/jetbrains/jps/incremental/groovy/GroovyBuilder.java ]; then
          substituteInPlace plugins/groovy/jps-plugin/src/org/jetbrains/jps/incremental/groovy/GroovyBuilder.java \
            --replace-fail 'return SystemProperties.getJavaHome() + "/bin/java";' 'String java = SystemProperties.getJavaHome() + "/bin/java";
        return new File(java).exists() ? java : SystemProperties.getJavaHome() + "/../bin/java";' || true
        fi

        # Run Ant
        ${jdk8}/bin/java -classpath ${ant}/share/ant/lib/ant-launcher.jar org.apache.tools.ant.launch.Launcher

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out
        rm -rf out/classes out/artifacts/*.zip out/artifacts/*.tar.gz out/dist.win.ce out/dist.mac.ce out/dist.all.ce/plugins
        cp -a out/* $out/
        runHook postInstall
      '';
    };
in
{
  inherit buildIntellij;
}
