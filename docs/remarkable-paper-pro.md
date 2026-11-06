# reMarkable Paper Pro

Notes and packages for the reMarkable Paper Pro (`ferrari`, aarch64, reMarkable
OS 3.x). Everything below assumes developer mode is enabled (Settings →
General → Software → Developer mode), SSH works over USB at `root@10.11.99.1`,
and you accept that you can brick the device by breaking `xochitl`.

## What the device does to you

- The root filesystem is mounted **read-only** at boot. `mount -o remount,rw /`
  makes it writable for the current boot. Writes then land on the real ext4
  rootfs slot and do persist across reboots; the filesystem is simply mounted
  read-only again the next time.
- `/etc` is an **overlay whose upper layer is on tmpfs**. Writing to `/etc`
  without unmounting the overlay silently loses the change at reboot:

  ```sh
  mount -o remount,rw /
  umount -R /etc
  # /etc now points at the real rootfs; /etc/dropbear is gone, so put the SSH
  # host keys (which live on /home) back so the session keeps working:
  mkdir -p /etc/dropbear
  mount --bind /home/root/.dropbear /etc/dropbear
  ```

- `/home` is the only writable storage that survives an **OS update**. An
  update replaces the whole rootfs slot (`/usr`, `/etc`, …) and leaves `/home`
  alone, so anything in `/usr` or `/etc` has to be reinstalled afterwards.
- Third-party software therefore lives under `/home/root`. The classic Toltec
  stack does not support this device (aarch64, different framebuffer/Qt); the
  current stack is [XOVI](https://github.com/asivery/xovi) +
  [rm-appload](https://github.com/asivery/rm-xovi-extensions) + QTFB, usually
  installed with [vellum](https://github.com/vellum-dev/vellum) or
  [reManager](https://remanager.io/).

## Packages here

These are ordinary native `aarch64-linux` packages — no cross toolchain — so
they match the derivations `cache.nixos.org` already serves and `nix build`
downloads them instead of compiling. They are dynamically linked against
`/nix/store`, which is fine because the tablet gets a real store (see
[Nix on the tablet](#nix-on-the-tablet)): copy the **closure**, not a bare
binary. rmweb is the single exception — upstream's self-contained bundle is
used because building it needs their Yocto SDK; see below.

The same packages work on the Paper Pro Move: it is the same aarch64 userland,
and rmweb derives the panel geometry at runtime.

```sh
# CLI tools: syncthing, tmux, htop, rsync, strace
# dynamically linked against /nix/store: copy the closure to the tablet's store
# (remote-program: nix-store is not on the tablet's non-interactive PATH; the
# single quotes keep the shell from globbing the `?')
nix copy --to 'ssh://root@10.11.99.1?remote-program=/nix/var/nix/profiles/default/bin/nix-store' ./rmpp-tools

# Nix store plumbing for the tablet (a plain shell script, no closure needed)
nix build .#rmpp_nix_setup -o rmpp-nix-setup
scp rmpp-nix-setup/bin/rmpp-nix-setup root@10.11.99.1:/tmp/
```

The store has to be mounted first (`rmpp_nix_setup`), otherwise the import hits
the read-only rootfs.

### rmweb (WPE WebKit browser)

[rmweb](https://github.com/exp78/rmweb) is a native e-ink browser for the
Paper Pro: reader mode, downloads that land in the reMarkable library, a
home-screen icon under XOVI/AppLoad. It is the one package here that is **not**
built from source — upstream cross-compiles WPE WebKit and Mesa llvmpipe
against the reMarkable *ferrari* Yocto SDK inside a `linux/arm64` Docker image
(hours and tens of GB of disk), so the only artifact that can be produced is
their self-contained release bundle. The bundle carries everything the stock
OS lacks and uses the device's own Qt 6, and Nix only unpacks it — no shebang,
strip or RPATH rewriting, the only edit is dropping the macOS `._*` metadata
files — so what ships is upstream's tree:

```sh
nix build .#rmpp_rmweb -o rmweb-bundle
scp -r rmweb-bundle/. root@10.11.99.1:/home/root/rmweb/
ssh root@10.11.99.1 /home/root/rmweb/install.sh
```

Then run `/home/root/rmweb/rmweb [URL]`, or start XOVI and tap the **rmweb**
icon that `install.sh` registered. The tree lives on `/home`, so it survives an
OS update — re-run `install.sh` afterwards to re-assert the AppLoad icon. Quit
with the ⏻ button so `xochitl` comes back.

KOReader is not packaged here: upstream ships only prebuilt aarch64 archives
for this device and this repository prefers building from source, so install it
with [vellum](https://github.com/vellum-dev/vellum) (`vellum install koreader`)
or reManager, which place it under `/home/root/xovi/exthome/appload` and keep it
across OS updates.

Syncthing is useful headless: run it under `/home/root` and point the web UI at
the device over USB or Wi-Fi.

```sh
ssh root@10.11.99.1
mkdir -p /home/root/syncthing
/nix/store/*-rmpp-tools/bin/syncthing serve \
  --home=/home/root/syncthing --gui-address=0.0.0.0:8384
```

## Nix on the tablet

`rmpp_nix_setup` does the whole dance, because Nix hardcodes `/nix` and `/` is
read-only:

1. `mount -o remount,rw /` (temporary),
2. `mkdir -p /nix` — the empty mountpoint on the rootfs (persists),
3. `mount --bind /home/root/nix /nix` — the store on `/home`, which survives
   OS updates,
4. installs the upstream **static aarch64** Nix release into that store
   (2.35.3 by default, `--version` to override),
5. optionally writes `/etc/systemd/system/nix.mount` (after collapsing the
   `/etc` overlay) so the bind mount is recreated on every boot, ordered after
   `home.mount`,
6. `mount -o remount,ro /` — restores the stock read-only rootfs.

```sh
ssh root@10.11.99.1 sh /tmp/rmpp-nix-setup --persist
# then, in a new shell:
export PATH="/nix/var/nix/profiles/default/bin:$PATH"
nix --version
```

Checks and caveats:

```sh
mount | grep ' /nix '          # the bind mount
findmnt -no SOURCE /nix        # /home/root/nix
mount | grep overlay           # remaining overlay mounts under /etc
```

- `--persist` collapses the `/etc` overlay and re-binds `/etc/dropbear`; if
  `umount -R /etc` fails because a process holds it, close other sessions and
  retry, or run without `--persist` and mount by hand after each boot.
- `--keep-rw` leaves `/` writable, `--no-install` only does the mount.
- After a reMarkable OS update, `/nix` and the mount unit are gone (the rootfs
  slot was replaced) while `/home/root/nix` and the store are intact. Re-run
  the script.
- Do not point the store at a directory outside `/home` unless you accept
  losing it on every update.
- Builds on the device itself are slow: build on the host for
  `aarch64-linux` and copy the closure, or use the packages above.

## Building on an x86_64 host

Because the packages are native `aarch64-linux` derivations (that is what makes
them cache hits), a foreign host has to be allowed to build them:

```sh
nix build --option extra-platforms aarch64-linux .#rmpp_tools
```

With only that flag, cache misses fail — the normal case is a cache hit, so
this is usually enough. For real emulation register qemu-user with binfmt_misc
(NixOS: `boot.binfmt.emulatedSystems = [ "aarch64-linux" ];`, other distros:
`systemd-binfmt`), then `extra-platforms = aarch64-linux` in `nix.conf` can
stay and anything not cached is built under emulation.

## References

- <https://remarkable.guide/faqs.html> — read-only rootfs, `/etc` overlay,
  what survives an update
- <https://developer.remarkable.com/documentation/developer-mode> — developer
  mode, `mount -o remount,rw /`
- <https://github.com/asivery/xovi> and
  <https://github.com/asivery/rm-xovi-extensions> — the extension framework
  and AppLoad
- <https://github.com/vellum-dev/vellum> — package manager for reMarkable OS 3.x
- <https://github.com/koreader/koreader/wiki/Installation-on-ReMarkable> —
  KOReader install steps for aarch64 devices (via vellum/AppLoad)
- <https://github.com/exp78/rmweb> — WPE WebKit browser for the Paper Pro
  (MIT), whose release bundle `rmpp_rmweb` packages
- <https://github.com/kja140/rmpro-hacks> — field notes for Syncthing,
  Tailscale and friends on the Paper Pro
- <https://nixos.org/manual/nix/stable/installation/installing-binary> —
  single-user Nix installation
