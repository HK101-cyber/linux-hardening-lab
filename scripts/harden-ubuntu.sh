#!/bin/bash
# ============================================================
# Linux Hardening Lab - Automated Hardening Script
# CIS Ubuntu 22.04 LTS Benchmark
# Author: Hammad Khan
# Idempotent - safe to run multiple times
# NOTE: Phase 1 (baseline audit) and Phase 13's final Lynis scan are
# deliberately NOT included here - they are measurement/verification
# steps, not configuration changes. Run Lynis manually before and after
# this script to measure its impact.
# ============================================================

set -e
LOG_FILE="/var/log/hardening-script.log"
echo "=== Hardening script run: $(date) ===" >> "$LOG_FILE"

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo $0)"
  exit 1
fi

echo "[Phase 2] Filesystem Hardening..."
grep -q "tmpfs /tmp" /etc/fstab || echo "tmpfs /tmp tmpfs defaults,noexec,nosuid,nodev 0 0" >> /etc/fstab
grep -q "hidepid=2" /etc/fstab || echo "proc /proc proc defaults,hidepid=2 0 0" >> /etc/fstab
mount -o remount /tmp 2>/dev/null || mount /tmp 2>/dev/null || true
mount -o remount /proc 2>/dev/null || true

cat > /etc/modprobe.d/hardening-blacklist.conf << 'EOF'
install cramfs /bin/false
install freevxfs /bin/false
install jffs2 /bin/false
install hfs /bin/false
install hfsplus /bin/false
install udf /bin/false
EOF

echo "[Phase 4] Process Hardening..."
cat > /etc/sysctl.d/99-hardening.conf << 'EOF'
kernel.randomize_va_space = 2
fs.suid_dumpable = 0
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
EOF
sysctl --system > /dev/null

systemctl disable apport --now 2>/dev/null || true
sed -i 's/enabled=1/enabled=0/' /etc/default/apport 2>/dev/null || true
grep -q "hard   core   0" /etc/security/limits.conf || echo "*    hard   core   0" >> /etc/security/limits.conf

echo "[Phase 7] User and Group Security..."
groupadd suusers 2>/dev/null || true
usermod -aG suusers hammad 2>/dev/null || true
grep -q "pam_wheel.so group=suusers" /etc/pam.d/su || \
  sed -i 's/^# auth       required   pam_wheel.so$/auth       required   pam_wheel.so group=suusers/' /etc/pam.d/su

echo "[Phase 9] Network Hardening (UFW)..."
ufw allow 2222/tcp > /dev/null 2>&1 || true
ufw limit 2222/tcp > /dev/null 2>&1
ufw logging medium > /dev/null 2>&1
ufw --force enable > /dev/null 2>&1

echo "All phases applied successfully. See $LOG_FILE"
echo "[Phase 3] Software and Updates..."
apt install -y unattended-upgrades apt-listchanges auditd audispd-plugins aide aide-common fail2ban apparmor-utils apparmor-profiles apparmor-profiles-extra > /dev/null 2>&1
sed -i 's|"${distro_id}:${distro_codename}";|// "${distro_id}:${distro_codename}";|' /etc/apt/apt.conf.d/50unattended-upgrades 2>/dev/null || true
grep -q "Automatic-Reboot \"true\"" /etc/apt/apt.conf.d/50unattended-upgrades || \
  sed -i 's|//Unattended-Upgrade::Automatic-Reboot "false";|Unattended-Upgrade::Automatic-Reboot "true";|' /etc/apt/apt.conf.d/50unattended-upgrades
apt purge -y telnet > /dev/null 2>&1 || true
dpkg -l | grep "^rc" | awk '{print $2}' | xargs -r dpkg --purge > /dev/null 2>&1 || true

echo "[Phase 5] SSH Hardening..."
grep -q "^Port 2222" /etc/ssh/sshd_config || sed -i '1i Port 2222' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config.d/50-cloud-init.conf 2>/dev/null || true
grep -q "^Banner" /etc/ssh/sshd_config || echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
sshd -t && systemctl restart ssh

echo "[Phase 6] Password Policy..."
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   7/' /etc/login.defs
sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/' /etc/login.defs
grep -q "SHA_CRYPT_MIN_ROUNDS" /etc/login.defs || echo "SHA_CRYPT_MIN_ROUNDS 5000" >> /etc/login.defs
grep -q "SHA_CRYPT_MAX_ROUNDS" /etc/login.defs || echo "SHA_CRYPT_MAX_ROUNDS 100000" >> /etc/login.defs

echo "[Phase 8] Auditd Configuration..."
augenrules --load > /dev/null 2>&1 || true
systemctl restart auditd 2>/dev/null || true

echo "[Phase 10] File Integrity Monitoring (AIDE)..."
if [ ! -f /var/lib/aide/aide.db ]; then
  aideinit > /dev/null 2>&1
  cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
fi
(crontab -l 2>/dev/null | grep -q "aide --config" ) || \
  (crontab -l 2>/dev/null; echo "0 3 * * * /usr/bin/aide --config=/etc/aide/aide.conf --check >> /var/log/aide-check.log 2>&1") | crontab -

echo "[Phase 11] AppArmor..."
aa-enforce /etc/apparmor.d/* > /dev/null 2>&1 || true

echo "[Phase 13] Quick wins - fail2ban..."
systemctl enable fail2ban --now > /dev/null 2>&1
echo "$(date): Completed all phases (2,3,4,5,6,7,8,9,10,11,13)" >> "$LOG_FILE"

echo "[Phase 12] Login Banners and Warnings..."
cat > /etc/issue << 'BANNER'
Authorized Access Only. All activity is monitored.
BANNER
cp /etc/issue /etc/issue.net
cat > /etc/motd << 'MOTD'
Welcome to the SEIM-LAB Environment.
Keep your logs clean and unauthorized actions recorded.
All sessions are monitored via auditd.
MOTD
chmod 644 /etc/issue /etc/issue.net /etc/motd
chown root:root /etc/issue /etc/issue.net /etc/motd
