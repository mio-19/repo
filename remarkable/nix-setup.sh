#!/bin/sh
# rmpp-nix-setup: give the reMarkable Paper Pro (codename ferrari, aarch64) a
# persistent Nix store at /nix.
#
# The Paper Pro boots with a read-only root filesystem. /home is the only
# location that is writable and survives an OS update (an update rewrites the
# rootfs slot and leaves /home untouched), and /etc has an overlay whose upper
# layer lives on tmpfs, so changes to /etc also disappear at the next reboot.
#
# Nix insists on /nix, so this script:
#   1. remounts / read-write for the current boot (writes then land on the real
#      ext4 rootfs and do survive reboots, the filesystem is just mounted ro),
#   2. creates the empty /nix mountpoint on that rootfs,
#   3. bind mounts /home/root/nix there, so the store lives on /home,
#   4. installs the upstream static aarch64 Nix release (unless already there),
#   5. optionally installs a systemd mount unit that recreates the bind mount on
#      every boot,
#   6. remounts / read-only again (unless --keep-rw).
#
# Everything here runs on the tablet as root, over USB:
#   scp rmpp-nix-setup root@10.11.99.1:/tmp/
#   ssh root@10.11.99.1 sh /tmp/rmpp-nix-setup --persist
#
# Re-run after every reMarkable OS update: updates replace the rootfs slot, so
# /nix and the mount unit vanish while /home/root/nix (and the installed store)
# are still there.
#
# Device behavior is documented by reMarkable and the community:
#   https://developer.remarkable.com/documentation/developer-mode
#   https://remarkable.guide/faqs.html
# The "umount -R /etc" overlay collapse is the same approach used by the
# xovi/AppLoad enable scripts (https://github.com/asivery/rm-xovi-extensions)
# and by xovi-boot (https://github.com/MaximeRivest/remarkable-experiments).

set -eu

NIX_VERSION="${NIX_VERSION:-2.35.3}"
STORE_DIR="${NIX_STORE_DIR:-/home/root/nix}"
MOUNTPOINT="${NIX_MOUNTPOINT:-/nix}"

log() { printf 'rmpp-nix-setup: %s\n' "$*"; }
die() {
	printf 'rmpp-nix-setup: error: %s\n' "$*" >&2
	exit 1
}

usage() {
	cat <<'EOF'
usage: rmpp-nix-setup [options]

  --no-install      only wire up the mount, do not install Nix
  --no-persist      do not install the systemd mount unit (default)
  --persist         install /etc/systemd/system/nix.mount so the bind mount
                    comes back after every boot; this collapses the /etc tmpfs
                    overlay, which briefly drops you out of /etc
  --keep-rw         leave / mounted read-write at the end (it is remounted
                    read-only by default)
  --version VERSION Nix release to install (default: 2.35.3)
  --store-dir DIR   persistent store location (default: /home/root/nix)
  -h, --help        show this help

The Nix release tarball is statically linked, so it does not depend on the
tablet's glibc or on any library from the read-only rootfs.
EOF
}

install_nix=yes
persist=no
keep_rw=no

while [ $# -gt 0 ]; do
	case "$1" in
	--no-install) install_nix=no ;;
	--install) install_nix=yes ;;
	--persist) persist=yes ;;
	--no-persist) persist=no ;;
	--keep-rw) keep_rw=yes ;;
	--version)
		shift
		[ $# -gt 0 ] || die "--version needs an argument"
		NIX_VERSION="$1"
		;;
	--store-dir)
		shift
		[ $# -gt 0 ] || die "--store-dir needs an argument"
		STORE_DIR="$1"
		;;
	-h | --help)
		usage
		exit 0
		;;
	*) die "unknown option: $1 (try --help)" ;;
	esac
	shift
done

[ "$(id -u)" -eq 0 ] || die "run this as root on the tablet (ssh root@10.11.99.1)"

case "$STORE_DIR" in
/*) ;;
*) die "--store-dir must be an absolute path" ;;
esac
case "$STORE_DIR" in
/home/*) ;;
*) log "warning: $STORE_DIR is not under /home, so it will not survive an OS update" ;;
esac

is_mounted() {
	awk -v target="$1" '$2 == target { found = 1 } END { exit !found }' /proc/mounts
}

is_root_rw() {
	awk '$2 == "/" && $4 !~ /(^|,)ro(,|$)/ { found = 1 } END { exit !found }' /proc/mounts
}

fetch() {
	url="$1"
	out="$2"
	if command -v curl >/dev/null 2>&1; then
		curl -fL --retry 3 -o "$out" "$url"
	elif command -v wget >/dev/null 2>&1; then
		wget -O "$out" "$url"
	else
		die "neither curl nor wget is available on the tablet"
	fi
}

install_nix_release() {
	version="$1"
	tmp="$(mktemp -d "${TMPDIR:-/tmp}/rmpp-nix.XXXXXX")"
	trap 'rm -rf "$tmp"' EXIT HUP INT TERM

	url="https://releases.nixos.org/nix/nix-$version/nix-$version-aarch64-linux.tar.xz"
	log "downloading $url"
	fetch "$url" "$tmp/nix.tar.xz"

	log "extracting Nix $version"
	if ! tar -xJf "$tmp/nix.tar.xz" -C "$tmp"; then
		command -v xz >/dev/null 2>&1 || die "tar cannot handle xz and xz is missing"
		xz -dc "$tmp/nix.tar.xz" | tar -xf - -C "$tmp"
	fi

	[ -x "$tmp/nix-$version-aarch64-linux/install" ] || die "unexpected Nix tarball layout"

	# Single-user install into the bind-mounted /nix. --no-channel-add keeps it
	# from pulling a nixpkgs channel (this repo pins its own nixpkgs), and the
	# profile snippet it appends lands in /home/root, which persists.
	log "installing Nix $version into $MOUNTPOINT"
	"$tmp/nix-$version-aarch64-linux/install" --no-daemon --no-channel-add --yes
}

persist_mount_unit() {
	command -v systemctl >/dev/null 2>&1 || die "systemctl not found, cannot install the mount unit"

	# /etc is an overlay with a tmpfs upperdir, so a unit written while it is
	# mounted is lost at the next reboot. Collapse the overlay first. This is
	# the same trick the community uses for xovi and friends.
	if awk '$2 == "/etc" && $3 == "overlay" { found = 1 } END { exit !found }' /proc/mounts; then
		log "collapsing the /etc tmpfs overlay so the unit reaches the real rootfs"
		umount -R /etc || die "could not unmount the /etc overlay (a process may be holding it)"
		# Dropbear host keys are bind mounted from /home; put them back so the
		# current SSH session keeps working.
		if [ -d /home/root/.dropbear ]; then
			mkdir -p /etc/dropbear
			mount --bind /home/root/.dropbear /etc/dropbear || log "warning: could not re-bind /etc/dropbear"
		fi
	fi

	mkdir -p /etc/systemd/system/multi-user.target.wants
	cat >/etc/systemd/system/nix.mount <<EOF
[Unit]
Description=Persistent Nix store ($STORE_DIR on /nix)
Requires=home.mount
After=home.mount local-fs.target

[Mount]
What=$STORE_DIR
Where=$MOUNTPOINT
Type=none
Options=bind

[Install]
WantedBy=multi-user.target
EOF
	ln -sf ../nix.mount /etc/systemd/system/multi-user.target.wants/nix.mount
	systemctl daemon-reload || log "warning: systemctl daemon-reload failed"
	log "installed /etc/systemd/system/nix.mount"
}

add_profile_path() {
	profile=/home/root/.profile
	if ! grep -q 'nix-profile/etc/profile.d/nix.sh' "$profile" 2>/dev/null; then
		{
			printf '\n# added by rmpp-nix-setup\n'
			printf '%s\n' 'if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/nix.sh"; fi'
		} >>"$profile"
	fi
}

# 1. / is read-only at boot. Remount it read-write for this boot.
if is_root_rw; then
	log "/ is already mounted read-write"
else
	log "remounting / read-write"
	mount -o remount,rw / || die "could not remount / read-write (is developer mode enabled?)"
	is_root_rw || die "/ is still read-only after remount"
fi

# 2. Empty mountpoint on the real rootfs. It persists across reboots; an OS
#    update replaces the rootfs slot, so re-run this script afterwards.
mkdir -p "$MOUNTPOINT"

# 3. The store itself lives on /home.
mkdir -p "$STORE_DIR"
if is_mounted "$MOUNTPOINT"; then
	log "$MOUNTPOINT is already mounted"
else
	log "bind mounting $STORE_DIR on $MOUNTPOINT"
	mount --bind "$STORE_DIR" "$MOUNTPOINT" || die "bind mount failed"
fi

# 4. Nix itself.
if [ "$install_nix" = yes ]; then
	if [ -x "$MOUNTPOINT/var/nix/profiles/default/bin/nix" ]; then
		log "Nix is already installed in $MOUNTPOINT"
	else
		install_nix_release "$NIX_VERSION"
	fi
fi

# 5. Optional boot-time bind mount.
if [ "$persist" = yes ]; then
	persist_mount_unit
	add_profile_path
fi

# 6. Restore the stock read-only root filesystem.
if [ "$keep_rw" = no ] && is_root_rw; then
	log "remounting / read-only"
	mount -o remount,ro / || log "warning: could not remount / read-only"
fi

log "done"
log "store: $STORE_DIR (bind mounted on $MOUNTPOINT)"
if [ "$persist" = yes ]; then
	log "the bind mount is restored by nix.mount at every boot"
else
	log "this mount lasts until the next reboot; re-run with --persist to keep it"
fi
log "use it with: export PATH=\"$MOUNTPOINT/var/nix/profiles/default/bin:\$PATH\""
