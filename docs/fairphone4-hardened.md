# Fairphone 4: LineageOS with AXP.OS hardening

The `los.FP4` configuration builds the pinned LineageOS 24.0 sources for the
Fairphone 4 (`FP4`). It imports the repository's conservative AXP.OS userspace
hardening subset in `los/hardened_24_0.nix`. This is a downstream LineageOS build,
not an official AXP.OS release or the complete AXP.OS patch set.

The AXP.OS FP4 kernel script was checked against the pinned 4.19.325 kernel in
cumulative order: 161 of its 295 active entries apply, 112 are already present,
19 do not apply, and 3 use a subdirectory application mode that the current
Robotnix kernel patch hook does not support. The 161 cleanly applying patches
are included in `kernel/fairphone_sm7225_axp_patches.nix` in script order. The
Nix patch hook's GNU `patch` matching behavior was used for this selection. The
19 incompatible and 3 subdirectory-only entries are excluded; the resulting
kernel is therefore a reviewed AXP.OS subset rather than the complete script.

The configuration selects a `user` build, disables KernelSU, Lindroid, Google
apps and microG, retains the Android kernel compatibility requirements, and
sets `WITH_AVB=true` so the FP4 device tree does not disable verification and
verity in vbmeta. AVB release signing uses a 4096-bit key and the vbmeta_system
chain. The proprietary firmware and vendor components remain necessary.

The pinned manifest records the FP4 kernel dependency as inactive. The device
module explicitly fetches the same recorded LineageOS 23.2 kernel revision,
`0ff1c1c66c00373cd9445db0ef1805493554cae1`, with its recorded hash. The Android
device tree remains LineageOS 24.0 revision
`5e457df37b105e4e11cba607b2bc6fe8862c18af`.

Build from the repository root:

```sh
nix build .#lineageos-fp4-img --out-link result-fp4-img -L
nix build .#lineageos-fp4-ota --out-link result-fp4-ota -L
```

The corresponding Robotnix targets are `losNoCcache.FP4.img` and
`losNoCcache.FP4.ota`. The `los.FP4` variants enable the repository's ccache
configuration, which requires the host cache directory setup described in
`los/default.nix`.

The image and OTA derivations use Robotnix test-key build paths. They are useful
for validation; deployment with private release keys requires the separate
release workflow. Keep keys outside the Nix store:

```sh
keys_dir="$PWD/private-fp4-keys"
umask 077
mkdir -p "$keys_dir"
$(nix build .#losNoCcache.FP4.generateKeysScript --no-link --print-out-paths) "$keys_dir"
release_script=$(nix build .#losNoCcache.FP4.releaseScript --no-link --print-out-paths)
mkdir -p fp4-release
cd fp4-release
"$release_script" "$keys_dir"
```

The commands above are instructions, not evidence that release keys have been
generated or that a release has been signed. Do not commit the private key
directory. No device flashing or bootloader locking is part of this setup.
Bootloader locking requires independent confirmation of the FP4 boot chain,
the enrolled custom key, rollback indexes, and a successfully boot-tested signed
image; enabling the build options alone does not establish that it is safe.

Device and installation references:

- [LineageOS FP4 device page](https://wiki.lineageos.org/devices/FP4/)
- [LineageOS FP4 build guide](https://wiki.lineageos.org/devices/FP4/build/)
- [LineageOS FP4 installation guide](https://wiki.lineageos.org/devices/FP4/install/)
- [AXP.OS build and patch source](https://git.disroot.org/AXP.OS/build)

The separate experimental mainline target is described in
`fairphone4-mainline.md`; it does not replace this device's downstream kernel.
