---
name: doc-gen-human-verification
description: >
  Two-tier verification sub-skill for the doc-gen pipeline. Determines whether
  a proposed change is BLOCKING (new taxonomy — requires human approval) or
  NON-BLOCKING (generated content — proceeds automatically). Manages the
  blocking interaction flow when taxonomy changes are needed.
---

# Doc-Gen — Human Verification

You are a sub-skill. You are invoked by other doc-gen skills, not by the user directly. Your job is to determine whether a proposed change requires human approval (BLOCKING) or can proceed automatically (NON-BLOCKING), and to manage the blocking interaction when needed.

You do not generate content. You do not write pages or edges. You only gate taxonomy changes and return a structured result to the caller.

---

## MCP Tools Used

| Tool | Purpose |
|------|---------|
| `knowledge_get_schema` | Retrieve valid tags and types from the Vault registry |
| `knowledge_resolve_context` | Check whether a repo/service is already known in Vault |
| `knowledge_registry_add` | Register a new value after user approval |

---

## Invocation Pattern

Calling skills invoke this sub-skill like this:

```
Use the doc-gen-human-verification skill to check:
  action: "propose_tag" | "propose_service" | "propose_edge_type" | "write_content" | "update_content"
  value: {the proposed value}
  context: {why this is being proposed — e.g. "scanner found tag 'data-pipeline' in repo docs"}
  fallback: {what to do if rejected — one of: skip | use_existing | abort}
```

All five fields are required. If `fallback` is omitted, default to `skip`.

---

## Tier Detection

When a calling skill passes an action, this skill determines the processing tier before doing any Vault lookup:

| Action | Vault Check Required | Tier if Value Unknown | Tier if Value Known |
|--------|---------------------|-----------------------|---------------------|
| `propose_tag` | `knowledge_get_schema` — check valid tags list | BLOCKING | Pass-through (return `approved` immediately) |
| `propose_service` | `knowledge_resolve_context` — check if repo is known | BLOCKING | Pass-through (return `approved` immediately) |
| `propose_edge_type` | Hardcoded list check — no Vault call needed | BLOCKING | Pass-through (return `approved` immediately) |
| `write_content` | None | NON-BLOCKING | NON-BLOCKING |
| `update_content` | None | NON-BLOCKING | NON-BLOCKING |

**Standard edge types (hardcoded):** `PART_OF`, `DEPENDS_ON`, `SENDS_TO`, `DOCS`, `RELATED`

If the action is `write_content` or `update_content`, skip all registry checks and return `non_blocking` immediately. No user interaction occurs.

---

## Execution Flow

### Step 1: Classify the Action

If `action` is `write_content` or `update_content`:
- Return `non_blocking` immediately. Stop here.

If `action` is `propose_tag`, `propose_service`, or `propose_edge_type`:
- Proceed to Step 2.

---

### Step 2: Registry Check

Perform the appropriate registry check based on action type.

#### For `propose_tag`

Call `knowledge_get_schema`. Inspect the returned schema for a `tags` field (or equivalent valid-values list). Check whether `value` (case-insensitive) already appears in the list.

- If YES: the tag is already registered. Return `approved` immediately. Stop here.
- If NO: proceed to Step 3 (BLOCKING interaction).
- If the call fails (tool error, timeout): proceed to Step 3 with a note that registry check failed. Annotate the blocking prompt accordingly (see Edge Cases).

#### For `propose_service`

Call `knowledge_resolve_context` with the `value` as the repo/service name.

- If a result is returned (entry point found): the service is already known. Return `approved` immediately. Stop here.
- If no result is returned (not found): proceed to Step 3 (BLOCKING interaction).
- If the call fails: proceed to Step 3 with registry-check-failed annotation.

#### For `propose_edge_type`

Check `value` (case-insensitive) against the hardcoded list: `[PART_OF, DEPENDS_ON, SENDS_TO, DOCS, RELATED]`.

- If match found: return `approved` immediately. Stop here.
- If no match: proceed to Step 3 (BLOCKING interaction). No Vault call is needed.

---

### Step 3: BLOCKING Interaction

Surface the decision to the user using this exact format:

```
[DOC-GEN] Taxonomy change required

Type:     {New Tag | New Service | New Edge Type}
Proposed: "{value}"
Context:  {context from caller}
Fallback: if rejected — {fallback}

Options:
  (1) Approve  — add "{value}" to the registry
  (2) Reject   — skip this item, apply fallback: {fallback}
  (3) Modify   — use a different value (enter it below)

Enter choice (1/2/3):
```

Wait for the user to respond. Do not proceed until a response is received.

---

### Step 4: Handle User Response

#### Response (1) — Approve

1. Call `knowledge_registry_add` to register `value` in the appropriate registry category:
   - For `propose_tag`: category is `tag`
   - For `propose_service`: category is `service`
   - For `propose_edge_type`: category is `edge_type`
2. If `knowledge_registry_add` succeeds: return `approved`.
3. If `knowledge_registry_add` fails: inform the user that registration failed, then return `approved_unregistered` with a warning note. The calling skill should still proceed but should flag that manual registry entry is needed.

#### Response (2) — Reject

Return `rejected` with the fallback action from the original invocation. No registry call is made.

#### Response (3) — Modify

1. Prompt the user: `Enter the value to use instead:`
2. Capture the modified value.
3. Re-run the registry check (Step 2) against the modified value.
   - If the modified value is already registered: return `approved_with_modification: {modified_value}`.
   - If the modified value is also not registered: surface the BLOCKING prompt again (Step 3) but now for the modified value. Do not recurse more than once — if the second value is also unregistered, offer only options (1) Approve or (2) Reject (no further modify loop).
4. If the user approves the modified value via `knowledge_registry_add`: return `approved_with_modification: {modified_value}`.
5. If the user rejects the modified value: return `rejected` with the original fallback.

---

## Return Value Format

All return values are emitted as the skill's final text response. Use exactly this format:

```
## Human Verification Result

action:  {propose_tag | propose_service | propose_edge_type | write_content | update_content}
value:   {the original value from the caller}
outcome: {approved | rejected | non_blocking | approved_with_modification | approved_unregistered}
effective_value: {value or modified_value — always present}
fallback_applied: {true | false}
notes:   {optional — registry failure warnings, modification trail, etc.}
```

**Outcome values and their meaning for callers:**

| Outcome | Meaning | Caller action |
|---------|---------|---------------|
| `approved` | Value exists in registry or user approved it | Proceed using `effective_value` |
| `approved_with_modification` | User substituted a different value | Proceed using `effective_value` (the modified value) |
| `approved_unregistered` | User approved but `knowledge_registry_add` failed | Proceed using `effective_value`; flag manual registry entry needed |
| `rejected` | User rejected the change | Apply the `fallback` action from the original invocation |
| `non_blocking` | Action was `write_content` or `update_content` | Proceed with write; tag content with `auto-generated: true` and confidence score |

---

## Non-Blocking Content Tagging

When returning `non_blocking`, the calling skill is responsible for writing the content. This skill does not write content directly. The calling skill MUST apply these attributes to any page or edge it writes:

- `auto-generated: true`
- `confidence: {score}` — the confidence score the calling skill computed for this content

This skill does not validate or enforce these attributes. They are the caller's responsibility.

---

## Edge Cases

### Registry check fails (tool error or timeout)

Proceed to the BLOCKING interaction (Step 3) with the prompt annotated:

```
[DOC-GEN] Taxonomy change required

Type:     {New Tag | New Service | New Edge Type}
Proposed: "{value}"
Context:  {context from caller}
Fallback: if rejected — {fallback}

WARNING: Registry check failed — could not confirm whether this value is
already registered. Proceeding with manual review.

Options:
  (1) Approve  — add "{value}" to the registry (or it may already exist)
  (2) Reject   — skip this item, apply fallback: {fallback}
  (3) Modify   — use a different value (enter it below)

Enter choice (1/2/3):
```

If the user chooses (1) and `knowledge_registry_add` also fails, return `approved_unregistered`.

### User enters invalid choice at the prompt

If the user enters anything other than `1`, `2`, or `3`, re-display the prompt with:

```
Invalid choice. Please enter 1, 2, or 3.
```

Repeat up to 3 times. If still no valid choice after 3 attempts, treat as (2) Reject and return `rejected` with fallback. Include a note in the result: `notes: "max prompt retries reached — defaulted to reject"`.

### User enters blank or whitespace-only value for Modify

If the user enters a blank value after choosing option (3), prompt once more:

```
Value cannot be blank. Enter the value to use instead (or enter "cancel" to reject):
```

If blank again or user enters `cancel`, return `rejected` with the original fallback.

### Caller provides an unrecognized action

If `action` is not one of the five recognized values (`propose_tag`, `propose_service`, `propose_edge_type`, `write_content`, `update_content`), return immediately with:

```
## Human Verification Result

action:  {unknown_value}
value:   {value}
outcome: error
effective_value: {value}
fallback_applied: false
notes:   "Unrecognized action '{action}'. Valid actions: propose_tag, propose_service, propose_edge_type, write_content, update_content."
```

Do not interact with the user for unrecognized actions.

### Caller omits required fields

If `action` or `value` is missing from the invocation, return immediately with an error outcome and a note describing which fields are missing. If `context` is missing, default to `"No context provided"` and continue. If `fallback` is missing, default to `skip` and continue.

---

## Constraints

- Do NOT write pages, edges, or any Vault content. Writing is the calling skill's responsibility.
- Do NOT invoke Anvil. This skill does not touch task state.
- Do NOT take more than 2 Vault tool calls per invocation (1 registry check + 1 registry_add at most).
- Do NOT loop the modify flow more than once. After one modify-and-recheck cycle, offer only Approve or Reject.
- ALWAYS wait for user input on BLOCKING checks. Do not infer or assume a response.
- ALWAYS return the result in the exact format specified in "Return Value Format".
