# CIS Ubuntu Linux 22.04 LTS Benchmark — Controls Implemented

| Control | Description | Phase | Status |
|---------|--------------|-------|--------|
| 1.1.1.x | Disable unused filesystem modules | 2 | Implemented |
| 1.1.2.x | Configure /tmp with noexec,nosuid,nodev | 2 | Implemented |
| 1.9     | Automatic security updates | 3 | Implemented |
| 5.2.x   | SSH hardening (root login, key auth) | 5 | Implemented |
| 5.3.1   | Password complexity | 6 | Implemented |
| 5.3.2   | Account lockout | 6 | In progress (see hardening-log.md) |
| 5.4.1.x | Password aging | 6 | Implemented |
| 6.1.x   | Sensitive file permissions (/etc/passwd, /etc/shadow, /etc/group, /etc/gshadow) | 7 | Verified compliant |
| 6.2.1   | No empty passwords | 7 | Verified compliant |
| 6.2.4   | Only root has UID 0 | 7 | Verified compliant |
| 5.6     | su restricted to suusers group via pam_wheel | 7 | Implemented |
| 4.1.x   | Auditd installed and enabled | 8 | Implemented |
| 4.1.2   | Audit rules — time changes | 8 | Implemented |
| 4.1.3   | Audit rules — user/group modifications | 8 | Implemented |
| 4.1.4   | Audit rules — network environment changes | 8 | Implemented |
| 4.1.5   | Audit rules — login/logout events | 8 | Implemented |
| 4.1.6   | Audit rules — session initiation | 8 | Implemented |
| 4.1.7   | Audit rules — permission modifications | 8 | Implemented |
| 4.1.8   | Audit rules — unauthorized file access | 8 | Implemented |
| 4.1.9   | Audit rules — privileged commands | 8 | Implemented |
| 4.1.10  | Audit rules — mounts | 8 | Implemented |
| 4.1.11  | Audit rules — file deletion | 8 | Implemented |
| 4.1.12  | Audit rules — sudoers changes | 8 | Implemented |
| 4.1.13  | Audit rules — kernel module loading | 8 | Implemented |
| 4.1.14  | Audit rules — SSH config changes | 8 | Implemented |
| 4.2.x   | Auditd log retention configured | 8 | Implemented |
