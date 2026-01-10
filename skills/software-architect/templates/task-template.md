# Task Template

Use this template for defining individual tasks within a PRP phase.

```xml
<task id="[phase.task]" agent="[agent-type]" effort="[S|M|L|XL]" value="[H|M|L]">

  <description>
    [Clear, actionable description of what to do.
    Should be completable in 15-30 minutes.
    Single responsibility - one thing done well.]
  </description>

  <files>
    <file action="create">[path/to/new-file.ts]</file>
    <file action="modify">[path/to/existing-file.ts]</file>
    <file action="delete">[path/to/deprecated-file.ts]</file>
  </files>

  <context>
    <reference file="[path/to/similar-file.ts]" usage="[Follow this pattern]"/>
    <documentation url="[https://docs.example.com]" section="[Relevant section]"/>
    <gotcha>[Known issue or quirk to avoid]</gotcha>
  </context>

  <pseudocode>
// Follow pattern from [reference file]
// Use existing [utility/pattern] for [purpose]

[Pseudocode matching project coding style]
[Include critical implementation details]
[Show imports and dependencies]
  </pseudocode>

  <acceptance-criteria>
    <criterion>[Specific, verifiable outcome that can be tested]</criterion>
    <criterion>[Another verifiable outcome]</criterion>
    <criterion>[TypeScript/linting requirement if applicable]</criterion>
  </acceptance-criteria>

  <handoff>
    <expects>
      <input from="[task id]">[What this task needs]</input>
    </expects>
    <produces>
      <output for="[task id]">[What this task provides]</output>
    </produces>
  </handoff>

  <validation>
    <command>[Specific validation command for this task]</command>
  </validation>

</task>
```

## Task Examples by Agent

### Backend Engineer Task

```xml
<task id="2.1" agent="backend-engineer" effort="M" value="H">
  <description>
    Create UserService with CRUD operations following the existing service pattern.
  </description>

  <files>
    <file action="create">src/services/user-service.ts</file>
    <file action="modify">src/services/index.ts</file>
  </files>

  <context>
    <reference file="src/services/product-service.ts" usage="Follow class structure"/>
    <reference file="src/types/user.ts" usage="Use User type"/>
    <gotcha>Always use the repository pattern, never direct DB access</gotcha>
  </context>

  <pseudocode>
import { UserRepository } from '../repositories/user-repository';
import { User, CreateUserInput, UpdateUserInput } from '../types/user';
import { NotFoundError, ValidationError } from '../errors';

export class UserService {
  constructor(private repo: UserRepository) {}

  async create(input: CreateUserInput): Promise<User> {
    // Validate email uniqueness
    const existing = await this.repo.findByEmail(input.email);
    if (existing) throw new ValidationError('Email already exists');

    return this.repo.create(input);
  }

  async findById(id: string): Promise<User> {
    const user = await this.repo.findById(id);
    if (!user) throw new NotFoundError('User not found');
    return user;
  }

  // ... update, delete methods
}
  </pseudocode>

  <acceptance-criteria>
    <criterion>UserService class exports from src/services/index.ts</criterion>
    <criterion>All methods return proper types from src/types/user.ts</criterion>
    <criterion>NotFoundError thrown when user doesn't exist</criterion>
    <criterion>npm run typecheck passes</criterion>
  </acceptance-criteria>

  <handoff>
    <expects>
      <input from="1.2">User type definitions</input>
      <input from="1.3">UserRepository implementation</input>
    </expects>
    <produces>
      <output for="3.1">UserService for API route handlers</output>
    </produces>
  </handoff>
</task>
```

### Frontend Engineer Task

```xml
<task id="4.1" agent="frontend-engineer" effort="M" value="H">
  <description>
    Create UserProfile component displaying user information with edit capability.
  </description>

  <files>
    <file action="create">src/components/UserProfile/UserProfile.tsx</file>
    <file action="create">src/components/UserProfile/UserProfile.styles.ts</file>
    <file action="create">src/components/UserProfile/index.ts</file>
  </files>

  <context>
    <reference file="src/components/ProductCard/ProductCard.tsx" usage="Follow component structure"/>
    <reference file="src/hooks/useApi.ts" usage="Use for data fetching"/>
  </context>

  <pseudocode>
import { useApi } from '../../hooks/useApi';
import { User } from '../../types/user';
import * as S from './UserProfile.styles';

interface UserProfileProps {
  userId: string;
  onEdit?: () => void;
}

export const UserProfile: React.FC<UserProfileProps> = ({ userId, onEdit }) => {
  const { data: user, isLoading, error } = useApi<User>(`/api/users/${userId}`);

  if (isLoading) return <S.Skeleton />;
  if (error) return <S.Error message={error.message} />;
  if (!user) return null;

  return (
    <S.Container>
      <S.Avatar src={user.avatarUrl} alt={user.name} />
      <S.Name>{user.name}</S.Name>
      <S.Email>{user.email}</S.Email>
      {onEdit && <S.EditButton onClick={onEdit}>Edit Profile</S.EditButton>}
    </S.Container>
  );
};
  </pseudocode>

  <acceptance-criteria>
    <criterion>Component renders user name and email</criterion>
    <criterion>Loading state shows skeleton</criterion>
    <criterion>Error state shows error message</criterion>
    <criterion>Edit button calls onEdit when clicked</criterion>
    <criterion>npm run lint passes</criterion>
  </acceptance-criteria>

  <handoff>
    <expects>
      <input from="3.1">GET /api/users/:id endpoint working</input>
    </expects>
    <produces>
      <output for="5.1">UserProfile component for page integration</output>
    </produces>
  </handoff>
</task>
```

### QA Engineer Task

```xml
<task id="6.1" agent="qa-engineer" effort="M" value="H">
  <description>
    Create unit tests for UserService covering all methods and edge cases.
  </description>

  <files>
    <file action="create">src/services/__tests__/user-service.test.ts</file>
  </files>

  <context>
    <reference file="src/services/__tests__/product-service.test.ts" usage="Follow test structure"/>
  </context>

  <pseudocode>
import { UserService } from '../user-service';
import { MockUserRepository } from '../../test-utils/mocks';

describe('UserService', () => {
  let service: UserService;
  let mockRepo: MockUserRepository;

  beforeEach(() => {
    mockRepo = new MockUserRepository();
    service = new UserService(mockRepo);
  });

  describe('create', () => {
    it('creates user with valid input', async () => {
      const input = { email: 'test@example.com', name: 'Test User' };
      const user = await service.create(input);
      expect(user.email).toBe(input.email);
    });

    it('throws ValidationError for duplicate email', async () => {
      mockRepo.findByEmail.mockResolvedValue({ id: '1', email: 'test@example.com' });
      await expect(service.create({ email: 'test@example.com', name: 'Test' }))
        .rejects.toThrow('Email already exists');
    });
  });

  describe('findById', () => {
    it('returns user when found', async () => { /* ... */ });
    it('throws NotFoundError when not found', async () => { /* ... */ });
  });
});
  </pseudocode>

  <acceptance-criteria>
    <criterion>Test file covers create, findById, update, delete methods</criterion>
    <criterion>Happy path and error cases tested</criterion>
    <criterion>All tests pass: npm test -- user-service</criterion>
    <criterion>Coverage > 80% for UserService</criterion>
  </acceptance-criteria>

  <handoff>
    <expects>
      <input from="2.1">Completed UserService implementation</input>
    </expects>
    <produces>
      <output>Test coverage for UserService</output>
    </produces>
  </handoff>
</task>
```

## Task ID Convention

Use hierarchical IDs: `[phase].[task]`

- Phase 1, Task 1: `1.1`
- Phase 2, Task 3: `2.3`
- Phase 3, Task 1: `3.1`

This makes task references and handoffs clear.

## Effort Guidelines Reminder

| Size | Time | Files | Decisions |
|------|------|-------|-----------|
| S | <15 min | 1 file | None |
| M | 15-30 min | 2-3 files | Few |
| L | 30-60 min | 3-5 files | Several |
| XL | 1+ hours | Many | Many (split this!) |
