{
  autoPatchelfHook,
  buildPackages,
  coreutils,
  fetchFromGitHub,
  findutils,
  git,
  gnused,
  gradle2nixBuilders,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  jdk8_headless,
  lib,
  makeWrapper,
  ncurses5,
  ncurses6,
  path,
  gradle-packages,
  stdenv,
  udev,
  unzip,
  callPackage,
  jq,
  runCommand,
  overrides-from-source,
}:
{
  version,
  tag ? if lib.length (lib.splitString "." version) == 2 then "v${version}.0" else "v${version}",
  rev ? null,
  hash,
  lockFile,
  defaultJava,
  gradleBuilders ? gradle2nixBuilders,
  buildJdk ? jdk17_headless,
  javaToolchains ? [
    jdk8_headless
    jdk11_headless
    jdk17_headless
    jdk21_headless
  ],
  bootstrapGradle,
}:
let
  toolchainPaths = lib.concatStringsSep "," javaToolchains;
  filteredLockfile = runCommand "filtered-gradle-${version}-gradle.lock" { } ''
    ${lib.getExe jq} '
      with_entries(
        select(
          (
            (.key | startswith("gradle:gradle:"))
            or (.key | startswith("android-studio:android-studio:"))
            or (.key | startswith("org.gradle.buildtool.internal:gradle-ide-starter:"))
          )
          | not
        )
      )
    ' ${lockFile} > $out
  '';
  jnaLibraryPath = lib.optionalString stdenv.hostPlatform.isLinux (lib.makeLibraryPath [ udev ]);
  jnaFlag = lib.optionalString stdenv.hostPlatform.isLinux ''--add-flags "-Djna.library.path=${jnaLibraryPath}"'';
  mkGradle' =
    {
      java ? defaultJava,
      ...
    }:
    gradleBuilders.buildGradlePackage rec {
      pname = "gradle";
      inherit version;
      lockFile = filteredLockfile;

      overrides = overrides-from-source;

      src =
        if rev == null then
          fetchFromGitHub {
            owner = "gradle";
            repo = "gradle";
            inherit tag hash;
          }
        else
          fetchFromGitHub {
            owner = "gradle";
            repo = "gradle";
            inherit rev hash;
          };

      gradle = bootstrapGradle;
      inherit buildJdk;

      nativeBuildInputs = [
        git
        makeWrapper
        unzip
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        autoPatchelfHook
      ];

      buildInputs = [
        stdenv.cc.cc
        ncurses5
        ncurses6
      ];

      dontAutoPatchelf = true;

      env = {
        JAVA_HOME = buildJdk;
      };

      gradleFlags = [
        "-PfinalRelease=true"
        "--no-configuration-cache"
        "--no-build-cache"
        # for speed:
        #"--configure-on-demand" # breaks 8.7.0-20240118-1
        "--no-daemon"
        # gradle2nix already set --parallel for us
      ]
      ++ (
        if lib.versionOlder version "8.99.9" then
          [
            "-Porg.gradle.configuration-cache=false" # gradle 8.x?
            "-Porg.gradle.java.installations.paths=${toolchainPaths}" # gradle 8.x
            "-Porg.gradle.java.installations.auto-download=false" # https://docs.gradle.org/8.14.4/userguide/toolchains.html#sec:auto_detection
          ]
        else
          [
            "-Dorg.gradle.configuration-cache=false" # gradle 9.x?
            "-Dorg.gradle.java.installations.auto-download=false" # gradle 9.x
            "-Dorg.gradle.java.installations.paths=${toolchainPaths}" # gradle 9.x
          ]
      );

      gradleBuildFlags = [ ":distributions-full:binDistributionZip" ];

      gradleLibexec = "${placeholder "out"}/libexec/gradle";

      postPatch = ''
        rm -f gradle/verification-metadata.xml
        echo "Removed gradle/verification-metadata.xml so the source-built Guava override is not rejected by upstream checksum verification."
        rm -fr gradle/wrapper .teamcity/.mvn/wrapper
        find . -name "*.jar" -print0 | xargs -0 rm
        echo "Removed gradle/wrapper, .teamcity/.mvn/wrapper and all .jar files"
      '';

      installPhase = ''
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
        # $gradleCliMainJar no such file with gradle older than gradle_8_9_20240411
        if [ -f "$gradleCliMainJar" ] && ! unzip -p "$gradleCliMainJar" META-INF/MANIFEST.MF | grep -q '^Main-Class: '; then
          printf 'Main-Class: org.gradle.launcher.GradleMain\n' > gradle-cli-main-manifest.txt
          ${buildPackages.jdk}/bin/jar ufm "$gradleCliMainJar" gradle-cli-main-manifest.txt
        fi

        echo ${lib.escapeShellArg "org.gradle.java.installations.paths=${toolchainPaths}"} > $gradleLibexec/gradle.properties

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
          . ${path}/pkgs/development/tools/build-managers/gradle/patching.sh

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
      passthru.lockFile = filteredLockfile;

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
    };

  unwrapped = callPackage mkGradle' { };
in
callPackage gradle-packages.wrapGradle {
  gradle-unwrapped = unwrapped;
}
