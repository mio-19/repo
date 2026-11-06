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

All binaries are cross-built from source (`pkgsCross.aarch64-multiplatform-musl.pkgsStatic`)
as fully static aarch64 binaries, so they need nothing from the tablet's
read-only rootfs and no dynamic loader from the store.

```sh
# CLI tools: syncthing, tmux, htop, rsync, strace
nix build .#rmpp_tools -o rmpp-tools
scp -r rmpp-tools/bin root@10.11.99.1:/home/root/rmpp-tools

# Nix store plumbing for the tablet
nix build .#rmpp_nix_setup -o rmpp-nix-setup
scp rmpp-nix-setup/bin/rmpp-nix-setup root@10.11.99.1:/tmp/
```

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
/home/root/rmpp-tools/bin/syncthing serve \
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
- Builds on the device itself are slow and only a cross-built store is really
  useful; build software on the host with `pkgsCross.aarch64-multiplatform-musl`
  and copy the closure, or use the packages above.

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
- <https://github.com/kja140/rmpro-hacks> — field notes for Syncthing,
  Tailscale and friends on the Paper Pro
- <https://nixos.org/manual/nix/stable/installation/installing-binary> —
  single-user Nix installation
