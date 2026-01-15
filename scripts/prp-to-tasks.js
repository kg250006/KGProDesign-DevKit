#!/usr/bin/env node
/**
 * prp-to-tasks.js - Extract tasks from PRP XML structure
 *
 * Usage: node prp-to-tasks.js <prp-file.md>
 * Output: JSON array of task objects to stdout
 *
 * PATTERN: Follows hooks/stop-hook.js for Node.js script conventions
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

// Extract tasks using regex
// PATTERN: Match <task id="N.N" ...>...</task> blocks
// Handle various attribute orders and multiline content
const taskRegex = /<task\s+id="([^"]+)"[^>]*agent="([^"]+)"[^>]*>([\s\S]*?)<\/task>/g;

const tasks = [];
let match;

while ((match = taskRegex.exec(content)) !== null) {
  const taskId = match[1];
  const agent = match[2];
  const taskContent = match[3];

  // Extract description from <description> tag
  const descMatch = taskContent.match(/<description>([\s\S]*?)<\/description>/);
  const description = descMatch ? descMatch[1].trim() : '';

  // Extract acceptance criteria
  const criteriaMatch = taskContent.match(/<acceptance-criteria>([\s\S]*?)<\/acceptance-criteria>/);
  let criteria = '';
  if (criteriaMatch) {
    // Extract individual criterion elements
    const criterionRegex = /<criterion>([^<]+)<\/criterion>/g;
    const criteriaList = [];
    let critMatch;
    while ((critMatch = criterionRegex.exec(criteriaMatch[1])) !== null) {
      criteriaList.push('- ' + critMatch[1].trim());
    }
    criteria = criteriaList.join('\n');
  }

  // Extract files
  const filesMatch = taskContent.match(/<files>([\s\S]*?)<\/files>/);
  let files = '';
  if (filesMatch) {
    const fileRegex = /<file\s+action="([^"]+)">([^<]+)<\/file>/g;
    const fileList = [];
    let fileMatch;
    while ((fileMatch = fileRegex.exec(filesMatch[1])) !== null) {
      fileList.push(`- [${fileMatch[1]}] ${fileMatch[2].trim()}`);
    }
    files = fileList.join('\n');
  }

  // Extract pseudocode
  const pseudoMatch = taskContent.match(/<pseudocode>([\s\S]*?)<\/pseudocode>/);
  const pseudocode = pseudoMatch ? pseudoMatch[1].trim() : '';

  // Extract effort and value if present
  const effortMatch = match[0].match(/effort="([^"]+)"/);
  const valueMatch = match[0].match(/value="([^"]+)"/);

  tasks.push({
    id: taskId,
    agent: agent,
    description: description,
    acceptance_criteria: criteria,
    files: files,
    pseudocode: pseudocode,
    effort: effortMatch ? effortMatch[1] : 'M',
    value: valueMatch ? valueMatch[1] : 'M'
  });
}

// CRITICAL: Also extract validation commands
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

// Output JSON structure
const output = {
  name: prpName,
  goal: goal,
  tasks: tasks,
  validation: validationCommands,
  total: tasks.length
};

console.log(JSON.stringify(output, null, 2));
