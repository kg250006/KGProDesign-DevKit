# Regression Test Report

## Session Information

| Field | Value |
|-------|-------|
| **Date** | {{DATE}} |
| **Project** | {{PROJECT_NAME}} |
| **Mode** | {{MODE}} |
| **Platform** | {{PLATFORM}} |
| **Test Runner** | {{TEST_RUNNER}} |
| **E2E Runner** | {{E2E_RUNNER}} |
| **Duration** | {{DURATION}} |

## Executive Summary

| Metric | Value | Status |
|--------|-------|--------|
| **Total Tests** | {{TOTAL_TESTS}} | - |
| **Passed** | {{PASSED}} | {{PASSED_STATUS}} |
| **Failed** | {{FAILED}} | {{FAILED_STATUS}} |
| **Skipped** | {{SKIPPED}} | - |
| **Fixed** | {{FIXED}} | - |
| **Blocked** | {{BLOCKED}} | {{BLOCKED_STATUS}} |
| **Coverage** | {{COVERAGE}}% | {{COVERAGE_STATUS}} |

### Overall Status: {{OVERALL_STATUS}}

---

## Test Results by Area

### Backend Tests

| Area | Passed | Failed | Skipped | Time |
|------|--------|--------|---------|------|
| Services | {{BACKEND_SERVICES_PASSED}}/{{BACKEND_SERVICES_TOTAL}} | {{BACKEND_SERVICES_FAILED}} | {{BACKEND_SERVICES_SKIPPED}} | {{BACKEND_SERVICES_TIME}} |
| API Routes | {{BACKEND_API_PASSED}}/{{BACKEND_API_TOTAL}} | {{BACKEND_API_FAILED}} | {{BACKEND_API_SKIPPED}} | {{BACKEND_API_TIME}} |
| Integration | {{BACKEND_INT_PASSED}}/{{BACKEND_INT_TOTAL}} | {{BACKEND_INT_FAILED}} | {{BACKEND_INT_SKIPPED}} | {{BACKEND_INT_TIME}} |

### Frontend Tests

| Area | Passed | Failed | Skipped | Time |
|------|--------|--------|---------|------|
| Components | {{FRONTEND_COMP_PASSED}}/{{FRONTEND_COMP_TOTAL}} | {{FRONTEND_COMP_FAILED}} | {{FRONTEND_COMP_SKIPPED}} | {{FRONTEND_COMP_TIME}} |
| Hooks | {{FRONTEND_HOOKS_PASSED}}/{{FRONTEND_HOOKS_TOTAL}} | {{FRONTEND_HOOKS_FAILED}} | {{FRONTEND_HOOKS_SKIPPED}} | {{FRONTEND_HOOKS_TIME}} |
| Pages | {{FRONTEND_PAGES_PASSED}}/{{FRONTEND_PAGES_TOTAL}} | {{FRONTEND_PAGES_FAILED}} | {{FRONTEND_PAGES_SKIPPED}} | {{FRONTEND_PAGES_TIME}} |

### E2E Tests

| Flow | Passed | Failed | Screenshots |
|------|--------|--------|-------------|
| {{E2E_FLOW_1}} | {{E2E_FLOW_1_PASSED}} | {{E2E_FLOW_1_FAILED}} | {{E2E_FLOW_1_SCREENSHOTS}} |
| {{E2E_FLOW_2}} | {{E2E_FLOW_2_PASSED}} | {{E2E_FLOW_2_FAILED}} | {{E2E_FLOW_2_SCREENSHOTS}} |

---

## Coverage Summary

### Overall Coverage

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| **Lines** | {{LINES_BEFORE}}% | {{LINES_AFTER}}% | {{LINES_CHANGE}} |
| **Branches** | {{BRANCHES_BEFORE}}% | {{BRANCHES_AFTER}}% | {{BRANCHES_CHANGE}} |
| **Functions** | {{FUNCTIONS_BEFORE}}% | {{FUNCTIONS_AFTER}}% | {{FUNCTIONS_CHANGE}} |
| **Statements** | {{STATEMENTS_BEFORE}}% | {{STATEMENTS_AFTER}}% | {{STATEMENTS_CHANGE}} |

### Coverage by Area

| Area | Coverage | Target | Status |
|------|----------|--------|--------|
| Auth/Security | {{AUTH_COVERAGE}}% | 90% | {{AUTH_STATUS}} |
| API Endpoints | {{API_COVERAGE}}% | 80% | {{API_STATUS}} |
| Business Logic | {{BUSINESS_COVERAGE}}% | 80% | {{BUSINESS_STATUS}} |
| UI Components | {{UI_COVERAGE}}% | 70% | {{UI_STATUS}} |
| Utilities | {{UTILS_COVERAGE}}% | 60% | {{UTILS_STATUS}} |

---

## Failures

### Fixed Failures

| # | File | Line | Error | Category | Retries |
|---|------|------|-------|----------|---------|
{{#FIXED_FAILURES}}
| {{INDEX}} | {{FILE}} | {{LINE}} | {{ERROR}} | {{CATEGORY}} | {{RETRIES}} |
{{/FIXED_FAILURES}}

### Blocked Failures

| # | File | Line | Error | Category | Reason | Action Required |
|---|------|------|-------|----------|--------|-----------------|
{{#BLOCKED_FAILURES}}
| {{INDEX}} | {{FILE}} | {{LINE}} | {{ERROR}} | {{CATEGORY}} | {{REASON}} | {{ACTION}} |
{{/BLOCKED_FAILURES}}

---

## Visual Regression (if applicable)

| Metric | Value |
|--------|-------|
| **Screenshots Compared** | {{VISUAL_COMPARED}} |
| **Matched** | {{VISUAL_MATCHED}} |
| **Changed** | {{VISUAL_CHANGED}} |
| **New (no baseline)** | {{VISUAL_NEW}} |

### Visual Changes Detected

{{#VISUAL_CHANGES}}
- **{{COMPONENT}}**: {{DESCRIPTION}}
  - Screenshot: {{SCREENSHOT_PATH}}
  - Approved: {{APPROVED}}
{{/VISUAL_CHANGES}}

---

## Performance Metrics

| Test Suite | Time | Trend |
|------------|------|-------|
| Unit Tests | {{UNIT_TIME}} | {{UNIT_TREND}} |
| Integration Tests | {{INT_TIME}} | {{INT_TREND}} |
| E2E Tests | {{E2E_TIME}} | {{E2E_TREND}} |
| **Total** | {{TOTAL_TIME}} | {{TOTAL_TREND}} |

---

## Recommendations

### Immediate Actions

{{#IMMEDIATE_ACTIONS}}
1. {{ACTION}}
{{/IMMEDIATE_ACTIONS}}

### Coverage Improvements

{{#COVERAGE_IMPROVEMENTS}}
- [ ] {{FILE}}: {{CURRENT}}% → {{TARGET}}% ({{PRIORITY}})
{{/COVERAGE_IMPROVEMENTS}}

### Flaky Tests to Stabilize

{{#FLAKY_TESTS}}
- [ ] {{FILE}}:{{LINE}} - {{DESCRIPTION}}
{{/FLAKY_TESTS}}

### Technical Debt

{{#TECH_DEBT}}
- [ ] {{ITEM}}
{{/TECH_DEBT}}

---

## Actions Log

| Time | Action |
|------|--------|
{{#ACTIONS_LOG}}
| {{TIME}} | {{ACTION}} |
{{/ACTIONS_LOG}}

---

## Environment

| Component | Version |
|-----------|---------|
| Node | {{NODE_VERSION}} |
| npm/pnpm/yarn | {{PKG_MANAGER_VERSION}} |
| Test Runner | {{TEST_RUNNER_VERSION}} |
| E2E Runner | {{E2E_RUNNER_VERSION}} |
| OS | {{OS}} |

---

## Next Steps

1. {{NEXT_STEP_1}}
2. {{NEXT_STEP_2}}
3. {{NEXT_STEP_3}}

---

*Report generated by regression-testing skill*
*Timestamp: {{TIMESTAMP}}*
