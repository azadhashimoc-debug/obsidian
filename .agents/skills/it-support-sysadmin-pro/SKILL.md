---
name: it-support-sysadmin-pro
description: Expert practical IT support, desktop troubleshooting, Windows & Linux OS administration, hardware repair, local LAN/Wi-Fi networking, router/switch setup, printer/scanner troubleshooting, Active Directory user management, CCTV, and office IT maintenance.
---

# Practical IT Support & Systems Administration (it-support-sysadmin-pro)

Comprehensive guide for enterprise help desk, hardware diagnostics, network troubleshooting, and office IT infrastructure management.

---

## 1. When to Use & Triggers
- Troubleshooting desktop & laptop hardware, assembly, component upgrades (RAM, SSD).
- Installing and optimizing Windows 10/11 and Linux distributions with clean drivers.
- Resolving local network issues: IP conflicts, DHCP/DNS, Wi-Fi coverage, router & switch VLANs.
- Troubleshooting network printers, scanners, print spoolers, and paper jams.
- Managing user accounts, permissions, and group policies in Active Directory / Windows Server.
- Setting up CCTV security cameras, NVRs, uninterruptible power supplies (UPS), and automated backups.

---

## 2. What TO Do (Core Principles)
- **Bottom-Up Diagnostic Approach:** Check Physical Layer (cables, LEDs, power) before investigating Software/OS layers.
- **Data Safety First:** Always take verified backups before formatting machines or modifying partition tables.
- **Static IP & DHCP Reservation:** Assign static IPs to network printers, NAS storage, and servers.

---

## 3. What NOT To Do
- ❌ Do NOT format user workstations without a verified backup of bookmarks, files, and credentials.
- ❌ Do NOT leave default admin credentials on network routers, switches, or CCTV cameras.

---

## 4. Step-by-Step Workflow
1. **Identify Problem & Symptoms:** Interview user and observe error codes/behavior.
2. **Isolate Component:** Determine whether issue is Hardware, OS, Network, or Application.
3. **Apply Targeted Fix:** Resolve root cause (restart spooler, crimp cable, replace RAM module).
4. **Verify & Document:** Test with user to confirm resolution and document in IT ticket log.

---

## 5. Production Checklist
- [ ] Is user data backed up before system reinstallation?
- [ ] Are network IP conflicts resolved with DHCP reservations?
- [ ] Are default admin passwords changed on all network devices?
- [ ] Are printer driver and network sharing permissions verified?

---

## 6. Cross-Skill Integration & Handoffs
- ➔ Coordinates with security-hardening-owasp for office network security.
- ➔ Works with devops-vps-deploy for local server and Linux maintenance.
