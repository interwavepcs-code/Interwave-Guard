#!/bin/bash
set -e

echo "===================================="
echo " Interwave Guard Appliance Installer "
echo "===================================="

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

echo "[1/9] Updating system..."
apt update -y
apt upgrade -y

echo "[2/9] Installing base packages..."
apt install -y \
  curl git ufw nginx openssl sqlite3 \
  python3 python3-flask \
  unbound unattended-upgrades

echo "[3/9] Installing Pi-hole..."
if ! command -v pihole >/dev/null; then
  curl -sSL https://install.pi-hole.net | bash /etc/pihole/setupVars.conf --unattended
fi

echo "[4/9] Installing Tailscale (not enabled)..."
curl -fsSL https://tailscale.com/install.sh | sh

echo "[5/9] Configuring Unbound..."
cat >/etc/unbound/unbound.conf.d/interwave.conf <<EOF
server:
  interface: 127.0.0.1
  port: 5335
  do-ip4: yes
  do-udp: yes
  do-tcp: yes
  prefetch: yes
  private-address: 192.168.0.0/16
  private-address: 10.0.0.0/8
  private-address: 172.16.0.0/12
EOF

systemctl enable --now unbound

echo "[6/9] Firewall setup (LAN only)..."
ufw default deny incoming
ufw default allow outgoing
ufw allow from 192.168.0.0/16 to any port 53
ufw allow from 10.0.0.0/8 to any port 53
ufw allow from 172.16.0.0/12 to any port 53
ufw allow from 192.168.0.0/16 to any port 443
ufw allow from 10.0.0.0/8 to any port 443
ufw allow from 172.16.0.0/12 to any port 443
ufw --force enable

echo "[7/9] Generating HTTPS certificate..."
mkdir -p /etc/nginx/certs
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout /etc/nginx/certs/interwave.key \
  -out /etc/nginx/certs/interwave.crt \
  -subj "/C=US/O=Interwave Guard/CN=adblocker.local"

echo "[8/9] Nginx reverse proxy..."
cat >/etc/nginx/sites-available/interwave <<'EOF'
server {
  listen 80;
  return 301 https://$host$request_uri;
}
server {
  listen 443 ssl;
  ssl_certificate /etc/nginx/certs/interwave.crt;
  ssl_certificate_key /etc/nginx/certs/interwave.key;

  location / {
    return 302 /setup/;
  }
}
EOF

rm -f /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/interwave /etc/nginx/sites-enabled/interwave
systemctl enable --now nginx

echo "[9/9] Final cleanup..."
systemctl enable unattended-upgrades
echo "[FINAL] Installing Interwave Guard app..."

# Create app directory
mkdir -p /opt/interwave

# Download Flask app
curl -fsSL https://raw.githubusercontent.com/interwavepcs-code/Interwave-Guard/main/appliance/app.py \
  -o /opt/interwave/app.py

chmod +x /opt/interwave/app.py

# Install systemd service
curl -fsSL https://raw.githubusercontent.com/interwavepcs-code/Interwave-Guard/main/appliance/interwave-wizard.service \
  -o /etc/systemd/system/interwave-wizard.service

# Enable and start service
systemctl daemon-reload
systemctl enable interwave-wizard
systemctl start interwave-wizard

echo "===================================="
echo " Installation complete!"
echo " Reboot recommended."
echo "===================================="
reboot

