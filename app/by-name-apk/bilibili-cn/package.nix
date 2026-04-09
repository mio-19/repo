{
  mk-apk-package,
  lib,
  stdenv,
  fetchurl,
  jdk25,
  lspatch-cli,
  biliroaming,
}:
let
  appPackage =
    let
      bilibiliApk = fetchurl {
        # https://www.apkmirror.com/apk/bilibili/bilibili-哔哩哔哩/bilibili-all-your-fav-videos-8-71-0-release/bilibili-all-your-fav-videos-8-71-0-3-android-apk-download/
        name = "tv.danmaku.bili-apkmirror-8.71.0-arm64-v8a.apk";
        url = "https://web.archive.org/web/20260326020743if_/https://eb5e7388c3df147b74dd2379b7cf8323.r2.cloudflarestorage.com/downloadprod/wp-content/uploads/2025/11/75/691ec673cdddf/tv.danmaku.bili_8.71.0-8710600_minAPI23%28arm64-v8a%29%28nodpi%29_apkmirror.com.apk?X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=72a5ba3a0b8a601e535d5525f12f8177%2F20260326%2Fauto%2Fs3%2Faws4_request&X-Amz-Date=20260326T020701Z&X-Amz-SignedHeaders=host&X-Amz-Expires=3600&X-Amz-Signature=ae2a0023e1bdb42d981e9f8e52b8332c999de82a13fdd34c797f907bd4ab6e56";
        hash = "sha256-5hTU/KR/ins7uz5uf/DbZc3U+nFV9mBT64QkAiwJskY=";
      };
    in
    stdenv.mkDerivation {
      pname = "bilibili-cn";
      version = "8.71.0";

      dontUnpack = true;

      nativeBuildInputs = [
        jdk25
      ];

      env = {
        JAVA_HOME = jdk25;
      };

      buildPhase = ''
        runHook preBuild

        workdir="$TMPDIR/bilibili-cn"
        mkdir -p "$workdir" "$workdir/out"

        cp "${bilibiliApk}" "$workdir/bilibili.apk"

        ${lib.getExe lspatch-cli} \
          --force \
          --output "$workdir/out" \
          --embed "${biliroaming}/biliroaming.apk" \
          "$workdir/bilibili.apk"

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        output_apk="$(ls "$workdir/out"/*-lspatched.apk 2>/dev/null | head -n1)"
        if [ -z "$output_apk" ]; then
          echo "No patched APK produced" >&2
          exit 1
        fi
        install -Dm644 "$output_apk" "$out/bilibili-cn.apk"
        runHook postInstall
      '';

      passthru = {
        inherit bilibiliApk;
      };

      meta = with lib; {
        description = "Bilibili cn client patched with the latest BiliRoaming Xposed module via LSPatch";
        homepage = "https://github.com/yujincheng08/BiliRoaming";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "bilibili-cn.apk";
  signScriptName = "sign-bilibili-cn";
  fdroid = {
    appId = "tv.danmaku.bili";
    metadataYml = ''
      Categories:
        - Video Players & Editors
      License: Proprietary
      SourceCode: https://github.com/yujincheng08/BiliRoaming
      IssueTracker: https://github.com/yujincheng08/BiliRoaming/issues
      AutoName: BiliBili CN
      Summary: BiliBili patched with BiliRoaming via LSPatch
      Description: |-
        BiliBili Roaming embeds the latest BiliRoaming Xposed module
        using LSPatch so the official BiliBili client bypasses region
        locks and gains other enhancements without root.
    '';
  };
}
