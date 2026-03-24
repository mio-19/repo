{
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  androidSdkBuilder,
  gradle-packages,
  go_1_26,
  jdk17,
  writableTmpDirAsHomeHook,
  gnumake,
  zip,
  unzip,
}:
let
  version = "1.96.2";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale-android";
    tag = "v${version}";
    hash = "sha256-1RWHKUzqbiK/fOkkOdjAhQ/F/qU1rOVqEa8ANv7zW+c=";
  };

  xMobileSrc = fetchFromGitHub {
    owner = "golang";
    repo = "mobile";
    # https://github.com/tailscale/tailscale-android/blob/5c5030c5434dc465d1e277b19222456544553482/go.mod#L7
    rev = "81131f6468ab";
    hash = "sha256-/WelLIFKCHuMZnRnaWFvBo8wZB33fRJurbbFEs16tG0=";
  };

  goModCache = stdenvNoCC.mkDerivation {
    pname = "tailscale-go-mod-cache";
    inherit version src;

    nativeBuildInputs = [ go_1_26 ];

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-ehqH2q9/+Nj86BQEfQ6OXKmSUr2/GM8GS5p1DD+lyAY=";

    dontConfigure = true;
    dontFixup = true;

    buildPhase = ''
      runHook preBuild

      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      export GOPATH="$TMPDIR/go"
      export GOCACHE="$TMPDIR/go-build-cache"
      export GOMODCACHE="$TMPDIR/go-mod-cache"
      export GOPROXY=https://proxy.golang.org,direct
      export GOSUMDB=sum.golang.org

      cp -R "$src" source
      chmod -R u+w source
      cd source

      cp -R ${xMobileSrc} x-mobile
      chmod -R u+w x-mobile
      patch -d x-mobile -p1 < ${./gomobile-avoid-empty-go-mod.patch}
      go mod edit -replace=golang.org/x/mobile=./x-mobile

      go mod download

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -R "$TMPDIR/go-mod-cache" "$out"
      runHook postInstall
    '';
  };

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-34
    s.build-tools-34-0-0
    s.ndk-27-3-13750724
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.7";
      hash = "sha256-VEw11r2Emuil7QvOo5umd9xA9J330YNVYVgtogCblh0=";
      defaultJava = jdk17;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "tailscale";
  inherit version src;

  gradleBuildTask = "assembleRelease";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    pname = "tailscale";
    pkg = finalAttrs.finalPackage;
    data = ./tailscale_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    go_1_26
    gnumake
    jdk17
    writableTmpDirAsHomeHook
    zip
    unzip
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk17}" else "${jdk17}/lib/openjdk";
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/27.3.13750724";
    NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/27.3.13750724";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2";
  };

  preBuild = ''
    export HOME="$PWD/.home"
    mkdir -p "$HOME/.android" "$HOME/.cache"

    patchShebangs tool build-tags.sh version-ldflags.sh

    export GOCACHE="$TMPDIR/go-cache"
    export GOPATH="$TMPDIR/go"
    export GOMODCACHE="$PWD/.gomodcache"
    cp -R ${goModCache} "$GOMODCACHE"
    chmod -R u+w "$GOMODCACHE"
    export GOPROXY=off
    export GOSUMDB=off

    cp -R ${xMobileSrc} x-mobile
    chmod -R u+w x-mobile
    patch -d x-mobile -p1 < ${./gomobile-avoid-empty-go-mod.patch}
    go mod edit -replace=golang.org/x/mobile=./x-mobile

    export TOOLCHAINDIR="${go_1_26}/share/go"
    export TOOLCHAIN_DIR="$TOOLCHAINDIR"
    export PATH="$TOOLCHAINDIR/bin:$PATH"

    # gomobile still falls back to GOPATH-style package resolution while
    # building the generated gobind wrapper. Mirror the resolved module graph
    # into GOPATH/src so those imports remain available in GOPATH mode.
    mkdir -p "$GOPATH/src/github.com/tailscale" "$GOPATH/src/golang.org/x"
    ln -s "$PWD" "$GOPATH/src/github.com/tailscale/tailscale-android"
    ln -s "$PWD/x-mobile" "$GOPATH/src/golang.org/x/mobile"
    find "$GOMODCACHE" -name go.mod -print | while read -r gomod; do
      module_dir="$(dirname "$gomod")"
      rel_path="''${module_dir#$GOMODCACHE/}"
      module_path="''${rel_path%@*}"
      mkdir -p "$GOPATH/src/$(dirname "$module_path")"
      ln -s "$module_dir" "$GOPATH/src/$module_path"
    done

    cat > tailscale.version <<EOF
    VERSION_LONG="${version}"
    VERSION_SHORT="${version}"
    VERSION_GIT_HASH=""
    VERSION_EXTRA_HASH=""
    EOF

    cat > android/local.properties <<EOF
    sdk.dir=${androidSdk}/share/android-sdk
    EOF

    substituteInPlace android/build.gradle \
      --replace-fail 'ndkVersion "23.1.7779620"' 'ndkVersion "27.3.13750724"'

    echo "org.gradle.jvmargs=-Xmx4096m" >> android/gradle.properties
    cat >> android/gradle.properties <<EOF
    android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2
    org.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2
    EOF

    make env
    make libtailscale
  '';

  gradleFlags = [
    "-p"
    "android"
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
  ];

  installPhase = ''
    runHook preInstall
    install -Dm644 android/build/outputs/apk/release/android-release-unsigned.apk "$out/tailscale.apk"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Tailscale Android client built from source";
    homepage = "https://github.com/tailscale/tailscale-android";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
})
