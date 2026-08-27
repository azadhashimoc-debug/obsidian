---
name: frontend-nextjs-pro
description: Master Next.js 15+ App Router, React 19 Server Components, TypeScript strict mode, Tailwind CSS, high-performance UI rendering, Core Web Vitals, and modern state architecture. Use when building, auditing, or optimizing modern web frontends, landing pages, and SaaS client applications.
---

# Master Next.js 15+ & TypeScript Architecture (rontend-nextjs-pro)

Expert guidelines for building high-performance, accessible, and scalable web frontends using Next.js 15+ App Router, React 19, TypeScript strict mode, and Tailwind CSS.

---

## 1. When to Use & Triggers
- Designing or implementing Next.js frontend pages, layouts, and components.
- Migrating from Pages Router to App Router.
- Optimizing Core Web Vitals (LCP, CLS, INP) and client-side performance.
- Structuring component hierarchies, Server vs Client Component boundaries.
- Integrating backend REST/GraphQL APIs with Server Actions or etch caching.

---

## 2. What TO Do (Core Principles)
- **Server Components by Default (RSC):** Keep components server-rendered; push 'use client' to the leaf nodes.
- **Granular Data Caching:** Use etch(url, { next: { tags: ['data'] } }) and revalidate with 
evalidateTag().
- **TypeScript Strict Standards:** Zero ny types. Define strict DTO interfaces and Zod schemas.
- **Zero Layout Shifts:** Always use 
ext/image with explicit dimensions/sizes and 
ext/font for web fonts.

---

## 3. What NOT To Do
- ❌ Do NOT put 'use client' at the top of page files unless the entire page is an interactive canvas.
- ❌ Do NOT perform client-side waterfall fetches (useEffect -> etch) when data can be prefetched on the server.
- ❌ Do NOT pass sensitive environment variables or secrets to Client Components.
- ❌ Do NOT use unoptimized <img> tags.

---

## 4. Step-by-Step Workflow
1. **Define Layout & Routes:** Create route folders in pp/ with page.tsx, layout.tsx, and loading.tsx.
2. **Structure Server/Client Boundaries:** Separate data fetching logic (Server) from interactive state (Client).
3. **Implement UI Components:** Style with mobile-first Tailwind CSS and Lucide icons.
4. **Integrate APIs & State:** Connect to backend endpoints using Server Actions or Zod-validated fetchers.
5. **Optimize Performance:** Verify bundle sizes and eliminate unnecessary client dependencies.

---

## 5. Production Checklist
- [ ] Are Server and Client component boundaries cleanly separated?
- [ ] Is dynamic metadata (generateMetadata) configured for SEO and OpenGraph?
- [ ] Are all image assets optimized with 
ext/image and explicit aspect ratios?
- [ ] Is input validation handled with Zod and React Hook Form / Server Actions?
- [ ] Are Core Web Vitals (INP < 200ms, LCP < 2.5s, CLS < 0.1) verified?

---

## 6. Cross-Skill Integration & Handoffs
- ➔ Receives UI specifications from ui-ux-pro-max.
- ➔ Hand off to ackend-django-pro for API schema synchronization.
- ➔ Hand off to 	echnical-seo-pro for Schema JSON-LD and sitemap generation.
