# CLAUDE.md

This file provides comprehensive guidance to Claude Code when working with Astro 5+ applications and the Islands Architecture.

## Core Development Philosophy

### KISS (Keep It Simple, Stupid)

Simplicity should be a key goal in design. Choose straightforward solutions over complex ones whenever possible. Simple solutions are easier to understand, maintain, and debug.

### YAGNI (You Aren't Gonna Need It)

Avoid building functionality on speculation. Implement features only when they are needed, not when you anticipate they might be useful in the future.

### Design Principles

- **Islands Architecture**: Ship minimal JavaScript, hydrate only what needs interactivity
- **Performance by Default**: Static-first with selective hydration for optimal performance
- **Framework Agnostic**: Mix React, Vue, Svelte, and other frameworks in the same project
- **Content-Driven**: Optimized for content-heavy websites with type-safe content management
- **Zero JavaScript by Default**: Only ship JavaScript when explicitly needed

## AI Assistant Guidelines

### Context Awareness

- When implementing features, always check existing patterns first
- Prefer static generation over client-side rendering when possible
- Use framework-specific components only when interactivity is required
- Check for similar functionality across different framework integrations
- Understand when to use `.astro` vs framework components

### Common Pitfalls to Avoid

- Over-hydrating components that could be static
- Mixing multiple frameworks unnecessarily in single components
- Ignoring Astro's partial hydration benefits
- Creating duplicate functionality across different framework islands
- Overwriting existing integrations without checking alternatives

### Workflow Patterns

- Preferably create tests BEFORE implementation (TDD)
- Use "think hard" for hydration strategy decisions
- Break complex interactive components into smaller, focused islands
- Validate framework choice and hydration requirements before implementation

## Astro 5+ Key Features

### Content Layer (New in Astro 5)

- **Flexible Content Management**: Load content from any source (files, APIs, CMSs)
- **Type-Safe Content**: Automatic TypeScript types for all content collections
- **Performance Boost**: Up to 5x faster builds for Markdown, 2x for MDX
- **Unified API**: Single interface for all content sources

```typescript
// content/config.ts
import { defineCollection, z } from "astro:content";

const blog = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    pubDate: z.date(),
    description: z.string(),
    author: z.string(),
    image: z
      .object({
        url: z.string(),
        alt: z.string(),
      })
      .optional(),
    tags: z.array(z.string()),
  }),
});

export const collections = { blog };
```

### Server Islands (New in Astro 5)

- **Mixed Static/Dynamic Content**: Combine cached static content with personalized dynamic content
- **Independent Loading**: Each island loads separately for optimal performance
- **Custom Caching**: Set custom cache headers and fallback content per island

### Hydration Directives (CRITICAL UNDERSTANDING)

```astro
<!-- Load immediately -->
<Component client:load />

<!-- Load when component becomes visible -->
<Component client:visible />

<!-- Load when browser is idle -->
<Component client:idle />

<!-- Load on media query match -->
<Component client:media="(max-width: 768px)" />

<!-- Render only on client (no SSR) -->
<Component client:only="react" />
```

## Project Structure (Islands Architecture)

```
src/
├── components/            # Astro components (.astro)
│   ├── ui/               # Static UI components
│   ├── islands/          # Interactive components (framework-specific)
│   └── layouts/          # Layout components
├── content/              # Content collections
│   ├── config.ts         # Content configuration
│   ├── blog/            # Blog posts (markdown/mdx)
│   └── docs/            # Documentation
├── pages/                # File-based routing (REQUIRED)
│   ├── api/             # API routes
│   ├── blog/            # Blog pages
│   └── [...slug].astro  # Dynamic routes
├── lib/                  # Utility functions and configurations
│   ├── utils.ts         # Helper functions
│   ├── constants.ts     # Application constants
│   └── schemas.ts       # Zod validation schemas
├── styles/              # Global styles
│   └── global.css       # CSS custom properties and globals
├── assets/              # Processed assets (images, etc.)
└── env.d.ts            # Environment and type definitions
```

## TypeScript Configuration (STRICT REQUIREMENTS)

### MUST Follow Astro TypeScript Templates

```json
{
  "extends": "astro/tsconfigs/strict",
  "include": [".astro/types.d.ts", "**/*"],
  "exclude": ["dist"],
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@/components/*": ["src/components/*"],
      "@/layouts/*": ["src/layouts/*"],
      "@/content/*": ["src/content/*"]
    },
    "verbatimModuleSyntax": true,
    "isolatedModules": true,
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true
  }
}
```

### MANDATORY Type Requirements

- **NEVER use `any` type** - use `unknown` if type is truly unknown
- **MUST use explicit type imports** with `import type { }` syntax
- **MUST define props interfaces** for all Astro components
- **MUST use Astro's built-in types** like `HTMLAttributes`, `ComponentProps`
- **MUST validate content with Zod schemas** in content collections

## Package Management & Dependencies

### MUST Use pnpm (MANDATORY)

**CRITICAL**: Always use pnpm for Astro projects for better performance and dependency management.

```bash
# Install pnpm globally
npm install -g pnpm

# Project setup
pnpm create astro@latest
pnpm install
pnpm dev
```

### Essential Astro 5 Dependencies

```json
{
  "dependencies": {
    "astro": "^5.0.0",
    "@astrojs/check": "^0.9.0",
    "@astrojs/ts-plugin": "^1.10.0",
    "typescript": "^5.6.0"
  },
  "devDependencies": {
    "@astrojs/tailwind": "^5.1.0",
    "tailwindcss": "^3.4.0",
    "prettier": "^3.3.0",
    "prettier-plugin-astro": "^0.14.0"
  }
}
```

### Framework Integrations (Add as needed)

```bash
# React integration
pnpm astro add react

# Vue integration
pnpm astro add vue

# Svelte integration
pnpm astro add svelte
```

## Data Validation with Zod (MANDATORY FOR CONTENT)

### Content Collections (REQUIRED Pattern)

```typescript
// src/content/config.ts
import { defineCollection, z } from "astro:content";

const blogSchema = z.object({
  title: z.string(),
  description: z.string(),
  pubDate: z.coerce.date(),
  updatedDate: z.coerce.date().optional(),
  heroImage: z.string().optional(),
  tags: z.array(z.string()).default([]),
  draft: z.boolean().default(false),
  author: z.object({
    name: z.string(),
    email: z.string().email().optional(),
    image: z.string().optional(),
  }),
});

export const collections = {
  blog: defineCollection({
    type: "content",
    schema: blogSchema,
  }),
};

export type BlogPost = z.infer<typeof blogSchema>;
```

## Testing Strategy (VITEST RECOMMENDED)

### MUST Meet These Testing Standards

- **MINIMUM 80% code coverage** - NO EXCEPTIONS
- **MUST use Vitest** for unit and component tests (Jest-compatible, Vite-native)
- **MUST use Astro Container API** for component testing
- **MUST test islands separately** from static components
- **MUST mock external dependencies** appropriately

## Component Guidelines (ASTRO-SPECIFIC)

### Astro Component Structure (MANDATORY)

```astro
---
// src/components/BlogCard.astro
export interface Props {
  title: string;
  description: string;
  pubDate: Date;
  image?: {
    src: string;
    alt: string;
  };
  tags?: string[];
  href: string;
}

const {
  title,
  description,
  pubDate,
  image,
  tags = [],
  href
} = Astro.props;

// Server-side logic here
const formattedDate = pubDate.toLocaleDateString('en-US', {
  year: 'numeric',
  month: 'long',
  day: 'numeric'
});
---

<article class="blog-card">
  {image && (
    <img
      src={image.src}
      alt={image.alt}
      loading="lazy"
      decoding="async"
    />
  )}

  <div class="content">
    <h3>
      <a href={href}>{title}</a>
    </h3>
    <p>{description}</p>

    <div class="meta">
      <time datetime={pubDate.toISOString()}>
        {formattedDate}
      </time>

      {tags.length > 0 && (
        <ul class="tags">
          {tags.map((tag) => (
            <li class="tag">{tag}</li>
          ))}
        </ul>
      )}
    </div>
  </div>
</article>

<style>
  .blog-card {
    /* Component-scoped styles */
    border: 1px solid var(--color-border);
    border-radius: 8px;
    overflow: hidden;
    transition: transform 0.2s ease;
  }
</style>
```

## Development Commands

### pnpm Scripts (MANDATORY)

```json
{
  "scripts": {
    "dev": "astro dev",
    "start": "astro dev",
    "build": "astro check && astro build",
    "preview": "astro preview",
    "check": "astro check",
    "sync": "astro sync",
    "test": "vitest",
    "test:coverage": "vitest --coverage",
    "lint": "eslint . --ext .js,.ts,.astro --max-warnings 0",
    "format": "prettier --write \"src/**/*.{astro,js,ts,md,json}\"",
    "format:check": "prettier --check \"src/**/*.{astro,js,ts,md,json}\"",
    "validate": "pnpm run check && pnpm run lint && pnpm run test:coverage"
  }
}
```

## CRITICAL GUIDELINES (MUST FOLLOW ALL)

1. **MUST use pnpm** - Never use npm or yarn for package management
2. **ENFORCE TypeScript strict mode** - Use `astro/tsconfigs/strict` template
3. **VALIDATE all content with Zod** - Content collections MUST have schemas
4. **MINIMUM 80% test coverage** - Use Vitest with Container API
5. **MUST understand hydration strategy** - Use appropriate client directives
6. **MAXIMUM 500 lines per file** - Split large components
7. **MUST use semantic imports** - `import type` for type-only imports
8. **MUST optimize images** - Use Astro's Image component
9. **MUST validate environment variables** - Use astro:env for type safety
10. **NEVER over-hydrate** - Default to static, hydrate only when needed
11. **MUST use framework components sparingly** - Prefer Astro components for static content
12. **MUST pass astro check** - Zero TypeScript errors required

## Pre-commit Checklist (MUST COMPLETE ALL)

- [ ] `astro check` passes with ZERO errors
- [ ] Content collections have proper Zod schemas
- [ ] Components use appropriate hydration directives
- [ ] Images are optimized with Astro's Image component
- [ ] Tests written with 80%+ coverage using Vitest
- [ ] Environment variables are properly typed with astro:env
- [ ] No unnecessary framework components (static content uses .astro)
- [ ] TypeScript strict mode compliance
- [ ] Prettier formatting applied to all .astro files
- [ ] All API routes have proper Zod validation
- [ ] Content types are properly exported and used
- [ ] No client-side JavaScript for static content
- [ ] Performance budget maintained (check bundle size)
- [ ] SEO metadata properly configured

### FORBIDDEN Practices

- **NEVER use npm or yarn** - MUST use pnpm for all package management
- **NEVER use client:load** without justification - prefer client:visible or client:idle
- **NEVER skip content validation** - all content MUST have Zod schemas
- **NEVER ignore hydration impact** - understand JavaScript bundle size
- **NEVER use framework components for static content** - use .astro files
- **NEVER bypass TypeScript checking** - astro check must pass
- **NEVER store secrets in client-side code** - use astro:env server context
- **NEVER ignore image optimization** - always use Astro's Image component
- **NEVER mix concerns** - separate static content from interactive islands
- **NEVER use any type** - leverage Astro's built-in type safety

---

*This guide is optimized for Astro 5+ with Islands Architecture and modern web performance.*
*Focus on minimal JavaScript, optimal hydration, and type-safe content management.*
*Last updated: January 2025*
