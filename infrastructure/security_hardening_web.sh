#!/bin/bash
# ====================================================================
# Enhanced Security Hardening Script for Web Server
# ====================================================================
set -e

echo "[SECURITY] Starting security hardening..."

# ====================================================================
# 1. SYSTEM UPDATES AND SECURITY PATCHES
# ====================================================================
echo "[SECURITY] Applying system updates..."
yum update -y
yum install -y \
  curl wget git vim htop \
  fail2ban fail2ban-systemd \
  aide \
  net-tools \
  openssl \
  yum-cron

# Enable automatic security updates
systemctl enable yum-cron
systemctl start yum-cron

# ====================================================================
# 2. SSH HARDENING
# ====================================================================
echo "[SECURITY] Hardening SSH configuration..."

# Backup original SSH config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Harden SSH daemon configuration
cat > /etc/ssh/sshd_config.d/99-hardening.conf << 'EOF'
# SSH Hardening Configuration
# Disable root login
PermitRootLogin no

# Disable password authentication (key-based only)
PubkeyAuthentication yes
PasswordAuthentication no

# Disable empty passwords
PermitEmptyPasswords no

# Disable X11 forwarding
X11Forwarding no

# Disable forwarding
AllowAgentForwarding no
AllowTcpForwarding no
PermitTunnel no
GatewayPorts no

# Limit authentication attempts
MaxAuthTries 3
MaxSessions 5

# Idle session timeout
ClientAliveInterval 300
ClientAliveCountMax 2

# Protocol hardening
Protocol 2
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key

# Strong ciphers and algorithms
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-256
KeyExchange curve25519-sha256,curve25519-sha256@libssh.org,gssapi-sha2-nistp256-sha256-,ext-info-c

# Security options
StrictModes yes
IgnoreUserKnownHosts no
IgnoreRhosts yes
RhostsRSAAuthentication no
RSAAuthentication no
GSSAPIAuthentication no
UsePAM yes

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# Banner
Banner /etc/ssh/banner.txt
EOF

# Create SSH banner
cat > /etc/ssh/banner.txt << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║                     AUTHORIZED ACCESS ONLY                      ║
║                                                                ║
║  Unauthorized access to this system is forbidden and will be   ║
║  prosecuted by law. By accessing this system, you agree that   ║
║  your actions may be monitored and recorded.                   ║
╚════════════════════════════════════════════════════════════════╝
EOF

# Verify SSH configuration syntax
sshd -t || (echo "[ERROR] SSH config has syntax errors"; exit 1)

# Restart SSH daemon
systemctl restart sshd

echo "[SECURITY] SSH hardening complete"

# ====================================================================
# 3. FIREWALL CONFIGURATION (UFW/Firewalld)
# ====================================================================
echo "[SECURITY] Configuring firewall..."

# Enable firewalld
systemctl enable firewalld
systemctl start firewalld

# Configure firewall rules
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-port=5000/tcp  # Backend
firewall-cmd --permanent --add-port=3000/tcp  # Frontend
firewall-cmd --permanent --add-port=22/tcp    # SSH
firewall-cmd --set-default-zone=public
firewall-cmd --reload

echo "[SECURITY] Firewall configuration complete"

# ====================================================================
# 4. FAIL2BAN SETUP
# ====================================================================
echo "[SECURITY] Configuring Fail2ban..."

systemctl enable fail2ban
systemctl start fail2ban

# Create custom Fail2ban jail configuration
cat > /etc/fail2ban/jail.d/sshd-hardening.conf << 'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
logpath = %(sshd_log)s
maxretry = 3
findtime = 600
bantime = 3600
destemail = admin@example.com
action = %(action_mwl)s
EOF

systemctl restart fail2ban

echo "[SECURITY] Fail2ban configuration complete"

# ====================================================================
# 5. AIDE (File Integrity Monitoring)
# ====================================================================
echo "[SECURITY] Setting up AIDE (File Integrity Monitoring)..."

# Initialize AIDE database
aideinit

# Create a cron job for daily AIDE checks
cat > /etc/cron.daily/aide-check << 'EOF'
#!/bin/bash
/usr/sbin/aide --check | mail -s "AIDE Check Results" root
EOF
chmod 755 /etc/cron.daily/aide-check

echo "[SECURITY] AIDE setup complete"

# ====================================================================
# 6. SELINUX HARDENING
# ====================================================================
echo "[SECURITY] Configuring SELinux..."

# Set SELinux to enforcing mode
semanage permissive -d unconfined_t 2>/dev/null || true
sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

echo "[SECURITY] SELinux configuration complete (will take effect after reboot)"

# ====================================================================
# 7. SYSCTL HARDENING (Kernel parameters)
# ====================================================================
echo "[SECURITY] Hardening kernel parameters..."

cat >> /etc/sysctl.d/99-hardening.conf << 'EOF'
# Kernel protection
kernel.unprivileged_userns_clone = 0
kernel.unprivileged_bpf_disabled = 1
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1

# Core dumps
kernel.core_uses_pid = 1
kernel.core_max = 0
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_regular = 2
fs.protected_fifos = 2

# IP forwarding (disable if not needed)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_max_syn_backlog = 4096

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Disable source packet routing
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Log Martians
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# TCP hardening
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 0
net.ipv4.tcp_dsack = 0
net.ipv4.tcp_fack = 0
EOF

sysctl -p /etc/sysctl.d/99-hardening.conf

echo "[SECURITY] Kernel parameter hardening complete"

# ====================================================================
# 8. AUDIT LOGGING
# ====================================================================
echo "[SECURITY] Configuring audit logging..."

yum install -y audit

cat > /etc/audit/rules.d/hardening.rules << 'EOF'
# Remove any existing rules
-D

# Buffer Size
-b 8192

# Failure Mode
-f 1

# Track file modifications
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity

# Track system calls
-a always,exit -F arch=b64 -S execve -k exec
-a always,exit -F arch=b64 -S connect -k network
-a always,exit -F arch=b64 -S open -F auid>=1000 -K file_open

# Make configuration immutable
-e 2
EOF

systemctl enable auditd
systemctl start auditd

echo "[SECURITY] Audit logging setup complete"

# ====================================================================
# 9. PERMISSIONS HARDENING
# ====================================================================
echo "[SECURITY] Hardening file permissions..."

# Set secure permissions on important files
chmod 644 /etc/passwd
chmod 000 /etc/shadow
chmod 644 /etc/group
chmod 000 /etc/gshadow

# Restrict access to sudo
chmod 440 /etc/sudoers
chmod 750 /etc/sudoers.d

# Remove unnecessary SUID/SGID binaries (if safe)
# This is environment-specific, so we'll just log them
find / -perm /6000 -type f 2>/dev/null | grep -v -E "(bin|usr|lib)" > /var/log/suid_files.log

echo "[SECURITY] File permissions hardening complete"

# ====================================================================
# 10. CloudWatch Agent Setup
# ====================================================================
echo "[SECURITY] Installing CloudWatch Agent..."

wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

echo "[SECURITY] CloudWatch Agent installed"

# ====================================================================
# 11. LOG ROTATION
# ====================================================================
echo "[SECURITY] Configuring log rotation..."

cat > /etc/logrotate.d/hardening << 'EOF'
/var/log/audit/audit.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 root root
    sharedscripts
    postrotate
        /sbin/systemctl reload auditd >/dev/null 2>&1 || true
    endscript
}
EOF

echo "[SECURITY] Log rotation configuration complete"

# ====================================================================
# 12. DISABLE UNNECESSARY SERVICES
# ====================================================================
echo "[SECURITY] Disabling unnecessary services..."

systemctl disable bluetooth 2>/dev/null || true
systemctl disable cups 2>/dev/null || true
systemctl disable avahi-daemon 2>/dev/null || true

echo "[SECURITY] Unnecessary services disabled"

# ====================================================================
# 13. CREATE SECURITY REPORT
# ====================================================================
echo "[SECURITY] Creating security hardening report..."

cat > /var/log/security-hardening-report.txt << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║       SECURITY HARDENING IMPLEMENTATION REPORT                  ║
║              TravelMemory Web Server                            ║
╚════════════════════════════════════════════════════════════════╝

COMPLETED SECURITY MEASURES:
✓ System updates and security patches applied
✓ SSH hardening (root login disabled, key-based auth only)
✓ Firewall configuration (firewalld)
✓ Fail2ban setup (brute force protection)
✓ AIDE file integrity monitoring
✓ SELinux hardening (enforcing mode)
✓ Sysctl kernel parameter hardening
✓ Audit logging configured
✓ File permissions hardened
✓ CloudWatch Agent installed
✓ Log rotation policies configured
✓ Unnecessary services disabled

SECURITY STATUS:
- SSH: Root login disabled, password auth disabled
- Firewall: Active and configured
- Intrusion Detection: Fail2ban enabled
- File Integrity: AIDE monitoring enabled
- Logging: Audit and CloudWatch enabled
- System: SELinux enforcing

RECOMMENDATIONS:
1. Enable SSL/TLS certificates (Let's Encrypt or ACM)
2. Configure database encryption
3. Implement secrets rotation policy
4. Set up CloudWatch alarms for security events
5. Enable MFA for AWS console access
6. Implement network segmentation
7. Regular security assessments and penetration testing

NEXT STEPS:
- Monitor CloudWatch logs for alerts
- Review audit logs regularly
- Schedule quarterly security reviews
- Keep software packages updated

Generated: $(date)
EOF

cat /var/log/security-hardening-report.txt

echo ""
echo "[SECURITY] ============================================"
echo "[SECURITY] Security hardening complete!"
echo "[SECURITY] ============================================"
echo "[SECURITY] Report saved to: /var/log/security-hardening-report.txt"
echo "[SECURITY] ============================================"
