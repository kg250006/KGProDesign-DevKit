# Conflict Resolution — detect before writing

A generic communication prompt will contradict rules a repo already has. These five
conflicts are not hypothetical; each was hit when the source ruleset was first dropped into
a real codebase. Detect them, show them to the user, and write the resolution into layer L4.

Unresolved conflicts block the install. Silently overriding a repo's existing rule is worse
than not installing at all.

<conflict_catalogue>

| ID | Conflict | Detection | Resolution |
|----|----------|-----------|------------|
| T1 | Commit-format rules, including co-author trailers | `grep -riE "co-authored-by\|commit message\|conventional commit" CLAUDE.md .claude/ 2>/dev/null` | The repo rule and the harness win. The artifact must state that it does not govern commits. Never carry a co-author ban across from the source prompt. |
| T2 | "Requested scope only" versus mandated adjacent work | `grep -nE "\b(must\|always\|never\|required)\b" CLAUDE.md` | List each mandated behavior as an explicit carve-out in L4, so the scope rule does not silently cancel it. Mandated adjacent work is not scope creep. |
| T3 | Prose rules leaking into code, templates, and generated docs | Always applies. No detection needed. | The artifact opens with a scope statement naming what it does not govern. Non-negotiable. |
| T4 | Reference codes colliding with ticket ids | `git log --oneline -200 \| grep -oE '[A-Z]{2,6}-[0-9]+' \| head -1 \| cut -d- -f1`, then `ls .github/ISSUE_TEMPLATE 2>/dev/null` | Reserve the discovered prefix. Codes may never reuse it. Write the reservation into the artifact's reference-codes section. |
| T5 | "Evidence" undefined | Read `package.json` scripts, then `pyproject.toml`, `Makefile`, `Cargo.toml`. Check `test -d PRPs`. | Bind evidence to the concrete commands found. If `PRPs/` exists, bind to the KGP PRP gates instead. A rule saying "no claim without evidence" is empty until the checks are named. |

</conflict_catalogue>

<detection_details>

**T2 is the noisiest detector.** A large CLAUDE.md can contain dozens of `must` and `always`
lines, most of which are coding rules with no bearing on reply scope. Filter to lines that
mandate an *action taken alongside the requested work*: updating docs, deleting replaced
code, logging lessons, auto-committing. Ignore lines that constrain how code is written.

**T4 returns nothing on repos using conventional commits.** That is a valid result, not a
failure. When no prefix is found, omit the reservation line entirely rather than writing
"none reserved", which spends a line to say nothing.

**T5 precedence.** If both a package manifest and `PRPs/` exist, list both: the manifest
commands are the fast gate, the PRP promise tokens are the completion gate.

</detection_details>

<pre_install_questions>

Four questions to answer before writing anything. They map onto the wizard's steps.

**Q1 — What does it contradict?**
Read the repo's CLAUDE.md first. Every "never" and "always" in the ruleset is a conflict
candidate. Decide which side wins and write the exception down.

**Q2 — What should it not touch?**
Commit messages, PR templates, ticket comments, generated docs. If a format matters to
someone else, scope the ruleset away from it.

**Q3 — What are your completion gates?**
"No claim without evidence" is empty until the checks are named. Type-check, tests, a
browser look. List them so "done" means the same thing every time.

**Q4 — Which phrases does your model actually use?**
The banned list is model-specific. Keep it if you switch models, trim it if you do not. See
`model-tics.md`.

</pre_install_questions>

<resolution_output>

Each resolved conflict becomes **one line** in the artifact's L4 Boundaries section. Not a
paragraph. The reasoning stays in this file; only the rule ships.

Example, from a T2 resolution:

```
- Mandated adjacent work stays required: update CHANGELOG.md on any version bump.
```

If a conflict cannot be resolved because the user does not answer, report it and stop. Do
not install a ruleset that contradicts a rule the repo already enforces.

</resolution_output>
