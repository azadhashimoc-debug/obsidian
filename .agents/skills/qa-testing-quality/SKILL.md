---
name: qa-testing-quality
description: Design comprehensive testing strategies, unit tests, integration tests, E2E testing (Playwright), debugging workflows, systematic code reviews, performance benchmarks, accessibility audits, and production readiness certification.
---

# Quality Assurance & Testing Excellence (qa-testing-quality)

Guidelines for building automated test suites, catching regressions before deploy, and enforcing rigorous code quality.

---

## 1. When to Use & Triggers
- Writing unit and integration tests (Pytest, Jest, React Testing Library).
- Designing End-to-End (E2E) automated browser tests with Playwright.
- Performing pre-release QA and production readiness audits.
- Investigating, reproducing, and fixing complex race conditions or edge cases.

---

## 2. What TO Do (Core Principles)
- **The Test Pyramid:** Write fast unit tests for business logic, integration tests for APIs, and targeted E2E tests for critical user journeys.
- **Test Isolation:** Never depend on shared state or external live APIs; use fixtures, factories, and mocks.
- **Bug Reproduction:** Always write a failing test reproducing the issue before writing the fix.

---

## 3. What NOT To Do
- ❌ Do NOT test implementation details; test observable behavior and outcomes.
- ❌ Do NOT skip tests or tolerate flaky test runs.

---

## 4. Step-by-Step Workflow
1. **Identify Critical Paths:** Map the revenue/auth paths (Sign up, Login, Checkout, Payment, Core Action).
2. **Write Unit Tests:** Cover domain service functions and edge cases.
3. **Write API Integration Tests:** Verify status codes, serializer validation, and permissions.
4. **Build E2E Smoke Tests:** Use Playwright for critical browser flows.
5. **Run Full Test Suite:** Verify 100% pass rate before production merge.

---

## 5. Production Checklist
- [ ] Do all unit and integration tests pass cleanly?
- [ ] Are critical user journeys covered by automated tests?
- [ ] Are edge cases (zero balance, invalid input, concurrent requests) tested?
- [ ] Is test coverage >= 80% on critical business logic?

---

## 6. Cross-Skill Integration & Handoffs
- ➔ Validates code built by ackend-django-pro and rontend-nextjs-pro.
- ➔ Reports bugs to clean-code-architect for surgical fixing.
