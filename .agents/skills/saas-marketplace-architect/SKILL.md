---
name: saas-marketplace-architect
description: Architect multi-tenant SaaS platforms, two-sided marketplaces, digital wallet & ledger systems, subscription billing, checkout funnels, payment gateway integrations, and comprehensive admin analytics dashboards.
---

# SaaS & Marketplace Architecture (saas-marketplace-architect)

Engineering blueprints for scalable SaaS, e-commerce, digital asset marketplaces, and transaction ledger architectures.

---

## 1. When to Use & Triggers
- Architecting SaaS platforms, subscription tiers, and multi-tenant data models.
- Building marketplace systems: catalog, vendor management, product listings, orders, reviews.
- Implementing digital wallet systems with immutable audit transaction ledgers.
- Integrating payment gateways (Stripe, local bank cards, crypto, manual bank receipts).
- Designing high-leverage Admin Dashboards for order fulfillment and financial reconciliation.

---

## 2. What TO Do (Core Principles)
- **Immutable Ledger System:** Every balance mutation must create a WalletTransaction row with before/after balances.
- **Atomic Checkout & Fulfillment:** Use database locks (select_for_update) during order checkout to prevent double-spending.
- **Order State Machine:** Enforce clean state transitions (pending -> in_progress -> completed / 
efunded).

---

## 3. What NOT To Do
- ❌ Do NOT update customer balances directly without an audit transaction record.
- ❌ Do NOT store raw card details in your database; always use gateway tokens.

---

## 4. Step-by-Step Workflow
1. **Data Model Design:** Create Tenant, Product, Order, Wallet, and Ledger models.
2. **Implement Ledger Engine:** Build atomic deposit, deduct, and refund services.
3. **Payment Gateway Webhooks:** Implement idempotent webhook handlers with signature verification.
4. **Build Admin Control Panel:** Create management dashboards for orders, disputes, and financial reconciliation.

---

## 5. Production Checklist
- [ ] Are wallet balance updates protected by database transaction locks?
- [ ] Are payment webhooks idempotent and signature-verified?
- [ ] Is automatic refund handling implemented for failed orders?
- [ ] Are administrative financial logs immutable?

---

## 6. Cross-Skill Integration & Handoffs
- ➔ Works with ackend-django-pro and rontend-nextjs-pro for full-stack implementation.
- ➔ Coordinates with security-hardening-owasp for transaction and anti-fraud safeguards.
