---
name: technical-seo-pro
description: Master technical SEO, Schema.org JSON-LD structured data, programmatic SEO, dynamic XML sitemaps, robots.txt, canonicalization, OpenGraph metadata, Core Web Vitals optimization, and semantic HTML. Use when building search-optimized web apps, landing pages, e-commerce, and content hubs.
---

# Technical SEO & Programmatic Search Engine Optimization (	echnical-seo-pro)

Comprehensive blueprint for maximizing organic search visibility, structured data indexing, crawl efficiency, and Core Web Vitals.

---

## 1. When to Use & Triggers
- Setting up SEO architecture for Next.js, Django, or static web applications.
- Generating Schema.org structured data (Organization, Product, Article, FAQ, SoftwareApplication).
- Building dynamic sitemap.xml, 
obots.txt, and canonical URL handling.
- Creating programmatic SEO landing pages and directory structures.
- Auditing indexability, crawl budget, and Core Web Vitals.

---

## 2. What TO Do (Core Principles)
- **Metadata & OpenGraph:** Unique titles (50-60 chars), meta descriptions (140-160 chars), and 1200x630px OG images.
- **Canonical URLs:** Always include canonical link tag on every page.
- **Rich Snippets (JSON-LD):** Inject Schema.org markup for Products, SoftwareApps, FAQs, and Breadcrumbs.
- **Server-Side Rendered HTML:** Ensure bots receive full semantic HTML without requiring client JS execution.

---

## 3. What NOT To Do
- ❌ Do NOT render critical content solely via client-side JavaScript without SSR/ISR.
- ❌ Do NOT create duplicate titles or meta descriptions across dynamic pages.
- ❌ Do NOT block CSS/JS assets in 
obots.txt.
- ❌ Do NOT omit image lt attributes.

---

## 4. Step-by-Step Workflow
1. **Keyword & URL Architecture:** Define clean, keyword-rich slug structures.
2. **Template Metadata:** Implement dynamic metadata in Next.js or meta tags in Django.
3. **Structured Data:** Inject valid JSON-LD schemas matching the page type.
4. **Sitemap & Robots:** Generate automated dynamic sitemap.xml and configure 
obots.txt.
5. **Audit & Validation:** Test with Google Rich Results Test and Lighthouse SEO audit.

---

## 5. Production Checklist
- [ ] Is dynamic sitemap.xml generated and registered in Google Search Console?
- [ ] Is JSON-LD valid and tested against Google Rich Results Test?
- [ ] Are canonical tags pointing to preferred URLs?
- [ ] Are OpenGraph images 1200x630px with valid absolute URLs?
- [ ] Is single <h1> tag present with logical heading hierarchy?

---

## 6. Cross-Skill Integration & Handoffs
- ➔ Coordinates with rontend-nextjs-pro and ackend-django-pro for sitemap/metadata rendering.
- ➔ Hand off to conversion-copywriter for meta description and headline copywriting.
