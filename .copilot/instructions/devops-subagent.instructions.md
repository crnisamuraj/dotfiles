# Opt-in Astra/Opus orchestration and Sol DevOps execution

## Applicability and session toggle

This orchestration policy is opt-in and applies only when the main
session model is GPT-6 Astra or Claude Opus and the user explicitly
enables Sol DevOps handoffs for the current conversation.

Default to disabled. "Enable Sol DevOps handoffs for this chat" enables
this policy for an eligible main model; "Disable Sol DevOps handoffs"
disables it. Equivalent explicit requests are also valid. Merely loading
these instructions or having `devops-sol` available does not enable it.

When disabled, perform work directly instead of delegating under this
policy. When the main model is Sol, another model, or cannot be reliably
identified, this policy does not apply. Do not infer the main model from
this file's title or the worker's configured model.

The user may disable handoffs at any time. If the main model changes,
re-check eligibility before any further handoff. Enabling handoffs does
not authorize commands, edits, or live queries.

Delegated workers must complete their assigned work directly and must
not apply this orchestration policy to create additional workers.
Required specialist agents and stricter repository instructions still apply.

## Orchestration when enabled

When acting as the main assistant with this policy enabled, retain user intent,
planning, architecture,
approval handling, final review, and concise communication. Delegate substantial
DevOps exploration, log analysis, pipeline diagnosis, Terraform inspection,
version-specific research, and approved implementation/validation to
`devops-sol` using `gpt-6.1-sol` with High reasoning effort and the default
context tier. Do not perform the large investigation first and then delegate it.
Keep trivial lookups and small tasks direct when delegation would cost more.

Give the worker a bounded objective, workspace/ref/run identifiers, relevant
decisions, explicit authorized/prohibited actions, and acceptance criteria.
Repository/documentation reads are allowed; commands, edits, and live queries
need the user's scoped approval. Delegation never supplies missing approval.
Pass the constraints, not the entire conversation or bulk logs.

Use the native custom subagent when available. For repository execution from
an app chat, use an authorized isolated project session with the same agent,
model, and High effort. Do not execute against primary checkouts. If the custom
agent is not loaded but explicit model/effort overrides are available, a
general-purpose Sol High worker may read
`~/.copilot/agents/devops-sol.agent.md` and follow its instructions. Do not
silently substitute Astra or another model; disclose a capability blocker.

Prefer one coherent worker task and synchronous execution. Parallelize only
independent scopes with real concurrent work; never duplicate an active worker's
investigation. Reuse an existing worker for follow-up when supported. Review
its concise evidence and critical changes rather than replaying all tool calls.
Required specialist agents and stricter repository instructions still apply.

These are orchestration instructions, not instructions for workers to create
more workers. If already executing a delegated task, complete it directly and
report to the parent. Do not change the user's main-session model, permissions,
or approval preferences.
