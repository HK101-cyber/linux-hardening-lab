# Hardening Log — Linux Hardening Lab

Chronological log of every phase, including real incidents encountered.
Full command-by-command detail lives in notes/command-log.md — this file 
is the higher-level summary version.

## Phase 1 — Baseline Assessment (July 2, 2026)
Installed Lynis from the official CISOfy repository. Ran the first full 
system audit. Baseline Hardening Index recorded: 57/100.

## Phase 2 — Filesystem Hardening (July 3, 2026)
Hardened /tmp (noexec,nosuid,nodev), verified sticky bit compliance, 
disabled unused filesystem kernel modules (with a documented squashfs 
exception for snap dependency), and restricted /proc visibility with hidepid=2.

## Phase 3 — Software and Updates (July 4, 2026)
Configured unattended-upgrades restricted to security-only repositories, 
with scheduled automatic reboot. Removed telnet. Verified GPG package 
signing is still enforced.

## Phase 4 — Process Hardening (July 4, 2026)
Verified ASLR is active. Disabled core dumps system-wide and for SUID 
binaries. Applied kernel hardening sysctl parameters (kptr_restrict, 
dmesg_restrict, protected_symlinks/hardlinks).

## Phase 5 — SSH Hardening (July 4, 2026)
Generated SSH key pair, verified key login before disabling passwords. 
Disabled root login, changed SSH port to 2222, disabled password 
authentication, configured UFW for the new port.

**Incident:** cloud-init's auto-generated /etc/ssh/sshd_config.d/50-cloud-init.conf 
silently re-enabled password authentication, overriding the main config 
due to Include-file load order. Diagnosed using `sshd -T` (effective 
running config) rather than trusting the raw config file. Fixed at the 
source file and reverified.

## Phase 6 — Password Policy (July 5, 2026)
Configured password aging (90/7/14 days), password complexity via 
pam_pwquality (12 char minimum, mixed case/digit/symbol), and account 
lockout via pam_faillock (5 attempts / 15 min).

**Incident 1:** pwquality.conf edits initially appeared not to apply — 
caused by a leading space left behind after removing comment markers, 
which broke a strict `^`-anchored grep check used to verify the config.

**Incident 2:** root bypasses pwquality enforcement when changing another 
user's password via `sudo passwd` — shows a warning but still allows a 
weak password through. Root cause: `enforce_for_root` is disabled by 
default. Documented as a known, accepted gap for now.

**Incident 3 (major):** the pam_faillock lines added to 
/etc/pam.d/common-auth broke su/sudo authentication entirely, independent 
of password correctness. This was discovered while deliberately testing 
lockout behavior, and was compounded by repeated failed sudo attempts 
made while diagnosing it, which also triggered the account's own lockout 
counter. Recovered via GRUB recovery mode (root shell, password reset, 
faillock counter reset). Root cause of the PAM issue was isolated using 
comparative behavior between `passwd` and `su` (different PAM service 
files), and resolved by removing the faulty pam_faillock lines entirely.

Lockout is being reconfigured and will be re-tested more incrementally 
next session, verifying each PAM line individually before testing lockout 
behavior again.

## Phase 7 — User and Group Security (July 6, 2026)
Audited all shell accounts — only root, hammad, and splunk have real 
shells. Splunk account confirmed locked (passwd -S shows L status).
No empty passwords found. Only root has UID 0 — no backdoor accounts.
Sudo group contains only hammad. No NOPASSWD entries in sudoers.
sudoers.d/ contains only a README — no software has granted itself sudo.
su command restricted to suusers group via pam_wheel in /etc/pam.d/su.
Sensitive file permissions verified compliant (/etc/shadow and /etc/gshadow 
are root:shadow 640 — not world-readable).
World-writable file audit found 26 files, all within 
/opt/splunk/etc/apps/splunk_gdi/ — a known Splunk app behavior, 
documented as accepted exception tied to co-located Splunk installation.

## Phase 8 — Auditd Configuration (July 6, 2026)
Installed auditd and audispd-plugins. Created comprehensive audit rules
file at /etc/audit/rules.d/hardening.rules covering: time changes,
user/group modifications, network environment changes, login/logout
events, session initiation, DAC permission changes, unauthorized file
access attempts, privileged commands (sudo/su/passwd), filesystem mounts,
file deletion, sudoers changes, kernel module loading, and SSH config
changes. Rules loaded with immutable flag (-e 2) — cannot be modified
without a reboot. Verified with ausearch showing a real captured
privileged event (sudo whoami) with full forensic detail (who, what,
when, from where, success/fail). Log retention configured: 50MB per
file, 10 files retained (500MB total).
## Phase 9 — Network Hardening (July 6, 2026)
UFW already active with default deny incoming policy. Existing rules
audited — all ports confirmed justified (SSH 2222, ELK 9200/5601/5044/8220,
Splunk 8000/9997). Three improvements made:
1. SSH port 2222 upgraded from ALLOW to LIMIT (rate-limiting for
   brute-force protection — blocks IPs after 6 attempts in 30 seconds)
2. Elasticsearch port 9200 restricted from Anywhere to localhost only
   (unauthenticated API exposure risk eliminated)
3. UFW logging upgraded from low to medium (logs both allowed and denied)

Network sysctl hardening applied to /etc/sysctl.d/99-hardening.conf:
ip_forward=0, send_redirects=0, accept_redirects=0, accept_source_route=0,
log_martians=1, icmp_echo_ignore_broadcasts=1, tcp_syncookies=1.

INCIDENT: log_martians refused to stay at 1 despite being correctly set
in 99-hardening.conf. Root cause: a network service reinitializes
interface settings after sysctl.d files load during boot, resetting it
back to 0. Fix: also added log_martians=1 to /etc/sysctl.conf which
loads later in the boot sequence, ensuring the setting persists.
## Phase 10 — File Integrity Monitoring / AIDE (July 8, 2026)
Installed AIDE. Initialized baseline database scanning 353,113 filesystem
entries using multiple hash algorithms (SHA256, SHA512, etc.). Database
took 52 minutes to initialize — full system scan. Activated database by
copying aide.db.new to aide.db. Ran first integrity check — found 8 added,
2 removed, 5 changed entries. All changes verified as expected normal
system behavior: running services writing logs (auditd, logstash, ufw),
systemd runtime directories, and the AIDE database file itself. Zero
suspicious changes. Scheduled daily automated check via root crontab at
3 AM, logging to /var/log/aide-check.log.
## Phase 11 — AppArmor Confinement (July 9, 2026)
Verified AppArmor default installation status (40 profiles enforced). Installed `apparmor-profiles` and `apparmor-profiles-extra` to expand coverage to 65 profiles. Installed `apparmor-utils` to resolve missing enforcement binaries. Enforced all 65 system profiles using `aa-enforce`, eliminating all weak 'complain' mode configurations. This ensures strict Mandatory Access Control (MAC) across core network and system utilities, mitigating potential privilege escalation vectors (MITRE T1068).
