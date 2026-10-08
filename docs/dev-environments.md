# Dev environments on NixOS

What this system config provides for `~/dev/pagoda-monorepo` and
`~/dev/proasync-monorepo`, and why. Audited 2026-07 against both repos'
actual dependencies — update this doc when those change.

## The layering

| Layer | Provides | Where |
| --- | --- | --- |
| Per-repo `shell.nix` + `.envrc` (direnv) | the **pinned Node version** and package manager for that repo | in each monorepo |
| Home Manager (`home/home.nix`) | fallback Node 22, yarn, native build toolchain, CLI tools (aws, heroku, gh, jq, ngrok, wp-cli), watchman | this repo |
| NixOS (`modules/common.nix`) | nix-ld with Electron/Chromium libs, docker, CUPS printing, firewall ports, direnv is enabled via HM | this repo |
| NixOS (`modules/dev-services.nix`) | PostgreSQL (`proasync` + `portal` DBs, trust auth), MariaDB (`wordpress`), Apache+PHP | this repo, imported by both hosts |

`programs.direnv` (with `nix-direnv`) is enabled in `home/home.nix`, so cd-ing into
either monorepo automatically enters its `shell.nix`. Run `direnv allow` once per repo
per machine.

## pagoda-monorepo (Yarn 1 + Turborepo, "wisdom" platform)

- **Node 18.18** pinned by the repo's own `shell.nix` (engines `>=18.18 <19` for the
  core apps). Exceptions: `apps/shopify-app` wants Node ≥20.10 and
  `apps/printing-service` (Electron 33) is happiest on ≥20 — both currently ride on
  `.yarnrc`'s `--ignore-engines`.
- **Yarn 1.22.19** via corepack (`"packageManager"` field) — the repo shellHook handles it.
- **PostgreSQL**: `console-api` and `gateway-api` hardcode host `127.0.0.1`, user
  `postgres`, db **`portal`** in their `knexfile.ts`. `modules/dev-services.nix`
  creates that database, and trust auth means the hardcoded password just works.
  Schema is applied manually with `psql` (per repo convention — never `knex migrate`).
- **Electron (`apps/printing-service`)**: runs the npm-downloaded Electron 33 binary.
  That works on NixOS because `programs.nix-ld` in `modules/common.nix` carries the
  full Chromium/Electron shared-library set (GTK, NSS, X11 libs, libGL, …). If
  Electron fails to start after a nixpkgs bump, a missing library in that list is the
  first suspect (`ldd` the binary, or run with `NIXOS_LD_DEBUG`).
  - Printing at runtime goes through CUPS `lp` and `/dev/usb/lp*` — `services.printing`
    is enabled in common.nix; the user is in the `lp` group.
  - Building distributables (`electron-builder --linux` → AppImage/deb) additionally
    needs `fakeroot` + `dpkg` — not installed globally; add them to the repo's
    `shell.nix` if you start building packages locally.
- **Native modules** (`bcrypt`, `bufferutil`, `utf-8-validate`, `zpl-image`): compiled
  by node-gyp during `yarn install`. The toolchain (`python3`, `gcc`, `gnumake`,
  `pkg-config`) is in `home.packages`.
- **CLI tools used by repo scripts**: `aws`, `heroku`, `jq`, `docker` — all provided
  (docker daemon enabled in common.nix; user is in the `docker` group).
- Deploy targets: S3 (awscli) + Heroku. `BROWSER=google-chrome` is exported by the
  repo's `.envrc` and Chrome is installed.

## proasync-monorepo (pnpm 9 + Turborepo + Biome)

- **Node ≥20** (`.nvmrc` = 20) via the repo's `shell.nix`; **pnpm 9.15.0** via corepack
  with a repo-local writable `COREPACK_HOME` (already handled by the shellHook).
- **No Electron.** The only "electron" in the lockfile is `electron-to-chromium`, a
  browserslist data table — don't add Electron anything for this repo.
- **No external databases needed for dev**: `training-server` uses embedded PGlite,
  `hemma-server` uses `better-sqlite3` (file-based). The system PostgreSQL is only
  relevant if you run the prod-style server with a real `DATABASE_URL`.
- **`better-sqlite3`** is the NixOS friction point: `prebuild-install` downloads a
  glibc prebuilt that nix-ld lets run (`stdenv.cc.cc.lib`, `zlib` are in the nix-ld
  list); if it falls back to source-building, the global toolchain covers it.
- **Expo / React Native (`apps/training-mobile`)**: Metro bundler on TCP **8081** and
  the training API on **4300** are opened in the firewall (`modules/lan-dev-ports.nix`,
  imported by home-desktop and proasync-laptop) so a phone on the LAN can connect via
  Expo Go. work-desktop keeps them closed on the office LAN; there the phone connects
  over Tailscale instead. `watchman` is installed for fast file watching.

## Global Node vs repo Node

`home/home.nix` installs **Node 22** (current LTS) for general use — one-off scripts,
`npx`, anything outside the monorepos. Each monorepo pins its own Node via `shell.nix`,
so the global version never leaks into repo work as long as direnv is allowed. If a
repo command complains about the Node version, you're probably outside the direnv shell.

## WordPress (wisdom-woocommerce-plugin)

MariaDB + Apache/PHP 8.4 (mysqli, gd, imagick, soap, …) run on both hosts via
`modules/dev-services.nix`; one-time site setup is `scripts/setup-wordpress.sh`,
`wp-cli` is installed globally.
