{
  callPackage,
  fetchFromGitHub,
  fetchurl,
  gradle-packages,
  gradle_4_10_3_bootstrap,
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
      fetchurl,
      gradle_4_10_3_bootstrap,
      jdk11_headless,
      jdk8_headless,
      makeWrapper,
      runtimeShell,
      stdenv,
      unzip,
      ...
    }:
    let
      gradleRunner = gradle_4_10_3_bootstrap;
      officialGradleBin = fetchurl {
        url = "https://services.gradle.org/distributions/gradle-4.10.3-bin.zip";
        hash = "sha256-hibL8ga04gGt57h3eQkGkERwVLyT8FKVTHhID6btGG4=";
      };
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

      patches = [ ../gradle_4_10_3_bootstrap/bootstrap-gradle4_9.patch ];

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
        substituteInPlace settings.gradle.kts \
          --replace-fail \
            'apply(from = "gradle/shared-with-buildSrc/build-cache-configuration.settings.gradle.kts")' \
            '// build cache configuration is disabled for the Nix source bootstrap'
        substituteInPlace buildSrc/settings.gradle.kts \
          --replace-fail \
            'apply(from = "../gradle/shared-with-buildSrc/build-cache-configuration.settings.gradle.kts")' \
            '// build cache configuration is disabled for the Nix source bootstrap'
        substituteInPlace buildSrc/build.gradle.kts \
          --replace-fail \
            '        compile(gradleApi())' \
            '        compile(gradleApi())
                compile("org.slf4j:slf4j-api:1.7.16")
                compile("javax.inject:javax.inject:1")
                compile("com.google.code.findbugs:jsr305:2.0.1")
                compile("net.rubygrapefruit:native-platform:0.14")'
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

        officialDist="$(mktemp -d)"
        unzip -q ${officialGradleBin} -d "$officialDist"
        for officialJar in "$officialDist"/gradle-4.10.3/lib/gradle-*.jar "$officialDist"/gradle-4.10.3/lib/plugins/gradle-*.jar; do
          props="$("$JAVA_HOME/bin/jar" tf "$officialJar" | grep '^[^/]*-classpath.properties$' || true)"
          for prop in $props; do
            targetJar="$out/libexec/gradle/''${officialJar#"$officialDist/gradle-4.10.3/"}"
            if [ -f "$targetJar" ]; then
              targetJarDir="$(mktemp -d)"
              (cd "$targetJarDir" && "$JAVA_HOME/bin/jar" xf "$targetJar")
              (cd "$targetJarDir" && "$JAVA_HOME/bin/jar" xf "$officialJar" "$prop")
              if grep -q "plexus-cipher-1.7.jar" "$targetJarDir/$prop"; then
                substituteInPlace "$targetJarDir/$prop" \
                  --replace-fail "plexus-cipher-1.7.jar" "plexus-cipher-1.4.jar"
              fi
              if [ "$prop" = "gradle-kotlin-dsl-provider-plugins-classpath.properties" ]; then
                substituteInPlace "$targetJarDir/$prop" \
                  --replace-fail "runtime=" "runtime=gradle-plugins-4.10.3.jar,"
                (cd "$targetJarDir" && "$JAVA_HOME/bin/jar" xf "$out/libexec/gradle/lib/plugins/gradle-plugins-4.10.3.jar" org/gradle/api/tasks/SourceSet.class org/gradle/api/tasks/SourceSetContainer.class org/gradle/api/tasks/SourceSetOutput.class)
              fi
              rm "$targetJar"
              if [ -f "$targetJarDir/META-INF/MANIFEST.MF" ]; then
                (cd "$targetJarDir" && "$JAVA_HOME/bin/jar" cfm "$targetJar" META-INF/MANIFEST.MF .)
              else
                (cd "$targetJarDir" && "$JAVA_HOME/bin/jar" cf "$targetJar" .)
              fi
            fi
          done
        done

        makeWrapper "$out/libexec/gradle/bin/gradle" "$out/bin/gradle" \
          --set-default JAVA_HOME "${finalAttrs.env.JAVA_HOME}"

        runHook postInstall
      '';

      passthru = {
        inherit (finalAttrs) jdk mitmCache;
        tests = { };
        fetchDeps = finalAttrs.mitmCache.updateScript;
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
