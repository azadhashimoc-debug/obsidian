---
name: ui-ux-pro-max
description: AI-powered design intelligence toolkit providing searchable databases of UI styles, color palettes, font pairings, chart types, and UX guidelines. Use when creating modern, accessible, beautiful web & mobile interfaces, landing pages, and dashboard designs.
---

# UI/UX Pro Max & Modern Design Systems (ui-ux-pro-max)

Comprehensive design intelligence for creating modern, responsive, aesthetic, and accessible user interfaces.

---

## 1. When to Use & Triggers
- Designing new user interfaces, landing pages, dashboards, and mobile components.
- Selecting color palettes, contrast ratios, and dark/glassmorphism design themes.
- Establishing typography hierarchy, font pairings, and responsive spacing tokens.
- Auditing UX flows, button placements, micro-interactions, and WCAG accessibility.

---

## 2. What TO Do (Core Principles)
- **Visual Hierarchy:** Emphasize the primary action (CTA) with high-contrast accent colors and larger weights.
- **Mobile-First Responsiveness:** Design for 375px screens first; ensure tap targets are at least 44x44px.
- **Dark & Glassmorphism Aesthetics:** Use subtle translucent backgrounds, thin borders (order-white/10), and deep ambient glow gradients.
- **Spacing & Rhythm:** Use consistent 4px/8px grid spacing (p-4, p-6, gap-6, 
ounded-2xl).

---

## 3. What NOT To Do
- ❌ Do NOT use low-contrast text that fails WCAG AA (minimum 4.5:1 ratio).
- ❌ Do NOT clutter dashboards with dense, unorganized widgets without visual whitespace.
- ❌ Do NOT rely solely on color to convey meaning; always use icons and text labels.

---

## 4. Step-by-Step Workflow
1. **Analyze User Intent:** Identify the user goal and primary call-to-action (CTA).
2. **Select Style & Palette:** Choose theme (Dark Modern, Glassmorphism, Clean SaaS) and 3 core colors.
3. **Draft Wireframe & Structure:** Build layout with clear hero, feature cards, and sticky CTA.
4. **Refine Polish & Micro-interactions:** Add smooth transitions (duration-200), hover states, and loading skeletons.

---

## 5. Production Checklist
- [ ] Are color contrast ratios >= 4.5:1 for standard text?
- [ ] Are tap targets on mobile >= 44x44px?
- [ ] Are responsive breakpoints tested across Mobile (375px), Tablet (768px), and Desktop (1280px)?
- [ ] Is dark mode supported with seamless background and border contrast?

---

## 6. Cross-Skill Integration & Handoffs
- ➔ Hand off to rontend-nextjs-pro for component implementation in Next.js / Tailwind.
- ➔ Hand off to conversion-copywriter for landing page copy and headline hooks.
