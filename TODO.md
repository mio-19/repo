# TODO: build rmweb (and Paper Pro packages) from source with nixpkgs

Goal: stop shipping upstream's prebuilt `rmweb-0.9.7.tar.gz` bundle and stop using
reMarkable's binary Yocto SDK. Compile the engine and the app from source with
nixpkgs' own bootstrap toolchain (`gcc`, `cmake`, `ninja`, `qt6`, `mesa`), for
`aarch64-linux`, so everything is a normal Nix derivation.

State at time of writing: `main` = `97ef4334` (clean tree), `.#rmpp_tools`,
`.#rmpp_rmweb` (prebuilt bundle), `.#rmpp_nix_setup` all build.

## Verified facts (don't re-research)

### Device
- Paper Pro "ferrari": i.MX8MM, 4x Cortex-A53, OS 3.28 (Yocto scarthgap),
  **glibc 2.39**, kernel 6.12.49, BusyBox userland, 500 MB read-only rootfs.
- Display: **no `/dev/fb*`**, no render node, no EGL/GL/Vulkan/GBM/Wayland.
  xochitl is **Qt 6.10.3** and presents through the closed-source QPA plugin
  `/usr/lib/plugins/platforms/libepaper.so` ("epaper" QPA) -> imx-drm.
  Only other QPA plugins on device: offscreen, minimal, vnc.
- No compiler on device; `/home` (46 GB) is the only writable, OTA-surviving place.

### rmweb upstream (github.com/exp78/rmweb, MIT, v0.9.7 tag)
- App source: `engine/wpeqt/` — CMake, C++17, **single `main.cpp`**, needs
  `Qt6 Gui Qml Quick` + pkg-config `wpe-webkit-2.0 wpe-platform-2.0 glib-2.0 gobject-2.0`.
  Flags: `QT_NO_KEYWORDS`, `-rdynamic`, `INSTALL_RPATH "$ORIGIN/../lib"`,
  `BUILD_WITH_INSTALL_RPATH`, `-fstack-protector-strong`, RELRO/bind-now.
- Engine: **WPE WebKit 2.48.5** built from
  `https://wpewebkit.org/releases/wpewebkit-2.48.5.tar.xz`
  sha256 `01f36010705adb14404c56baf033147f7927cc7c6badec81bb141266fcdd8d0b`.
  Configure options used upstream (`engine/build-wpe.incontainer.sh`):
  `-DPORT=WPE -DUSE_SKIA=ON -DUSE_GSTREAMER=OFF -DENABLE_VIDEO=OFF
  -DENABLE_WEB_AUDIO=OFF -DENABLE_MEDIA_SOURCE=OFF -DENABLE_MEDIA_STREAM=OFF
  -DENABLE_WEB_CODECS=OFF -DENABLE_WEBGL=OFF -DENABLE_WEB_RTC=OFF
  -DENABLE_SPELLCHECK=OFF -DENABLE_GAMEPAD=OFF -DENABLE_BUBBLEWRAP_SANDBOX=OFF
  -DENABLE_INTROSPECTION=OFF -DENABLE_DOCUMENTATION=OFF -DUSE_AVIF=OFF
  -DUSE_JPEGXL=OFF -DUSE_LIBHYPHEN=OFF -DENABLE_JOURNALD_LOG=OFF
  -DENABLE_WPE_PLATFORM=ON -DENABLE_WPE_PLATFORM_HEADLESS=ON
  -DENABLE_WPE_PLATFORM_DRM=OFF -DENABLE_WPE_PLATFORM_WAYLAND=OFF
  -DENABLE_WPE_QT_API=OFF -DUSE_ATK=OFF -DUSE_WOFF2=OFF
  -DUSE_LIBBACKTRACE=OFF -DUSE_SYSPROF_CAPTURE=OFF -DENABLE_MINIBROWSER=OFF
  -DENABLE_COG=OFF -DENABLE_API_TESTS=OFF -DENABLE_WEBDRIVER=OFF`
- Extra deps upstream cross-builds (hashes from `scripts/build-wpe.sh`):
  libwpe 1.16.2 (`960bdd11...`), libtasn1 4.19.0 (`1613f0ac...`),
  libxslt 1.1.39 (`2a20ad62...`), harfbuzz 8.3.0 for `libharfbuzz-icu`
  (`109501ea...`), plus `engine/atomic16.c` (16-byte atomics shim for A53).
- Bundle layout at `/home/root/rmweb`: `bin/rmweb-wpeqt`, `lib/`, `lib/dri/`,
  `lib/gio/modules/`, `libexec/wpe-webkit-2.0`, `lib/wpe-webkit-2.0` (injected
  bundle), `share/wpe-webkit-2.0`, `share/reader/Readability*.js`, `rmweb`,
  `rmweb-env.sh`, `install.sh`, `appload-entry.sh`, `appload/`, `icon.svg`, `VERSION`.
- Runtime env (`rmweb-env.sh`): `QT_QPA_PLATFORM=epaper`,
  `QT_QUICK_BACKEND=epaper`, `QSG_RENDER_LOOP=basic`, `GALLIUM_DRIVER=llvmpipe`,
  `LIBGL_ALWAYS_SOFTWARE=1`, `EGL_PLATFORM=surfaceless`, `LIBGL_DRIVERS_PATH=$R/lib/dri`,
  `WEBKIT_SKIA_ENABLE_CPU_RENDERING=1`, `WEBKIT_INJECTED_BUNDLE_PATH=...`,
  `GIO_EXTRA_MODULES=$R/lib/gio/modules`, `WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1`.

### nixpkgs (nixos-unstable at time of writing)
- Has: `libwpe` 1.16.3, `libwpe-fdo`, `cog`, `webkitgtk_6_0`, `mesa` 26.2.6,
  `qt6.qtbase` **6.12.0**, `libsoup_3`, `harfbuzz`, `libxslt`, `libtasn1`, `libepoxy`.
- Does **not** have: `wpewebkit`, `wpebackend-fdo` (named `libwpe-fdo`).
  => WPE WebKit must be packaged here from the upstream tarball.
- This dev host: x86_64, 16 cores, ~400 GB free on `/nix`, and
  **binfmt for `aarch64-linux` is registered** — aarch64 binaries run
  (`/nix/store/*-rmpp-tools/bin/htop --version` worked), so `aarch64-linux`
  derivations can be *built and verified* here under qemu-user (slow), using
  `--option extra-platforms aarch64-linux`.

### reMarkable SDK (rejected, for the record)
- Public installers exist for both hosts (`.../remarkable-production-image-5.7.119-ferrari-public-{x86_64,aarch64}-toolchain.sh`, ~467 MB). The aarch64 one refuses to install on x86_64 ("Incompatible SDK installer! Your host is x86_64 and this SDK was built for aarch64 hosts").
- **Decision: do not use it.** Binary SDK/toolchain + binary Qt is exactly what we
  are trying to get away from; nixpkgs' source bootstrap is preferred.

## Hard problem to solve: the epaper QPA

The app cannot render without `libepaper.so`, which is closed source and built
against **Qt 6.10.3**. Qt QPA plugins hard-fail on a Qt *version* mismatch
(plugin metadata carries the Qt version), so an app linked against nixpkgs
Qt 6.12 will not load the device's epaper plugin, and an app linked against
6.12 at build time would also reference symbols the device's 6.10.3 libs lack.

Options to investigate, in order:
1. **Build Qt 6.10.3 from source in nixpkgs** (qtbase/qtdeclarative) so the
   version matches the device's, then confirm `libepaper.so` loads (it also
   needs the same private-API build config as reMarkable's Qt — may still fail).
2. Check whether `libepaper.so` exposes a stable C entry point that could be
   driven without Qt (unlikely; it is a QPA plugin + packing code).
3. Ask upstream (exp78/rmweb) whether a Qt-version-independent display path is
   possible; their own build uses the device Qt for exactly this reason.
4. Accept "compile-only" from-source build with nixpkgs Qt: everything builds,
   nothing renders on device — only useful as CI proof, not as the shipped pkg.

## Tasks

- [ ] `remarkable/rmweb/wpewebkit.nix`: WPE WebKit 2.48.5 from the upstream
      tarball, native `aarch64-linux`, nixpkgs deps (`libsoup_3`, `libwpe`,
      `libxslt`, `libtasn1`, `harfbuzz` + ICU, `libwebp`, `libxkbcommon`,
      `libepoxy`, `glib-networking`, `mesa`, `sqlite`, `libpsl`, `libpng`,
      `libjpeg`, `fontconfig`, `freetype`, `cairo`, `libdrm`), upstream's
      configure flags, nativeBuildInputs `cmake ninja pkg-config python3 perl
      ruby gperf unifdef gettext bison flex`; `meta.platforms = [ "aarch64-linux" ]`.
- [ ] `remarkable/rmweb/default.nix`: build `rmweb-wpeqt` from the git tag
      (`fetchFromGitHub`, tag `v0.9.7`) with nixpkgs `qt6` + the derivation above;
      keep upstream's CMake flags/rpath; assemble the `/home/root/rmweb` tree
      (app + engine + helpers + `rmweb`, `rmweb-env.sh`, `install.sh`,
      `appload-entry.sh`, `appload/`, `icon.svg`, `VERSION`).
- [ ] Mesa: use nixpkgs `mesa` (llvmpipe + swrast + surfaceless EGL) instead of
      `build/stage-mesa`; verify `LIBGL_DRIVERS_PATH` contents and that no
      device GL/GBM is needed.
- [ ] Remove `pkgs.fetchurl` of the release bundle from `remarkable/default.nix`
      once the source build produces an equivalent tree.
- [ ] Qt 6.10.3 experiment (see above) — decide epaper strategy before shipping.
- [ ] Build + verify on this host (emulated aarch64):
      `nix build --option extra-platforms aarch64-linux .#rmpp_rmweb` and check
      `readelf -d` sonames/RUNPATH, injected-bundle path, `lib/dri/*`.
- [ ] Test on device: `nix copy` the closure, `rmweb-env.sh` + epaper QPA,
      page turns, downloads, AppLoad icon.
- [ ] Update `docs/remarkable-paper-pro.md` (drop "prebuilt bundle" text, add
      build-from-source section, expected build time/disk, Qt caveat).
- [ ] Update `TODO.md`/commit as each item lands; do not hand-edit generated files;
      `nixfmt` every `.nix` touched.

## How to resume

```sh
cd repo
git status -sb                 # expect clean, main == origin/main
nix build --option extra-platforms aarch64-linux .#rmpp_tools   # sanity: aarch64 via binfmt
# then start with remarkable/rmweb/wpewebkit.nix (task 1)
```

Notes:
- Emulated builds are slow; run long `nix build`s in a BACKGROUND shell and check
  logs, or build WPE once natively on an aarch64 machine.
- Keep `rmpp_tools`/`rmpp_nix_setup` as they are: native `aarch64-linux` from
  cache.nixos.org (no cross compile), which is already the preferred shape.
- Verify with the real upstream numbers above rather than re-deriving them.
