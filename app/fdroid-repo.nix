{
  pkgs,
  androidSdk,
  apps ? [ ],
  repoVersion ? "unstable",
  repoName ? "Unofficial Repo",
  repoDescription ? "Unsigned F-Droid repository",
}:

let
  lib = pkgs.lib;

  appApkSources = map (app: app.apkPath) apps;

  allApkSources = appApkSources;

  appMetadata = lib.filter (x: x != null) (
    map (
      app:
      if app ? appId && app ? metadataYml then
        {
          appId = app.appId;
          file = pkgs.writeText "fdroid-metadata-${lib.replaceStrings [ "." ] [ "-" ] app.appId}.yml" app.metadataYml;
        }
      else
        null
    ) apps
  );
in
assert lib.assertMsg (
  allApkSources != [ ]
) "fdroid-repo.nix requires at least one APK source via apkSources or apps";

pkgs.stdenvNoCC.mkDerivation {
  pname = "fdroid-repo-unsigned";
  version = repoVersion;

  dontUnpack = true;

  buildPhase = ''
    runHook preBuild

    export HOME="$TMPDIR/home"
    mkdir -p "$HOME" unsigned metadata

    apk_count=0

    for src in ${lib.escapeShellArgs allApkSources}; do
      if [[ -d "$src" ]]; then
        while IFS= read -r apk; do
          badging="$(${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt dump badging "$apk")"
          pkg="$(echo "$badging" | sed -n "s/^package: name='\([^']*\)'.*/\1/p")"
          ver="$(echo "$badging" | sed -n "s/^package: .* versionCode='\([^']*\)'.*/\1/p")"
          if [[ -z "$pkg" || -z "$ver" ]]; then
            echo "Failed to parse package name/versionCode from $apk" >&2
            exit 1
          fi
          cp "$apk" "unsigned/''${pkg}_''${ver}.apk"
          apk_count=$((apk_count + 1))
        done < <(find "$src" -maxdepth 1 -type f -name '*.apk')
      elif [[ -f "$src" ]]; then
        badging="$(${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt dump badging "$src")"
        pkg="$(echo "$badging" | sed -n "s/^package: name='\([^']*\)'.*/\1/p")"
        ver="$(echo "$badging" | sed -n "s/^package: .* versionCode='\([^']*\)'.*/\1/p")"
        if [[ -z "$pkg" || -z "$ver" ]]; then
          echo "Failed to parse package name/versionCode from $src" >&2
          exit 1
        fi
        cp "$src" "unsigned/''${pkg}_''${ver}.apk"
        apk_count=$((apk_count + 1))
      else
        echo "APK source does not exist: $src" >&2
        exit 1
      fi
    done

    if [[ "$apk_count" -eq 0 ]]; then
      echo "No APK files found in apkSources" >&2
      exit 1
    fi

    ${lib.concatMapStringsSep "\n" (entry: "cp ${entry.file} metadata/${entry.appId}.yml") appMetadata}

    cat > config.yml << EOF
    repo_name: ${repoName}
    repo_description: ${repoDescription}
    repo_url: https://mio-19.github.io/fdroid-repo/repo
    EOF

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -R unsigned "$out/unsigned"
    cp -R metadata "$out/metadata"
    cp config.yml "$out/config.yml"
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Unsigned F-Droid repository containing one or more apps";
    platforms = platforms.unix;
  };
}
