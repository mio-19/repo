#!/bin/sh
set -eu

# Copy a prebuilt libhub.so into Cargokit's jni output dirs.
# The shared library is built with pkgsCross in package.nix.

build_one_android() {
  platform="$1"
  case "$platform" in
    android-arm64) abi=arm64-v8a ;;
    android-arm) abi=armeabi-v7a ;;
    android-x64) abi=x86_64 ;;
    android-x86) abi=x86 ;;
    *)
      echo "skipping unsupported Cargokit platform: $platform" >&2
      return 0
      ;;
  esac

  if [ -z "${UPLINK_LIBHUB_SO:-}" ] || [ ! -f "${UPLINK_LIBHUB_SO}" ]; then
    echo "UPLINK_LIBHUB_SO is not set or missing" >&2
    exit 1
  fi
  mkdir -p "${CARGOKIT_OUTPUT_DIR}/${abi}"
  cp -v "${UPLINK_LIBHUB_SO}" "${CARGOKIT_OUTPUT_DIR}/${abi}/libhub.so"
}

cmd="${1:-}"
case "$cmd" in
  build-gradle)
    OLD_IFS=$IFS
    IFS=,
    for platform in ${CARGOKIT_TARGET_PLATFORMS}; do
      IFS=$OLD_IFS
      build_one_android "$platform"
    done
    ;;
  *)
    echo "unsupported cargokit command: $cmd" >&2
    exit 1
    ;;
esac
