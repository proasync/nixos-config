# Installing NixOS on a machine

The install-day runbook: from a blank disk to your own login screen, with this repo's
full setup on the first boot. [`scripts/install.sh`](../scripts/install.sh) does the
disk work and the install; this page is everything around it. Written 2026-10 for
moving `work-desktop` off Arch; the same steps work for any host in `flake.nix`.

## Before install day

1. **Back up.** On `work-desktop` this is `~/BACKUP` (its README lists what is in
   it and how to restore). `sudo ./backup-root.sh` adds the root-only files: VPN
   config, network connections, SSH host keys, printer drivers. Copy the folder to a
   USB stick formatted **ext4**: FAT/exFAT drop file permissions (SSH then refuses
   the keys) and symlinks. It holds live credentials, so keep that stick private.
2. **Browser passwords.** Saved passwords don't decrypt on a new system; they come
   back through Chrome sync. Check they are at passwords.google.com.
3. **Disks.** Unplug any disk with an OS you want to keep safe (on `work-desktop`:
   the Arch disk, GIGABYTE 240 GB SATA). A Windows disk can stay: the script never
   offers a disk holding NTFS or BitLocker, and never mounts or writes it. Keep the
   **backup stick unplugged** until after the first boot: it is ext4, so the script
   would list it as a disk you can erase (it skips only the live USB and Windows).
4. **A new host only** (not `work-desktop`, which exists): create `hosts/<newhost>/`
   with a `configuration.nix` (copy the closest host) and `niri/monitor.kdl` (copy
   `home-desktop`'s), add `"<newhost>"` to the host list in `flake.nix`, commit and
   push. The script clones from GitHub, so it only sees what is pushed. Add
   `hypr/monitors.conf` only if the host will run Hyprland.
5. **Write the USB stick** (erases it). Find the stick with `lsblk` (by size and
   model), then:

   ```sh
   cd ~/Downloads
   curl -L -o nixos.iso        https://channels.nixos.org/nixos-26.05/latest-nixos-graphical-x86_64-linux.iso
   curl -L -o nixos.iso.sha256 https://channels.nixos.org/nixos-26.05/latest-nixos-graphical-x86_64-linux.iso.sha256
   echo "$(cut -d' ' -f1 nixos.iso.sha256)  nixos.iso" | sha256sum -c    # must say OK
   sudo dd if=nixos.iso of=/dev/sdX bs=4M status=progress oflag=sync       # sdX = the stick
   ```

   The stick's NixOS version doesn't matter much: the installed system runs the
   versions pinned in `flake.lock`. It does decide the first `system.stateVersion`
   (26.05 here), which a new host's `configuration.nix` should match.

## Install day

> **Open issue (2026-10-23): the `pswarm` flake input.** Since 2026-10-22 `flake.nix`
> takes pSwarm from `git+file:///home/proasync/dev/proasync-monorepo` (a local checkout,
> because the monorepo is private and `sudo nixos-rebuild` evaluates as root, without
> your GitHub key). The live USB has no such checkout, so `install.sh` will fail when it
> evaluates the flake. Untested; decide how to handle it before the next install (e.g.
> clone the monorepo to that path on the live system first, or make the input
> optional).

1. Plug in the stick and the network cable, power on, open the boot menu (**F9** on
   HP; often F8, F11 or F12 elsewhere) and pick the stick's entry starting with
   **UEFI**. Secure Boot must be off in the firmware (already off on `work-desktop`); the
   stick won't start otherwise.
2. The live desktop starts by itself. Open a terminal from the app menu.
3. Run:

   ```sh
   git clone https://github.com/proasync/nixos-config.git
   cd nixos-config
   sudo bash scripts/install.sh work-desktop
   ```

   No login is needed: the repo is public, git and the network work out of the box.
4. Answer the script:
   - **Disk:** it lists every disk. The live USB and Windows are marked *skipped*;
     the others are bold, with size, model and whether they hold data. Type the new
     disk's name (e.g. `sda`), then `ERASE`.
   - Then it runs on its own for 20–60 minutes (downloads, and compiles SomeWM and
     claude-squad). A "Git tree … is dirty" warning is expected: it is
     the new `hardware-configuration.nix`, not yet committed.
   - **Root password** (twice): the rescue login, for when your own login fails.
   - **proasync password** (twice): your everyday login.
5. At "Done": type `reboot`, and take out the stick once the screen goes dark. Not
   before: the live system runs from the stick and crashes without it. The install
   itself is safe by then (written, synced and unmounted); if it did crash, hold the
   power button and start again. NixOS is now first in the boot order.

**If it stops with an error,** it prints which command failed. Nothing outside the
chosen disk was touched. Run the same `sudo bash scripts/install.sh …` again: it
starts over from the disk choice. A network blip during the download is the usual
cause.

## After the first boot

1. **Log in** (SDDM): pick Awesome. Wired network is up by itself.
2. **GitHub login and SSH key.** Pushing and cloning need an SSH key that GitHub
   knows. If the backup has your own `~/.ssh` (`id_ed25519` and the like), restore
   it as its README says. The `ssh_host_*` files under `etc/ssh` are the computer's
   identity, not a GitHub key: leave them. Otherwise let `gh` make one:

   ```sh
   gh auth login
   ```

   Answer GitHub.com, **SSH**, yes to a new key, Enter (no passphrase), title
   `work-desktop`, login with a web browser. `ssh -T git@github.com` then greets you
   by name. The first time, it asks to confirm GitHub's key: it must be
   `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU`.
3. **Restore the backup:** plug in the backup stick and follow the *Restore on
   NixOS* section of its README. No backup? Clone the dev repos:

   ```sh
   mkdir -p ~/dev
   git clone git@github.com:pagodalogistics/wisdom-monorepo.git ~/dev/pagoda-monorepo
   git clone git@github.com:proasync/proasync-monorepo.git ~/dev/proasync-monorepo
   ```

   Do this before the first `nrs`: the `pswarm` flake input reads
   `~/dev/proasync-monorepo` (branch `develop`, at least the commit `flake.lock`
   pins), and `nrs` fails without it.
4. **Commit the hardware config** the script generated (it is already staged), so
   GitHub and the other machines have it, and fetch the newer wallpapers, which the
   live USB left as small Git LFS placeholders:

   ```sh
   cd ~/nixos-config
   git commit -m "work-desktop: hardware config from the install"
   git push
   git lfs pull
   ```

   `git status` should then be clean. The script set the copy up for this: GitHub
   over SSH, and git's record of the files already matches the new disk. Without
   that, git listed the older wallpapers as modified and refused to pull (fixed
   2026-10-14). After this, `nrs` works as on the other machines.
5. **Tailscale** (hosts importing `modules/remote-access.nix`): if an older install
   of the machine is registered under the same name (the Arch `work-desktop`),
   remove it in the Tailscale admin console first, or the new one gets a `-1`
   suffix. Then `sudo tailscale up`. Keys allowed to SSH in are listed in
   `modules/remote-access.nix`.
6. **Monitors** (several screens): X places them in its own order. Arrange them
   with `arandr`, then save the layout as an `xrandr` command in Awesome's
   `configs/<host>/autostart.lua`, as `configs/work-desktop/autostart.lua` does
   (see *Per-host settings* in the README). Under SomeWM, arrange them with
   `wdisplays` and copy the positions into `configs/<host>/somewm.lua` (work-desktop's
   is the example); the names differ there (`DP-1`, not `DisplayPort-0`).
7. **Bluetooth:** pair the headphones again in blueman (tray icon).
8. **Wallpaper:** pick one in `waypaper` (any session; they share it).
9. **Apps:** log in to Chrome (sync brings passwords back), VS Code, Signal,
   WhatsApp, Teams, Spotify, Obsidian. VS Code settings and extensions are not in
   this repo (see the end of [updating.md](updating.md)).
10. **Dev repos and databases:** cloned and restored by the backup's restore steps;
    what the system provides for them is in [dev-environments.md](dev-environments.md).
    Optional WordPress setup: `sudo bash ~/nixos-config/scripts/setup-wordpress.sh`.

Git identity is set in `home/home.nix` (`programs.git.settings.user.*`); don't use
`git config --global`, the config file is a read-only link.

**Windows** (on its own disk) is not in the NixOS boot menu: systemd-boot only lists
systems on its own boot partition. Start it from the firmware boot menu (F9 on HP).
