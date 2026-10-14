#!/usr/bin/env bash
# Install NixOS from this repo onto one empty disk. Run it from the NixOS live USB:
#
#   git clone https://github.com/proasync/nixos-config.git
#   cd nixos-config
#   sudo bash scripts/install.sh <host>          # e.g. work-desktop
#
# The full walkthrough (before, during, after) is docs/install.md.
#
# What it does, in order; it stops at the first error:
#   1. checks: root, booted in UEFI mode, running on the live USB, host exists
#   2. you pick the disk. The live USB and any disk holding Windows (NTFS or
#      BitLocker) are never offered; you confirm by typing the disk's name
#   3. wipes that disk: 1 GiB boot partition (FAT32) + the rest as root (ext4).
#      No swap partition: modules/common.nix sets up zram swap
#   4. mounts it at /mnt and runs nixos-generate-config
#   5. copies this repo to /mnt/home/proasync/nixos-config (the dotfile links
#      expect that path) and puts the generated hardware-configuration.nix
#      into hosts/<host>/
#   6. nixos-install --flake .../nixos-config#<host>
#   7. asks for the root password, then the proasync password
#   8. hands /home/proasync to proasync and unmounts
#
# Only the chosen disk is written or mounted. Other disks keep their own
# bootloaders; start them from the firmware boot menu.

set -euo pipefail

user=proasync
host=${1:-}
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
target=/mnt
dest=$target/home/$user/nixos-config
sysbin=/nix/var/nix/profiles/system/sw/bin   # the new system's tools, inside nixos-enter

bold=$'\e[1m'; red=$'\e[31m'; green=$'\e[32m'; yellow=$'\e[33m'; reset=$'\e[0m'
step() { printf '\n%s==> %s%s\n' "$bold" "$*" "$reset"; }
die()  { printf '\n%sERROR: %s%s\n' "$red" "$*" "$reset" >&2; exit 1; }
trap 'printf "\n%sStopped: \"%s\" failed (line %s).%s\nNothing outside the chosen disk was touched. Running the same command again starts over from the disk choice.\n" "$red" "$BASH_COMMAND" "$LINENO" "$reset" >&2' ERR

# ── 1. Checks ─────────────────────────────────────────────
hosts=$(find "$repo/hosts" -mindepth 1 -maxdepth 1 -type d -printf '%f ')
[[ -n $host ]]       || die "say which machine to install: sudo bash scripts/install.sh <host>   (hosts: $hosts)"
[[ $EUID -eq 0 ]]    || die "run it with sudo: sudo bash scripts/install.sh $host"
[[ -f $repo/hosts/$host/configuration.nix ]] || die "no hosts/$host/ in this repo (hosts: $hosts)"
grep -q "\"$host\"" "$repo/flake.nix"        || die "\"$host\" is missing from the host list in flake.nix"
if ! command -v nixos-install >/dev/null || ! mountpoint -q /iso; then
  die "this only runs from the NixOS live USB"
fi
[[ -d /sys/firmware/efi ]] \
  || die "the USB stick was started in legacy (BIOS) mode. Reboot, open the boot menu (F9 on HP) and pick the entry that starts with 'UEFI'."

if mountpoint -q "$target"; then
  echo "Unmounting $target, left over from an earlier attempt."
  umount -R "$target"
fi

# ── 2. Pick the disk ──────────────────────────────────────
step "Disks in this computer"
candidates=()
while read -r disk; do
  fstypes=$(lsblk -nro FSTYPE "$disk" | grep -v '^$' | sort -u | tr '\n' ' ' || true)
  info=$(lsblk -dno SIZE,TRAN,MODEL "$disk" | xargs)
  case " $fstypes " in
    *" iso9660 "*)               printf '  %-14s %s   %s(the live USB: skipped)%s\n' "${disk#/dev/}" "$info" "$yellow" "$reset" ;;
    *" ntfs "*|*" BitLocker "*)  printf '  %-14s %s   %s(Windows: skipped)%s\n'      "${disk#/dev/}" "$info" "$yellow" "$reset" ;;
    *)
      candidates+=("$disk")
      if [[ -z $fstypes ]]; then contents="empty"
      else contents="${red}has data: ${fstypes% }${reset}"; fi
      printf '  %s%-14s%s %s   %s\n' "$bold" "${disk#/dev/}" "$reset" "$info" "$contents" ;;
  esac
done < <(lsblk -dnpo NAME,TYPE | awk '$2 == "disk" && $1 !~ /zram/ {print $1}')

(( ${#candidates[@]} > 0 )) || die "no disk to install to. Is the new SSD connected?"

echo
echo "Only the disks in bold can be chosen. Check size and model against the new SSD."
read -rp "Type the name of the disk to ERASE and install on (like sda or nvme1n1): " answer
disk=""
for c in "${candidates[@]}"; do
  if [[ ${c#/dev/} == "$answer" ]]; then disk=$c; fi
done
[[ -n $disk ]] || die "\"$answer\" is not one of the disks above. Nothing was changed."

echo
printf '%sEverything on %s (%s) will be erased.%s\n' "$red" "$disk" "$(lsblk -dno SIZE,MODEL "$disk" | xargs)" "$reset"
read -rp "Type ERASE to continue: " answer
[[ $answer == ERASE ]] || die "not confirmed. Nothing was changed."

# ── 3. Partition and format ───────────────────────────────
step "Partitioning $disk: 1 GiB boot + the rest for NixOS"
# The desktop may have auto-mounted something from it.
while read -r dev; do
  umount -A "$dev" 2>/dev/null || true
  swapoff "$dev" 2>/dev/null || true
done < <(lsblk -lnpo NAME "$disk")
lsblk -lnpo NAME,TYPE "$disk" | awk '$2 == "part" {print $1}' | xargs -r wipefs -aq
wipefs -aq "$disk"
parted -s "$disk" -- \
  mklabel gpt \
  mkpart ESP fat32 1MiB 1025MiB \
  set 1 esp on \
  mkpart nixos ext4 1025MiB 100%
udevadm settle

if [[ $disk =~ [0-9]$ ]]; then p=p; else p=""; fi   # nvme0n1 → nvme0n1p1, sda → sda1
boot_part=$disk${p}1
root_part=$disk${p}2
for _ in {1..10}; do
  if [[ -b $root_part ]]; then break; fi
  sleep 1
done
[[ -b $boot_part && -b $root_part ]] || die "the new partitions $boot_part and $root_part did not appear"

step "Formatting"
mkfs.fat -F 32 -n BOOT "$boot_part"
mkfs.ext4 -F -q -L nixos "$root_part"

# ── 4. Mount and generate the hardware config ─────────────
step "Mounting at $target and detecting the hardware"
mount "$root_part" "$target"
mkdir -p "$target/boot"
mount -o fmask=0077,dmask=0077 "$boot_part" "$target/boot"
nixos-generate-config --root "$target"

hw=$target/etc/nixos/hardware-configuration.nix
for part in "$root_part" "$boot_part"; do
  uuid=$(blkid -s UUID -o value "$part")
  grep -q "$uuid" "$hw" || die "the generated hardware-configuration.nix does not mention $part ($uuid)"
done

# ── 5. Put the repo on the new disk ───────────────────────
step "Copying this repo to $dest"
mkdir -p "$target/home/$user"
chmod 700 "$target/home/$user"
cp -a "$repo" "$dest"
cp "$hw" "$dest/hosts/$host/hardware-configuration.nix"
# Flakes only see files git tracks; this also covers a brand-new hosts/<host>/.
git -C "$dest" -c safe.directory='*' add "hosts/$host"

# ── 6. Install ────────────────────────────────────────────
step "Installing NixOS for $host"
echo "This downloads several GB and compiles a few packages (SomeWM among them)."
echo "Expect 20-60 minutes. A \"Git tree ... is dirty\" warning is expected."
nixos-install --flake "$dest#$host" --no-root-passwd

# ── 7. Passwords ──────────────────────────────────────────
step "Password for root: the rescue login, rarely used (typed twice, nothing shows while typing)"
until nixos-enter --root "$target" -c "$sysbin/passwd root"; do echo "That did not take; try again."; done
step "Password for $user: your everyday login (typed twice)"
until nixos-enter --root "$target" -c "$sysbin/passwd $user"; do echo "That did not take; try again."; done

# ── 8. Finish ─────────────────────────────────────────────
step "Handing /home/$user to $user"
nixos-enter --silent --root "$target" -c "$sysbin/chown -R $user:users /home/$user"

step "Unmounting"
sync
umount -R "$target"

printf '\n%sDone.%s Type: reboot   Take the USB stick out once the screen goes dark,\n' "$green$bold" "$reset"
echo "not before: the live system runs from it and crashes without it (the install is safe either way)."
echo "After the first login, continue with \"After the first boot\" in docs/install.md."
