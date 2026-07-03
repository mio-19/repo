{
  pkgs,
  androidSdk,
  apps ? [ ],
  repoVersion ? "unstable",
  repoName ? "Unofficial Repo",
  repoDescription ? "Unsigned F-Droid repository",
  repoUrl ? "https://mio-19.github.io/fdroid-repo/repo",
}:

let
  lib = pkgs.lib;

  appCommands = lib.concatMapStringsSep "\n" (app: ''
    src=${lib.escapeShellArg app.apkPath}
    destDir=${if app.preSigned then "repo" else "unsigned"}
    if [[ -d "$src" ]]; then
      while IFS= read -r apk; do
        process_apk "$apk" "$destDir"
      done < <(find "$src" -maxdepth 1 -type f -name '*.apk')
    elif [[ -f "$src" ]]; then
      process_apk "$src" "$destDir"
    else
      echo "APK source does not exist: $src" >&2
      exit 1
    fi
  '') apps;

  appMetadata = map (app: {
    appId = app.appId;
    file = pkgs.writeText "fdroid-metadata-${lib.replaceStrings [ "." ] [ "-" ] app.appId}.yml" app.metadataYml;
  }) apps;
in
assert lib.assertMsg (apps != [ ]) "fdroid-repo.nix requires at least one app";

pkgs.stdenvNoCC.mkDerivation {
  pname = "fdroid-repo-unsigned";
  version = repoVersion;

  dontUnpack = true;

  nativeBuildInputs = [ pkgs.coreutils ];

  buildPhase = ''
        runHook preBuild

        export HOME="$TMPDIR/home"
        mkdir -p "$HOME" unsigned repo metadata

        apk_count=0

        process_apk() {
          local apk="$1"
          local destDir="$2"
          local badging pkg ver apk_abs
          
          badging="$(${androidSdk}/share/android-sdk/build-tools/36.1.0/aapt dump badging "$apk")"
          pkg="$(echo "$badging" | sed -n "s/^package: name='\([^']*\)'.*/\1/p")"
          ver="$(echo "$badging" | sed -n "s/^package: .* versionCode='\([^']*\)'.*/\1/p")"
          
          if [[ -z "$pkg" || -z "$ver" ]]; then
            echo "Failed to parse package name/versionCode from $apk" >&2
            exit 1
          fi
          
          apk_abs="$(readlink -f "$apk")"
          if [[ -z "$apk_abs" ]]; then
            echo "Failed to resolve absolute path for $apk" >&2
            exit 1
          fi
          
          ln -s "$apk_abs" "$destDir/''${pkg}_''${ver}.apk"
          apk_count=$((apk_count + 1))
        }

    ${appCommands}

        if [[ "$apk_count" -eq 0 ]]; then
          echo "No APK files found in apkSources" >&2
          exit 1
        fi

        ${lib.concatMapStringsSep "\n" (
          entry: "cp ${entry.file} metadata/${entry.appId}.yml"
        ) appMetadata}

        echo "repo_name: ${repoName}" > config.yml
        echo "repo_description: ${repoDescription}" >> config.yml
        echo "repo_url: ${repoUrl}" >> config.yml

        runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    mv unsigned "$out/unsigned"
    mv repo "$out/repo"
    mv metadata "$out/metadata"
    mv config.yml "$out/config.yml"
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Unsigned F-Droid repository containing one or more apps";
    platforms = platforms.unix;
  };
}
