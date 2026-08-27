---
name: devops-vps-deploy
description: Master Linux VPS configuration, Ubuntu server hardening, Nginx reverse proxy, Gunicorn/Uvicorn, Systemd service management, Certbot SSL, Docker containerization, CI/CD pipelines, and automated database backup & disaster recovery drills.
---

# Production DevOps & Linux VPS Deployment (devops-vps-deploy)

Complete runbook for deploying, monitoring, and maintaining production applications on Linux VPS, cloud providers, and containerized stacks.

---

## 1. When to Use & Triggers
- Provisioning and hardening Ubuntu/Debian Linux VPS servers.
- Configuring Nginx reverse proxy blocks, SSL/TLS certificates, and gzip/brotli compression.
- Setting up Systemd service units for web workers (Gunicorn) and background queues (Celery).
- Designing Dockerfiles, docker-compose environments, and CI/CD pipelines.
- Setting up automated PostgreSQL backups and running restore drills.

---

## 2. What TO Do (Core Principles)
- **SSH Hardening:** Enforce key-based authentication (PasswordAuthentication no) and disable root login.
- **UFW Firewall:** Open only ports 22 (SSH), 80 (HTTP), 443 (HTTPS).
- **Systemd Management:** Run Gunicorn and Celery as non-root services with Restart=always.
- **Automated Backups:** Daily compressed pg_dump rotated with retention policies and tested via restore drills.

---

## 3. What NOT To Do
- ❌ Do NOT run web services or background workers as the 
oot user.
- ❌ Do NOT store database backups solely on the primary server disk.
- ❌ Do NOT forget collectstatic --noinput and migrate before restarting app services.

---

## 4. Step-by-Step Workflow
1. **Server Provisioning:** Update packages, create sudo user, configure SSH keys and UFW firewall.
2. **Database Setup:** Install and secure PostgreSQL with strong passwords and connection pooling.
3. **App Deployment:** Clone repository, setup virtualenv, install dependencies, run migrations.
4. **Services Configuration:** Create Systemd .service files for Gunicorn and Celery.
5. **Nginx & SSL:** Configure Nginx server block, proxy pass to Unix socket, and run Certbot.

---

## 5. Production Checklist
- [ ] Is SSH password login disabled and root login forbidden?
- [ ] Is UFW firewall enabled with only necessary ports open?
- [ ] Are Systemd services running and configured to restart on failure?
- [ ] Is SSL auto-renewal tested (certbot renew --dry-run)?
- [ ] Is automated daily database backup configured and verified?

---

## 6. Cross-Skill Integration & Handoffs
- ➔ Deploys application code from ackend-django-pro and rontend-nextjs-pro.
- ➔ Applies firewall and SSL standards from security-hardening-owasp.
