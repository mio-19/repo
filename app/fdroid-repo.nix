{
  pkgs,
  apkSources ? [ ],
  apps ? [ ],
  repoVersion ? "unstable",
  repoName ? "Forkgram Unofficial Repo",
  repoDescription ? "Unsigned F-Droid repository for Forkgram builds",
}:

let
  lib = pkgs.lib;

  appApkSources = lib.concatMap (
    app:
    (if app ? apkPath then [ app.apkPath ] else [ ])
    ++ (if app ? apkSources then app.apkSources else [ ])
  ) apps;

  allApkSources = apkSources ++ appApkSources;

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
  pname = "forkgram-fdroid-repo-unsigned";
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
          cp "$apk" unsigned/
          apk_count=$((apk_count + 1))
        done < <(find "$src" -maxdepth 1 -type f -name '*.apk')
      elif [[ -f "$src" ]]; then
        cp "$src" unsigned/
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
    repo_url: https://example.invalid/fdroid/repo
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
