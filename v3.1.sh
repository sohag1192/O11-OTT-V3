#!/bin/bash
#
# O11 OTT Streamer v3 Installer & Manager
# Modified by: Md. Sohag Rana (production-ready, lifecycle support)

set -e

INSTALL_DIR="/home/o11"
ZIP_URL="https://github.com/sohag1192/O11-OTT-V3/raw/main/v3p.zip"
ZIP_FILE="v3p.zip"
LAUNCHER="v3p_launcher"
SERVICE_NAME="o11"

install_app() {
    echo "🔧 Updating package list and installing dependencies..."
    sudo apt-get update -y
    sudo apt-get install -y ffmpeg unzip wget

    echo "📁 Creating installation directory at $INSTALL_DIR..."
    sudo mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"

    if [ ! -f "$ZIP_FILE" ]; then
        echo "⬇️ Downloading $ZIP_FILE..."
        sudo wget -O "$ZIP_FILE" "$ZIP_URL"
    else
        echo "⚡ Using existing $ZIP_FILE"
    fi

    echo "📦 Unzipping $ZIP_FILE..."
    sudo unzip -o "$ZIP_FILE"

    echo "🔐 Making $LAUNCHER executable..."
    sudo chmod +x "$LAUNCHER"

    echo "📝 Creating systemd service: $SERVICE_NAME.service..."
    sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null <<EOF
[Unit]
Description=O11 OTT Streamer Service
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/$LAUNCHER -p 2086 -noramfs
Restart=on-failure
RestartSec=3
LimitNOFILE=infinity
LimitNPROC=infinity
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    echo "🔄 Reloading systemd and enabling service..."
    sudo systemctl daemon-reload
    sudo systemctl enable "$SERVICE_NAME"
    sudo systemctl restart "$SERVICE_NAME"

    echo "✅ Installation complete. Service '$SERVICE_NAME' is now running."
}

uninstall_app() {
    echo "🛑 Stopping and disabling service..."
    sudo systemctl stop "$SERVICE_NAME" || true
    sudo systemctl disable "$SERVICE_NAME" || true

    echo "🗑 Removing systemd service file..."
    sudo rm -f /etc/systemd/system/${SERVICE_NAME}.service
    sudo systemctl daemon-reload

    echo "🗑 Removing installation directory..."
    sudo rm -rf "$INSTALL_DIR"

    echo "✅ Uninstallation complete. Service '$SERVICE_NAME' removed."
}

status_app() {
    echo "📊 Checking service status..."
    sudo systemctl status "$SERVICE_NAME" --no-pager
}

case "$1" in
    install)
        install_app
        ;;
    uninstall)
        uninstall_app
        ;;
    status)
        status_app
        ;;
    *)
        echo "Usage: $0 {install|uninstall|status}"
        exit 1
        ;;
esac
