{
  lib,
  pkgs,
  stdenv,
  callPackage,
  fetchFromGitHub,
  makeWrapper,
  unzip,
  autoPatchelfHook,
  coreutils,
  findutils,
  git,
  gnused,
  jdk8_headless,
  jdk11,
  jdk17,
  jdk21,
  ncurses5,
  ncurses6,
  udev,
  buildPackages,
}:
{
  version,
  tag ? if lib.length (lib.splitString "." version) == 3 then "v${version}" else "v${version}.0",
  hash,
  deps,
  defaultJava,
  bootstrapGradle ? pkgs.gradle-packages.${"gradle_" + lib.versions.major version}.wrapped,
}:
let
  mkGradle' =
    {
      java ? defaultJava,
      javaToolchains ? [ ],
      gradleInitScript ? null,
      mitmCache ? null,
      ...
    }:
    stdenv.mkDerivation (finalAttrs: {
      pname = "gradle";
      inherit version;

      src = fetchFromGitHub {
        owner = "gradle";
        repo = "gradle";
        inherit tag hash;
      };

      nativeBuildInputs = [
        bootstrapGradle
        git
        makeWrapper
        unzip
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        autoPatchelfHook
      ]
      ++ lib.optionals (mitmCache != "") [
        finalAttrs.mitmCache
      ];

      buildInputs = [
        stdenv.cc.cc
        ncurses5
        ncurses6
      ];

      dontAutoPatchelf = true;

      gradleBuildCommand = ''
        export GRADLE_USER_HOME="$TMPDIR/gradle-home"
        mkdir -p "$GRADLE_USER_HOME"

        gradleFlagsArray+=(
          --no-configuration-cache
          -PfinalRelease=true
          -Dorg.gradle.configuration-cache=false
          -Dorg.gradle.java.installations.auto-download=false
          -Dorg.gradle.java.installations.paths=${
            lib.concatStringsSep "," (
              [
                jdk8_headless
                jdk11
                jdk17
                jdk21
              ]
              ++ javaToolchains
            )
          }
        )

        gradle :distributions-full:binDistributionZip
      '';

      configurePhase = ''
        runHook preConfigure
      '';

      buildPhase = ''
        runHook preBuild
        ${finalAttrs.gradleBuildCommand}
        runHook postBuild
      '';

      gradleUpdateScript = ''
        ${finalAttrs.gradleBuildCommand}
      '';

      mitmCache = bootstrapGradle.fetchDeps {
        pkg = finalAttrs.finalPackage;
        pname = "gradle-${version}";
        data = deps;
        silent = false;
        useBwrap = false;
      };

      gradleLibexec = "${placeholder "out"}/libexec/gradle";

      installPhase =
        let
          toolchainPaths = "org.gradle.java.installations.paths=${lib.concatStringsSep "," javaToolchains}";
          jnaLibraryPath = lib.optionalString stdenv.hostPlatform.isLinux (lib.makeLibraryPath [ udev ]);
          jnaFlag = lib.optionalString stdenv.hostPlatform.isLinux ''--add-flags "-Djna.library.path=${jnaLibraryPath}"'';
        in
        ''
          runHook preInstall

          dist_zip="$(find . -path '*/build/distributions/gradle-*-bin.zip' | grep '/distributions-full/' | head -n1)"
          test -n "$dist_zip"
          test -f "$dist_zip"
          mkdir dist-unpack
          unzip -q "$dist_zip" -d dist-unpack
          cd dist-unpack/gradle-*

          mkdir -vp $gradleLibexec
          cp -av lib/ $gradleLibexec
          [ -f $gradleLibexec/lib/gradle-launcher-*.jar ] || { echo "No Gradle launcher jar found!" >&2; exit 1; }

          gradleCliMainJar="$(echo $gradleLibexec/lib/gradle-gradle-cli-main-*.jar)"
          if ! unzip -p "$gradleCliMainJar" META-INF/MANIFEST.MF | grep -q '^Main-Class: '; then
            printf 'Main-Class: org.gradle.launcher.GradleMain\n' > gradle-cli-main-manifest.txt
            ${buildPackages.jdk}/bin/jar ufm "$gradleCliMainJar" gradle-cli-main-manifest.txt
          fi

          echo ${lib.escapeShellArg toolchainPaths} > $gradleLibexec/gradle.properties

          mkdir -vp $gradleLibexec/bin
          cp -v bin/gradle $gradleLibexec/bin/gradlew
          chmod +x $gradleLibexec/bin/gradlew
          patchShebangs --host $gradleLibexec/bin/gradlew

          mkdir -vp $out/bin
          makeWrapper $gradleLibexec/bin/gradlew $out/bin/gradle \
            --set-default JAVA_HOME ${java} \
            --suffix PATH : ${
              lib.makeBinPath [
                coreutils
                findutils
                gnused
              ]
            } \
            ${jnaFlag}

          runHook postInstall
        '';

      dontFixup = !stdenv.hostPlatform.isLinux;

      fixupPhase =
        let
          arch = if stdenv.hostPlatform.is64bit then "amd64" else "i386";
          newFileEvents = toString (lib.versionAtLeast version "8.12");
        in
        ''
          export PATH="${buildPackages.jdk}/bin:$PATH"
          . ${pkgs.path}/pkgs/development/tools/build-managers/gradle/patching.sh

          nativeVersion="$(extractVersion native-platform $gradleLibexec/lib/native-platform-*.jar)"
          for variant in "" "-ncurses5" "-ncurses6"; do
            autoPatchelfInJar \
              $gradleLibexec/lib/native-platform-linux-${arch}$variant-''${nativeVersion}.jar \
              "${lib.getLib stdenv.cc.cc}/lib64:${
                lib.makeLibraryPath [
                  stdenv.cc.cc
                  ncurses5
                  ncurses6
                ]
              }"
          done

          if [ -n "${newFileEvents}" ]; then
            fileEventsVersion="$(extractVersion gradle-fileevents $gradleLibexec/lib/gradle-fileevents-*.jar)"
            autoPatchelfInJar \
              $gradleLibexec/lib/gradle-fileevents-''${fileEventsVersion}.jar \
              "${lib.getLib stdenv.cc.cc}/lib64:${lib.makeLibraryPath [ stdenv.cc.cc ]}"
          else
            fileEventsVersion="$(extractVersion file-events $gradleLibexec/lib/file-events-*.jar)"
            autoPatchelfInJar \
              $gradleLibexec/lib/file-events-linux-${arch}-''${fileEventsVersion}.jar \
              "${lib.getLib stdenv.cc.cc}/lib64:${lib.makeLibraryPath [ stdenv.cc.cc ]}"
          fi

          mkdir $out/nix-support
          echo ${stdenv.cc.cc} > $out/nix-support/manual-runtime-dependencies
          echo ${ncurses5} >> $out/nix-support/manual-runtime-dependencies
          echo ${ncurses6} >> $out/nix-support/manual-runtime-dependencies
          ${lib.optionalString stdenv.hostPlatform.isLinux "echo ${udev} >> $out/nix-support/manual-runtime-dependencies"}
        '';

      passthru.jdk = java;

      meta = {
        platforms = [
          "aarch64-darwin"
          "aarch64-linux"
          "i686-windows"
          "x86_64-cygwin"
          "x86_64-darwin"
          "x86_64-linux"
          "x86_64-windows"
        ];
        description = "Enterprise-grade build system";
        homepage = "https://www.gradle.org/";
        changelog = "https://docs.gradle.org/${version}/release-notes.html";
        sourceProvenance = with lib.sourceTypes; [ fromSource ];
        license = lib.licenses.asl20;
        mainProgram = "gradle";
      };
    });

  unwrapped = callPackage mkGradle' { };
in
callPackage pkgs.gradle-packages.wrapGradle {
  gradle-unwrapped = unwrapped;
}
