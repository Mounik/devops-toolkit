#!/bin/bash
# server-init.sh — Bootstrap a fresh Linux server
# Usage: curl -sL <url> | bash
# Or: bash server-init.sh --user deploy --ssh-key "ssh-ed25519 AAAA..."

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[-]${NC} $1"; exit 1; }

# Parse args
DEPLOY_USER="${1:-deploy}"
SSH_KEY="${2:-}"
TIMEZONE="${3:-${TZ:-Europe/Paris}}"

# Root check
[[ $EUID -ne 0 ]] && err "Run as root"

log "Bootstrapping server for user: $DEPLOY_USER"

# 1. System update
log "Updating system..."
apt update && apt upgrade -y
apt install -y curl wget git vim htop tmux unzip jq ca-certificates gnupg

# 2. Create deploy user
if ! id "$DEPLOY_USER" &>/dev/null; then
    log "Creating user: $DEPLOY_USER"
    useradd -m -s /bin/bash -G sudo "$DEPLOY_USER"
    mkdir -p /home/$DEPLOY_USER/.ssh
    chmod 700 /home/$DEPLOY_USER/.ssh
fi

# 3. Add SSH key if provided
if [[ -n "$SSH_KEY" ]]; then
    log "Adding SSH key for $DEPLOY_USER"
    echo "$SSH_KEY" >> /home/$DEPLOY_USER/.ssh/authorized_keys
    chmod 600 /home/$DEPLOY_USER/.ssh/authorized_keys
    chown -R $DEPLOY_USER:$DEPLOY_USER /home/$DEPLOY_USER/.ssh
fi

# 4. Harden SSH
log "Hardening SSH..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
cat > /etc/ssh/sshd_config.d/hardening.conf <<EOF
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
MaxSessions 3
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
EOF

# 5. Install UFW
log "Configuring firewall..."
apt install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# 6. Install fail2ban
log "Installing fail2ban..."
apt install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# 7. Install Docker
log "Installing Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo $ID)/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release && echo $ID) $(. /etc/os-release && echo $VERSION_CODENAME) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
usermod -aG docker "$DEPLOY_USER"
systemctl enable docker
systemctl start docker

# 8. Automatic security updates
log "Enabling automatic security updates..."
apt install -y unattended-upgrades apt-listchanges
dpkg-reconfigure -plow unattended-upgrades

# 9. Set timezone
log "Setting timezone to $TIMEZONE..."
timedatectl set-timezone "$TIMEZONE"

# 10. Enable BBR
log "Enabling TCP BBR..."
if ! grep -q bbr /etc/sysctl.conf; then
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
fi

log "========================================="
log "Server bootstrap complete!"
log "User: $DEPLOY_USER"
log "SSH: key-only auth, root login disabled"
log "Firewall: UFW (22, 80, 443)"
log "Docker: installed + compose plugin"
log "========================================="
warn "RESTART SSHD IN ANOTHER TERMINAL FIRST:"
warn "  systemctl restart sshd"
warn "Then verify you can login as $DEPLOY_USER before closing this session!"