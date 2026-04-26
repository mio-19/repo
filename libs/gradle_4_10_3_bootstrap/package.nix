{
  callPackage,
  fetchFromGitHub,
  gradle-packages,
  gradle_4_9_0,
  jdk11_headless,
  jdk8_headless,
  makeWrapper,
  runtimeShell,
  stdenv,
  unzip,
}:
let
  mkGradle' =
    {
      fetchFromGitHub,
      gradle_4_9_0,
      jdk11_headless,
      jdk8_headless,
      makeWrapper,
      runtimeShell,
      stdenv,
      unzip,
      ...
    }:
    let
      gradleRunner = gradle_4_9_0;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "gradle-unwrapped";
      version = "4.10.3";

      src = fetchFromGitHub {
        owner = "gradle";
        repo = "gradle";
        tag = "v4.10.3";
        hash = "sha256-rpvkNqSdInehucshyQb4X1ZpROkx8n9hga95L8XkKTk=";
      };

      patches = [ ./bootstrap-gradle4_9.patch ];

      gradleBuildTask = ":distributions:binZip";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      nativeBuildInputs = [
        gradleRunner
        jdk11_headless
        jdk8_headless
        makeWrapper
        unzip
      ];

      mitmCache = gradleRunner.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./deps.json;
        silent = false;
        useBwrap = false;
      };

      __darwinAllowLocalNetworking = true;

      jdk = jdk8_headless;
      env.JAVA_HOME = jdk8_headless.passthru.home;

      preBuild = ''
        export HOME="$PWD/.home"
        export GRADLE_USER_HOME="$HOME/.gradle"
        mkdir -p "$GRADLE_USER_HOME"
        cat > "$GRADLE_USER_HOME/gradle.properties" <<'EOF'
        org.gradle.daemon=false
        org.gradle.jvmargs=-Xmx1024m -Dfile.encoding=UTF-8
        EOF
        export gradleInitScript="$PWD/init-build-compat.gradle"
        cat > "$gradleInitScript" <<'EOF'
        gradle.projectsLoaded {
          rootProject.allprojects {
            tasks.withType(AbstractArchiveTask) {
              if (it.hasProperty('preserveFileTimestamps')) {
                preserveFileTimestamps = false
              }
              if (it.hasProperty('reproducibleFileOrder')) {
                reproducibleFileOrder = true
              }
            }
          }
        }
        EOF
        filteredGradleFlagsArray=()
        skipNext=
        for arg in "''${gradleFlagsArray[@]}"; do
          if [ -n "$skipNext" ]; then
            skipNext=
            continue
          fi
          if [ "$arg" = "--init-script" ]; then
            skipNext=1
            continue
          fi
          filteredGradleFlagsArray+=("$arg")
        done
        gradleFlagsArray=("''${filteredGradleFlagsArray[@]}" --init-script "$gradleInitScript")
      '';

      gradleFlags = [
        "-x"
        ":docs:distDocs"
        "-x"
        ":docs:samples"
        "-PfinalRelease=true"
        "-PpromotionCommitId=v4.10.3"
        "-Pjava9Home=${jdk11_headless.passthru.home}"
        "-Djava9Home=${jdk11_headless.passthru.home}"
        "-Dfile.encoding=UTF-8"
        "-DbootstrapWithGradle4_9_0=true"
      ];

      postPatch = ''
        rm -f gradle/verification-metadata.xml
        rm -rf gradle/wrapper .teamcity/.mvn/wrapper
        find . -name "*.jar" -print0 | xargs -0 rm -f
      '';

      gradleUpdateScript = ''
        runHook preBuild
        tmpbin="$(mktemp -d)"
        tee > "$tmpbin/gradlecustom" <<EOF
        #!${runtimeShell}
        exec ${gradleRunner}/bin/gradle ''${gradleFlags[@]} ''${gradleFlagsArray[@]} "\$@"
        EOF
        chmod +x "$tmpbin/gradlecustom"
        export PATH="$tmpbin:$PATH"
        gradlecustom ${finalAttrs.gradleUpdateTask}
        runHook postGradleUpdate
      '';

      buildPhase = ''
        runHook preBuild
        tmpbin="$(mktemp -d)"
        tee > "$tmpbin/gradlecustom" <<EOF
        #!${runtimeShell}
        exec ${gradleRunner}/bin/gradle ''${gradleFlags[@]} ''${gradleFlagsArray[@]} "\$@"
        EOF
        chmod +x "$tmpbin/gradlecustom"
        export PATH="$tmpbin:$PATH"
        gradlecustom ${finalAttrs.gradleBuildTask}
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        distZip="$(find . -path '*/build/distributions/gradle-*-bin.zip' | head -n1)"
        test -n "$distZip"
        test -f "$distZip"

        mkdir dist-unpack
        unzip -q "$distZip" -d dist-unpack
        cd dist-unpack/gradle-*

        mkdir -p "$out/libexec/gradle" "$out/bin"
        mv lib "$out/libexec/gradle/"
        mv bin "$out/libexec/gradle/"
        for jar in "$out"/libexec/gradle/lib/plugins/gradle-resources-http-*.jar "$out"/libexec/gradle/lib/plugins/gradle-resources-sftp-*.jar "$out"/libexec/gradle/lib/plugins/httpclient-*.jar "$out"/libexec/gradle/lib/plugins/httpcore-*.jar "$out"/libexec/gradle/lib/plugins/jsch-*.jar; do
          if [ -e "$jar" ]; then
            mv "$jar" "$out/libexec/gradle/lib/"
          fi
        done
        substituteInPlace "$out/libexec/gradle/bin/gradle" \
          --replace-fail \
            'CLASSPATH=$APP_HOME/lib/gradle-launcher-4.10.3.jar' \
            'CLASSPATH=$APP_HOME/lib/gradle-launcher-4.10.3.jar:$APP_HOME/lib/*:$APP_HOME/lib/plugins/*'

        makeWrapper "$out/libexec/gradle/bin/gradle" "$out/bin/gradle" \
          --set-default JAVA_HOME "${finalAttrs.env.JAVA_HOME}"

        runHook postInstall
      '';

      passthru = {
        inherit (finalAttrs) jdk mitmCache;
        tests = { };
      };
    });

  unwrapped = callPackage mkGradle' { };
in
(callPackage gradle-packages.wrapGradle {
  gradle-unwrapped = unwrapped;
}).overrideAttrs
  (old: {
    passthru = old.passthru // {
      inherit (unwrapped) mitmCache;
    };
  })
