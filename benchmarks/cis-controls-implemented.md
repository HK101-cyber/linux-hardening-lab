| Control | Description | Phase | Status |
| :--- | :--- | :---: | :--- |
| **1.1.1.x** | Disable unused filesystem modules | 2 | Implemented |
| **1.1.2.x** | Configure /tmp with noexec,nosuid,nodev | 2 | Implemented |
| **1.9** | Automatic security updates | 3 | Implemented |
| **5.2.x** | SSH hardening (root login, key auth) | 5 | Implemented |
| **5.3.1** | Password complexity | 6 | Implemented |
| **5.3.2** | Account lockout | 6 | In progress (see hardening-log.md) |
| **5.4.1.x** | Password aging | 6 | Implemented |
| **5.6** | su restricted to suusers group via pam_wheel | 7 | Implemented |
| **6.1.x** | Sensitive file permissions (/etc/passwd, /etc/shadow, /etc/group, /etc/gshadow) | 7 | Verified compliant |
| **6.2.1** | No empty passwords | 7 | Verified compliant |
| **6.2.4** | Only root has UID 0 | 7 | Verified compliant |
| **4.1.x** | Auditd installed and enabled | 8 | Implemented |
| **4.1.2** | Audit rules — time changes | 8 | Implemented |
| **4.1.3** | Audit rules — user/group modifications | 8 | Implemented |
| **4.1.4** | Audit rules — network environment changes | 8 | Implemented |
| **4.1.5** | Audit rules — login/logout events | 8 | Implemented |
| **4.1.6** | Audit rules — session initiation | 8 | Implemented |
| **4.1.7** | Audit rules — permission modifications | 8 | Implemented |
| **4.1.8** | Audit rules — unauthorized file access | 8 | Implemented |
| **4.1.9** | Audit rules — privileged commands | 8 | Implemented |
| **4.1.10** | Audit rules — mounts | 8 | Implemented |
| **4.1.11** | Audit rules — file deletion | 8 | Implemented |
| **4.1.12** | Audit rules — sudoers changes | 8 | Implemented |
| **4.1.13** | Audit rules — kernel module loading | 8 | Implemented |
| **4.1.14** | Audit rules — SSH config changes | 8 | Implemented |
| **4.2.x** | Auditd log retention configured | 8 | Implemented |
| **3.1.1** | IP forwarding disabled | 9 | Implemented |
| **3.1.2** | Send redirects disabled | 9 | Implemented |
| **3.2.1** | Source routed packets rejected | 9 | Implemented |
| **3.2.2** | ICMP redirects rejected | 9 | Implemented |
| **3.2.3** | Secure ICMP redirects rejected | 9 | Implemented |
| **3.2.4** | Suspicious packets logged (log_martians) | 9 | Implemented |
| **3.2.5** | Broadcast ICMP ignored | 9 | Implemented |
| **3.2.6** | Bogus ICMP responses ignored | 9 | Implemented |
| **3.2.7** | TCP SYN cookies enabled | 9 | Implemented |
| **3.5.x** | UFW firewall configured — default deny incoming | 9 | Implemented |
| **3.5.x** | SSH rate-limited (LIMIT rule) | 9 | Implemented |
| **3.5.x** | Elasticsearch restricted to localhost | 9 | Implemented |
| **1.4.1** | AIDE installed | 10 | Implemented |
| **1.4.2** | Filesystem baseline database initialized (353,113 entries) | 10 | Implemented |
| **1.4.3** | Daily AIDE integrity check scheduled via cron (3 AM) | 10 | Implemented |
| **1.6.1.1** | AppArmor installed and enabled in bootloader | 11 | Implemented |
| **1.6.1.2** | All AppArmor profiles set to enforce mode | 11 | Implemented |
| 1.7.1.1 | Local login warning banner configured (/etc/issue) | 12 | Implemented |
| 1.7.1.2 | Remote login warning banner configured (/etc/issue.net) | 12 | Implemented |
| 1.7.1.4 | File permissions and ownership set on login banners | 12 | Implemented |
| 5.2.14  | SSH Banner configured to display /etc/issue.net | 12 | Implemented |
| 1.6.x   | AppArmor enabled, expanded to 65 profiles, all in enforce mode | 11 | Implemented |
| 1.7.x   | Login warning banner (/etc/issue, /etc/issue.net) | 12 | Implemented |
| 1.7.x   | SSH pre-auth banner configured | 12 | Implemented |
| 1.7.x   | MOTD configured, no OS version leakage | 12 | Implemented |
