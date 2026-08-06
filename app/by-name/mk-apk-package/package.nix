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

      preventGradleDaemonFork() {
        if [[ -n "''${preventGradleDaemonForkDone:-}" ]]; then
          return
        fi
        
        if [ -f gradle.properties ]; then
          local propJvmArgs
          propJvmArgs="$(grep '^org\.gradle\.jvmargs=' gradle.properties | cut -d= -f2-)"
          if [ -n "$propJvmArgs" ]; then
            export JAVA_OPTS="''${JAVA_OPTS:-} $propJvmArgs"
          fi
        fi
        
        # Force Gradle Daemon to use IPv4 so that it connects to the daemon or mitm-cache
        # over 127.0.0.1 which is permitted by __darwinAllowLocalNetworking.
        gradleFlagsArray+=("-Djava.net.preferIPv4Stack=true" "-Dorg.gradle.jvmargs=-Djava.net.preferIPv4Stack=true")
        export JAVA_OPTS="''${JAVA_OPTS:-} -Djava.net.preferIPv4Stack=true"
        
        preventGradleDaemonForkDone=1
      }

      disableGradleLintTasks
      preventGradleDaemonFork
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
    preBuild = disableLintHook + ''
      export mitmCacheWrapperScript="$(mktemp)"
      cat << 'EOF' > "$mitmCacheWrapperScript"
      #!/bin/sh
      echo "Starting mitm-cache wrapper..." > .mitm-cache.log
      mitm-cache "$@" >> .mitm-cache.log 2>&1
      EOF
      chmod +x "$mitmCacheWrapperScript"
      # We override mitm-cache in PATH so gradleConfigureHook calls our wrapper
      mkdir -p ./bin
      ln -s "$mitmCacheWrapperScript" ./bin/mitm-cache
      export PATH="$(pwd)/bin:$PATH"
    '' + (old.preBuild or "");
    preGradleUpdate = disableLintHook + (old.preGradleUpdate or "");
    # The mitmCache setup-hook runs ephemeral-port-reserve to find a free
    # localhost port for the MITM proxy. This requires socket bind access
    # which the macOS sandbox blocks by default.
    __darwinAllowLocalNetworking = true;
  }
)
