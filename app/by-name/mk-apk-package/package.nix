{
  lib,
  mkSignScript,
}:
{
  appPackage,
  mainApk,
  signScriptName,
  defaultOut ? "${lib.removeSuffix ".apk" mainApk}-signed.apk",
  fdroid ? null,
}:

appPackage.overrideAttrs (
  finalAttrs: old:
  let
    hasGradleBuild =
      old ? gradleBuildTask
      || old ? gradleUpdateTask
      || old ? gradleCheckTask
      || old ? gradleBuildFlagsArray
      || old ? gradleFlags;

    # Centralize Gradle lint disabling for APK packages here instead of
    # repeating package-local -xlintVitalRelease flags. This avoids fetching
    # SDK index endpoints such as play-sdk/index/snapshot and group-index for
    # projects where those requests come from lint. Context:
    # https://github.com/NixOS/nixpkgs/issues/501643#issuecomment-4122356032
    disableLintHook = ''
      disableGradleLintTasks() {
        if [[ -n "''${disableGradleLintTasksDone:-}" ]]; then
          return
        fi

        if ! type gradle >/dev/null 2>&1; then
          return
        fi

        local task
        local leaf
        local -a lintTasks=()

        while IFS= read -r task; do
          leaf="''${task##*:}"
          case "$leaf" in
            lint|lint[A-Z]*)
              lintTasks+=("$task")
              ;;
          esac
        done < <(
          gradle -q tasks --all 2>/dev/null \
            | awk '/^[[:space:]]*[:[:alnum:]_.-]+[[:space:]]+- / { print $1 }' \
            | sort -u
        )

        if [[ "''${#lintTasks[@]}" -eq 0 ]]; then
          return
        fi

        for task in "''${lintTasks[@]}"; do
          gradleFlagsArray+=("-x$task")
        done

        disableGradleLintTasksDone=1
      }

      disableGradleLintTasks
    '';

    # Darwin: mitm-cache needs loopback (nixpkgs gradle docs) and preferIPv4Stack
    # so Java dual-stack ::ffff:127.0.0.1 is not treated as non-localhost
    # (see NixOS/nix#11270 discussion).
    darwinGradleMitmHook = ''
      if [[ "$(uname -s)" = Darwin ]]; then
        export GRADLE_OPTS="''${GRADLE_OPTS:-} -Djava.net.preferIPv4Stack=true"
      fi
    '';
  in
  {
    passthru = (old.passthru or { }) // {
      signScript = mkSignScript {
        name = signScriptName;
        apkPath = "${finalAttrs.finalPackage}/${mainApk}";
        inherit defaultOut;
      };
    };

    meta =
      (old.meta or { })
      // {
        inherit mainApk;
      }
      // lib.optionalAttrs (fdroid != null) fdroid;
  }
  // lib.optionalAttrs hasGradleBuild {
    preBuild = disableLintHook + darwinGradleMitmHook + (old.preBuild or "");
    preGradleUpdate = disableLintHook + darwinGradleMitmHook + (old.preGradleUpdate or "");
    __darwinAllowLocalNetworking = true;
  }
)
