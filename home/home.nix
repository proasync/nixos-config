{ config, pkgs, ... }:

{
  home.username = "proasync";
  home.homeDirectory = "/home/proasync";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  # ── User packages ──────────────────────────────────────
  home.packages = with pkgs; [
    # Browsers
    google-chrome
    brave
    firefox

    # Terminal & editor
    alacritty
    (vscode.override {
      commandLineArgs = [ "--password-store=gnome-libsecret" ];
    })

    # X11 / Awesome WM tools
    picom
    unclutter
    dmenu
    rofi
    nitrogen
    numlockx
    flameshot
    xrandr
    xkill
    arandr
    xclip

    # Wayland / Hyprland tools
    waybar
    mako
    hyprpaper
    hyprlock
    hypridle
    wl-clipboard
    grim
    slurp
    satty
    brightnessctl
    playerctl
    nwg-displays
    wlr-randr
    libnotify

    # File management
    thunar
    thunar-archive-plugin
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
    libreoffice-fresh

    # Development
    nodejs_20
    yarn
    rsync
    jq
    wp-cli

    # GUI utilities
    pavucontrol
    htop
    networkmanagerapplet
    dbeaver-bin
    gimp
    inkscape
    seahorse
    lsof
    fastfetch
    nerd-fonts.mononoki

    # Theming
    (catppuccin-gtk.override { variant = "mocha"; accents = [ "mauve" ]; })
    papirus-icon-theme
  ];

  fonts.fontconfig.enable = true;

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
      nrd = "sudo nixos-rebuild dry-build --flake ~/nixos-config#$(hostname)";
    };

    bashrcExtra = ''
      # Default editor
      export EDITOR='code --wait'
      export VISUAL='code --wait'

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

  # ── Git ────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings.user = {
      name = "proasync";
      email = "andreas@pagodalog.com";
    };
  };

  # ── GTK theme ──────────────────────────────────────────
  gtk = {
    enable = true;
    theme.name = "catppuccin-mocha-mauve-standard+default";
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
  };

  # ── Xresources ─────────────────────────────────────────
  xresources.properties = {
    "Xcursor.theme" = "Bibata-Modern-Ice";
    "Xcursor.size" = 24;
  };

  # ── Dotfiles (symlinked to repo for live editing) ──────
  home.file.".config/hypr".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/proasync/nixos-config/home/dotfiles/hypr";

  home.file.".config/awesome".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/proasync/nixos-config/home/dotfiles/awesome";

  home.file.".config/waybar".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/proasync/nixos-config/home/dotfiles/waybar";

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

  # User scripts
  home.file.".local/bin/imv-dir" = {
    source = ./scripts/imv-dir;
    executable = true;
  };

  # Desktop entries
  home.file.".local/share/applications/imv-dir.desktop".source =
    ./applications/imv-dir.desktop;
}
