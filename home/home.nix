{ config, pkgs, lib, osConfig, ... }:

let
  # Shared by every host. Anything host-specific goes in hosts/<host>/home.nix
  # (imported by flake.nix) or a per-host file under hosts/<host>/ — never a
  # hostname check here.
  hostName = osConfig.networking.hostName;
  niriDir = "/home/proasync/nixos-config/home/dotfiles/niri";
  hostNiriDir = "/home/proasync/nixos-config/hosts/${hostName}/niri";
  hostHasNiriExtras = builtins.pathExists (../hosts + "/${hostName}/niri/hostextras.kdl");
in
{
  # Hyprland is retired; its Home Manager side only activates on hosts that
  # import modules/hyprland.nix.
  imports = [ ./hyprland.nix ];

  # niri's monitor.kdl is always per host: nwg-displays (Mod+D) writes through
  # the ~/.config/niri/monitor.kdl link, so it must never point at a file other
  # hosts share. niri rejects the whole config if an included file is missing.
  assertions = [{
    assertion = builtins.pathExists (../hosts + "/${hostName}/niri/monitor.kdl");
    message = "hosts/${hostName}/niri/monitor.kdl is missing: every host needs its own (copy one from another host).";
  }];

  home.username = "proasync";
  home.homeDirectory = "/home/proasync";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.sessionVariables = {
    BROWSER = "google-chrome-stable";
  };

  # ── User packages ──────────────────────────────────────
  home.packages = with pkgs; [
    # Browsers
    google-chrome
    brave

    # Terminal & editor
    alacritty
    vim
    neovim
    (vscode.override {
      commandLineArgs = [ "--password-store=gnome-libsecret" ];
    })

    # X11 / Awesome WM tools
    picom
    unclutter
    dmenu
    rofi
    feh            # X11 wallpaper (nitrogen was removed from nixpkgs)
    numlockx
    flameshot
    xrandr
    xkill
    arandr
    xclip
    alsa-utils  # amixer — needed by Awesome WM volume widget/keys

    # Wayland tools (niri). Hyprland-only ones are in home/hyprland.nix.
    waybar
    mako
    awww           # Wayland wallpaper daemon (was swww; binaries awww/awww-daemon)
    xwayland-satellite  # niri runs X11-only apps through this (it must be on PATH)
    swaylock    # screen locker: wm-scripts/lock.sh, theme in dotfiles/swaylock/
    swayidle    # idle → lock / screens off; started by niri/config.kdl
    wl-clipboard
    cliphist    # clipboard history — autostarted by Hyprland and niri
    grim
    slurp
    satty
    brightnessctl
    playerctl
    nwg-displays
    wlr-randr
    libnotify
    socat
    openssl

    # File management
    thunar
    thunar-archive-plugin
    thunar-volman           # volume manager plugin for Thunar
    tumbler               # thumbnail service for Thunar
    udiskie               # auto-mount daemon
    gvfs                  # virtual filesystem (Thunar mount support)
    xarchiver
    unzip
    zip
    p7zip
    imv

    # Communication
    teams-for-linux
    whatsapp-electron
    signal-desktop

    # Productivity & media
    obsidian
    spotify
    cava
    mpv
    waypaper
    libreoffice

    # Terminal rice
    yazi
    pipes-rs
    cbonsai

    # Development
    claude-code
    codex       # OpenAI Codex CLI — sign in with ChatGPT (Pro/Team sub, no API key)
    # Multi-agent TUI: runs Claude Code + Codex etc. in parallel tmux+worktree
    # sessions. Built from source (not in nixpkgs). Provides `cs`. Needs tmux
    # (enabled below) + gh (present). See home/packages/claude-squad.nix.
    (callPackage ./packages/claude-squad.nix { })
    # pSwarm desktop app launcher (proasync-monorepo/apps/pswarm-desktop): runs the
    # repo's release binary inside its nix-shell. See home/packages/pswarm.nix.
    (callPackage ./packages/pswarm.nix { })
    nodejs_22   # general-purpose Node; repos pin their own via shell.nix + direnv
                # (pagoda → Node 18, proasync → Node 20)
    yarn
    rsync
    jq
    wp-cli
    heroku
    gh
    awscli2
    ngrok
    # Native node-module build toolchain (bcrypt, zpl-image, better-sqlite3 …
    # need these when prebuilt binaries don't run on NixOS)
    python3
    gcc
    gnumake
    pkg-config
    watchman    # faster file watching for Metro/Expo (training-mobile)

    # GUI utilities
    pavucontrol
    htop
    btop
    networkmanagerapplet
    openfortivpn
    dbeaver-bin
    gimp
    inkscape
    imagemagick
    wineWow64Packages.stable   # wineWowPackages renamed upstream (WoW64)
    seahorse
    lsof
    fastfetch
    # (fonts live in modules/common.nix → fonts.packages)

    # Theming
    (catppuccin-gtk.override { variant = "mocha"; accents = [ "mauve" ]; })
    papirus-icon-theme
  ];

  fonts.fontconfig.enable = true;

  # ── Firefox (prevent it from hijacking default browser) ──
  programs.firefox = {
    enable = true;
    # Firefox already keeps its profile here (~/.mozilla/firefox doesn't exist).
    configPath = "${config.xdg.configHome}/mozilla/firefox";
    policies = {
      DontCheckDefaultBrowser = true;
      DefaultDownloadDirectory = "\${home}/Downloads";
    };
  };

  # ── Shell (bash) ───────────────────────────────────────
  programs.bash = {
    enable = true;
    historyControl = [ "ignoreboth" "erasedups" ];
    historySize = 10000;
    historyFileSize = 20000;

    shellAliases = {
      ls = "ls --color=auto";
      grep = "grep --color=auto";
      egrep = "egrep --color=auto";
      fgrep = "fgrep --color=auto";
      ll = "ls -lah";
      la = "ls -A";
      df = "df -h";
      wget = "wget -c";
      psa = "ps auxf";
      "cd.." = "cd ..";
      # NixOS rebuild shortcuts
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-config#$(hostname)";
      nrt = "sudo nixos-rebuild test --flake ~/nixos-config#$(hostname)";
      # for when switch refuses ("switch inhibitors", e.g. D-Bus change): then reboot
      nrb = "sudo nixos-rebuild boot --flake ~/nixos-config#$(hostname)";
      nrd = "sudo nixos-rebuild dry-build --flake ~/nixos-config#$(hostname)";
    };

    bashrcExtra = ''
      # Default editor
      export EDITOR='nvim'
      export VISUAL='nvim'

      # Git prompt
      if [ -f /run/current-system/sw/share/bash-completion/completions/git-prompt.sh ]; then
        source /run/current-system/sw/share/bash-completion/completions/git-prompt.sh
      fi
      if type __git_ps1 &>/dev/null; then
        export GIT_PS1_SHOWDIRTYSTATE=1
        export GIT_PS1_SHOWUNTRACKEDFILES=1
        export PS1='\[\033[01;32m\]\u@\h\[\033[00m\] \[\033[01;34m\]\w\[\033[33m\]$(__git_ps1 " (%s)")\[\033[00m\] $ '
      else
        export PS1='\[\033[01;32m\]\u@\h\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\] $ '
      fi

      # Tab completion (case-insensitive)
      bind "set completion-ignore-case on"

      # PATH
      [[ -d "$HOME/.local/bin" ]] && PATH="$HOME/.local/bin:$PATH"

      # Archive extractor
      ex () {
        if [ -f "$1" ] ; then
          case $1 in
            *.tar.bz2)   tar xjf "$1"   ;;
            *.tar.gz)    tar xzf "$1"   ;;
            *.bz2)       bunzip2 "$1"   ;;
            *.rar)       unrar x "$1"   ;;
            *.gz)        gunzip "$1"    ;;
            *.tar)       tar xf "$1"    ;;
            *.tbz2)      tar xjf "$1"   ;;
            *.tgz)       tar xzf "$1"   ;;
            *.zip)       unzip "$1"     ;;
            *.Z)         uncompress "$1";;
            *.7z)        7z x "$1"      ;;
            *.tar.xz)    tar xf "$1"    ;;
            *.tar.zst)   tar xf "$1"    ;;
            *)           echo "'$1' cannot be extracted via ex()" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }

      # System info
      fastfetch
    '';
  };

  # ── Direnv ─────────────────────────────────────────────
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableBashIntegration = true;
  };

  # ── tmux ───────────────────────────────────────────────
  # Required by claude-squad (spawns each agent in its own tmux session).
  # Also the thing that keeps a long agent run alive across a disconnect —
  # useful later for driving agents over SSH from another machine/phone.
  # Kept minimal so it doesn't interfere with claude-squad's session mgmt.
  programs.tmux = {
    enable = true;
    mouse = true;
    baseIndex = 1;
    historyLimit = 50000;
    escapeTime = 10;      # snappier for TUIs (claude-squad, nvim)
    terminal = "tmux-256color";
  };

  # ── Git ────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings.user.name = "proasync";
    settings.user.email = "andreas@pagodalog.com";
    # Wallpapers in this repo are stored via LFS (see .gitattributes).
    lfs.enable = true;
  };

  # ── GTK theme ──────────────────────────────────────────
  gtk = {
    enable = true;
    theme.name = "catppuccin-mocha-mauve-standard";
    iconTheme.name = "Papirus-Dark";
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      size = 24;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    # HM 26.05 stopped applying theme.name to GTK4 by default; keep the old look.
    gtk4.theme = config.gtk.theme;
  };

  # ── Xresources ─────────────────────────────────────────
  xresources.properties = {
    "Xcursor.theme" = "Bibata-Modern-Ice";
    "Xcursor.size" = 24;
  };

  # ── Dotfiles (symlinked to repo for live editing) ──────
  # Scripts shared by the Wayland compositors (niri, and Hyprland if it comes
  # back): power menu, lock, Chrome launcher, touchpad toggle.
  home.file.".config/wm-scripts".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/proasync/nixos-config/home/dotfiles/wm-scripts";

  home.file.".config/swaylock".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/proasync/nixos-config/home/dotfiles/swaylock";

  # Claude Code settings: real files, NOT symlinks (decided 2026-10-09).
  # Claude Code rewrites these itself (the /model picker, "always allow" permission
  # answers) using a temp file + rename placed next to the *first* symlink hop. With
  # mkOutOfStoreSymlink that first hop lives in /nix/store (read-only), so every such
  # write failed with "Failed to set model: EROFS", and each `nrs` (force = true)
  # re-created the broken link. Now: seed each file from the template once (when it is
  # missing or still a symlink), then leave Claude Code's own copy alone. To push a
  # template change to the live file, edit the live file too — or delete the live file
  # and rebuild to re-seed. The template's "model" is only the first-run default.
  # Runs after linkGeneration, i.e. after home-manager has removed the old symlinks.
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    tpl=/home/proasync/nixos-config/home/dotfiles/claude
    run mkdir -p "$HOME/.claude"
    for f in settings.json settings.local.json; do
      dst="$HOME/.claude/$f"
      if [ -L "$dst" ] || [ ! -e "$dst" ]; then
        run cp --remove-destination "$tpl/$f" "$dst"
        run chmod 644 "$dst"
      fi
    done
  '';

  # waypaper's config.ini is its own state (last wallpaper), not managed here.
  # swww was renamed to awww (nixpkgs 2026-03, binaries too), so point an old
  # `backend = swww` at awww. Idempotent; a no-op once migrated or if absent.
  home.activation.waypaperAwww = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cfg="$HOME/.config/waypaper/config.ini"
    if [ -f "$cfg" ] && grep -q '^backend = swww$' "$cfg"; then
      run sed -i 's/^backend = swww$/backend = awww/' "$cfg"
    fi
  '';

  # Flameshot 14 captures through xdg-desktop-portal, which has no working
  # backend under Awesome (X11) → "Unable to capture screen". Its own escape
  # hatch is the X11 grabber (ignored on Wayland). flameshot.ini is Flameshot's
  # state (it writes it), so only make sure this one key is set.
  home.activation.flameshotX11Capture = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cfg="$HOME/.config/flameshot/flameshot.ini"
    if [ ! -f "$cfg" ]; then
      run mkdir -p "$HOME/.config/flameshot"
      run sh -c "printf '[General]\nuseX11LegacyScreenshot=true\n' > '$cfg'"
    elif ! grep -q '^useX11LegacyScreenshot=true$' "$cfg"; then
      run sed -i '/^useX11LegacyScreenshot=/d' "$cfg"
      if grep -q '^\[General\]' "$cfg"; then
        run sed -i '/^\[General\]/a useX11LegacyScreenshot=true' "$cfg"
      else
        run sh -c "printf '[General]\nuseX11LegacyScreenshot=true\n' >> '$cfg'"
      fi
    fi
  '';

  # niri is shared, except monitor.kdl (always per host) and hostextras.kdl
  # (per host if hosts/<host>/niri/hostextras.kdl exists). config.kdl pulls
  # both in with `include`, resolved next to these links.
  home.file.".config/niri/config.kdl".source =
    config.lib.file.mkOutOfStoreSymlink "${niriDir}/config.kdl";
  home.file.".config/niri/waybar".source =
    config.lib.file.mkOutOfStoreSymlink "${niriDir}/waybar";
  home.file.".config/niri/scripts".source =
    config.lib.file.mkOutOfStoreSymlink "${niriDir}/scripts";
  home.file.".config/niri/monitor.kdl".source =
    config.lib.file.mkOutOfStoreSymlink "${hostNiriDir}/monitor.kdl";
  home.file.".config/niri/hostextras.kdl".source =
    config.lib.file.mkOutOfStoreSymlink
      (if hostHasNiriExtras then "${hostNiriDir}/hostextras.kdl" else "${niriDir}/hostextras.kdl");

  # Until 2026-10-10 ~/.config/niri was one link to the whole repo folder. Home
  # Manager checks new link targets before it removes old links, so through
  # that folder link it finds the repo's own files in the way, and aborts where
  # they differ (the laptop's hostextras.kdl vs the shared one; rehearsed
  # 2026-10-10). So remove the old link first, and only if it is Home Manager's
  # own. A no-op once every host has switched; then it can go.
  home.activation.niriFolderLink = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    if [[ -L "$HOME/.config/niri" && "$(readlink "$HOME/.config/niri")" == /nix/store/*-home-manager-files/* ]]; then
      run rm $VERBOSE_ARG "$HOME/.config/niri"
    fi
  '';

  home.file.".config/awesome".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/proasync/nixos-config/home/dotfiles/awesome";

  home.file.".config/mako".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/proasync/nixos-config/home/dotfiles/mako";

  home.file.".config/alacritty".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/proasync/nixos-config/home/dotfiles/alacritty";

  home.file.".config/rofi".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/proasync/nixos-config/home/dotfiles/rofi";

  home.file.".config/wallpapers".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/proasync/nixos-config/home/dotfiles/wallpapers";

  home.file.".config/imv".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/proasync/nixos-config/home/dotfiles/imv";

  home.file.".config/cava".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/proasync/nixos-config/home/dotfiles/cava";

  home.file.".config/btop".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/proasync/nixos-config/home/dotfiles/btop";

  # User scripts
  home.file.".local/bin/imv-dir" = {
    source = ./scripts/imv-dir;
    executable = true;
  };

  # Desktop entries
  home.file.".local/share/applications/pswarm.desktop".source =
    ./applications/pswarm.desktop;
  home.file.".local/share/applications/imv-dir.desktop".source =
    ./applications/imv-dir.desktop;
  home.file.".local/share/applications/cava.desktop".source =
    ./applications/cava.desktop;
  home.file.".local/share/applications/btop.desktop".source =
    ./applications/btop.desktop;
  home.file.".local/share/applications/yazi.desktop".source =
    ./applications/yazi.desktop;
  home.file.".local/share/applications/pipes-sh.desktop".source =
    ./applications/pipes-sh.desktop;
  home.file.".local/share/applications/cbonsai.desktop".source =
    ./applications/cbonsai.desktop;

  # MIME type associations
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http"  = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "text/html"              = "google-chrome.desktop";
      "application/xhtml+xml"  = "google-chrome.desktop";
      "image/jpeg"    = "imv-dir.desktop";
      "image/png"     = "imv-dir.desktop";
      "image/gif"     = "imv-dir.desktop";
      "image/webp"    = "imv-dir.desktop";
      "image/bmp"     = "imv-dir.desktop";
      "image/tiff"    = "imv-dir.desktop";
      "image/svg+xml" = "imv-dir.desktop";
      "image/avif"    = "imv-dir.desktop";
      "image/heic"    = "imv-dir.desktop";
      # Video
      "video/mp4"                 = "mpv.desktop";
      "video/x-matroska"          = "mpv.desktop";
      "video/webm"                = "mpv.desktop";
      "video/x-msvideo"           = "mpv.desktop";
      "video/quicktime"           = "mpv.desktop";
      "video/x-flv"               = "mpv.desktop";
      "video/mpeg"                = "mpv.desktop";
      "video/ogg"                 = "mpv.desktop";
      "video/3gpp"                = "mpv.desktop";
      "video/x-ogm+ogg"           = "mpv.desktop";
      # Audio (standalone files)
      "audio/mpeg"                = "mpv.desktop";
      "audio/flac"                = "mpv.desktop";
      "audio/ogg"                 = "mpv.desktop";
      "audio/wav"                 = "mpv.desktop";
      "audio/x-wav"               = "mpv.desktop";
      "audio/mp4"                 = "mpv.desktop";
      "audio/aac"                 = "mpv.desktop";
    };
  };
}
