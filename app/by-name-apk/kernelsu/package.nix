{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.kernelsu;
  mainApk = "kernelsu.apk";
  signScriptName = "sign-kernelsu";
  fdroid = {
    appId = "me.weishu.kernelsu";
    metadataYml = ''
      Categories:
        - System
      License: GPL-3.0-or-later
      WebSite: https://kernelsu.org/
      SourceCode: https://github.com/tiann/KernelSU
      IssueTracker: https://github.com/tiann/KernelSU/issues
      Changelog: https://github.com/tiann/KernelSU/releases
      AutoName: KernelSU
      Summary: Kernel-based root manager
      Description: |-
        KernelSU is a kernel-based root solution for Android with a
        companion manager app for granting root access, managing modules,
        and configuring policies.

        This package is the upstream manager app built from source.
      RequiresRoot: true
    '';
  };
}
