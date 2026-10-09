{ config, pkgs, ... }:

# Local development services — databases + WordPress stack.
#
# Imported by every host that should run dev services (currently all three:
# home-desktop, proasync-laptop, work-desktop). If a future machine shouldn't
# run them, just drop this import from its hosts/<host>/configuration.nix.

{
  # ── MariaDB — WordPress development ────────────────────
  services.mysql = {
    enable = true;
    # Pinned: `pkgs.mariadb` follows nixpkgs' default and a major bump upgrades
    # the data dir in place (no way back on rollback). Bump deliberately.
    package = pkgs.mariadb_114;
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

  # ── Apache + PHP — WordPress ───────────────────────────
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

  # ── PostgreSQL — local development database ────────────
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    # "portal" is pagoda-monorepo's dev DB (hardcoded in apps/{console-api,
    # gateway-api}/src/knexfile.ts — connects as user `postgres` over
    # 127.0.0.1; trust auth below makes the hardcoded password irrelevant).
    ensureDatabases = [ "proasync" "portal" ];
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
}
