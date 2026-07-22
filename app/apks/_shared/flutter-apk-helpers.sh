# Shared shell helpers for Flutter APK builds under app/apks/.
# Source from postPatch/preBuild:  . "${flutterApkHelpers}"
#
# Expected env (set by the calling package.nix before sourcing as needed):
#   FLUTTER_SDK_STORE   – nix store path of the Flutter package (for setup_writable_flutter_sdk)
#   GRADLE_BIN          – path to gradle executable (for setup_pinned_gradlew)

setup_writable_flutter_sdk() {
  local flutter_store="${1:-${FLUTTER_SDK_STORE:?FLUTTER_SDK_STORE unset}}"
  cp -LR "$flutter_store" flutter-sdk
  chmod -R u+w flutter-sdk
  # https://github.com/NixOS/nixpkgs/pull/500309#issuecomment-4192628176
  touch flutter-sdk/bin/cache/engine.realm
  if [ -x flutter-sdk/bin/cache/artifacts/engine/linux-x64/font-subset ]; then
    chmod +x flutter-sdk/bin/cache/artifacts/engine/linux-x64/font-subset
  fi
  # Other engine ABIs may also ship font-subset; make any present copy executable.
  find flutter-sdk/bin/cache/artifacts/engine -type f -name font-subset -exec chmod +x {} + 2>/dev/null || true
}

setup_pinned_gradlew() {
  local gradle_bin="${1:-${GRADLE_BIN:?GRADLE_BIN unset}}"
  local extra_args="${2:-}"
  # Expand gradle_bin/extra_args now; leave "$@" for the runtime wrapper.
  cat > android/gradlew <<EOF
#!/bin/sh
exec ${gradle_bin}${extra_args:+ $extra_args} "\$@"
EOF
  chmod +x android/gradlew
}

append_mitm_gradle_opts() {
  GRADLE_OPTS="${GRADLE_OPTS:-}"
  if [[ -n "${MITM_CACHE_KEYSTORE:-}" ]]; then
    GRADLE_OPTS="$GRADLE_OPTS -Dhttp.proxyHost=$MITM_CACHE_HOST"
    GRADLE_OPTS="$GRADLE_OPTS -Dhttp.proxyPort=$MITM_CACHE_PORT"
    GRADLE_OPTS="$GRADLE_OPTS -Dhttps.proxyHost=$MITM_CACHE_HOST"
    GRADLE_OPTS="$GRADLE_OPTS -Dhttps.proxyPort=$MITM_CACHE_PORT"
    GRADLE_OPTS="$GRADLE_OPTS -Djavax.net.ssl.trustStore=$MITM_CACHE_KEYSTORE"
    GRADLE_OPTS="$GRADLE_OPTS -Djavax.net.ssl.trustStorePassword=$MITM_CACHE_KS_PWD"
  fi
  export GRADLE_OPTS
}

clone_dart_package() {
  local source_dir="$1"
  local patched_name="$2"
  local patched_dir="$PWD/.dart-patched/$patched_name"

  cp -LR "$source_dir" "$patched_dir"
  chmod -R u+w "$patched_dir"
  printf '%s\n' "$patched_dir"
}

# package_config rootUri often ends with "/." — strip that before basename.
dart_package_basename() {
  local dir="${1%/}"
  dir="${dir%/.}"
  basename "$dir"
}

replace_dart_package_root() {
  local original_dir="$1"
  local patched_dir="$2"

  substituteInPlace .dart_tool/package_config.json \
    --replace-fail "$original_dir" "$patched_dir"
}

replace_flutter_plugin_root() {
  local original_dir="$1"
  local patched_dir="$2"

  if [ -f .flutter-plugins-dependencies ] && grep -Fq "$original_dir" .flutter-plugins-dependencies; then
    substituteInPlace .flutter-plugins-dependencies \
      --replace-fail "$original_dir" "$patched_dir"
  fi

  if [ -f .flutter-plugins ] && grep -Fq "$original_dir" .flutter-plugins; then
    substituteInPlace .flutter-plugins \
      --replace-fail "$original_dir" "$patched_dir"
  fi
}

remap_dart_package_root() {
  local original_dir="$1"
  local patched_dir="$2"

  replace_dart_package_root "$original_dir" "$patched_dir"
  replace_flutter_plugin_root "$original_dir" "$patched_dir"
}

# Clone a nix-store Dart package root into .dart-patched and remap package_config /
# flutter plugin metadata. Uses associative array patched_pkg_dirs for dedup.
# Caller must: declare -A patched_pkg_dirs; mkdir -p .dart-patched
ensure_writable_dart_package() {
  local package_dir="$1"
  local work_dir="$package_dir"
  local name

  if [[ "$package_dir" == /nix/store/* ]]; then
    if [ -z "${patched_pkg_dirs[$package_dir]:-}" ]; then
      name="$(dart_package_basename "$package_dir")"
      patched_pkg_dirs[$package_dir]="$(clone_dart_package "$package_dir" "$name")"
      if grep -Fq "$package_dir" .dart_tool/package_config.json; then
        replace_dart_package_root "$package_dir" "${patched_pkg_dirs[$package_dir]}"
      fi
      replace_flutter_plugin_root "$package_dir" "${patched_pkg_dirs[$package_dir]}"
    fi
    work_dir="${patched_pkg_dirs[$package_dir]}"
  fi
  printf '%s\n' "$work_dir"
}
