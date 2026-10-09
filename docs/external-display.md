# External display on proasync-laptop (X11 / Awesome)

Runbook for TVs, projectors and monitors on the laptop. Read before touching
xrandr on this machine: it has bitten twice (2026-09-25: black screens, hard
reboots, lost work).

## TL;DR for a demo

```sh
~/.config/awesome/scripts/tv-mirror.sh on        # mirror, correct aspect
~/.config/awesome/scripts/tv-mirror.sh on --stretch   # whole desktop, 11 % wider
~/.config/awesome/scripts/tv-mirror.sh status
~/.config/awesome/scripts/tv-mirror.sh off       # run before unplugging
```

`~/.config/awesome` is a live (`mkOutOfStoreSymlink`) link to
`~/nixos-config/home/dotfiles/awesome`, so scripts added there are usable
immediately — no `nrs` needed.

- Save your work first. Nothing here is zero-risk.
- Plug the cable in **after** you are logged in. Do not restart Awesome
  (Mod+Shift+R) or log in with the TV attached: `monitor-setup.sh` runs at
  Awesome start and rearranges outputs into an extended layout at the TV's
  preferred mode (4K@60 on a 4K TV — see below).
- Picture cut off at the TV edges = TV overscan. Fix on the TV: picture size
  "Just Scan" / "Screen Fit" / "Fit to screen" / "Full pixel" / "Unscaled", or
  rename the HDMI input to "PC".
- picom (shadows/blur) is off while the mirror is on. That is deliberate.

## Why the script is shaped the way it is

| Rule | Reason |
|------|--------|
| Stop picom before any output change, restart only after the external is off | Turning HDMI-1 off with picom (glx + vsync) running wedged the panel's CRTC: `Present-flip: queue flip during flip on CRTC 0 failed: Device or resource busy`, both screens black, only the cursor left. |
| Never pass `eDP-1` to xrandr | The revert that "restored" the panel was itself a modeset on a wedged pipeline. Leaving the panel alone means there is nothing to restore. |
| Keep the external's footprint inside the 2880x1800 framebuffer (`--scale-from`, `--same-as`) | A larger framebuffer makes X resize the screen, which re-sets every CRTC including the panel. |
| 1080p first, never 4K@60 | Xorg logs `HDMI max TMDS frequency 300000KHz`. 4K@60 (594 MHz) only works as YCbCr 4:2:0 and went black after a while. 4K@30 (297 MHz) would fit but is right at the limit. |
| No auto-revert timer | A 90 s dead-man switch turned a working TV off mid-use. The user decides when it goes off. |
| Aspect via Awesome padding | Panel is 16:10, TVs 16:9. Reserving the bottom 180 px (`screen.padding`) and mirroring the top 2880x1620 gives a correct aspect without touching the panel mode. |

## Mirror vs. extended for presentations

Mirror (the script) is the safe default on this setup:

- X11 has one global DPI (`Xft.dpi` 160 for the panel). In an extended layout
  a 1080p TV gets the same 1.67× scaling: chunky UI, and apps already running
  (Chrome) do not re-read DPI when `monitor-setup.sh` drops it to 96.
- The extended layout in `monitor-setup.sh` re-positions and re-sets the panel
  and grows the framebuffer — the operations that have gone wrong here.
- Mirror needs no window juggling: what you see is what they see.

Extended is fine at a desk with a known monitor where you log in with it
attached and Awesome/DPI start up for that layout. It is the wrong tool for a
one-off unknown TV.

## Boot came up at ~800x600, everything crawled, terminal would not open

Seen 2026-09-30 09:35. Kernel log had no `i915` lines at all; instead
`xe 0000:00:02.0: Your graphics device 7d45 is not officially supported`, and
Xorg fell back to `Output None-1 ... 800x600` with `Refusing to try glamor on
llvmpipe` (software rendering). Awesome's main loop took seconds per
iteration, Chrome's GPU process failed, GL terminals could not start.

The GPU's PCI id matches both `i915` and `xe`; only `xe` (which refuses Meteor
Lake) was loaded — the same modalias-race class as the iwlwifi fix in
`hosts/proasync-laptop/configuration.nix`. Fix: `boot.initrd.kernelModules = [ "i915" ]`
plus `xe` blacklisted. If it still happens: `journalctl -k -b -1 | grep -E
'i915|xe 0000'` and compare with a good boot.

## If the screen goes black anyway

1. Wait ~30 s.
2. `Ctrl+Alt+F3` (maybe with Fn), wait 3 s, `Ctrl+Alt+F2` back to the session
   — forces X to re-set the outputs, windows survive.
3. If a real TTY works: `xrandr --output HDMI-1 --off` with `DISPLAY=:0`, then
   `pkill -x picom` was probably the missing step.
4. Last resort: `Alt+SysRq` R-E-I-S-U-B (sysrq is enabled on this host).

## Known wart

`app-picom@autostart.service` fails at every login ("Backend not specified"):
the picom package ships an XDG autostart entry that runs picom without a
config. Harmless — `rc.lua` starts the real picom with `picom.conf`.
