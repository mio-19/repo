{
  mk-apk-package,
  lib,
  stdenv,
  fetchurl,
  apkeditor,
  jdk21,
  lspatch-cli,
  biliroaming,
}:
let
  appPackage =
    let
      bilibiliXapk = fetchurl {
        # APKPure page: https://apkpure.com/bilibili-cn/com.bilibili.app.in/download
        name = "bilibili-3.20.4.xapk";
        url = "https://web.archive.org/web/20260325091913if_/https://d-e03.winudf.com/b/XAPK/Y29tLmJpbGliaWxpLmFwcC5pbl84MjMwODAwX2QwOTQ0MWNl?_fn=5ZOU5ZOp5ZOU5ZOpXzMuMjAuNF9BUEtQdXJlLnhhcGs&_p=Y29tLmJpbGliaWxpLmFwcC5pbg%3D%3D&download_id=1604604969224655&is_hot=true&k=73a846966fe740e9afd465bec8c4939c69c4fa05&uu=https%3A%2F%2Fd-13.winudf.com%2Fb%2FXAPK%2FY29tLmJpbGliaWxpLmFwcC5pbl84MjMwODAwX2QwOTQ0MWNl%3Fk%3D8ae72aafe12b58b2181c4f65b92ffe4e69c4fa05";
        hash = "sha256-A+kdswvRBcK8/4Voo5++Hq3VzKBWQW4FrU6HJyhp7As=";
      };

      version = "3.20.4-lspatched";
    in
    stdenv.mkDerivation {
      pname = "bilibili-roaming";
      inherit version;

      dontUnpack = true;

      nativeBuildInputs = [
        apkeditor
        jdk21
      ];

      env = {
        JAVA_HOME = jdk21;
      };

      buildPhase = ''
        runHook preBuild

        workdir="$TMPDIR/bilibili-roaming"
        mkdir -p "$workdir" "$workdir/out"
        cp ${bilibiliXapk} "$workdir/bilibili.xapk"
        chmod u+w "$workdir/bilibili.xapk"

        APKEditor m -i "$workdir/bilibili.xapk" -o "$workdir/bilibili-base.apk"

        ${lib.getExe lspatch-cli} \
          --force \
          --output "$workdir/out" \
          --embed "${biliroaming}/biliroaming.apk" \
          "$workdir/bilibili-base.apk"

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        output_apk="$(ls "$workdir/out"/*-lspatched.apk 2>/dev/null | head -n1)"
        if [ -z "$output_apk" ]; then
          echo "No patched APK produced" >&2
          exit 1
        fi
        install -Dm644 "$output_apk" "$out/bilibili-roaming.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Bilibili client patched with the latest BiliRoaming Xposed module via LSPatch";
        homepage = "https://github.com/yujincheng08/BiliRoaming";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "bilibili-roaming.apk";
  signScriptName = "sign-bilibili-roaming";
  fdroid = {
    appId = "com.bilibili.app.in";
    metadataYml = ''
      Categories:
        - Video Players & Editors
      License: Proprietary
      SourceCode: https://github.com/yujincheng08/BiliRoaming
      IssueTracker: https://github.com/yujincheng08/BiliRoaming/issues
      AutoName: BiliBili Play
      Summary: BiliBili Google Play version patched with BiliRoaming via LSPatch
      Description: |-
        BiliBili Roaming embeds the latest BiliRoaming Xposed module
        using LSPatch so the official BiliBili client bypasses region
        locks and gains other enhancements without root.
    '';
  };
}
