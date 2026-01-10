# CLAUDE.md

This file provides comprehensive guidance to Claude Code when working with Java code in this repository.

## Core Development Philosophy

### KISS (Keep It Simple, Stupid)

Simplicity should be a key goal in design. Choose straightforward solutions over complex ones whenever possible. Simple solutions are easier to understand, maintain, and debug.

### YAGNI (You Aren't Gonna Need It)

Avoid building functionality on speculation. Implement features only when they are needed, not when you anticipate they might be useful in the future.

### Design Principles

- **Dependency Inversion**: High-level modules should not depend on low-level modules. Both should depend on abstractions.
- **Open/Closed Principle**: Software entities should be open for extension but closed for modification.
- **Single Responsibility**: Each class, method, and module should have one clear purpose.
- **Fail Fast**: Validate inputs early and throw exceptions immediately when issues occur.

## Code Structure & Modularity

### File and Method Limits

- **Never create a class file longer than 500 lines**. If approaching this limit, refactor by extracting classes.
- **Methods should be under 50 lines** for better AI comprehension and maintainability.
- **Classes should focus on one concept** - follow Single Responsibility Principle.
- **Cyclomatic complexity must not exceed 10** per method (SonarQube rule).

### Project Structure (Maven Standard Layout)

```
project-root/
├── pom.xml
├── CLAUDE.md
├── .claude/
│   └── commands/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/company/project/
│   │   │       ├── controller/
│   │   │       ├── service/
│   │   │       ├── repository/
│   │   │       ├── entity/
│   │   │       ├── dto/
│   │   │       ├── exception/
│   │   │       ├── config/
│   │   │       └── util/
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-prod.yml
│   │       └── logback-spring.xml
│   └── test/
│       ├── java/
│       │   └── com/company/project/
│       └── resources/
└── target/
```

## Maven Configuration

### Essential POM Configuration

```xml
<properties>
    <!-- Java Version -->
    > Insert project specific versions

    <!-- Spring Versions -->
    > Insert project specific versions

    <!-- Plugin Versions -->
    > Insert project specific versions
</properties>
```

### Maven Commands

```bash
# Clean and compile
mvn clean compile

# Run tests
mvn test

# Run tests with coverage
mvn clean test jacoco:report

# Package application
mvn clean package

# Run SonarQube analysis
mvn clean verify sonar:sonar

# Check for dependency updates
mvn versions:display-dependency-updates

# Enforce code style
mvn checkstyle:check

# Run SpotBugs analysis
mvn spotbugs:check
```

## Code Style & Conventions

### Java Style Guide

- **Follow Google Java Style Guide** with these specifics:
  - Line length: 100 characters
  - Indent: 4 spaces (no tabs)
  - Braces: Egyptian style (same line)
- **Use `final` keyword judiciously** - for variables and parameters, but avoid on classes using Spring AOP features
- **Prefer immutable objects** - thread-safe by design
- **No wildcard imports** - explicit imports only
- **One class per file** - except for inner classes

### Naming Conventions

- **Classes**: `PascalCase` (e.g., `UserService`)
- **Interfaces**: `PascalCase` without "I" prefix
- **Methods**: `camelCase` (e.g., `getUserById`)
- **Constants**: `UPPER_SNAKE_CASE`
- **Packages**: `lowercase` (e.g., `com.company.project`)
- **Type Parameters**: Single capital letters (e.g., `T`, `E`, `K`, `V`)

## Type Safety & Annotations

### Bean Validation

- **Use Bean Validation** (JSR-380) for validation
- **Use `@Valid`** for method parameters
- **Use `@Validated`** for method return values

### Strict Typing Requirements

- **No raw types** - Always use generics
- **No `Object` type** unless absolutely necessary
- **Use `Optional<T>`** instead of returning null
- **Annotate everything** - `@NonNull`, `@Nullable`
- **No suppressed warnings** without justification

### Essential Annotations

```java
// Nullability annotations (JSR-305)
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import javax.annotation.ParametersAreNonnullByDefault;

// Package-level default
@ParametersAreNonnullByDefault
package com.company.project;

// Lombok for boilerplate reduction
import lombok.Data;
import lombok.Builder;
import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;

// Validation annotations
import jakarta.validation.constraints.*;
```

### Generic Types Best Practices

```java
// Bad: Raw types
List list = new ArrayList();
Map map = new HashMap();

// Good: Parameterized types
List<String> list = new ArrayList<>();
Map<String, User> map = new HashMap<>();

// Good: Bounded type parameters
public interface Repository<T extends Entity> {
    Optional<T> findById(Long id);
    List<T> findAll();
}

// Good: Multiple bounds
public <T extends Comparable<T> & Serializable> void process(T item) {
    // Implementation
}
```

## AI Assistant Guidelines

### Best Practices

- Document repository-specific conventions in CLAUDE.md
- Specify coding style preferences in CLAUDE.md
- List unexpected behaviors or warnings in CLAUDE.md
- Include environment setup instructions in CLAUDE.md

### AI-Assisted Development Guidelines

- Provide clear context in method names and Javadoc
- Include example inputs/outputs in documentation
- Use descriptive variable names that convey intent
- Structure code to be easily understood by AI assistants
- Keep methods focused and under 50 lines for better AI comprehension
- Use consistent naming patterns across the codebase
- Document edge cases and business logic clearly
- Include unit tests that demonstrate usage patterns

### Search Command Requirements

**CRITICAL**: Always use `rg` (ripgrep) instead of traditional `grep` and `find` commands:

```bash
# Don't use grep
grep -r "pattern" .

# Use rg instead
rg "pattern"

# Don't use find with name
find . -name "*.java"

# Use rg with file filtering
rg --files | rg "\.java$"
# or
rg --files -g "*.java"
```

## OpenAPI/Swagger Documentation Requirements (MANDATORY)

**CRITICAL**: Every REST controller and DTO MUST include comprehensive OpenAPI annotations for frontend developers.

### Required Controller Annotations

Every `@RestController` class MUST include:

```java
@RestController
@RequestMapping("/api/resource")
@Tag(name = "Resource Management", description = "Operations for managing resources")
@Validated
public class ResourceController {

    @Operation(
        summary = "Brief action description",
        description = "Detailed explanation of what this endpoint does, including business logic"
    )
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Success case description"),
        @ApiResponse(responseCode = "400", description = "Bad request - validation failed"),
        @ApiResponse(responseCode = "404", description = "Resource not found"),
        @ApiResponse(responseCode = "500", description = "Internal server error")
    })
    @GetMapping("/{id}")
    public ResponseEntity<ResourceResponse> getById(
        @Parameter(description = "Resource unique identifier", example = "123", required = true)
        @PathVariable Long id,

        @Parameter(description = "Include related data", example = "true")
        @RequestParam(defaultValue = "false") Boolean includeDetails
    ) {
        // Implementation
    }
}
```

### Required DTO Annotations

Every DTO class MUST include:

```java
@Schema(description = "Resource response containing all resource information")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ResourceResponse {

    @Schema(description = "Unique identifier", example = "123", accessMode = Schema.AccessMode.READ_ONLY)
    private Long id;

    @Schema(description = "Resource name", example = "Sample Resource", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotBlank(message = "Name cannot be blank")
    @Size(min = 2, max = 100, message = "Name must be between 2 and 100 characters")
    private String name;

    @Schema(description = "Resource creation timestamp", example = "2024-01-15T10:30:00Z", accessMode = Schema.AccessMode.READ_ONLY)
    private LocalDateTime createdAt;

    @Schema(description = "List of related items", implementation = RelatedItemResponse.class)
    private List<RelatedItemResponse> relatedItems;
}
```

### Dependencies Required

```xml
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.8.5</version>
</dependency>
```

**Access URLs:**
- Swagger UI: `http://localhost:8080/swagger-ui.html`
- OpenAPI JSON: `http://localhost:8080/v3/api-docs`

## Javadoc Requirements

Every public class, method, and field MUST have Javadoc. Use Google's Javadoc style:

```java
/**
 * Calculates the discount price for a product.
 *
 * <p>This method applies a percentage discount to the original price,
 * ensuring the final price doesn't go below the minimum threshold.
 *
 * @param originalPrice the original price of the product, must be positive
 * @param discountPercent the discount percentage (0-100)
 * @param minPrice the minimum allowed price after discount
 * @return the calculated discount price
 * @throws IllegalArgumentException if any parameter is invalid
 * @since 1.2.0
 */
@Nonnull
public BigDecimal calculateDiscount(
        @Nonnull BigDecimal originalPrice,
        double discountPercent,
        @Nonnull BigDecimal minPrice) {
    // Implementation
}
```

### Documentation Rules

- First sentence is a summary (ends with period)
- Use `<p>` for paragraph breaks
- Document all parameters with `@param`
- Document return value with `@return`
- Document exceptions with `@throws`
- Use `@since` for API versioning
- Link related items with `{@link}`

## Testing Strategy

### Test Organization

- Unit tests: Same package structure as main code
- Integration tests: Separate `src/test/integration` folder
- Test naming: `ClassNameTest` for unit tests
- Test method naming: `should_ExpectedBehavior_When_StateUnderTest`

### Testing Best Practices

```java
// JUnit 5 + AssertJ + Mockito
import org.junit.jupiter.api.*;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@DisplayName("UserService")
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserService userService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    @DisplayName("should return user when valid ID provided")
    void should_ReturnUser_When_ValidIdProvided() {
        // Given
        Long userId = 1L;
        User expectedUser = User.builder()
            .id(userId)
            .name("John Doe")
            .build();
        when(userRepository.findById(userId))
            .thenReturn(Optional.of(expectedUser));

        // When
        Optional<User> result = userService.findById(userId);

        // Then
        assertThat(result)
            .isPresent()
            .hasValue(expectedUser);
        verify(userRepository).findById(userId);
    }

    @Test
    @DisplayName("should throw exception when ID is null")
    void should_ThrowException_When_IdIsNull() {
        // When/Then
        assertThatThrownBy(() -> userService.findById(null))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessage("User ID cannot be null");
    }
}
```

### Test Coverage Requirements

- Minimum 80% line coverage
- Minimum 80% branch coverage
- Critical business logic: 90%+ coverage
- All public methods must have tests

## SonarQube Configuration

### Code Quality Rules (standard sonarqube rules)

- **Cognitive Complexity**: Max 15 per method
- **Cyclomatic Complexity**: Max 10 per method
- **Duplicated Lines**: Max 3%
- **Code Coverage**: Min 80%
- **No new issues introduced (default Sonar way quality gate)**
- **Technical Debt Ratio**: Max 5%
- **Security Hotspots**: Must be reviewed

## Spring Boot Best Practices

### Final Classes and AOP Limitations

- **CRITICAL**: Avoid `final` modifier on Spring service classes (`@Service`, `@Component`, `@Repository`)
- **Reason**: Spring AOP (including `@Transactional`, `@Cacheable`, `@Async`) uses CGLIB proxies
- **Problem**: Final classes cannot be subclassed, preventing proxy creation
- **Solution**: Use non-final classes with constructor injection

#### When to Use Final

**DO use final for:**
- Local variables and method parameters
- Fields that should never change
- Utility classes with only static methods
- DTOs and value objects without AOP annotations

**AVOID final for:**
- `@Service`, `@Component`, `@Repository` classes
- Classes using `@Transactional`, `@Cacheable`, `@Async`
- Any class requiring Spring AOP features

### Proxy Strategy

```java
// Good: Non-final service class
@Service
@Transactional
public class UserService {
    // Implementation
}

// Bad: Final class prevents AOP
@Service
@Transactional
public final class UserService { // CGLIB cannot proxy this!
    // Implementation
}
```

## Git Workflow

### Commit Message Format

- NEVER include claude code, written by claude code or similar in the commit message

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types: feat, fix, docs, style, refactor, test, chore

## Critical Guidelines

1. **No raw types** - Always use generics
2. **No null returns** - Use Optional<T>
3. **Validate all inputs** - Use Jakarta Validation
4. **Document all public APIs** - Complete Javadoc AND OpenAPI annotations
5. **MANDATORY OpenAPI** - Every REST endpoint MUST have complete @Operation, @ApiResponses, @Parameter, and @Schema annotations
6. **Test everything** - Minimum 80% coverage
7. **Handle all exceptions** - No empty catch blocks
8. **Use final judiciously** - For variables/parameters, avoid on Spring service classes
9. **No magic numbers** - Extract to constants
10. **One class per file** - Except inner classes
11. **Follow SonarQube rules** - Zero blockers/criticals
12. **Frontend-first API design** - All endpoints must be React developer friendly with complete examples and schemas

## Pre-commit Checklist

- [ ] All compiler warnings resolved
- [ ] Javadoc for all public methods/classes
- [ ] **OpenAPI annotations on ALL REST endpoints** (@Operation, @ApiResponses, @Parameter, @Schema)
- [ ] **DTO schemas with examples** (@Schema with description and example on all fields)
- [ ] **API documentation accessible** at `/swagger-ui.html`
- [ ] Unit tests written (80%+ coverage)
- [ ] No SonarQube critical/blocker issues
- [ ] No SpotBugs high priority warnings
- [ ] Code formatted (mvn spotless:apply)
- [ ] All inputs validated
- [ ] Logging at appropriate levels (if logging is setup)
- [ ] **Frontend developer can use API** without asking questions

---

*Keep this guide updated as patterns evolve. Quality over speed, always.*
*Last updated: January 2025*
