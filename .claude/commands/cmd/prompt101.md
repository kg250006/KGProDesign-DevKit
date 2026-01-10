# PageForge Core Values - Prompt Reminder

## =4 CRITICAL: Always Remember These Core Principles

### Architecture Absolutes
- **JSON FLAT-FILE STORAGE** -  postgres is ONLY for guide registry and user data
- **OLLAMA LLM REQUIRED** - AI-driven chunking at localhost:11434
- **INFINITE CONTAINERS** - NO absolute positioning allowed
- **SEQUENTIAL USER FLOW** - Each phase must complete before next

### Development Philosophy
- **KISS**: Keep It Simple, Stupid
- **YAGNI**: You Aren't Gonna Need It (Don't add features not requested)
- **DRY**: Don't Repeat Yourself

### Testing is Truth
Work is NOT complete until:
- Tests are written/updated
- All tests pass
- Docker build succeeds
- Coverage remains at 100%
- if I'm complaining, that something is not being shown on the front end that you believe, you already fixed, always consider whether the docker container is old and needs to be rebuilt with no caching

### Golden Rules
1. **Do what has been asked; nothing more, nothing less**
2. **NEVER create files unless absolutely necessary**
3. **ALWAYS prefer editing existing files over creating new ones**
4. **NEVER proactively create documentation (only summary.md allowed)**
5. **NEVER make up features or functionality not in specs**
6. **ALWAYS test when possible**
7. **ALWAYS use agents for tasks**
8. **MAXIMIZE parallelization (up to 20 concurrent tasks)**

### Before Any Task
1. Read README.md for architecture
2. Check master-implementation-roadmap.md for priorities
3. Review relevant summary.md files
4. Follow edit lock protocol

### Performance Standards
- PDF processing: <30 seconds
- Page load: <2 seconds
- Widget operations: <100ms
- JSON reads: <50ms

### Remember
- Don't assume libraries exist - check package.json/pyproject.toml first
- Follow existing code patterns and conventions
- Update summary.md after changes
- Never leave edit locks in place
