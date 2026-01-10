# CLAUDE.md

This file provides guidance to Claude Code when working with React 19 applications.

## Core Development Philosophy

### KISS (Keep It Simple, Stupid)

Simplicity should be a key goal in design. Choose straightforward solutions over complex ones whenever possible. Simple solutions are easier to understand, maintain, and debug.

### YAGNI (You Aren't Gonna Need It)

Avoid building functionality on speculation. Implement features only when they are needed, not when you anticipate they might be useful in the future.

### Component-First Architecture

Build with reusable, composable components. Each component should have a single, clear responsibility and be self-contained with its own styles, tests, and logic co-located.

### Performance by Default

With React 19's compiler, manual optimizations are largely unnecessary. Focus on clean, readable code and let the compiler handle performance optimizations.

### Design Principles (MUST FOLLOW)

- **Vertical Slice Architecture**: MUST organize by features, not layers
- **Composition Over Inheritance**: MUST use React's composition model
- **Fail Fast**: MUST validate inputs early with Zod, throw errors immediately

## React 19 Key Features

### Automatic Optimizations

- **React Compiler**: Eliminates need for `useMemo`, `useCallback`, and `React.memo`
- Let the compiler handle performance - write clean, readable code

### Core Features

- **Server Components**: Use for data fetching and static content
- **Actions**: Handle async operations with built-in pending states
- **use() API**: Simplified data fetching and context consumption
- **Document Metadata**: Native support for SEO tags
- **Enhanced Suspense**: Better loading states and error boundaries

### React 19 TypeScript Integration (MANDATORY)

- **MUST use `ReactElement` instead of `JSX.Element`** for return types
- **MUST import `ReactElement` from 'react'** explicitly
- **NEVER use `JSX.Element` namespace** - use React types directly

```typescript
// CORRECT: Modern React 19 typing
import { ReactElement } from 'react';

function MyComponent(): ReactElement {
  return <div>Content</div>;
}

// FORBIDDEN: Legacy JSX namespace
function MyComponent(): JSX.Element {  // Cannot find namespace 'JSX'
  return <div>Content</div>;
}
```

### Actions Example

```typescript
import { useActionState, ReactElement } from 'react';

function ContactForm(): ReactElement {
  const [state, submitAction, isPending] = useActionState(
    async (previousState: any, formData: FormData) => {
      const result = contactSchema.safeParse({
        email: formData.get('email'),
        message: formData.get('message'),
      });

      if (!result.success) {
        return { error: result.error.flatten() };
      }

      await sendEmail(result.data);
      return { success: true };
    },
    null
  );

  return (
    <form action={submitAction}>
      <button disabled={isPending}>
        {isPending ? 'Sending...' : 'Send'}
      </button>
    </form>
  );
}
```

## Project Structure (Vertical Slice Architecture)

```
src/
├── features/              # Feature-based modules
│   └── [feature]/
│       ├── __tests__/     # Co-located tests
│       ├── components/    # Feature components
│       ├── hooks/         # Feature-specific hooks
│       ├── api/           # API integration
│       ├── schemas/       # Zod validation schemas
│       ├── types/         # TypeScript types
│       └── index.ts       # Public API
├── shared/
│   ├── components/        # Shared UI components
│   ├── hooks/            # Shared custom hooks
│   ├── utils/            # Helper functions
│   └── types/            # Shared TypeScript types
└── test/                 # Test utilities and setup
```

## TypeScript Configuration (STRICT REQUIREMENTS)

### MUST follow These Compiler Options

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "allowJs": false
  }
}
```

### MANDATORY Type Requirements

- **NEVER use `any` type** - use `unknown` if type is truly unknown
- **MUST have explicit return types** for all functions and components
- **MUST use proper generic constraints** for reusable components
- **MUST use type inference from Zod schemas** using `z.infer<typeof schema>`
- **NEVER use `@ts-ignore`** or `@ts-expect-error` - fix the type issue properly

## Data Validation with Zod (MANDATORY FOR ALL EXTERNAL DATA)

### MUST Follow These Validation Rules
- **MUST validate ALL external data**: API responses, form inputs, URL params, environment variables
- **MUST use branded types**: For all IDs and domain-specific values
- **MUST fail fast**: Validate at system boundaries, throw errors immediately
- **MUST use type inference**: Always derive TypeScript types from Zod schemas

### Schema Example (MANDATORY PATTERNS)
```typescript
import { z } from 'zod';

// MUST use branded types for ALL IDs
const UserIdSchema = z.string().uuid().brand<'UserId'>();
type UserId = z.infer<typeof UserIdSchema>;

// MUST include validation for ALL fields
export const userSchema = z.object({
  id: UserIdSchema,
  email: z.string().email(),
  username: z.string()
    .min(3)
    .max(20)
    .regex(/^[a-zA-Z0-9_]+$/),
  age: z.number().min(18).max(100),
  role: z.enum(['admin', 'user', 'guest']),
});

export type User = z.infer<typeof userSchema>;
```

### Form Validation with React Hook Form

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

function UserForm(): ReactElement {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<User>({
    resolver: zodResolver(userSchema),
    mode: 'onBlur',
  });

  const onSubmit = async (data: User): Promise<void> => {
    // Handle validated data
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      {/* Form fields */}
    </form>
  );
}
```

## Testing Strategy (MANDATORY REQUIREMENTS)

### MUST Meet These Testing Standards

- **MINIMUM 80% code coverage** - NO EXCEPTIONS
- **MUST co-locate tests** with components in `__tests__` folders
- **MUST use React Testing Library** for all component tests
- **MUST test user behavior** not implementation details
- **MUST mock external dependencies** appropriately
- **NEVER skip tests** for new features or bug fixes

### Test Example

```typescript
import { describe, it, expect, vi } from 'vitest';
import { render, screen, userEvent } from '@testing-library/react';

describe('UserProfile', () => {
  it('should update user name on form submission', async () => {
    const user = userEvent.setup();
    const onUpdate = vi.fn();

    render(<UserProfile onUpdate={onUpdate} />);

    const input = screen.getByLabelText(/name/i);
    await user.type(input, 'John Doe');
    await user.click(screen.getByRole('button', { name: /save/i }));

    expect(onUpdate).toHaveBeenCalledWith(
      expect.objectContaining({ name: 'John Doe' })
    );
  });
});
```

## Component Guidelines (STRICT REQUIREMENTS)

### MANDATORY TypeScript Requirements

```typescript
// REQUIRED: Explicit types, clear props
interface ButtonProps {
  variant: "primary" | "secondary";
  size?: "small" | "medium" | "large";
  onClick: (event: React.MouseEvent<HTMLButtonElement>) => void;
  children: React.ReactNode;
  disabled?: boolean;
}

const Button: React.FC<ButtonProps> = ({
  variant,
  size = "medium",
  onClick,
  children,
  disabled = false,
}) => {
  // Implementation
};

// FORBIDDEN: Implicit types, loose typing
const Button = ({ variant, onClick, children }: any) => {
  // Implementation
};
```

### MUST Follow Component Best Practices

- **MAXIMUM 200 lines** per component file
- **MUST follow single responsibility** principle
- **MUST validate props** with Zod when accepting external data
- **MUST implement error boundaries** for all feature modules
- **MUST handle ALL states**: loading, error, empty, and success
- **NEVER return null** without explicit empty state handling
- **MUST include ARIA labels** for accessibility

## State Management (STRICT HIERARCHY)

### MUST Follow This State Hierarchy

1. **Local State**: `useState` ONLY for component-specific state
2. **Context**: For cross-component state within a single feature
3. **Server State**: MUST use TanStack Query for ALL API data
4. **Global State**: Zustand ONLY when truly needed app-wide
5. **URL State**: MUST use search params for shareable state

### MANDATORY Server State Pattern

```typescript
import { useQuery, useMutation } from "@tanstack/react-query";

function useUser(id: UserId) {
  return useQuery({
    queryKey: ["user", id],
    queryFn: async () => {
      const response = await fetch(`/api/users/${id}`);

      if (!response.ok) {
        throw new ApiError("Failed to fetch user", response.status);
      }

      const data = await response.json();
      return userSchema.parse(data);
    },
    staleTime: 5 * 60 * 1000,
    retry: 3,
  });
}
```

## Security Requirements (MANDATORY)

### Input Validation (MUST IMPLEMENT ALL)

- **MUST sanitize ALL user inputs** with Zod before processing
- **MUST validate file uploads**: type, size, and content
- **MUST prevent XSS** with proper escaping
- **MUST implement CSP headers** in production
- **NEVER use dangerouslySetInnerHTML** without sanitization

### API Security

- **MUST validate ALL API responses** with Zod schemas
- **MUST handle errors gracefully** without exposing internals
- **NEVER log sensitive data** (passwords, tokens, PII)

## npm Scripts

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "test": "vitest",
    "test:coverage": "vitest --coverage",
    "lint": "eslint . --ext ts,tsx --max-warnings 0",
    "format": "prettier --write \"src/**/*.{ts,tsx}\"",
    "type-check": "tsc --noEmit",
    "validate": "npm run type-check && npm run lint && npm run test:coverage"
  }
}
```

## CRITICAL GUIDELINES (MUST FOLLOW ALL)

1. **ENFORCE strict TypeScript** - ZERO compromises on type safety
2. **VALIDATE everything with Zod** - As much as possible
3. **MINIMUM 80% test coverage** - NO EXCEPTIONS
4. **MUST co-locate related files** - Tests MUST be in `__tests__` folders
5. **MAXIMUM 200 lines per component** - Split if larger
6. **MAXIMUM cognitive complexity of 15** - Refactor if higher
7. **MUST handle ALL states** - Loading, error, empty, and success
8. **MUST use semantic commits** - feat:, fix:, docs:, refactor:, test:
9. **MUST write complete JSDoc** - ALL exports must be documented
10. **MUST pass ALL automated checks** - Before ANY merge

## Pre-commit Checklist (MUST COMPLETE ALL)

- [ ] TypeScript compiles with ZERO errors
- [ ] Zod schemas validate ALL external data
- [ ] Tests written and passing (MINIMUM 80% coverage)
- [ ] ESLint passes with ZERO warnings
- [ ] ALL states handled (loading, error, empty, success)
- [ ] Accessibility requirements met (ARIA labels, keyboard nav)
- [ ] ZERO console.log statements
- [ ] ALL functions have complete JSDoc documentation
- [ ] Component props are fully documented
- [ ] Component files under 200 lines
- [ ] Cognitive complexity under 15 for all functions

### FORBIDDEN Practices

- **NEVER use `any` type** (except library declaration merging with comments)
- **NEVER skip tests**
- **NEVER ignore TypeScript errors**
- **NEVER trust external data without validation**
- **NEVER exceed complexity limits**
- **NEVER skip documentation**
- **NEVER use `JSX.Element`** - use `ReactElement` instead

---

*This guide is a living document. Update it as new patterns emerge and tools evolve.*
*Focus on quality over speed, maintainability over cleverness.*
*Last updated: January 2025*
