#!/usr/bin/env node
/**
 * prp-to-tasks.js - Extract tasks from PRP XML or Markdown structure
 *
 * Usage: node prp-to-tasks.js <prp-file.md>
 * Output: JSON array of task objects to stdout
 *
 * PATTERN: Follows hooks/stop-hook.js for Node.js script conventions
 *
 * Supports three formats:
 * Format A (XML attributes): <task id="1.1" agent="backend-engineer" effort="M" value="H">
 * Format B (XML nested):     <task id="1.1"><metadata><agent>backend-engineer</agent>...</metadata>
 * Format C (Markdown):       ## Task 1.1: Title \n ### Description \n ...
 */

const fs = require('fs');
const path = require('path');

// Get PRP file path from command line
const prpFile = process.argv[2];

// CRITICAL: Validate input
if (!prpFile) {
  console.error('Usage: node prp-to-tasks.js <prp-file.md>');
  process.exit(1);
}

// Check file exists
if (!fs.existsSync(prpFile)) {
  console.error(`Error: PRP file not found: ${prpFile}`);
  process.exit(1);
}

// Read PRP content
const content = fs.readFileSync(prpFile, 'utf8');

const tasks = [];

// ============================================================================
// FORMAT A & B: Extract XML tasks
// ============================================================================
const taskRegex = /<task\s+id="([^"]+)"[^>]*>([\s\S]*?)<\/task>/g;
let match;

while ((match = taskRegex.exec(content)) !== null) {
  const taskId = match[1];
  const taskContent = match[2];
  const fullTaskTag = match[0];

  // Extract agent - try attribute first, then nested metadata
  let agent = '';
  const agentAttrMatch = fullTaskTag.match(/<task[^>]*agent="([^"]+)"/);
  if (agentAttrMatch) {
    agent = agentAttrMatch[1];
  } else {
    // Try nested <metadata><agent> format
    const agentNestedMatch = taskContent.match(/<metadata>[\s\S]*?<agent>([^<]+)<\/agent>/);
    if (agentNestedMatch) {
      agent = agentNestedMatch[1].trim();
    }
  }

  // Extract effort - try attribute first, then nested metadata
  let effort = 'M';
  const effortAttrMatch = fullTaskTag.match(/effort="([^"]+)"/);
  if (effortAttrMatch) {
    effort = effortAttrMatch[1];
  } else {
    const effortNestedMatch = taskContent.match(/<effort>([^<]+)<\/effort>/);
    if (effortNestedMatch) {
      effort = effortNestedMatch[1].trim();
    }
  }

  // Extract value - try attribute first, then nested metadata
  let value = 'M';
  const valueAttrMatch = fullTaskTag.match(/value="([^"]+)"/);
  if (valueAttrMatch) {
    value = valueAttrMatch[1];
  } else {
    const valueNestedMatch = taskContent.match(/<value>([^<]+)<\/value>/);
    if (valueNestedMatch) {
      value = valueNestedMatch[1].trim();
    }
  }

  // Extract timeout hint - try attribute first, then nested metadata
  let timeout = 'default';
  const timeoutAttrMatch = fullTaskTag.match(/timeout="([^"]+)"/);
  if (timeoutAttrMatch) {
    timeout = timeoutAttrMatch[1];
  } else {
    const timeoutNestedMatch = taskContent.match(/<timeout>([^<]+)<\/timeout>/);
    if (timeoutNestedMatch) {
      timeout = timeoutNestedMatch[1].trim();
    }
  }

  // Extract iterations hint - try attribute first, then nested metadata
  let iterations = 'default';
  const iterationsAttrMatch = fullTaskTag.match(/iterations="([^"]+)"/);
  if (iterationsAttrMatch) {
    iterations = iterationsAttrMatch[1];
  } else {
    const iterationsNestedMatch = taskContent.match(/<iterations>([^<]+)<\/iterations>/);
    if (iterationsNestedMatch) {
      iterations = iterationsNestedMatch[1].trim();
    }
  }

  // Extract description from <description> tag
  const descMatch = taskContent.match(/<description>([\s\S]*?)<\/description>/);
  const description = descMatch ? descMatch[1].trim() : '';

  // Extract acceptance criteria - handle both formats
  const criteriaMatch = taskContent.match(/<acceptance-criteria>([\s\S]*?)<\/acceptance-criteria>/);
  let criteria = '';
  if (criteriaMatch) {
    const criterionRegex = /<criterion[^>]*>([^<]*(?:<[^/][^<]*)*)<\/criterion>/g;
    const criteriaList = [];
    let critMatch;
    while ((critMatch = criterionRegex.exec(criteriaMatch[1])) !== null) {
      const critText = critMatch[1].trim();
      if (critText) {
        criteriaList.push('- ' + critText);
      }
    }
    // Also try to extract test attributes for validation
    const testRegex = /<criterion[^>]*test="([^"]+)"[^>]*>/g;
    let testMatch;
    while ((testMatch = testRegex.exec(criteriaMatch[1])) !== null) {
      criteriaList.push('- [TEST] ' + testMatch[1]);
    }
    criteria = criteriaList.join('\n');
  }

  // Extract files - handle both formats
  const filesMatch = taskContent.match(/<files>([\s\S]*?)<\/files>/);
  let files = '';
  if (filesMatch) {
    const fileList = [];
    // Try Format B first (path as attribute)
    const fileRegexB = /<file\s+action="([^"]+)"\s+path="([^"]+)"[^>]*>/g;
    let fileMatchB;
    while ((fileMatchB = fileRegexB.exec(filesMatch[1])) !== null) {
      fileList.push(`- [${fileMatchB[1]}] ${fileMatchB[2].trim()}`);
    }
    // If no matches, try Format A (path as content)
    if (fileList.length === 0) {
      const fileRegexA = /<file\s+action="([^"]+)"[^>]*>([^<]+)<\/file>/g;
      let fileMatchA;
      while ((fileMatchA = fileRegexA.exec(filesMatch[1])) !== null) {
        fileList.push(`- [${fileMatchA[1]}] ${fileMatchA[2].trim()}`);
      }
    }
    files = fileList.join('\n');
  }

  // Extract pseudocode
  const pseudoMatch = taskContent.match(/<pseudocode>([\s\S]*?)<\/pseudocode>/);
  const pseudocode = pseudoMatch ? pseudoMatch[1].trim() : '';

  // Extract dependencies if present
  const depsMatch = taskContent.match(/<dependencies>([^<]+)<\/dependencies>/);
  const dependencies = depsMatch ? depsMatch[1].trim() : '';

  // Only add task if we found meaningful content
  if (taskId && (description || agent)) {
    // Auto-detect extended timeout for test tasks if not explicitly set
    if (timeout === 'default') {
      const descLower = description.toLowerCase();
      const testKeywords = [
        'run test', 'execute test', 'test suite',
        'npm test', 'pytest', 'jest', 'vitest', 'playwright', 'cypress',
        'e2e', 'end-to-end', 'integration test',
        'npm run build', 'cargo build', 'gradle build',
        'database migration', 'seed database',
        'full validation', 'run all test',
        // E2E and verification keywords
        'verify all pass', 'run all tests', 'spec.ts', 'spec.js',
        'test coverage', 'verify tests', 'execute tests', 'all tests pass',
        'verification', 'run the tests', 'execute the tests'
      ];
      if (testKeywords.some(kw => descLower.includes(kw))) {
        timeout = 'extended';
      }
    }

    tasks.push({
      id: taskId,
      agent: agent,
      description: description,
      acceptance_criteria: criteria,
      files: files,
      pseudocode: pseudocode,
      effort: effort,
      value: value,
      timeout: timeout,
      iterations: iterations,
      dependencies: dependencies
    });
  }
}

// ============================================================================
// FORMAT C: Extract Markdown tasks (if no XML tasks found)
// ============================================================================
if (tasks.length === 0) {
  // Pattern: ## Task X.X: Title or ### Task X.X: Title
  const mdTaskRegex = /^#{2,3}\s+Task\s+(\d+(?:\.\d+)?):?\s*(.*)$/gm;
  const mdMatches = [...content.matchAll(mdTaskRegex)];

  for (let i = 0; i < mdMatches.length; i++) {
    const mdMatch = mdMatches[i];
    const taskId = mdMatch[1];
    const taskTitle = mdMatch[2].trim();
    const startIdx = mdMatch.index + mdMatch[0].length;

    // Find the end of this task section (next ## Task or end of file)
    let endIdx = content.length;
    if (i + 1 < mdMatches.length) {
      endIdx = mdMatches[i + 1].index;
    } else {
      // Check for other ## headers that would end the task
      const nextHeader = content.slice(startIdx).match(/\n## [^T]/);
      if (nextHeader) {
        endIdx = startIdx + nextHeader.index;
      }
    }

    const taskContent = content.slice(startIdx, endIdx);

    // Extract description from ### Description section
    let description = taskTitle;
    const descSection = taskContent.match(/###\s*Description\s*\n([\s\S]*?)(?=\n###|\n## |$)/i);
    if (descSection) {
      description = descSection[1].trim();
    }

    // Extract files from ### Files section or markdown table
    let files = '';
    const filesSection = taskContent.match(/###\s*Files[^\n]*\n([\s\S]*?)(?=\n###|\n## |$)/i);
    if (filesSection) {
      // Look for markdown table rows: | `path` | description |
      const tableRows = filesSection[1].matchAll(/\|\s*`?([^`|\n]+)`?\s*\|/g);
      const fileList = [];
      for (const row of tableRows) {
        const filePath = row[1].trim();
        if (filePath && !filePath.match(/^-+$/) && !filePath.match(/^File$/i)) {
          fileList.push(`- [create] ${filePath}`);
        }
      }
      files = fileList.join('\n');
    }

    // Extract implementation/pseudocode from ### Implementation section
    let pseudocode = '';
    const implSection = taskContent.match(/###\s*Implementation\s*\n([\s\S]*?)(?=\n## |$)/i);
    if (implSection) {
      // Extract code blocks
      const codeBlocks = implSection[1].matchAll(/```[\w]*\n([\s\S]*?)```/g);
      const codes = [];
      for (const block of codeBlocks) {
        codes.push(block[1].trim());
      }
      pseudocode = codes.join('\n\n');
    }

    // Extract acceptance criteria from ### Acceptance or ### Validation section
    let criteria = '';
    const acSection = taskContent.match(/###\s*(?:Acceptance|Validation|Success)[^\n]*\n([\s\S]*?)(?=\n###|\n## |$)/i);
    if (acSection) {
      // Look for bullet points or numbered lists
      const bullets = acSection[1].matchAll(/^[\s]*[-*\d.]+\s+(.+)$/gm);
      const criteriaList = [];
      for (const bullet of bullets) {
        criteriaList.push('- ' + bullet[1].trim());
      }
      criteria = criteriaList.join('\n');
    }

    // Try to determine agent from PRP metadata or default
    let agent = '';
    const prpAgentMatch = content.match(/<agent>([^<]+)<\/agent>/);
    if (prpAgentMatch) {
      agent = prpAgentMatch[1].trim();
    } else {
      // Default based on task content keywords
      if (taskContent.match(/test|spec|coverage/i)) {
        agent = 'KGP:qa-engineer';
      } else if (taskContent.match(/database|model|schema|migration/i)) {
        agent = 'KGP:data-engineer';
      } else if (taskContent.match(/docker|deploy|infrastructure|ci|cd/i)) {
        agent = 'KGP:devops-engineer';
      } else if (taskContent.match(/api|endpoint|service|backend/i)) {
        agent = 'KGP:backend-engineer';
      } else if (taskContent.match(/ui|frontend|component|react/i)) {
        agent = 'KGP:frontend-engineer';
      } else {
        agent = 'KGP:backend-engineer'; // Default
      }
    }

    // Auto-detect extended timeout for test tasks
    let timeout = 'default';
    const descLower = description.toLowerCase();
    const testKeywords = [
      'run test', 'execute test', 'test suite',
      'npm test', 'pytest', 'jest', 'vitest', 'playwright', 'cypress',
      'e2e', 'end-to-end', 'integration test',
      'npm run build', 'cargo build', 'gradle build',
      'database migration', 'seed database',
      // E2E and verification keywords
      'verify all pass', 'run all tests', 'spec.ts', 'spec.js',
      'test coverage', 'verify tests', 'execute tests', 'all tests pass',
      'verification', 'run the tests', 'execute the tests'
    ];
    if (testKeywords.some(kw => descLower.includes(kw))) {
      timeout = 'extended';
    }

    tasks.push({
      id: taskId,
      agent: agent,
      description: description,
      acceptance_criteria: criteria,
      files: files,
      pseudocode: pseudocode.slice(0, 5000), // Limit pseudocode size
      effort: 'M',
      value: 'H',
      timeout: timeout,
      iterations: 'default',
      dependencies: ''
    });
  }
}

// ============================================================================
// FORMAT D: Single-task PRP (has goal/implementation but no discrete tasks)
// ============================================================================
if (tasks.length === 0) {
  // Check if this is a single-task PRP by looking for task reference in metadata
  const taskRefMatch = content.match(/<tasks>([^<]+)<\/tasks>/);
  const goalMatch2 = content.match(/<goal>([\s\S]*?)<\/goal>/);

  if (taskRefMatch && goalMatch2) {
    const taskId = taskRefMatch[1].trim();
    const goalText = goalMatch2[1].trim();

    // Extract files from <files-to-create> or ### File: sections
    let files = '';
    const filesToCreate = content.match(/<files-to-create>([\s\S]*?)<\/files-to-create>/);
    if (filesToCreate) {
      const fileList = [];
      const fileRegex = /<file>([^<]+)<\/file>/g;
      let fileMatch;
      while ((fileMatch = fileRegex.exec(filesToCreate[1])) !== null) {
        fileList.push(`- [create] ${fileMatch[1].trim()}`);
      }
      files = fileList.join('\n');
    }

    // If no XML files, look for ### File: headers
    if (!files) {
      const fileHeaders = content.matchAll(/###\s+File:\s*(.+)$/gm);
      const fileList = [];
      for (const fh of fileHeaders) {
        fileList.push(`- [create] ${fh[1].trim()}`);
      }
      files = fileList.join('\n');
    }

    // Extract acceptance criteria from ## Acceptance Criteria section
    let criteria = '';
    const acSection = content.match(/##\s*Acceptance Criteria\s*\n([\s\S]*?)(?=\n## |$)/i);
    if (acSection) {
      const bullets = acSection[1].matchAll(/^[\s]*[-*]+\s+(.+)$/gm);
      const criteriaList = [];
      for (const bullet of bullets) {
        criteriaList.push('- ' + bullet[1].trim());
      }
      criteria = criteriaList.join('\n');
    }

    // Extract implementation code blocks as pseudocode
    let pseudocode = '';
    const implSection = content.match(/##\s*Implementation\s*\n([\s\S]*?)(?=\n## Acceptance|$)/i);
    if (implSection) {
      const codeBlocks = implSection[1].matchAll(/```[\w]*\n([\s\S]*?)```/g);
      const codes = [];
      for (const block of codeBlocks) {
        if (codes.length < 3) { // Limit to first 3 code blocks
          codes.push(block[1].trim().slice(0, 2000));
        }
      }
      pseudocode = codes.join('\n\n...\n\n');
    }

    // Determine agent
    let agent = 'KGP:backend-engineer';
    if (content.match(/test|spec|coverage/i)) {
      agent = 'KGP:qa-engineer';
    } else if (content.match(/docker|deploy|infrastructure/i)) {
      agent = 'KGP:devops-engineer';
    }

    // Auto-detect extended timeout for test tasks
    let timeout = 'default';
    const goalLower = goalText.toLowerCase();
    const testKeywords = [
      'run test', 'execute test', 'test suite',
      'npm test', 'pytest', 'jest', 'vitest', 'playwright', 'cypress',
      'e2e', 'end-to-end', 'integration test',
      'npm run build', 'cargo build', 'gradle build',
      'database migration', 'seed database',
      // E2E and verification keywords
      'verify all pass', 'run all tests', 'spec.ts', 'spec.js',
      'test coverage', 'verify tests', 'execute tests', 'all tests pass',
      'verification', 'run the tests', 'execute the tests'
    ];
    if (testKeywords.some(kw => goalLower.includes(kw))) {
      timeout = 'extended';
    }

    tasks.push({
      id: taskId,
      agent: agent,
      description: goalText,
      acceptance_criteria: criteria,
      files: files,
      pseudocode: pseudocode.slice(0, 5000),
      effort: 'L', // Single-task PRPs are usually larger
      value: 'H',
      timeout: timeout,
      iterations: 'default',
      dependencies: ''
    });
  }
}

// ============================================================================
// Extract validation commands
// ============================================================================
const validationRegex = /<level[^>]*>\s*<command>([\s\S]*?)<\/command>/g;
const validationCommands = [];
let valMatch;
while ((valMatch = validationRegex.exec(content)) !== null) {
  validationCommands.push(valMatch[1].trim());
}

// Extract goal
const goalMatch = content.match(/<goal>([\s\S]*?)<\/goal>/);
const goal = goalMatch ? goalMatch[1].trim() : '';

// Extract PRP name
const nameMatch = content.match(/<prp\s+name="([^"]+)"/);
const prpName = nameMatch ? nameMatch[1] : path.basename(prpFile, '.md');

// ============================================================================
// Extract research findings (don't reinvent the wheel)
// ============================================================================
const researchFindings = {
  libraries: [],
  patterns: [],
  pitfalls: [],
  references: []
};

// Extract recommended libraries
const librariesMatch = content.match(/<recommended-libraries>([\s\S]*?)<\/recommended-libraries>/);
if (librariesMatch) {
  const libRegex = /<library\s+name="([^"]+)"\s+purpose="([^"]+)"[^>]*>([\s\S]*?)<\/library>/g;
  let libMatch;
  while ((libMatch = libRegex.exec(librariesMatch[1])) !== null) {
    const lib = {
      name: libMatch[1],
      purpose: libMatch[2]
    };
    // Extract rationale
    const rationaleMatch = libMatch[3].match(/<rationale>([^<]+)<\/rationale>/);
    if (rationaleMatch) lib.rationale = rationaleMatch[1].trim();
    // Extract docs URL
    const docsMatch = libMatch[3].match(/<docs-url>([^<]+)<\/docs-url>/);
    if (docsMatch) lib.docsUrl = docsMatch[1].trim();
    // Extract install command
    const installMatch = libMatch[3].match(/<install>([^<]+)<\/install>/);
    if (installMatch) lib.install = installMatch[1].trim();

    researchFindings.libraries.push(lib);
  }
}

// Extract patterns to follow
const patternsMatch = content.match(/<patterns-to-follow>([\s\S]*?)<\/patterns-to-follow>/);
if (patternsMatch) {
  const patternRegex = /<pattern\s+source="([^"]+)"[^>]*>([\s\S]*?)<\/pattern>/g;
  let patMatch;
  while ((patMatch = patternRegex.exec(patternsMatch[1])) !== null) {
    const pattern = { source: patMatch[1] };
    const descMatch = patMatch[2].match(/<description>([^<]+)<\/description>/);
    if (descMatch) pattern.description = descMatch[1].trim();
    const appMatch = patMatch[2].match(/<applicability>([^<]+)<\/applicability>/);
    if (appMatch) pattern.applicability = appMatch[1].trim();
    researchFindings.patterns.push(pattern);
  }
}

// Extract pitfalls to avoid
const pitfallsMatch = content.match(/<pitfalls-to-avoid>([\s\S]*?)<\/pitfalls-to-avoid>/);
if (pitfallsMatch) {
  const pitfallRegex = /<pitfall\s+source="([^"]+)"[^>]*>([\s\S]*?)<\/pitfall>/g;
  let pitMatch;
  while ((pitMatch = pitfallRegex.exec(pitfallsMatch[1])) !== null) {
    const pitfall = { source: pitMatch[1] };
    const issueMatch = pitMatch[2].match(/<issue>([^<]+)<\/issue>/);
    if (issueMatch) pitfall.issue = issueMatch[1].trim();
    const mitMatch = pitMatch[2].match(/<mitigation>([^<]+)<\/mitigation>/);
    if (mitMatch) pitfall.mitigation = mitMatch[1].trim();
    researchFindings.pitfalls.push(pitfall);
  }
}

// Extract documentation references
const refsMatch = content.match(/<documentation-references>([\s\S]*?)<\/documentation-references>/);
if (refsMatch) {
  const refRegex = /<reference\s+url="([^"]+)"\s+topic="([^"]+)"[^>]*>([\s\S]*?)<\/reference>/g;
  let refMatch;
  while ((refMatch = refRegex.exec(refsMatch[1])) !== null) {
    const ref = { url: refMatch[1], topic: refMatch[2], keyPoints: [] };
    const pointRegex = /<point>([^<]+)<\/point>/g;
    let pointMatch;
    while ((pointMatch = pointRegex.exec(refMatch[3])) !== null) {
      ref.keyPoints.push(pointMatch[1].trim());
    }
    researchFindings.references.push(ref);
  }
}

// Check if we have any research findings
const hasResearch = researchFindings.libraries.length > 0 ||
                    researchFindings.patterns.length > 0 ||
                    researchFindings.pitfalls.length > 0 ||
                    researchFindings.references.length > 0;

// Output JSON structure
const output = {
  name: prpName,
  goal: goal,
  tasks: tasks,
  validation: validationCommands,
  total: tasks.length,
  research: hasResearch ? researchFindings : null
};

console.log(JSON.stringify(output, null, 2));
