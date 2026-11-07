# Opt-in Terra execution handoffs

## Applicability and conversation toggle

This policy is opt-in and works with any main-session model. The current main
assistant remains the lead; no Sol-specific lead agent or model switch is needed.

Default to disabled. "Enable Terra handoffs for this chat" enables this policy
for the current conversation; "Disable Terra handoffs" disables it. Equivalent
explicit requests are valid. A request to use Terra for one specific task
authorizes only that handoff, not automatic delegation for the rest of the chat.
Loading these instructions, seeing `worker-terra` in the catalog, discussing the
setup, or implementing this configuration does not enable handoffs.

When disabled, work directly instead of delegating under this policy. The user
may disable handoffs at any time; do not launch further Terra work afterward.
Changing the main-session model does not enable or disable the conversation
toggle. Never change the user's selected model, permissions, or approval settings.

Enabling handoffs authorizes delegation, not state-changing actions. The working
agreements and scoped user approvals still apply. During planning, delegate only
investigation and proposals; do not treat delegation as permission to implement.

## Lead and worker responsibilities

The lead retains user intent, planning, architecture decisions, scope, approval
handling, coordination, critical review, and final communication. Delegate
substantial, bounded coding, debugging, tests, repository exploration, research,
documentation, or other execution work when it saves meaningful effort or keeps
bulk investigation out of the lead's context. Keep trivial lookups and small
changes direct when handoff overhead would cost more. Do not complete the large
investigation first and then delegate the same investigation.

Use `worker-terra`, configured as `gpt-6.1-terra` with High reasoning effort.
Give it a bounded objective, workspace and relevant refs, decisions and
constraints, authorized and prohibited actions, and acceptance criteria. Pass the
necessary context, not the entire conversation or bulk logs. Safe read-only local
and remote inspection is allowed under the working agreements; relay explicit
scoped approval for edits and other state-changing actions. Delegation never
supplies missing approval.

Prefer one coherent worker assignment and wait for its result. Run workers in
parallel only for genuinely independent scopes with useful concurrent work. Do
not duplicate an active worker's investigation or assign concurrent edits to
overlapping files. Reuse the worker for follow-up when supported. Review its
decisive evidence and critical changes rather than replaying all tool calls;
verify acceptance criteria before reporting completion.

Use the native custom agent at `~/.codex/agents/worker-terra.toml` when available.
If it is unavailable but explicit model/effort overrides are supported, a
general-purpose worker may use exactly `gpt-6.1-terra` with High effort and read
that file's `developer_instructions` before starting. In an app chat, repository
implementation belongs in an authorized isolated project session/worktree, not
an unrelated primary checkout. Do not silently substitute another model. Report
a capability blocker and offer direct execution or an explicitly approved
alternative instead. Codex CLI requires version 0.159.0 or later for Terra.

## Other policies and delegated work

Required specialist agents and stricter repository instructions still apply.
This policy does not enable Sol DevOps handoffs or alter their eligibility. If
multiple optional policies apply to the same assignment, follow the user's
explicit worker choice; if none is clear, ask which to use rather than dispatching
duplicate work or creating a chain of workers.

These are instructions for the lead, not permission for delegated workers to
delegate again. If already executing a delegated task, complete it directly and
report to the parent. Terra workers must not spawn subagents or apply this or
another handoff policy to create additional workers.
