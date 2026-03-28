{
  lib,
  mkSignScript,
  appPackage,
  mainApk,
  signScriptName,
  defaultOut ? "${lib.removeSuffix ".apk" mainApk}-signed.apk",
  fdroid ? null,
}:

appPackage.overrideAttrs (old: {
  passthru = (old.passthru or { }) // {
    signScript = mkSignScript {
      name = signScriptName;
      apkPath = "${appPackage}/${mainApk}";
      inherit defaultOut;
    };
  };

  meta =
    (old.meta or { })
    // {
      inherit mainApk;
    }
    // lib.optionalAttrs (fdroid != null) fdroid;
})
