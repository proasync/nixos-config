# Updating NixOS (all hosts)

How to update without the surprises of 2026-10-09, and what to check afterwards.

## Why that update hurt

The lock had not moved for 8 months (2026-02-13 → 2026-10-08 on `nixos-unstable`),
so everything changed at once. Nix caught the config-level breakage at build time
(nitrogen removed, swww renamed, renamed options). What it cannot catch is apps
*behaving* differently, and those were most of the pain:

| Change | Symptom | Fix (in repo unless noted) |
| --- | --- | --- |
| D-Bus implementation → dbus-broker | `nrs` stops right after building, nothing switches | `nrb` + reboot (switch inhibitor) |
| SDDM remembers the last session by `/nix/store` path | logged into niri instead of Awesome | laptop `services.displayManager.defaultSession = "none+awesome"` |
| niri `disabled-on-external-mouse` + keyd virtual pointer | touchpad dead in niri | option removed in `niri/config.kdl` |
| niri needs `xwayland-satellite` on PATH | X11 apps don't start in niri | package added |
| Hyprland 0.56 removed `dwindle:pseudotile` | config error; Hyprland (UWSM) froze | option removed |
| Flameshot 14 captures via xdg-desktop-portal | "Unable to capture screen" in Awesome | HM activation sets `useX11LegacyScreenshot=true` |
| VS Code 1.140 draws its own frame (`_GTK_FRAME_EXTENTS`) | odd double border, no visible top gap | VS Code setting `window.titleBarStyle: native` (not in repo) |
| VS Code 1.140 ships Copilot built in | slow startup, extension host stalls | VS Code setting `chat.disableAIFeatures: true` (not in repo) |

## How to avoid it

1. **Update little and often.** Every 2–4 weeks on unstable means a handful of
   changes per update, each easy to spot. Months of drift means dozens at once.
2. **Or follow a stable release** (decision pending, not set up yet): pin
   `nixpkgs` to `nixos-YY.MM` and home-manager to `release-YY.MM`. Routine updates
   then only bring fixes; the big changes come twice a year, on a day you pick, with
   release notes to read first. Apps you want fresh (claude-code, VS Code) can come
   from an extra `nixpkgs-unstable` input. 26.11 is due around end of November 2026.
3. **Do it on a branch, on one machine first**, and only merge/push after a
   reboot into the new system worked. Other hosts follow with `git pull` + rebuild.

## Procedure

```sh
cd ~/nixos-config && git switch -c update/$(date +%Y-%m)
nix flake update
# every host must evaluate — fix warnings too, they become errors later
for h in proasync-laptop home-desktop work-desktop; do
  nix eval --raw .#nixosConfigurations.$h.config.system.build.toplevel.drvPath >/dev/null && echo "$h ok"
done
new=$(nix build --no-link --print-out-paths .#nixosConfigurations.$(hostname).config.system.build.toplevel)
nix store diff-closures /run/current-system "$new" | less   # what changes, by version
diff /run/current-system/switch-inhibitors "$new/switch-inhibitors"  # any output → reboot needed
```

Then save your work and either `nrs` (no inhibitor change) or `nrb` + reboot.
Databases are pinned to a major version (`postgresql_17`, `mariadb_114`), so an
update never migrates their data; bump those deliberately.

## After the reboot — checklist (laptop)

- Login screen preselects **Awesome**; touchpad and keyboard work.
- Wallpaper is set (feh, `~/.fehbg`); picom runs and logs to `~/.cache/picom/`.
- **Super+P** screenshot works (Flameshot).
- VS Code and the Claude panel open normally.
- `systemctl --failed` shows nothing new (`app-picom@autostart` always fails — harmless).
- `nixos-version` shows the new date; `claude --version` moved.

If something is badly off: reboot and pick the previous generation in the boot
menu, then `git switch master` and investigate calmly.

## Settings that live outside this repo

Not managed by Nix, so they don't follow you to other machines:
`~/.config/Code/User/settings.json` (`window.titleBarStyle`, `chat.disableAIFeatures`,
`github.copilot.chat.claudeAgent.enabled`) and VS Code extensions.
