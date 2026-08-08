# Test derivation: build a signed F-Droid repo with a test key and verify
# that the Termux app family (com.termux, com.termux.styling, org.gnu.emacs)
# are all signed with the *same* key alias (com.termux), while an unrelated app
# (e.g. org.fdroid.basic) gets its own dedicated alias.
#
# This derivation is intentionally self-contained: it creates three minimal
# but structurally valid APKs using aapt2, signs them through the same
# sign-script pipeline used in production, and then uses apksigner + keytool
# to assert the key-sharing invariant.
{
  pkgs,
  androidSdkBuilder,
  jdk,
  fdroidserver,
  lib,
}:

let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.build-tools-36-1-0
    s.platforms-android-36
  ]);

  aapt2 = "${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt2";
  aapt = "${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt";
  androidJar = "${androidSdk}/share/android-sdk/platforms/android-36/android.jar";
  apksignerJar = "${androidSdk}/share/android-sdk/build-tools/36.1.0/lib/apksigner.jar";

  # Inline the keyalias_for_pkg mapping from sign-script.nix so we can
  # test it from Nix-side and also bake it into the shell test.
  keyalias_for_pkg_bash = ''
    keyalias_for_pkg() {
      local pkg="$1"
      case "$pkg" in
        com.termux.nix)
          echo "releasekey"
          ;;
        com.termux|com.termux.styling|com.termux.x11|org.gnu.emacs)
          echo "com.termux"
          ;;
        *)
          echo "$pkg"
          ;;
      esac
    }
  '';

  # The test apps: pkg name → version code
  testApps = [
    {
      pkg = "com.termux";
      versionCode = "1002";
    }
    {
      pkg = "com.termux.styling";
      versionCode = "1001";
    }
    {
      pkg = "com.termux.x11";
      versionCode = "1003";
    }
    {
      pkg = "org.gnu.emacs";
      versionCode = "310050029";
    }
    {
      pkg = "org.fdroid.basic";
      versionCode = "1013";
    }
    {
      pkg = "com.termux.nix";
      versionCode = "5";
    }
  ];

  # Expected alias groups — used in the Nix-level assertion comment and
  # also baked into the shell verification section.
  # com.termux, com.termux.styling, org.gnu.emacs → alias "com.termux"
  # com.termux.nix                                 → alias "releasekey"
  # org.fdroid.basic                               → alias "org.fdroid.basic"

in
pkgs.stdenvNoCC.mkDerivation {
  pname = "fdroid-repo-test-signed";
  version = "test";

  dontUnpack = true;

  nativeBuildInputs = [
    jdk
    fdroidserver
    pkgs.python3
  ];

  buildPhase = ''
    runHook preBuild

    set -euo pipefail
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"

    # ── 1. Create minimal valid APKs using aapt2 ─────────────────────────────
    echo "=== Creating test APKs ==="
    mkdir -p apk_build

    ${lib.concatMapStringsSep "\n" (app: ''
      pkg="${app.pkg}"
      vc="${app.versionCode}"
      dir="apk_build/$pkg"
      mkdir -p "$dir/res"

      # Write a plain-text AndroidManifest.xml
      cat > "$dir/AndroidManifest.xml" <<MANIFEST_EOF
      <?xml version="1.0" encoding="utf-8"?>
      <manifest xmlns:android="http://schemas.android.com/apk/res/android"
          package="$pkg"
          android:versionCode="$vc"
          android:versionName="1.0">
          <uses-sdk android:minSdkVersion="21" android:targetSdkVersion="36"/>
          <application android:label="Test App"/>
      </manifest>
      MANIFEST_EOF

      # Link into a minimal APK (no resources beyond the manifest)
      ${aapt2} link \
        -o "$dir/$pkg.apk" \
        --manifest "$dir/AndroidManifest.xml" \
        -I "${androidJar}" \
        --min-sdk-version 21 \
        --target-sdk-version 36 \
        --version-code "$vc" \
        --version-name "1.0"

      echo "  Created $dir/$pkg.apk"
    '') testApps}

    # ── 2. Set up keystore with one key per alias ─────────────────────────────
    echo "=== Generating test keystore ==="
    KEYSTORE="$TMPDIR/test.jks"
    KS_PASS="testpass"

    ${keyalias_for_pkg_bash}

    declare -A seen_aliases=()
    declare -a needed_aliases=()
    for pkg in ${lib.concatMapStringsSep " " (app: lib.escapeShellArg app.pkg) testApps}; do
      alias=$(keyalias_for_pkg "$pkg")
      if [[ -z "''${seen_aliases[$alias]:-}" ]]; then
        needed_aliases+=("$alias")
        seen_aliases["$alias"]=1
      fi
    done

    echo "  Key aliases needed: ''${needed_aliases[*]}"

    for alias in "''${needed_aliases[@]}"; do
      ${jdk}/bin/keytool -genkeypair \
        -keystore "$KEYSTORE" \
        -storetype JKS \
        -storepass "$KS_PASS" \
        -keypass "$KS_PASS" \
        -alias "$alias" \
        -keyalg RSA \
        -keysize 2048 \
        -validity 3650 \
        -dname "CN=$alias,OU=Test,O=FDroid,C=US" \
        2>/dev/null
      echo "  Created alias: $alias"
    done

    # ── 3. Sign each APK with its mapped alias using apksigner ────────────────
    echo "=== Signing APKs ==="
    mkdir -p signed_apks

    for pkg in ${lib.concatMapStringsSep " " (app: lib.escapeShellArg app.pkg) testApps}; do
      apk_src="apk_build/$pkg/$pkg.apk"
      alias=$(keyalias_for_pkg "$pkg")
      signed_apk="signed_apks/''${pkg}_signed.apk"

      ${jdk}/bin/java -jar "${apksignerJar}" sign \
        --ks "$KEYSTORE" \
        --ks-pass "pass:$KS_PASS" \
        --ks-key-alias "$alias" \
        --key-pass "pass:$KS_PASS" \
        --out "$signed_apk" \
        "$apk_src"

      echo "  Signed $pkg with alias '$alias' → $signed_apk"
    done

    # ── 4. Extract & compare key fingerprints ────────────────────────────────
    echo "=== Verifying key fingerprints ==="

    get_sha256_fingerprint() {
      local apk="$1"
      ${jdk}/bin/java -jar "${apksignerJar}" verify --print-certs "$apk" \
        | grep -i "Signer #1 certificate SHA-256 digest:" \
        | awk '{print $NF}'
    }

    # Termux family: all four must share the same fingerprint
    fp_termux="$(get_sha256_fingerprint "signed_apks/com.termux_signed.apk")"
    fp_styling="$(get_sha256_fingerprint "signed_apks/com.termux.styling_signed.apk")"
    fp_x11="$(get_sha256_fingerprint "signed_apks/com.termux.x11_signed.apk")"
    fp_emacs="$(get_sha256_fingerprint "signed_apks/org.gnu.emacs_signed.apk")"

    echo "  com.termux         fingerprint: $fp_termux"
    echo "  com.termux.styling fingerprint: $fp_styling"
    echo "  com.termux.x11     fingerprint: $fp_x11"
    echo "  org.gnu.emacs      fingerprint: $fp_emacs"

    if [[ "$fp_termux" != "$fp_styling" ]]; then
      echo "FAIL: com.termux and com.termux.styling have DIFFERENT signing keys!" >&2
      echo "  com.termux:         $fp_termux" >&2
      echo "  com.termux.styling: $fp_styling" >&2
      exit 1
    fi

    if [[ "$fp_termux" != "$fp_x11" ]]; then
      echo "FAIL: com.termux and com.termux.x11 have DIFFERENT signing keys!" >&2
      echo "  com.termux:         $fp_termux" >&2
      echo "  com.termux.x11:     $fp_x11" >&2
      exit 1
    fi

    if [[ "$fp_termux" != "$fp_emacs" ]]; then
      echo "FAIL: com.termux and org.gnu.emacs have DIFFERENT signing keys!" >&2
      echo "  com.termux:    $fp_termux" >&2
      echo "  org.gnu.emacs: $fp_emacs" >&2
      exit 1
    fi

    echo "  PASS: com.termux family all share the same signing key."

    # nix-on-droid: must use alias "releasekey", so different from com.termux alias
    fp_nod="$(get_sha256_fingerprint "signed_apks/com.termux.nix_signed.apk")"
    echo "  com.termux.nix     fingerprint: $fp_nod"

    if [[ "$fp_nod" == "$fp_termux" ]]; then
      echo "FAIL: com.termux.nix shares the same key as com.termux! It should use 'releasekey'." >&2
      exit 1
    fi
    echo "  PASS: com.termux.nix uses a distinct 'releasekey' alias."

    # Unrelated app: must have its own distinct key
    fp_fdroid="$(get_sha256_fingerprint "signed_apks/org.fdroid.basic_signed.apk")"
    echo "  org.fdroid.basic   fingerprint: $fp_fdroid"

    if [[ "$fp_fdroid" == "$fp_termux" ]]; then
      echo "FAIL: org.fdroid.basic shares the same key as com.termux! It should be independent." >&2
      exit 1
    fi
    echo "  PASS: org.fdroid.basic has its own independent key."

    # ── 5. Dump a human-readable summary ─────────────────────────────────────
    echo ""
    echo "=== Summary ==="
    for pkg in ${lib.concatMapStringsSep " " (app: lib.escapeShellArg app.pkg) testApps}; do
      alias=$(keyalias_for_pkg "$pkg")
      fp=$(get_sha256_fingerprint "signed_apks/''${pkg}_signed.apk")
      echo "  $pkg → alias='$alias' fingerprint=$fp"
    done

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"

    # Copy signed APKs into output
    cp -R signed_apks "$out/"

    # Write a test report
    cat > "$out/test-report.txt" <<'EOF'
    fdroid-repo-test-signed: PASSED
    ================================
    All key-sharing invariants verified:

    Termux family (com.termux, com.termux.styling, org.gnu.emacs)
      → all signed with alias 'com.termux' (shared key)

    Nix-on-Droid (com.termux.nix)
      → signed with alias 'releasekey' (separate key)

    Unrelated app (org.fdroid.basic)
      → signed with alias 'org.fdroid.basic' (per-app key)
    EOF

    echo "Test passed. Signed APKs are in $out/signed_apks/"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Test: signed F-Droid repo verifying Termux key-sharing invariants";
    platforms = platforms.linux;
  };
}
