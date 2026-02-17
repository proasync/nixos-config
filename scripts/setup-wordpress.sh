#!/usr/bin/env bash
set -euo pipefail

# WordPress setup script for NixOS
# Run once after nixos-rebuild on a new machine:
#   sudo bash ~/nixos-config/scripts/setup-wordpress.sh

WP_PATH="/srv/http"
DB_NAME="wordpress"
DB_USER="wordpress"
SITE_URL="http://localhost"
SITE_TITLE="Wisdom Dev"
ADMIN_USER="admin"
ADMIN_PASS="admin"
ADMIN_EMAIL="admin@localhost.com"

echo "=== WordPress Setup for NixOS ==="

# 1. Create document root
echo "[1/6] Creating document root..."
mkdir -p "$WP_PATH"
chown wwwrun:wwwrun "$WP_PATH"

# 2. Download WordPress
if [ ! -f "$WP_PATH/wp-includes/version.php" ]; then
    echo "[2/6] Downloading WordPress..."
    sudo -u wwwrun wp core download --path="$WP_PATH"
else
    echo "[2/6] WordPress already downloaded, skipping."
fi

# 3. Configure wp-config.php
if [ ! -f "$WP_PATH/wp-config.php" ]; then
    echo "[3/6] Creating wp-config.php..."
    sudo -u wwwrun wp config create \
        --dbname="$DB_NAME" \
        --dbuser="$DB_USER" \
        --dbpass="" \
        --dbhost="localhost" \
        --path="$WP_PATH"

    # Enable debug logging for development
    sudo -u wwwrun wp config set WP_DEBUG true --raw --path="$WP_PATH"
    sudo -u wwwrun wp config set WP_DEBUG_LOG true --raw --path="$WP_PATH"
    sudo -u wwwrun wp config set WP_DEBUG_DISPLAY false --raw --path="$WP_PATH"
else
    echo "[3/6] wp-config.php already exists, skipping."
fi

# 4. Install WordPress
if ! sudo -u wwwrun wp core is-installed --path="$WP_PATH" 2>/dev/null; then
    echo "[4/6] Installing WordPress..."
    sudo -u wwwrun wp core install \
        --url="$SITE_URL" \
        --title="$SITE_TITLE" \
        --admin_user="$ADMIN_USER" \
        --admin_password="$ADMIN_PASS" \
        --admin_email="$ADMIN_EMAIL" \
        --path="$WP_PATH"
else
    echo "[4/6] WordPress already installed, skipping."
fi

# 5. Install and activate WooCommerce
if ! sudo -u wwwrun wp plugin is-installed woocommerce --path="$WP_PATH" 2>/dev/null; then
    echo "[5/6] Installing WooCommerce..."
    sudo -u wwwrun wp plugin install woocommerce --activate --path="$WP_PATH"
else
    echo "[5/6] WooCommerce already installed."
    sudo -u wwwrun wp plugin activate woocommerce --path="$WP_PATH" 2>/dev/null || true
fi

# 6. Create plugin directory for development
PLUGIN_DIR="$WP_PATH/wp-content/plugins/wisdom-ship-woocommerce-plugin"
echo "[6/6] Setting up plugin directory..."
mkdir -p "$PLUGIN_DIR"
chown -R wwwrun:wwwrun "$PLUGIN_DIR"
chmod -R 775 "$PLUGIN_DIR"

echo ""
echo "=== Done! ==="
echo "WordPress:   $SITE_URL"
echo "Admin panel: $SITE_URL/wp-admin"
echo "Login:       $ADMIN_USER / $ADMIN_PASS"
echo ""
echo "Next: cd ~/dev/wisdom-woocommerce-plugin && yarn dev"
