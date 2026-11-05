{
  mk-apk-package,
  lib,
  path,
  pkgsCross,
  symlinkJoin,
  runCommand,
  runtimeShell,
  jdk17_headless,
  jdk21_headless,
  gradle_9_7_1,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  writeShellScriptBin,
  nix-update,
  rustPlatform,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  git,
  go_1_27,
  python313,
  unzip,
  cmake,
  ninja,
}:
let
  appPackage = stdenv.mkDerivation (
    finalAttrs0:
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-37-0
        s.platforms-android-36
        s.build-tools-37-0-0
        s.build-tools-36-0-0
        s.build-tools-35-0-0
        s.ndk-29-0-14206865
        s.cmake-3-31-6
      ]);
      androidSdkRoot = "${androidSdk}/share/android-sdk";
      androidNdkRoot = "${androidSdkRoot}/ndk/29.0.14206865";
      aapt2 = "${androidSdkRoot}/build-tools/37.0.0/aapt2";

      gradle = gradle_9_7_1;

      xMobileSrc = fetchFromGitHub {
        owner = "golang";
        repo = "mobile";
        rev = "81488f6aeb60";
        hash = "sha256-LIFK+KQPgpzZqh7U92fEnCSHBSVF8HPv9lIVhWy5xBo=";
      };

      androidCrossConfig = {
        config.allowUnfree = true;
        localSystem = stdenv.buildPlatform.system;
      };

      mkAndroidPkgs =
        {
          config,
          rustTarget,
        }:
        import path (
          androidCrossConfig
          // {
            crossSystem = {
              inherit config;
              androidSdkVersion = "35";
              androidNdkVersion = "29";
              useAndroidPrebuilt = true;
              rust.rustcTarget = rustTarget;
            };
          }
        );

      aarch64AndroidPkgs = mkAndroidPkgs {
        config = "aarch64-unknown-linux-android";
        rustTarget = "aarch64-linux-android";
      };

      x86_64AndroidPkgs = mkAndroidPkgs {
        config = "x86_64-unknown-linux-android";
        rustTarget = "x86_64-linux-android";
      };

      rdpCargoDeps = rustPlatform.fetchCargoVendor {
        pname = "haven-rdp-transport-jni-libs";
        inherit (finalAttrs0) version src;
        cargoRoot = "rdp-kotlin/rust";
        hash = "sha256-mdzdd/k3yqXhBKLBgAT3LSAUHej5isa734mIETBkGrI=";
      };

      mkRdpTransportJniLib =
        {
          crossPkgs,
          rustTarget,
          abi,
        }:
        crossPkgs.rustPlatform.buildRustPackage {
          pname = "haven-rdp-transport-jni-lib-${abi}";
          inherit (finalAttrs0) version src;

          sourceRoot = "${finalAttrs0.src.name}/rdp-kotlin/rust";
          cargoDeps = rdpCargoDeps;

          CARGO_BUILD_TARGET = rustTarget;
          doCheck = false;

          env = {
            ANDROID_HOME = androidSdkRoot;
            ANDROID_SDK_ROOT = androidSdkRoot;
            ANDROID_NDK_ROOT = androidNdkRoot;
            ANDROID_NDK_HOME = androidNdkRoot;
          };

          installPhase = ''
            runHook preInstall
            install -Dm755 target/${rustTarget}/release/librdp_transport.so \
              "$out/${abi}/librdp_transport.so"
            runHook postInstall
          '';
        };

      rdpTransportJniLibs = symlinkJoin {
        name = "haven-rdp-transport-jni-libs";
        paths = [
          (mkRdpTransportJniLib {
            crossPkgs = aarch64AndroidPkgs;
            rustTarget = "aarch64-linux-android";
            abi = "arm64-v8a";
          })
          (mkRdpTransportJniLib {
            crossPkgs = x86_64AndroidPkgs;
            rustTarget = "x86_64-linux-android";
            abi = "x86_64";
          })
        ];
      };

      spiceCargoDeps = rustPlatform.fetchCargoVendor {
        pname = "haven-spice-transport-jni-libs";
        inherit (finalAttrs0) version src;
        cargoRoot = "spice-kotlin/rust";
        hash = "sha256-JUJ9vDrCgsCtVEkLdV86qJqfOVKTWq3VbdCVZFojEeM=";
      };

      mkSpiceTransportJniLib =
        {
          crossPkgs,
          rustTarget,
          abi,
        }:
        crossPkgs.rustPlatform.buildRustPackage {
          pname = "haven-spice-transport-jni-lib-${abi}";
          inherit (finalAttrs0) version src;

          sourceRoot = "${finalAttrs0.src.name}/spice-kotlin/rust";
          cargoDeps = spiceCargoDeps;

          CARGO_BUILD_TARGET = rustTarget;
          doCheck = false;

          env = {
            ANDROID_HOME = androidSdkRoot;
            ANDROID_SDK_ROOT = androidSdkRoot;
            ANDROID_NDK_ROOT = androidNdkRoot;
            ANDROID_NDK_HOME = androidNdkRoot;
          };

          installPhase = ''
            runHook preInstall
            install -Dm755 target/${rustTarget}/release/libspice_transport.so               "$out/${abi}/libspice_transport.so"
            runHook postInstall
          '';
        };

      spiceTransportJniLibs = symlinkJoin {
        name = "haven-spice-transport-jni-libs";
        paths = [
          (mkSpiceTransportJniLib {
            crossPkgs = aarch64AndroidPkgs;
            rustTarget = "aarch64-linux-android";
            abi = "arm64-v8a";
          })
          (mkSpiceTransportJniLib {
            crossPkgs = x86_64AndroidPkgs;
            rustTarget = "x86_64-linux-android";
            abi = "x86_64";
          })
        ];
      };

      prepareXMobile = replacement: ''
        cp -R ${xMobileSrc} x-mobile
        chmod -R u+w x-mobile
        if [[ ! -f x-mobile/go.mod ]]; then
          (cd x-mobile && go mod init golang.org/x/mobile)
        fi
        substituteInPlace x-mobile/cmd/gomobile/init.go \
          --replace-fail 'if err := goInstall([]string{"golang.org/x/mobile/cmd/gobind@latest"}, nil); err != nil {' \
                         'if _, err := exec.LookPath("gobind"); err != nil {'
        patch -d x-mobile -p1 < ${../tailscale/gomobile-avoid-empty-go-mod.patch}
        (cd go && go mod edit -go=1.27.2 -replace=golang.org/x/mobile=${replacement})
      '';

      # Keep these commits aligned with upstream's openvpn3-core/deps.lock.
      openvpn3Sources = {
        openvpn3 = fetchFromGitHub {
          owner = "OpenVPN";
          repo = "openvpn3";
          rev = "b432eb39c7a48c5138ecdd294a389c733bc329a4";
          hash = "sha256-+kbxIYZHYu1O2AHDgR7cKO0i5chBddxTwjEd/XFh1fw=";
        };
        mbedtls = fetchFromGitHub {
          owner = "Mbed-TLS";
          repo = "mbedtls";
          tag = "v3.6.7";
          fetchSubmodules = true;
          hash = "sha256-t1ZPeFA3ftKaEIaXQ7RXZEsiOAYK4KSSm55SFr9g17A=";
        };
        lz4 = fetchFromGitHub {
          owner = "lz4";
          repo = "lz4";
          tag = "v1.10.0";
          hash = "sha256-/dG1n59SKBaEBg72pAWltAtVmJ2cXxlFFhP+klrkTos=";
        };
        fmt = fetchFromGitHub {
          owner = "fmtlib";
          repo = "fmt";
          tag = "11.2.0";
          hash = "sha256-sAlU5L/olxQUYcv8euVYWTTB8TrVeQgXLHtXy8IMEnU=";
        };
        asio = fetchFromGitHub {
          owner = "chriskohlhoff";
          repo = "asio";
          tag = "asio-1-38-2";
          hash = "sha256-ZPPdADK+ivwAk0gqBzyFjpRsMoZyGCq/qiKN8rMrHUk=";
        };
      };

      openvpn3Native = stdenv.mkDerivation {
        pname = "haven-openvpn3-native";
        inherit (finalAttrs0) version src;
        nativeBuildInputs = [
          cmake
          ninja
          git
          python313
        ];
        dontConfigure = true;
        env.ANDROID_NDK_HOME = androidNdkRoot;

        postPatch = ''
          substituteInPlace openvpn3-core/build-android.sh \
            --replace-fail '"armeabi-v7a:armeabi-v7a"' "" \
            --replace-fail '"x86:x86"' ""
        '';

        buildPhase = ''
          runHook preBuild
          # Fail on dependency pin changes instead of silently using old sources.
          echo 'cd48d9f3913a3fdfae3702713586b62dbd7d504ffbe4204c6fa0bccafe2e0abc  openvpn3-core/deps.lock' \
            | sha256sum -c -
          sourcesDir="$PWD/openvpn3-core/.deps/sources"
          mkdir -p "$sourcesDir"
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: source: ''
              cp -R ${source} "$sourcesDir/${name}"
            '') openvpn3Sources
          )}
          chmod -R u+w "$sourcesDir"
          for asioPatch in "$sourcesDir"/openvpn3/deps/vcpkg-ports/asio/*.patch; do
            git -C "$sourcesDir/asio" apply "$asioPatch"
          done
          # Match source preparation in Haven's fetch-deps.sh (GPL-3.0-only):
          # https://github.com/GlassHaven/Haven/blob/v5.92.0/openvpn3-core/fetch-deps.sh
          cat openvpn3-core/deps.lock openvpn3-core/fetch-deps.sh \
            | sha256sum | cut -d ' ' -f1 > "$sourcesDir/.prepared"
          bash openvpn3-core/build-android.sh
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mv core/tunnel/jniLibs-openvpn3 "$out"
          runHook postInstall
        '';
      };

      rcloneGoModCache = stdenvNoCC.mkDerivation {
        pname = "haven-rclone-go-mod-cache";
        inherit (finalAttrs0) version src;

        nativeBuildInputs = [ go_1_27 ];

        outputHashMode = "recursive";
        outputHashAlgo = "sha256";
        outputHash = "sha256-MWtJ9riO09mexUwxMbMnNxnkmiWQwW7SPW/Qhp33AQ0=";
        dontConfigure = true;
        dontFixup = true;

        buildPhase = ''
          runHook preBuild

          export HOME="$TMPDIR/home"
          mkdir -p "$HOME"
          export GOPATH="$TMPDIR/go"
          export GOCACHE="$TMPDIR/go-build-cache"
          export GOMODCACHE="$TMPDIR/go-mod-cache"
          # Prefer a matching toolchain when nixpkgs go is older than go.mod;
          # with go >= 1.26.6 this typically does not download anything.
          export GOTOOLCHAIN=auto
          export GOPROXY=https://proxy.golang.org,direct
          export GOSUMDB=sum.golang.org
          export GODEBUG=http2client=0

          cp -R "$src" source
          chmod -R u+w source
          cd source/rclone-android

          ${prepareXMobile "../x-mobile"}
          cd go
          go mod tidy -v
          go mod vendor -v
          VENDOR_PATH=$(find "$PWD" -name vendor -type d | head -n 1)

          cd ../x-mobile
          go mod download

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p "$out"
          cp -R "$VENDOR_PATH" "$out/vendor"
          rm -rf "$TMPDIR/go-mod-cache/cache/download/sumdb"
          chmod -R u+w "$TMPDIR/go-mod-cache"
          mv "$TMPDIR/go-mod-cache" "$out/cache"
          runHook postInstall
        '';
      };

      rcloneTransportJniLibs = stdenv.mkDerivation {
        pname = "haven-rclone-transport-jni-libs";
        inherit (finalAttrs0) version src;

        nativeBuildInputs = [
          go_1_27
          jdk21_headless
          unzip
        ];

        dontConfigure = true;

        env = {
          JAVA_HOME = jdk21_headless.passthru.home;
          ANDROID_HOME = androidSdkRoot;
          ANDROID_SDK_ROOT = androidSdkRoot;
          ANDROID_NDK_ROOT = androidNdkRoot;
          ANDROID_NDK_HOME = androidNdkRoot;
        };

        preBuild = ''
          export HOME="$TMPDIR/home"
          mkdir -p "$HOME"

          export GOCACHE="$TMPDIR/go-cache"
          export GOPATH="$TMPDIR/go"
          export GOMODCACHE="$PWD/.gomodcache"
          mkdir -p "$GOCACHE" "$GOPATH"
          cp -R ${rcloneGoModCache}/cache "$GOMODCACHE"
          chmod -R u+w "$GOMODCACHE"

          if [ -f "$GOMODCACHE/tailscale.com@v1.104.2/go.mod" ]; then
            substituteInPlace "$GOMODCACHE/tailscale.com@v1.104.2/go.mod" \
              --replace-fail "go 1.27.3" "go 1.27.2"
          fi
          if [ -f "$GOMODCACHE/cache/download/tailscale.com/@v/v1.104.2.mod" ]; then
            substituteInPlace "$GOMODCACHE/cache/download/tailscale.com/@v/v1.104.2.mod" \
              --replace-fail "go 1.27.3" "go 1.27.2"
          fi

          export GOBIN="$TMPDIR/go-bin"
          mkdir -p "$GOBIN"
          export PATH="$GOBIN:$PATH"

          # Upstream/tailscale need go >= 1.26.6; nixpkgs go_1_27 is new enough now.
          export GOTOOLCHAIN=local
          export GOPROXY=off
          export GOSUMDB=off
        '';

        buildPhase = ''
            runHook preBuild

            cd rclone-android
            ${prepareXMobile "../x-mobile"}
            mkdir -p ../core/tunnel
            cp -R ${openvpn3Native} ../core/tunnel/jniLibs-openvpn3
            chmod -R u+w ../core/tunnel/jniLibs-openvpn3
            cd go

            substituteInPlace go.sum \
              --replace-fail "tailscale.com v1.104.2/go.mod h1:D+gqEyJjFnwIaojBLaKxUbOfEO3cRXOaFaOZ5BIvYqs=" \
                             "tailscale.com v1.104.2/go.mod h1:zM/DEBP/ZMXOlPtP3M2lL3P8xQ/2FTl5MB3TSxMbouo="

            (cd ../x-mobile/cmd/gobind && go build -o "$GOBIN/gobind")
            (cd ../x-mobile/cmd/gomobile && go build -o "$GOBIN/gomobile")

            mkdir -p "$GOPATH/src/sh.haven" "$GOPATH/src/golang.org/x"
            ln -s "$PWD" "$GOPATH/src/sh.haven/rcbridge"
            ln -s "$PWD/../x-mobile" "$GOPATH/src/golang.org/x/mobile"
            cp -R ${rcloneGoModCache}/vendor/. "$GOPATH/src/"

            mkdir -p ../jniLibs ../build

            mkdir -p ../../core/tunnel/jniLibs-openvpn3/arm64-v8a
            mkdir -p ../../core/tunnel/jniLibs-openvpn3/x86_64

            printf '%s\n' \
              '#include <stddef.h>' \
              'void *new_session() { return NULL; }' \
              'int start_session(void *ptr) { return -1; }' \
              'void stop_session(void *ptr) {}' \
              'void cleanup_session(void *ptr) {}' \
              'void reconnect_session(void *ptr, int seconds) {}' \
              'void check_library() {}' \
              > "$TMPDIR/openvpn3_stub.c"

            $ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android26-clang -c "$TMPDIR/openvpn3_stub.c" -o "$TMPDIR/openvpn3_stub_arm64.o"
            $ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar rcs ../../core/tunnel/jniLibs-openvpn3/arm64-v8a/libopenvpn3_android_arm64.a "$TMPDIR/openvpn3_stub_arm64.o"

            $ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android26-clang -c "$TMPDIR/openvpn3_stub.c" -o "$TMPDIR/openvpn3_stub_x86_64.o"
            $ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar rcs ../../core/tunnel/jniLibs-openvpn3/x86_64/libopenvpn3_android_amd64.a "$TMPDIR/openvpn3_stub_x86_64.o"

            export GOFLAGS="-mod=mod -buildvcs=false -ldflags=-checklinkname=0"
            export GO111MODULE=on
            gomobile init
            gomobile bind \
              -target=android/arm64,android/amd64 \
              -javapkg=sh.haven.rclone.binding \
              -androidapi=26 \
              -ldflags "-s -w -checklinkname=0" \
              -v \
              -o ../build/rcbridge.aar \
              . ./wgbridge ./tsbridge ./mailbridge ./nbbridge ./ovpnbridge ./ocbridge


          cd ..
          unzip -o build/rcbridge.aar "jni/*" -d build/extracted
          unzip -o build/rcbridge.aar "classes.jar" -d build/extracted

          install -Dm755 build/extracted/jni/arm64-v8a/libgojni.so jniLibs/arm64-v8a/libgojni.so
          install -Dm755 build/extracted/jni/x86_64/libgojni.so jniLibs/x86_64/libgojni.so
          install -Dm644 build/extracted/classes.jar build/rcbridge-bindings.jar

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p "$out/jniLibs" "$out/build"
          install -Dm755 jniLibs/arm64-v8a/libgojni.so "$out/jniLibs/arm64-v8a/libgojni.so"
          install -Dm755 jniLibs/x86_64/libgojni.so "$out/jniLibs/x86_64/libgojni.so"
          install -Dm644 build/rcbridge-bindings.jar "$out/build/rcbridge-bindings.jar"
          runHook postInstall
        '';
      };

      wayvncShimToolchain =
        let
          aarch64LinuxGnuCc = pkgsCross.aarch64-multiplatform.stdenv.cc;
          x86_64LinuxGnuCc = pkgsCross.gnu64.stdenv.cc;
          armv7LinuxGnuCc = pkgsCross.armv7l-hf-multiplatform.stdenv.cc;
        in
        runCommand "haven-wayvnc-shim-toolchain" { } ''
          mkdir -p "$out/bin"

          cat > "$out/bin/aarch64-linux-gnu-gcc" <<'EOF'
          #!${runtimeShell}
          args=()
          for arg in "$@"; do
            args+=("$arg")
            if [ "$arg" = "-static" ]; then
              args+=("-L${pkgsCross.aarch64-multiplatform.glibc.static}/lib" "-B${pkgsCross.aarch64-multiplatform.glibc.static}/lib")
            fi
          done
          exec ${aarch64LinuxGnuCc}/bin/${aarch64LinuxGnuCc.targetPrefix}gcc "''${args[@]}"
          EOF
          chmod +x "$out/bin/aarch64-linux-gnu-gcc"
          ln -s ${aarch64LinuxGnuCc}/bin/${aarch64LinuxGnuCc.targetPrefix}strip "$out/bin/aarch64-linux-gnu-strip"

          cat > "$out/bin/x86_64-linux-gnu-gcc" <<'EOF'
          #!${runtimeShell}
          args=()
          for arg in "$@"; do
            args+=("$arg")
            if [ "$arg" = "-static" ]; then
              args+=("-L${pkgsCross.gnu64.glibc.static}/lib" "-B${pkgsCross.gnu64.glibc.static}/lib")
            fi
          done
          exec ${x86_64LinuxGnuCc}/bin/${x86_64LinuxGnuCc.targetPrefix}gcc "''${args[@]}"
          EOF
          chmod +x "$out/bin/x86_64-linux-gnu-gcc"
          ln -s ${x86_64LinuxGnuCc}/bin/${x86_64LinuxGnuCc.targetPrefix}strip "$out/bin/x86_64-linux-gnu-strip"

          cat > "$out/bin/arm-linux-gnueabihf-gcc" <<'EOF'
          #!${runtimeShell}
          args=()
          for arg in "$@"; do
            args+=("$arg")
            if [ "$arg" = "-static" ]; then
              args+=("-L${pkgsCross.armv7l-hf-multiplatform.glibc.static}/lib" "-B${pkgsCross.armv7l-hf-multiplatform.glibc.static}/lib")
            fi
          done
          exec ${armv7LinuxGnuCc}/bin/${armv7LinuxGnuCc.targetPrefix}gcc "''${args[@]}"
          EOF
          chmod +x "$out/bin/arm-linux-gnueabihf-gcc"
          ln -s ${armv7LinuxGnuCc}/bin/${armv7LinuxGnuCc.targetPrefix}strip "$out/bin/arm-linux-gnueabihf-strip"
        '';
    in
    {
      pname = "haven";
      version = "5.94.2";

      src = fetchFromGitHub {
        owner = "GlassHaven";
        repo = "Haven";
        tag = "v${finalAttrs0.version}";
        fetchSubmodules = true;
        hash = "sha256-6Uei0hEpgPd8+1QEiY3vaU+hP+gtCuaKe931at2FeDo=";
      };

      patches = [
        # Build unsigned APK (no keystore in sandbox)
        ./remove-signing-config.patch
        # Build the Rust JNI libraries in Nix instead of invoking cargo-ndk from Gradle.
        ./skip-gradle-rdp-native-build.patch
        ./skip-gradle-rclone-native-build.patch
        ./skip-gradle-spice-native-build.patch
        ./skip-gradle-prns-native-build.patch
      ];

      postPatch = ''
        rm -f gradle/verification-metadata.xml
      '';

      gradleBuildTask = ":app:assembleArm64FullRelease";
      gradleUpdateTask = finalAttrs0.gradleBuildTask;

      # $(nix build .#apk_haven.mitmCache.updateScript --no-link --print-out-paths)
      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs0) pname;
        attrPath = "apk_haven";
        pkg = finalAttrs0.finalPackage;
        data = ./haven_deps.json;
        silent = false;
        useBwrap = false;
      };

      passthru = {
        # Exposed so the update script can (re)compute their hashes on their own.
        inherit
          rdpCargoDeps
          spiceCargoDeps
          rcloneGoModCache
          openvpn3Sources
          openvpn3Native
          ;

        # Fixed-output dependencies that change with the source and that
        # `nix-update --src-only` cannot refresh by itself.
        updateDeps = [
          "rdpCargoDeps.vendorStaging"
          "spiceCargoDeps.vendorStaging"
          "rcloneGoModCache"
        ];

        updateScript = writeShellScriptBin "update-haven" ''
          set -euo pipefail

          package_file="app/apks/haven/package.nix"
          package_attr=".#apk_haven"
          fake_hash="${lib.fakeHash}"

          . "${../_shared/update-script-helpers.sh}"

          # The vendored Rust crates and the rclone Go module cache need a
          # correct hash before the Gradle mitm cache can be regenerated.
          ${lib.getExe nix-update} --flake --src-only --version-regex='^v?([0-9]+\.[0-9]+\.[0-9]+(-rc[0-9]+)?)$' apk_haven

          refresh_update_deps ${lib.concatStringsSep " " finalAttrs0.passthru.updateDeps}

          refresh_mitm_cache
        '';
      };

      nativeBuildInputs = [
        gradle
        jdk17_headless
        jdk21_headless
        writableTmpDirAsHomeHook
        git
        python313
        go_1_27
        unzip
        wayvncShimToolchain
      ];

      env = {
        JAVA_HOME = jdk21_headless.passthru.home;
        ANDROID_HOME = androidSdkRoot;
        ANDROID_SDK_ROOT = androidSdkRoot;
        ANDROID_NDK_ROOT = androidNdkRoot;
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = aapt2;
        HAVEN_SKIP_PYTHON_REQUIREMENTS = "1";
        SKIP_QEMU_LOADERS = "1";
        SKIP_UML = "1";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdkRoot}" > local.properties

        mkdir -p rdp-kotlin/jniLibs
        cp -r ${rdpTransportJniLibs}/. rdp-kotlin/jniLibs/

        mkdir -p spice-kotlin/jniLibs
        cp -r ${spiceTransportJniLibs}/. spice-kotlin/jniLibs/

        mkdir -p rclone-android/jniLibs
        cp -r ${rcloneTransportJniLibs}/jniLibs/. rclone-android/jniLibs/
        mkdir -p rclone-android/build
        cp ${rcloneTransportJniLibs}/build/rcbridge-bindings.jar rclone-android/build/
        mkdir -p core/tunnel/jniLibs-openvpn3
        # The update script removes this tree after recording dependencies.
        chmod -R u+w rdp-kotlin/jniLibs spice-kotlin/jniLibs \
          rclone-android/jniLibs core/tunnel/jniLibs-openvpn3

        # When running in mitmCache dependency-fetch mode, configure pip (used by
        # Chaquopy) to trust the mitm proxy certificate so PyPI downloads are captured.
        if [[ -n "''${MITM_CACHE_CA:-}" ]]; then
          export PIP_CERT="$MITM_CACHE_CA"
          export REQUESTS_CA_BUNDLE="$MITM_CACHE_CA"
          export SSL_CERT_FILE="$MITM_CACHE_CA"
          export PIP_PROXY="http://''${MITM_CACHE_ADDRESS}"
          export HTTPS_PROXY="http://''${MITM_CACHE_ADDRESS}"
          export HTTP_PROXY="http://''${MITM_CACHE_ADDRESS}"
          export https_proxy="http://''${MITM_CACHE_ADDRESS}"
          export http_proxy="http://''${MITM_CACHE_ADDRESS}"
          export ALL_PROXY="http://''${MITM_CACHE_ADDRESS}"
          export all_proxy="http://''${MITM_CACHE_ADDRESS}"
          export NO_PROXY=""
          export no_proxy=""
        fi
      '';

      preBuild = lib.optionalString stdenv.hostPlatform.isDarwin ''
        # AGP writes SDK metadata under ~/.android; /var/empty is read-only on Darwin sandboxes.
        export ANDROID_USER_HOME="$HOME/.android"
        export GRADLE_USER_HOME="$HOME/.gradle"
        mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"
        export GRADLE_OPTS="''${GRADLE_OPTS:+$GRADLE_OPTS }-Duser.home=$HOME"
      '';

      gradleFlags = [
        "-xlintVitalRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless.passthru.home},${jdk21_headless.passthru.home}"
        "-Dandroid.aapt2FromMavenOverride=${aapt2}"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${aapt2}"
        # Upstream builds these from source in Gradle (no longer ships jniLibs).
        # The Nix sandbox cannot clone ffmpeg deps, and wayland needs more
        # host tooling wired up; skip for now so the APK still builds.
        "-PskipWaylandNatives=true"
        "-PskipFfmpegNatives=true"
        "-PskipOpenvpn3Native=true"
        "-PskipUml"
        "-PtargetAbi=arm64"
      ];

      installPhase = ''
        runHook preInstall
        apk_path="$(find app/build/outputs -name "*.apk" | head -n 1)"
        install -Dm644 "$apk_path" "$out/haven.apk"
        runHook postInstall
      '';

      meta = with lib; {
        sourceProvenance = with sourceTypes; [ fromSource ];
        description = "Haven – SSH/Mosh terminal and Reticulum network client for Android";
        homepage = "https://github.com/GlassHaven/Haven";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    }
  );
in
mk-apk-package {
  inherit appPackage;
  mainApk = "haven.apk";
  signScriptName = "sign-haven";
  fdroid = {
    appId = "sh.haven.app";
    metadataYml = ''
      Categories:
        - Internet
        - System
      License: GPL-3.0-only
      SourceCode: https://github.com/GlassHaven/Haven
      IssueTracker: https://github.com/GlassHaven/Haven/issues
      AutoName: Haven
      Summary: SSH/Mosh terminal and Reticulum network client
      Description: |-
        Haven is an SSH/Mosh terminal and Reticulum network client for Android,
        featuring end-to-end encrypted messaging via the Reticulum stack.
        This package is built from source (arm64).
    '';
  };
}
