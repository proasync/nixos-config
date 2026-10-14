# Desktop freezes and stalls on proasync-laptop (Awesome / SomeWM)

What to do when the desktop stops responding, what to collect afterwards, and
what past freezes turned out to be. Machine: ASUS Zenbook S 13 (UX5304MA),
Intel Meteor Lake iGPU, 30 GB RAM, zram swap only (no disk swap), X on VT 2,
picom `glx` backend.

## When it freezes — try in this order

Each step either fixes it or tells us more. Pressing power is the last step,
not the first.

1. **Mod+Shift+P** — restart picom (`scripts/picom-restart.sh`). If the screen
   comes back, the compositor had stalled; its log is kept (see below).
2. **Text console: Ctrl+Alt+F3.** The F-row on this ASUS may be in hotkey
   (media) mode, so if nothing happens try **Fn+Ctrl+Alt+F3**. On the POK3R
   F3 is **Ctrl+Alt+Fn+3**. On either keyboard **Ctrl+Alt+CapsLock+3** works
   too (keyd maps CapsLock+3 → F3). Log in, then:
   - `pkill -x picom`, back to the desktop with **Ctrl+Alt+F2** (or
     Fn/CapsLock+2). Desktop works again → it was picom.
   - Still stuck → `top` (anything at 100 % CPU? memory full?), then
     `kill -HUP $(pgrep -x awesome)` restarts Awesome and keeps the windows.
3. **Magic SysRq** (enabled: `kernel.sysrq = 1` in
   `hosts/proasync-laptop/configuration.nix`). SysRq is the Print Screen key
   — **Fn+P** on the POK3R. Hold **Alt**, tap PrtSc (Fn+P) and let go of it,
   then, still holding Alt, tap the letter. Let go of Fn before the letter:
   the Fn layer can turn letters into other keys. Nothing appears on screen;
   the effect itself (or a `sysrq:` line in `journalctl -k`) is the feedback.
   - **R** takes the keyboard back from X → retry step 2.
   - **W** dumps blocked tasks to the kernel log — tells us whether X or picom
     is stuck in the GPU driver. Wait ~10 s before rebooting so it is saved.
   - **F** runs the OOM killer once — the fix when memory is full.
   - Last resort instead of holding power: **R E I S U B**, Alt held the whole
     time, a few seconds between letters (syncs and unmounts disks, then
     reboots). If a letter does nothing, tap Fn+P again before it.
   Verified 2026-10-09: Alt, Fn+P, H logs `sysrq: HELP` in `journalctl -k`.
4. **Short press on power** — clean shutdown via logind (works as long as the
   kernel is alive). **Holding** power is a hard power-off.

## Afterwards — what to collect

```sh
journalctl --list-boots | tail -3            # which boot froze (-1 = previous)
journalctl -b -1 -p warning -o short-iso | tail -50
journalctl -b -1 -k -o short-iso | grep -iE 'i915|gpu|hang|oom|sysrq|blocked'
journalctl -b -1 -o short-iso | grep -iE 'memory pressure|too slow|main loop'
journalctl -b -1 -o short-iso | grep -E 'Power key|Powering off'  # clean or hard off
journalctl -b -1 -u earlyoom -o short-iso | grep -iE 'sending|killed'  # what earlyoom killed
ls -lt ~/.cache/picom/                       # picom log of the frozen session
```

The last lines before a gap in the journal date the freeze; note what was
started just before it.

## Slow, or hangs every few seconds — measure it live

For "everything is sluggish / freezes for a moment every ~30 s" while the
machine still responds (any session: Awesome, SomeWM, niri). Measure **while it
is happening**; afterwards the numbers look normal. Background: this laptop's
NixOS runs from an **external USB SSD** (`sda`, SSK SSD, USB 10 Gb/s, UAS), so
any stall of that disk freezes every app that writes, the desktop included.

Already in place (don't re-investigate): `usbcore.autosuspend=-1` (the root
SSD must never autosuspend), the Intel Sensor Hub blacklist (its firmware timed
out every ~30 s and wedged i915 — the *previous* "hangs every 30 s", fixed;
check with `lsmod | grep -i ish`, should be empty), zram + earlyoom.

```sh
uptime; top -b -n 2 -d 2 | grep '%Cpu' | tail -1   # high "wa" (iowait) → disk
cat /proc/pressure/io      # "full avg10" = % of time programs were blocked on disk
free -h                    # memory full? → see OOM section below
ps -eo stat,wchan:20,comm | awk '$1 ~ /^D/'        # who is blocked; …+flush-8:0 = writes to sda stuck
journalctl -k -b | grep -iE 'uas|reset|I/O error|blocked for more'   # USB/disk errors

# disk, per second for 30 s: written MB/s and requests in flight (read/write)
p=$(awk '$3=="sda"{print $10}' /proc/diskstats); for i in $(seq 30); do sleep 1
  c=$(awk '$3=="sda"{print $10}' /proc/diskstats)
  echo "$i  $(( (c-p)*512/1048576 )) MB/s  inflight $(cat /sys/block/sda/inflight | xargs)"; p=$c; done

# latency of small "must be on disk" writes (what editors/browsers do constantly)
dd if=/dev/zero of=~/.cache/lat bs=4k count=100 oflag=dsync; rm ~/.cache/lat
```

How to read it:

| Measurement | Healthy | Seen 2026-10-14 (bad) |
| --- | --- | --- |
| `wa` in top | a few % | 49 % |
| IO pressure `full avg60` | ≈ 0 | 66 |
| writes in flight with 0 MB/s moving | never for seconds | 11–22 requests stuck 2–3 s, ~29 s apart |
| `dd … oflag=dsync`, 100 writes | ≲ 0.3 s | 1.8 s (18 ms each) |

Disk looks bad → check the SSD's health (temperature, wear, error counts):
`nix shell nixpkgs#smartmontools -c sudo smartctl -a /dev/sda`. Also try another
USB-C port, no hub, and feel whether the SSD is hot.

Disk looks fine but the screen stutters → graphics. Caveat: the kernel worker
`kworker/…+i915_flip` also shows state `D` for a moment during every normal
frame, so sampling it is **not** proof of a stall unless it stays `D` for
seconds. The usual suspect on Intel laptop panels is Panel Self Refresh (PSR).
Test with `boot.kernelParams = [ "i915.enable_psr=0" ]` in
`hosts/proasync-laptop/configuration.nix` (`nrs` + reboot; NixOS disables the
systemd-boot command-line editor, so there's no one-off test). PSR saves about
0.2–0.6 W, only while the picture is completely still — roughly 3–5 % of
battery (~15–25 min per charge at the ~9.5 W this laptop draws in normal use).
Middle ground if PSR is the cause: `i915.enable_psr=1` (keeps PSR1, drops the
buggier PSR2). Battery draw for before/after comparisons:
`cat /sys/class/power_supply/BAT*/power_now` (µW).

## picom logging

picom is always started through
[picom-restart.sh](../home/dotfiles/awesome/scripts/picom-restart.sh) (Awesome
autostart, Mod+Shift+P, `tv-mirror.sh`, `picom-toggle.sh`). It logs at `info` to
`~/.cache/picom/picom-<start time>.log` and keeps the newest 10, so a restart
or reboot does not overwrite the log of the run that froze. For more detail on
one run: `PICOM_LOG_LEVEL=debug ~/.config/awesome/scripts/picom-restart.sh`.

## Past incidents

| When | Symptom | Finding |
| --- | --- | --- |
| 2026-10-08 ~09:46 | Cursor moved; clicks, keys, workspace switching and Ctrl+Alt+F3 did nothing. Short power press → clean shutdown. | Kernel alive. No GPU hang, OOM, crash or display change in the logs; nothing logged for ~3.5 min after VS Code + `yarn dev:client` were started. Cause unknown — suspects: picom `glx` stall, X server blocked, or a client stuck holding an X grab. picom had no log then. Ctrl+Alt+F3 may simply have needed Fn. |
| 2026-10-08 ~21:26 | Total freeze, power held. | **Out of memory.** journald "Under memory pressure", libinput "your system is too slow", Awesome main loop 6.4 s, InnoDB memory-pressure event — then nothing. No swap, so the kernel thrashed instead of killing a process. The process using the memory is not identifiable from the logs. |
| 2026-10-14 ~20:30 (SomeWM, 3 min after boot) | Extremely slow, hangs every ~30 s; first time since the Sensor Hub fix. | **Disk stalls on the USB root SSD**: iowait 49 %, IO pressure full avg60 66 %, `flush-8:0` blocked, small writes stuck 2–3 s with nothing moving, ~29 s apart. No USB/UAS errors, TRIM fine, 47 % full; reads fast (900 MB/s), small sync writes slow (18 ms). Calm again 16 min after boot. `i915_flip` sampling was inconclusive (see caveat above). **No change made** — decision: measure live next time; SMART check pending. |

## Out-of-memory protection (since 2026-10-09)

Set in `modules/common.nix`, all hosts:

- **`zramSwap`** — swap on a compressed RAM disk (zstd, up to 50 % of RAM).
  No partition, nothing written to the SSD. Idle pages compress ~3:1, so the
  laptop's 30 GB acts like roughly 40 GB, and memory filling up degrades
  gradually instead of thrashing. `zramctl` / `swapon --show` show it.
- **`services.earlyoom`** — when available RAM *and* free swap are both under
  10 %, kills the process with the highest OOM score. Chrome tabs and VS Code
  renderers carry `oom_score_adj` 300, so it is normally one tab ("Aw,
  Snap!"), not the session; the desktop (X, Awesome, picom, sddm, systemd,
  PipeWire, …) is on its `--avoid` list. Each kill shows a desktop
  notification and is logged: `journalctl -u earlyoom`.

Integrated graphics have no VRAM of their own: WebGL/three.js buffers and
textures live in system RAM. Heavy three.js pages that recreate renderers or
scenes on hot reload without `dispose()` grow with every save — Chrome's task
manager (Shift+Esc) shows memory per tab, `renderer.info.memory` per scene.
