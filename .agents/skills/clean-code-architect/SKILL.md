---
name: clean-code-architect
description: Enforce clean code standards, surgical refactoring, architectural simplicity, technical debt elimination, Architecture Decision Records (ADR), and structured git workflows. Derived from Karpathy guidelines and senior engineering best practices.
---

# Clean Code & Architectural Simplicity (clean-code-architect)

Guidelines to prevent overengineering, maintain pristine codebases, execute surgical edits, and maintain living architectural documentation.

---

## 1. When to Use & Triggers
- Writing, refactoring, or reviewing code across any language or framework.
- Evaluating architectural decisions and creating Architecture Decision Records (ADR).
- Cleaning up dead code, legacy debt, or excessive abstractions.
- Enforcing structured Git commits and repository hygiene.

---

## 2. What TO Do (Core Principles)
- **Think Before Coding:** State assumptions explicitly. If uncertain, ask.
- **Simplicity First:** Write the minimum code that solves the problem. No premature abstractions for single-use code.
- **Surgical Edits:** Touch only what is strictly necessary. Match existing codebase style.
- **Living Documentation:** Document key architectural tradeoffs in Decisions.md.

---

## 3. What NOT To Do
- ❌ Do NOT add speculative 'flexibility' or unrequested configuration layers.
- ❌ Do NOT rewrite working adjacent code during a bug fix.
- ❌ Do NOT leave unused imports, dead variables, or orphaned functions.

---

## 4. Step-by-Step Workflow
1. **Understand & Reproduce:** Read surrounding code and understand existing conventions before editing.
2. **Plan Minimal Intervention:** Determine the smallest possible change that achieves the goal.
3. **Execute Surgically:** Make the edit without altering unrelated formatting or comments.
4. **Clean & Verify:** Remove newly orphaned imports and verify that all tests pass.

---

## 5. Production Checklist
- [ ] Can every changed line be traced directly to the user request?
- [ ] Are there zero unneeded abstractions or overcomplicated patterns?
- [ ] Are unused imports and variables cleaned up?
- [ ] Are architectural decisions documented in Decisions.md?

---

## 6. Cross-Skill Integration & Handoffs
- ➔ Applies globally across all code written by ackend-django-pro, rontend-nextjs-pro, and unity-developer.
