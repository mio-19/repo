{
  lib,
  stdenv,
  stdenvNoCC,
  buildGoModule,
  fetchFromGitHub,
  fetchurl,
  androidSdkBuilder,
  gradle-packages,
  go_1_24,
  go_1_26,
  jdk17,
  makeWrapper,
  writableTmpDirAsHomeHook,
  gnumake,
  zip,
  unzip,
  zlib,
}:
let
  version = "1.96.2";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale-android";
    rev = "1.96.2-td916d8651-ga82504d6b";
    hash = "sha256-1RWHKUzqbiK/fOkkOdjAhQ/F/qU1rOVqEa8ANv7zW+c=";
  };

  goToolchainRev = "5cce30e20c1fc6d8463b0a99acdd9777c4ad124b";

  tailscaleGoToolchain = fetchurl {
    url = "https://github.com/tailscale/go/releases/download/build-${goToolchainRev}/linux-amd64.tar.gz";
    hash = "sha256-DBVVWSLjaufFWIchBwy/cLYLaGeZ9lHuu0ptzC9XBPY=";
  };

  xMobileSrc = fetchFromGitHub {
    owner = "golang";
    repo = "mobile";
    rev = "81131f6468ab";
    hash = "sha256-LIFK+KQPgpzZqh7U92fEnCSHBSVF8HPv9lIVhWy5xBo=";
  };

  gomobilePinned = buildGoModule {
    pname = "gomobile-tailscale";
    version = "81131f6468ab";
    src = xMobileSrc;
    vendorHash = "sha256-SD5FXRG5nDGVDWAG9dOhVm1ga3NBV8iEBtjiaFTFLIU=";
    doCheck = false;
    nativeBuildInputs = [ makeWrapper ];
    subPackages = [
      "bind"
      "cmd/gobind"
      "cmd/gomobile"
    ];
    go = go_1_24;

    postInstall = ''
      mkdir -p $out/src/golang.org/x
      ln -s $src $out/src/golang.org/x/mobile
    '';

    postFixup = ''
      for prog in gomobile gobind; do
        wrapProgram $out/bin/$prog \
          --suffix GOPATH : $out \
          --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ zlib ]}"
      done
    '';
  };

  goVendor = stdenvNoCC.mkDerivation {
    pname = "tailscale-go-vendor";
    inherit version src;

    nativeBuildInputs = [ jdk17 ];

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-hDZL0OAH7/iknhnEcvXmzWKMDwnJ2SfnyobAsm/qPsI=";

    dontConfigure = true;
    dontFixup = true;

    buildPhase = ''
      runHook preBuild

      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      export GOCACHE="$TMPDIR/go-cache"
      export GOPATH="$TMPDIR/go"
      export PATH="$TMPDIR/go-toolchain/bin:$PATH"

      mkdir -p "$TMPDIR/go-toolchain"
      tar -xzf ${tailscaleGoToolchain} -C "$TMPDIR/go-toolchain" --strip-components=1

      cp -R "$src" source
      chmod -R u+w source
      cd source

      go mod vendor

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -R vendor "$out"
      runHook postInstall
    '';
  };

  goModCache = stdenvNoCC.mkDerivation {
    pname = "tailscale-go-mod-cache";
    inherit version src;

    nativeBuildInputs = [ go_1_26 ];

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-CG825wTedXiobnEyhdN+au4CYmg2UfhonMxRzHsQFJc=";

    dontConfigure = true;
    dontFixup = true;

    buildPhase = ''
      runHook preBuild

      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      export GOPATH="$TMPDIR/go"
      export GOCACHE="$TMPDIR/go-build-cache"
      export GOMODCACHE="$TMPDIR/go-mod-cache"

      cp -R "$src" source
      chmod -R u+w source
      cd source

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
    s.ndk-26-1-10909125
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
    ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/26.1.10909125";
    NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/26.1.10909125";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2";
  };

  postUnpack = "";

  preBuild = ''
    export HOME="$PWD/.home"
    mkdir -p "$HOME/.android"

    patchShebangs tool build-tags.sh version-ldflags.sh

    export PATH="${go_1_26}/bin:$PATH"
    export TOOLCHAINDIR="${go_1_26}"
    export TOOLCHAIN_DIR=1
    export GOCACHE="$TMPDIR/go-cache"
    export GOPATH="$TMPDIR/go"
    export GOMODCACHE="$PWD/.gomodcache"
    cp -R ${goModCache} "$GOMODCACHE"
    chmod -R u+w "$GOMODCACHE"
    export GOPROXY=off
    export GOSUMDB=off

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
      --replace-fail 'ndkVersion "23.1.7779620"' 'ndkVersion "26.1.10909125"'

    cat >> android/gradle.properties <<EOF
    android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2
    org.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2
    EOF

    mkdir -p android/build/go/bin
    cp ${gomobilePinned}/bin/gobind android/build/go/bin/gobind
    cp ${gomobilePinned}/bin/gomobile android/build/go/bin/gomobile
    chmod +x android/build/go/bin/gobind android/build/go/bin/gomobile

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
