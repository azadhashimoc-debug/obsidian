---
name: security-hardening-owasp
description: Implement enterprise-grade web and API security, OWASP Top 10 defenses, Content Security Policy (CSP), anti-fraud, rate limiting, secure authentication, secrets management, CORS, and vulnerability auditing. Use for security reviews, auth hardening, and production deployment safety.
---

# Web Security & OWASP Hardening (security-hardening-owasp)

Guidelines for securing modern web applications, APIs, and databases against attacks, data leaks, and abuse.

---

## 1. When to Use & Triggers
- Auditing authentication, authorization, password reset, and session workflows.
- Configuring security headers: CSP, HSTS, X-Frame-Options, X-Content-Type-Options.
- Implementing API rate limiting, IP throttling, and anti-scraping / anti-DDoS defenses.
- Securing database access, avoiding SQL injection, and managing private media/receipts.
- Performing pre-production vulnerability and security checklists.

---

## 2. What TO Do (Core Principles)
- **Parameterized Queries:** Rely 100% on ORM parameterized queries to eliminate SQL injection.
- **Secure Cookie Flags:** Always set cookies to HttpOnly, Secure, and SameSite=Lax (or Strict).
- **Strict Content Security Policy (CSP):** Disallow unsafe-inline where possible; restrict script sources.
- **Private Media Isolation:** Keep sensitive receipts/invoices outside public web roots; serve via auth views.

---

## 3. What NOT To Do
- ❌ NEVER commit .env, secrets, or API tokens to git repositories.
- ❌ Do NOT run production with DEBUG=True.
- ❌ Do NOT rely on client-side authentication checks alone without server-side validation.
- ❌ Do NOT use $proxy_add_x_forwarded_for for rate limiting behind reverse proxies; use trusted IP headers.

---

## 4. Step-by-Step Workflow
1. **Threat Modeling:** Identify sensitive assets (auth tokens, payment ledgers, user PII).
2. **Enforce Auth & RBAC:** Validate object-level permissions on every endpoint.
3. **Configure Headers:** Apply HSTS, CSP, X-Frame-Options, and CORS allowlists.
4. **Implement Throttling:** Add rate limiting to /login, /register, /checkout, and /api/*.
5. **Run Security Audit:** Scan with automated tools and verify manage.py check --deploy.

---

## 5. Production Checklist
- [ ] Is DEBUG=False confirmed in production settings?
- [ ] Are all secrets loaded via environment variables?
- [ ] Are cookies set with HttpOnly, Secure, and SameSite?
- [ ] Are login and API endpoints rate-limited against brute force?
- [ ] Are private media files protected by authorization checks?

---

## 6. Cross-Skill Integration & Handoffs
- ➔ Audits code written by ackend-django-pro and rontend-nextjs-pro.
- ➔ Coordinates with devops-vps-deploy for Nginx firewall, SSL, and UFW settings.
