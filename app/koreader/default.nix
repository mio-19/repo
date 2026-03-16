{
  lib,
  stdenv,
  fetchFromGitHub,
  nixpkgsSrc,
  androidSdk,
  jdk17_headless,
  gradle,
  gettext,
  cmake,
  ninja,
  git,
  gawk,
  gnugrep,
  p7zip,
  perl,
  pkg-config,
  autoconf,
  automake,
  libtool,
  meson,
  python3,
  util-linux,
  curl,
  cacert,
  unzip,
  zip,
  which,
  removeReferencesTo,
  writableTmpDirAsHomeHook,
}:
let
  version = "2025.10";

  src = fetchFromGitHub {
    owner = "koreader";
    repo = "koreader";
    rev = "v${version}";
    hash = "sha256-uYKN5fgIdCVH+pXU2lmsGu7HxZbDld5EJVO9o7Tk8BA=";
    fetchSubmodules = true;
  };

  commonNativeBuildInputs = [
    androidSdk
    cmake
    gawk
    git
    gnugrep
    gradle
    gettext
    jdk17_headless
    meson
    ninja
    p7zip
    perl
    pkg-config
    autoconf
    automake
    libtool
    python3
    util-linux
    curl
    unzip
    which
    removeReferencesTo
    writableTmpDirAsHomeHook
    zip
  ];

  commonEnv = {
    JAVA_HOME = jdk17_headless;
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/26.3.11579264";
    ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/26.3.11579264";
  };

  commonPostPatch = ''
    # Avoid Gradle wrapper downloading its own distribution.
    substituteInPlace make/android.mk \
      --replace-fail '$(ANDROID_LAUNCHER_DIR)/gradlew' 'gradle'

    # Build-machine generators (LuaJIT host tools, Meson generator binaries)
    # must use native compiler, not Android clang from NDK.
    substituteInPlace base/Makefile.defs \
      --replace-fail 'HOSTCC:=clang' 'HOSTCC:=${stdenv.cc}/bin/cc' \
      --replace-fail 'HOSTCXX:=clang++' 'HOSTCXX:=${stdenv.cc}/bin/c++'

    # LuaJIT's external project derives TARGET_CC from CROSS+CC, and upstream sets
    # CC to HOSTCC. In Nix we use native HOSTCC for build tools, so force LuaJIT's
    # target CC to clang (from NDK toolchain PATH) instead.
    substituteInPlace base/thirdparty/luajit/CMakeLists.txt \
      --replace-fail 'CC=''${HOSTCC}' 'CC=clang'

    # CHMLib uses ffs() without a visible declaration under Android C99.
    chm_lib_path=""
    for p in \
      base/thirdparty/kpvcrlib/crengine/thirdparty/chmlib/src/chm_lib.c \
      base/crengine/thirdparty/chmlib/src/chm_lib.c; do
      if [[ -f "$p" ]]; then
        chm_lib_path="$p"
        break
      fi
    done
    if [[ -n "$chm_lib_path" ]]; then
      substituteInPlace "$chm_lib_path" \
        --replace-fail 'int window_size = ffs(h->window_size) - 1;' 'int window_size = __builtin_ffs(h->window_size) - 1;'
    fi

    # Harfbuzz invokes gen-hb-version.py directly; ensure its shebang points
    # to a valid Python interpreter inside the Nix sandbox.
    harfbuzz_cfg_cmd='list(APPEND CFG_CMD COMMAND'
    harfbuzz_cfg_cmd_rewrite=$(cat <<'EOF'
list(APPEND PATCH_CMD COMMAND ''${ISED} "1s@^#!/usr/bin/env python3@#!${python3}/bin/python3@" src/gen-hb-version.py)
  list(APPEND PATCH_CMD COMMAND ''${ISED} "1s@^#!/usr/bin/env python3@#!${python3}/bin/python3@" src/gen-harfbuzzcc.py)

list(APPEND CFG_CMD COMMAND
EOF
)
    substituteInPlace base/thirdparty/harfbuzz/CMakeLists.txt \
      --replace-fail "$harfbuzz_cfg_cmd" "$harfbuzz_cfg_cmd_rewrite"

    # Glib also runs a Python generator directly during Meson/Ninja steps.
    glib_cfg_cmd='list(APPEND CFG_CMD COMMAND'
    glib_cfg_cmd_rewrite=$(cat <<'EOF'
list(APPEND PATCH_CMD COMMAND ''${ISED} "1s@^#!/usr/bin/env python3@#!${python3}/bin/python3@" tools/gen-visibility-macros.py)

list(APPEND CFG_CMD COMMAND
EOF
)
    substituteInPlace base/thirdparty/glib/CMakeLists.txt \
      --replace-fail "$glib_cfg_cmd" "$glib_cfg_cmd_rewrite"

    glib_patch_files='PATCH_FILES ''${PATCH_FILES}'
    glib_patch_files_rewrite=$(cat <<'EOF'
  PATCH_FILES ''${PATCH_FILES}
    PATCH_COMMAND ''${PATCH_CMD}
EOF
)
    substituteInPlace base/thirdparty/glib/CMakeLists.txt \
      --replace-fail "$glib_patch_files" "$glib_patch_files_rewrite"

  '';

  mkBuildEnv = ''
    export HOME="$TMPDIR/home"
    export SSL_CERT_FILE="${cacert}/etc/ssl/certs/ca-bundle.crt"
    export NIX_SSL_CERT_FILE="$SSL_CERT_FILE"
    mkdir -p "$HOME"
  '';

  koreaderDeps = stdenv.mkDerivation {
    pname = "koreader-deps";
    inherit version src;

    nativeBuildInputs = commonNativeBuildInputs;
    env = commonEnv;

    dontConfigure = true;
    dontPatchShebangs = true;
    postPatch = commonPostPatch;

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-BNmjtC/ucn0t5gfOBCTIwbFUF6w/7ow09I7X60vzx9o=";
    dontFixup = true;

    buildPhase = ''
      runHook preBuild

      ${mkBuildEnv}
      # Fetch third-party source dependencies into */build/downloads caches.
      make \
        TARGET=android \
        ANDROID_ARCH=arm64 \
        ANDROID_FLAVOR=Fdroid \
        KOR_BASE=base \
        download-all

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/src-downloads"

      # Copy download caches for reuse in the offline build.
      mapfile -t downloads_dirs < <(find base -type d -path '*/build/downloads' -print | sort)
      for d in "''${downloads_dirs[@]}"; do
        mkdir -p "$out/src-downloads/$(dirname "$d")"
        cp -a "$d" "$out/src-downloads/$d"
      done

      # Normalize git metadata the same way nixpkgs fetchgit does when
      # leaveDotGit = true, so cached repos remain usable and deterministic.
      . ${nixpkgsSrc}/pkgs/build-support/fetchgit/deterministic-git
      while IFS= read -r gitdir; do
        repo="$(readlink -f "$(dirname "$gitdir")")"
        git -C "$repo" fetch --unshallow >/dev/null 2>&1 || true
        git -C "$repo" remote set-head origin -d >/dev/null 2>&1 || true
        make_deterministic_repo "$repo"
      done < <(find "$out/src-downloads" -name .git | sort)

      # Fixed-output derivations must not keep runtime refs to build inputs.
      find "$out/src-downloads" -type f -exec remove-references-to -t "${stdenv.shell}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${androidSdk}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${jdk17_headless}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${cmake}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${gawk}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${git}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${gnugrep}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${gradle}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${meson}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${ninja}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${p7zip}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${perl}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${pkg-config}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${autoconf}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${automake}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${libtool}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${python3}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${util-linux}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${curl}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${unzip}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${which}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${zip}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${stdenv.cc}" '{}' + || true
      find "$out/src-downloads" -type f -exec remove-references-to -t "${stdenv.cc.cc}" '{}' + || true

      # Keep fixed-output hash stable across rebuilds.
      find "$out/src-downloads" -exec touch -h -d '@1' '{}' +

      runHook postInstall
    '';
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "koreader";
  inherit version src;

  nativeBuildInputs = commonNativeBuildInputs;
  env = commonEnv;

  dontConfigure = true;
  postPatch = ''
    patchShebangs .
    ${commonPostPatch}
  '';

  buildPhase = ''
    runHook preBuild

    ${mkBuildEnv}

    mkdir -p .empty-assets .empty-libs

    chmod -R u+w .
    cp -a "${koreaderDeps}/src-downloads/base/." base/
    chmod -R u+w base
    patchShebangs base

    # Some third-party downloaded sources are unpacked after patchPhase and may
    # still carry /usr/bin/env shebangs that are not usable in the sandbox.
    while IFS= read -r py; do
      substituteInPlace "$py" \
        --replace-fail '#!/usr/bin/env python3' '#!${python3}/bin/python3'
    done < <(grep -RIl '^#!/usr/bin/env python3' base || true)

    make \
      TARGET=android \
      ANDROID_ARCH=arm64 \
      ANDROID_FLAVOR=Fdroid \
      KOR_BASE=base \
      GRADLE_FLAGS="--offline" \
      update

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    apk_path="$(echo koreader-android-arm64-*.apk)"
    install -Dm644 "$apk_path" "$out/koreader.apk"

    runHook postInstall
  '';

  passthru = {
    deps = koreaderDeps;
  };

  meta = with lib; {
    description = "KOReader Android app (arm64 F-Droid flavor, built from source)";
    homepage = "https://github.com/koreader/koreader";
    license = licenses.agpl3Only;
    platforms = platforms.unix;
  };
})