# Desktop freezes on proasync-laptop (X11 / Awesome)

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
   (media) mode, so if nothing happens try **Fn+Ctrl+Alt+F3**, or
   **Ctrl+Alt+CapsLock+3** (keyd maps CapsLock+3 → F3). Log in, then:
   - `pkill -x picom`, back to the desktop with **Ctrl+Alt+F2** (or
     Fn/CapsLock+2). Desktop works again → it was picom.
   - Still stuck → `top` (anything at 100 % CPU? memory full?), then
     `kill -HUP $(pgrep -x awesome)` restarts Awesome and keeps the windows.
3. **Magic SysRq** (enabled: `kernel.sysrq = 1` in
   `hosts/proasync-laptop/configuration.nix`). Hold **Alt+PrtSc** (SysRq is
   the Print Screen key) and tap a letter:
   - **R** takes the keyboard back from X → retry step 2.
   - **W** dumps blocked tasks to the kernel log — tells us whether X or picom
     is stuck in the GPU driver. Wait ~10 s before rebooting so it is saved.
   - **F** runs the OOM killer once — the fix when memory is full.
   - Last resort instead of holding power: **R E I S U B**, a few seconds
     between letters (syncs and unmounts disks, then reboots).
   Check it works while things are fine: Alt+PrtSc+H should log a
   `sysrq: HELP` line in `journalctl -k`.
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
