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

    preBuild = lib.optionalString hasGradleBuild disableLintHook + (old.preBuild or "");

    preGradleUpdate = lib.optionalString hasGradleBuild disableLintHook + (old.preGradleUpdate or "");

    meta =
      (old.meta or { })
      // {
        inherit mainApk;
      }
      // lib.optionalAttrs (fdroid != null) fdroid;
  }
)
