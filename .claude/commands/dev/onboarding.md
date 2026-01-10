---
command: onboarding
description: Comprehensive onboarding analysis for new developers joining the project
---

# Developer Onboarding Analysis

Please perform a comprehensive onboarding analysis for a new developer joining this project. Execute the following steps:

## 1. Project Overview

First, analyze the repository structure and provide:

- Project name, purpose, and main functionality
- Tech stack (languages, frameworks, databases, tools)
- Architecture pattern (MVC, microservices, etc.)
- Key dependencies and their purposes

## 2. Repository Structure

Map out the codebase organization:

- List all top-level directories with their purposes
- Identify where different types of code live (models, controllers, utils, tests)
- Highlight any non-standard or unique organizational patterns
- Note any monorepo structures or submodules

## 3. Getting Started

Create step-by-step setup instructions:

- Prerequisites (required software, versions)
- Environment setup commands
- How to install dependencies
- Configuration files that need to be created/modified
- How to run the project locally
- How to run tests
- How to build for production

## 4. Key Components

Identify and explain the most important files/modules:

- Entry points (main.js, index.py, app.tsx, etc.)
- Core business logic locations
- Database models/schemas
- API endpoints or routes
- Configuration management
- Authentication/authorization implementation

## 5. Development Workflow

Document the development process:

- Git branch naming conventions
- How to create a new feature
- Testing requirements
- Code style/linting rules
- PR process and review guidelines
- CI/CD pipeline overview

## 6. Architecture Decisions

Identify important patterns and decisions:

- Design patterns used and why
- State management approach
- Error handling strategy
- Logging and monitoring setup
- Security measures
- Performance optimizations

## 7. Common Tasks

Provide examples for frequent development tasks:

- How to add a new API endpoint
- How to create a new database model
- How to add a new test
- How to debug common issues
- How to update dependencies

## 8. Potential Gotchas

List things that might trip up new developers:

- Non-obvious configurations
- Required environment variables
- External service dependencies
- Known issues or workarounds
- Performance bottlenecks
- Areas of technical debt

## 9. Documentation and Resources

Locate existing documentation:

- README, wikis, docs/
- API documentation
- Database schemas
- Deployment guides
- Team conventions or style guides

## 10. Next Steps

Create an onboarding checklist for the new developer:

- [ ] Set up development environment
- [ ] Run the project successfully
- [ ] Make a small Readme change
- [ ] Run the test suite
- [ ] Understand the main user flow
- [ ] Identify area to start contributing

## Output Format

Please create:

1. A comprehensive **ONBOARDING.md** file at the root of the repository with all the core information and make sure it includes a quickstart guide with the essential setup steps.

2. Suggest an update to the **README.md** if it's missing critical information that the user can make and commit (don't update the readme directly) - suggest the update to the user.

**Focus on clarity and actionability.** Assume the developer is completely new to this codebase.
