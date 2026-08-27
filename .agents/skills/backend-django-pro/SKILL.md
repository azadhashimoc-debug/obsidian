---
name: backend-django-pro
description: Build scalable, robust, and secure Python & Django 5+ backends, RESTful APIs, Celery task queues, Redis caching, PostgreSQL transaction management, concurrency locking, and secure authentication. Use for backend architecture, API development, database optimization, and background processing.
---

# Master Django 5+ & Python Backend Architecture (ackend-django-pro)

Expert guidelines for architecting production-grade Django backends, high-throughput REST APIs, asynchronous task processing with Celery/Redis, and PostgreSQL optimization.

---

## 1. When to Use & Triggers
- Designing Django models, database schemas, and migration strategies.
- Building RESTful APIs (Django REST Framework / Django Ninja).
- Handling async workflows, cron jobs, and background workers with Celery + Redis.
- Resolving database bottlenecks, N+1 queries, race conditions, and indexing.
- Implementing custom user authentication, JWT/session security, and role-based permissions.

---

## 2. What TO Do (Core Principles)
- **Concurrency Safety:** Use select_for_update() inside 	ransaction.atomic() when modifying balances or orders.
- **N+1 Elimination:** Always use select_related() for ForeignKey/OneToOne and prefetch_related() for ManyToMany.
- **Idempotent Background Tasks:** Pass only primitive IDs (e.g. order_id) to Celery tasks; implement retry with exponential backoff.
- **Thin Views, Fat Services:** Keep views focused on request/response; move business logic to domain service modules.

---

## 3. What NOT To Do
- ❌ Do NOT run synchronous external API requests inside HTTP request-response cycles; delegate to Celery.
- ❌ Do NOT modify balance/ledger rows without atomic transaction locks.
- ❌ Do NOT use SQLite in production; use PostgreSQL with connection pooling.
- ❌ Do NOT query databases inside loops.

---

## 4. Step-by-Step Workflow
1. **Model & Schema Design:** Define models with proper indexes, constraints, and relationships.
2. **Migrations:** Create and test migrations safely (python manage.py makemigrations && migrate).
3. **Service & Business Logic:** Implement atomic service functions with error handling.
4. **API Endpoints:** Build REST views/serializers with strict validation and permission classes.
5. **Background Tasks:** Define Celery tasks with idempotency keys and error alerts.

---

## 5. Production Checklist
- [ ] Are all database modifications wrapped in 	ransaction.atomic() where consistency is required?
- [ ] Are query counts inspected to ensure zero N+1 queries?
- [ ] Are Celery tasks idempotent with robust retry logging?
- [ ] Is rate limiting configured on auth and payment endpoints?
- [ ] Is python manage.py check --deploy passing clean?

---

## 6. Cross-Skill Integration & Handoffs
- ➔ Hand off to security-hardening-owasp for vulnerability and authorization audits.
- ➔ Hand off to devops-vps-deploy for Nginx, Gunicorn, and Systemd deployment.
- ➔ Hand off to qa-testing-quality for Pytest unit and integration test suites.
