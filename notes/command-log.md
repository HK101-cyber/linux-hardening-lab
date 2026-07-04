# Linux Hardening Lab — Command Log & Study Notes
Personal reference log — one entry per command, with WHY explained.

---

## PHASE 1 — Baseline Assessment
**Date:** 2026-07-03

### Install Lynis (official repo, not apt default — more current version)
sudo apt install -y curl gnupg apt-transport-https
curl -fsSL https://packages.cisofy.com/keys/cisofy-software-public.key | sudo gpg --dearmor -o /usr/share/keyrings/cisofy-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/cisofy-archive-keyring.gpg] https://packages.cisofy.com/community/lynis/deb/ stable main" | sudo tee /etc/apt/sources.list.d/cisofy-lynis.list
sudo apt update && sudo apt install -y lynis

### Run baseline audit (--cronjob = non-interactive, reliable for scripting/logging)
sudo lynis audit system --cronjob | tee ~/linux-hardening-lab/lynis-reports/before-hardening.txt

### Pull real logs (lynis writes via terminal control codes, tee alone misses content)
sudo cp /var/log/lynis.log ~/linux-hardening-lab/lynis-reports/before-hardening.txt
sudo cp /var/log/lynis-report.dat ~/linux-hardening-lab/lynis-reports/before-hardening-report.dat

### Get the score directly
grep "hardening_index" ~/linux-hardening-lab/lynis-reports/before-hardening-report.dat

**RESULT: Baseline Hardening Index = 57**

**Lesson learned:** `tee` doesn't reliably capture lynis's screen output because 
lynis uses terminal control codes for formatting. Always pull from 
/var/log/lynis.log and /var/log/lynis-report.dat instead.

---

## PHASE 2 — Filesystem Hardening
**Date:** 2026-07-03

### Backup fstab before editing (always do this before touching system configs)
sudo cp /etc/fstab /etc/fstab.bak-$(date +%F)

### Harden /tmp — block execution from world-writable temp dir
echo "tmpfs /tmp tmpfs defaults,noexec,nosuid,nodev 0 0" | sudo tee -a /etc/fstab
sudo mount /tmp

### Verify noexec actually blocks execution (don't just trust config — test it)
echo '#!/bin/bash
echo "if you see this, noexec failed"' > /tmp/test.sh
chmod +x /tmp/test.sh
/tmp/test.sh
# Result: Permission denied — confirmed working

### Check sticky bit on world-writable dirs (CIS 1.1.2.4)
sudo find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null
# Result: empty output = already compliant, no fix needed

### Blacklist unused filesystem kernel modules (CIS 1.1.1.x)
# IMPORTANT: checked `snap list` first — squashfs is required by snapd/lxd/core20, excluded it
sudo tee /etc/modprobe.d/hardening-blacklist.conf << 'CONF'
install cramfs /bin/false
install freevxfs /bin/false
install jffs2 /bin/false
install hfs /bin/false
install hfsplus /bin/false
install udf /bin/false
CONF

### Test the blacklist works
sudo modprobe cramfs
# Result: ERROR / Invalid argument = blocked successfully (this is the GOOD outcome)

### Harden /proc — hide other users' process info (CIS 1.1.6)
echo "proc /proc proc defaults,hidepid=2 0 0" | sudo tee -a /etc/fstab
sudo mount -o remount /proc

### Verify hidepid works without breaking services
ps aux | grep logstash          # as normal user — should NOT show logstash
sudo ps aux | wc -l              # as root — shows full process count
sudo systemctl status logstash kibana elasticsearch --no-pager
# Result: hammad sees only 5 procs (own session), root sees 123. Services unaffected.

**Lesson learned:** Always check for dependencies (like snap→squashfs) before 
blindly applying CIS checklist items. Document exceptions with reasoning.

---

## PHASE 3 — Software and Updates
Date: 2026-07-04

Install unattended-upgrades:
sudo apt install -y unattended-upgrades apt-listchanges

Configured /etc/apt/apt.conf.d/50unattended-upgrades:
- Disabled general repo, kept only -security origins
- Automatic-Reboot "true"
- Automatic-Reboot-Time "03:00"

Enabled daily scheduler in /etc/apt/apt.conf.d/20auto-upgrades

Test dry run:
sudo unattended-upgrade --dry-run --debug
Result: only security packages queued, ELK packages correctly excluded

Checked and removed unnecessary packages:
dpkg -l | grep telnet
sudo apt purge -y telnet
Result: removed successfully

Checked for other legacy services (all clean, none installed):
dpkg -l | grep xinetd
dpkg -l | grep avahi-daemon
dpkg -l | grep cups
dpkg -l | grep rpcbind

Checked live listening ports:
sudo ss -tulnp
Result: SSH, DNS, DHCP normal. Splunk (8000, 8089, 9997) and ELK 
confirmed intentional - will allow through firewall in Phase 9.

Verified GPG package signing still enforced:
grep -r "AllowUnauthenticated" /etc/apt/apt.conf.d/
Result: empty = secure default active

Lesson learned: dpkg -l | grep can give false positives from library 
names (e.g. "avahi" matches libavahi-client3, which isn't the actual 
service). Always double check with the -daemon or actual service name.
