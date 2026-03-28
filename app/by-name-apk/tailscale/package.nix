{ callPackage, raw }:
callPackage ../mk-apk-package.nix {
  appPackage = raw.tailscale;
  mainApk = "tailscale.apk";
  signScriptName = "sign-tailscale";
  fdroid = {
    appId = "com.tailscale.ipn";
    metadataYml = ''
      Categories:
        - Internet
      License: BSD-3-Clause
      WebSite: https://tailscale.com/
      SourceCode: https://github.com/tailscale/tailscale-android
      IssueTracker: https://github.com/tailscale/tailscale-android/issues
      Changelog: https://github.com/tailscale/tailscale-android/releases
      AutoName: Tailscale
      Summary: Mesh VPN client
      Description: |-
        Tailscale is a mesh VPN client for connecting devices over a
        private WireGuard-based network.
        This package is built from source from the upstream
        tailscale-android repository.
    '';
  };
}
