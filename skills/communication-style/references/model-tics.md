# Model Tics — the L3 banned-phrase layer

This is the only file in the skill that may name a model. Isolating model-specific strings
here is what lets a generated ruleset survive a model switch without a rewrite.

The source prompt this skill derives from was written for one model family, and its banned
list reflects that. A list of phrases a model never says costs tokens and earns nothing.

<neutral>

Always merged into every generated file, regardless of which model the user runs.

These are conversational filler that current assistant models produce across the board:

- "Great question"
- "You're absolutely right"
- "Let me break this down"
- "It's worth noting that"
- "In summary" or "To summarize", used as a closing paragraph on an already-short reply
- "I'd be happy to"
- "Certainly!" or "Absolutely!" as an opener
- "I hope this helps"
- "Feel free to let me know if"

</neutral>

<overlay name="opus">

Observed and documented in the source material. Merge when the user runs this family.

- "load-bearing"
- "worth stating plainly"
- "here's the honest truth"
- "the real tension"
- "carry the argument"

</overlay>

<overlay name="sonnet">

Empty by default. Populate from observation, never from guessing.

</overlay>

<overlay name="haiku">

Empty by default. Populate from observation, never from guessing.

</overlay>

<overlay name="fable">

Empty by default. Populate from observation, never from guessing.

The source material notes explicitly that this family does not use the `opus` list, which is
the clearest evidence that overlays must not be merged indiscriminately.

</overlay>

<overlay name="other">

Free-form. Populated during the wizard from whatever the user has actually noticed, on
whatever model they run. Any model not listed above uses this plus `neutral`.

</overlay>

<merge_rule>

1. Start with `neutral`. It is never optional.
2. Add each overlay the user selected in wizard step 3.
3. Deduplicate, preserving first-seen order.
4. Render as a single `## Phrases to avoid` section in the artifact.
5. Append this closing line verbatim:

   `Add phrases you actually observe. Do not add guesses.`

That line matters. It is the mechanism by which the list stays accurate over time, and it
tells the reader the list is theirs to extend.

</merge_rule>

<guidance>

**Why the overlays start empty.**

Filling a model's overlay by predicting which phrases it overuses produces rules that ban
strings the model never emits. Every such line is loaded into context on every session and
blocks nothing. The `opus` overlay is populated only because those five phrases were
observed and written down in the source material.

**When to add a phrase.**

Add it when you have seen it twice from the same model in your own sessions. One occurrence
is noise.

**On switching models.**

The rest of the ruleset carries over unchanged. Re-run `/KGP:comm-style tweak` and change
the overlay selection. If the artifact needs any other edit to work on the new model, the
layer separation has failed and that is a bug in this skill, not in the artifact.

</guidance>
