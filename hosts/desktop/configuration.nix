{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "home-desktop";
  networking.networkmanager.enable = true;

  # Timezone & locale
  time.timeZone = "Europe/Stockholm";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sv_SE.UTF-8";
    LC_IDENTIFICATION = "sv_SE.UTF-8";
    LC_MEASUREMENT = "sv_SE.UTF-8";
    LC_MONETARY = "sv_SE.UTF-8";
    LC_NAME = "sv_SE.UTF-8";
    LC_NUMERIC = "sv_SE.UTF-8";
    LC_PAPER = "sv_SE.UTF-8";
    LC_TELEPHONE = "sv_SE.UTF-8";
    LC_TIME = "sv_SE.UTF-8";
  };

  # Keyboard
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # User account
  users.users.proasync = {
    isNormalUser = true;
    description = "Proasync";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # GPU drivers (desktop = AMD)
  services.xserver.videoDrivers = [ "amdgpu" ];

  # ── Host-specific services ─────────────────────────────

  # MariaDB for WordPress development
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = [ "wordpress" ];
    ensureUsers = [
      {
        name = "wordpress";
        ensurePermissions = {
          "wordpress.*" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  # Apache + PHP for WordPress
  services.httpd = {
    enable = true;
    user = "wwwrun";
    group = "wwwrun";
    virtualHosts.localhost = {
      documentRoot = "/srv/http";
      extraConfig = ''
        <Directory "/srv/http">
          Options Indexes FollowSymLinks
          AllowOverride All
          Require all granted
          DirectoryIndex index.php index.html
        </Directory>
      '';
    };
    enablePHP = true;
    phpPackage = pkgs.php84.buildEnv {
      extensions = { enabled, all }: enabled ++ (with all; [
        mysqli
        pdo_mysql
        curl
        gd
        zip
        mbstring
        xml
        imagick
        intl
        soap
        bcmath
      ]);
      extraConfig = ''
        upload_max_filesize = 64M
        post_max_size = 64M
        memory_limit = 256M
        max_execution_time = 300
      '';
    };
  };

  # PostgreSQL local development database
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    ensureDatabases = [ "proasync" ];
    ensureUsers = [
      {
        name = "proasync";
        ensureClauses.superuser = true;
        ensureClauses.login = true;
      }
    ];
    authentication = ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
  };

  system.stateVersion = "25.11";
}
