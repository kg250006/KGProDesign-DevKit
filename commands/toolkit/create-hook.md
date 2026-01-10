---
description: "[KGP] Configure Claude Code hooks for event-driven automation (PreToolUse, PostToolUse, Stop, SessionStart, etc.)"
argument-hint: [hook type and description]
allowed-tools: [Read, Write, Glob, AskUserQuestion, WebSearch]
---

<objective>
Create a Claude Code hook for: $ARGUMENTS

Hooks allow event-driven automation that triggers on specific Claude Code events.
</objective>

<hook_types>
**Available Hook Types:**

| Type | When Triggered | Use Cases |
|------|----------------|-----------|
| `PreToolUse` | Before any tool executes | Validate, log, block |
| `PostToolUse` | After tool completes | Log, notify, chain |
| `Stop` | When Claude finishes | Summarize, cleanup |
| `SessionStart` | When session begins | Initialize, load context |
| `UserPromptSubmit` | When user sends message | Validate, preprocess |
</hook_types>

<process>

<step_1_clarify>
**Clarify Hook Requirements**

If not specified, ask:
- What event should trigger the hook?
- What action should it take?
- Should it block or just log?
</step_1_clarify>

<step_2_design>
**Design Hook**

Choose implementation type:

**Command-based Hook:**
Runs a shell command on trigger.
```json
{
  "event": "PostToolUse",
  "matcher": {
    "tool": "Bash"
  },
  "command": "echo 'Command executed' >> ~/claude-logs.txt"
}
```

**LLM-based Hook:**
Sends to Claude for processing.
```json
{
  "event": "Stop",
  "matcher": {},
  "llm": {
    "prompt": "Summarize what was accomplished in this session."
  }
}
```
</step_2_design>

<step_3_generate>
**Generate Hook Configuration**

Create hook file:

```json
{
  "hooks": [
    {
      "event": "[event type]",
      "matcher": {
        // Optional filters
        "tool": "ToolName",
        "content": "pattern"
      },
      "command": "shell command here",
      // OR
      "llm": {
        "prompt": "LLM prompt here"
      }
    }
  ]
}
```
</step_3_generate>

<step_4_save>
**Save Hook**

Save to: `.claude/hooks/[name].json`

Or add to existing hooks file.
</step_4_save>

<step_5_test>
**Test Hook**

Provide test instructions:
1. Trigger the event manually
2. Verify hook executes
3. Check expected behavior
</step_5_test>

</process>

<examples>
**Log all Bash commands:**
```json
{
  "hooks": [{
    "event": "PostToolUse",
    "matcher": { "tool": "Bash" },
    "command": "echo \"$(date): $CLAUDE_TOOL_OUTPUT\" >> ~/.claude/bash-log.txt"
  }]
}
```

**Notify on session end:**
```json
{
  "hooks": [{
    "event": "Stop",
    "command": "terminal-notifier -message 'Claude session ended'"
  }]
}
```

**Validate before file write:**
```json
{
  "hooks": [{
    "event": "PreToolUse",
    "matcher": { "tool": "Write" },
    "llm": {
      "prompt": "Review this file write for security issues. Block if problematic."
    }
  }]
}
```
</examples>

<output_format>
## Hook Created

**File:** `.claude/hooks/[name].json`
**Event:** [event type]
**Action:** [what it does]

**Test by:**
1. [How to trigger]
2. [What to expect]
</output_format>

<success_criteria>
- Hook file created with valid JSON
- Event type specified
- Matcher configured if needed
- Action defined (command or LLM)
</success_criteria>
