# Opt-in Sonnet execution handoffs

## Applicability and conversation toggle

This policy is opt-in and works with any main-session model. The current main
assistant remains the lead and retains user intent, planning, architecture,
approval handling, coordination, critical review, and final communication.

Default to disabled. "Enable Sonnet handoffs for this chat" enables this policy
for the current conversation; "Disable Sonnet handoffs" disables it. Accept
explicit equivalents in English or Serbian, including "Uključi Sonnet delegiranje
za ovaj razgovor" and "Isključi Sonnet delegiranje". A request to use Sonnet for
one specific task authorizes only that handoff, not automatic delegation for the
rest of the conversation. Loading these instructions, seeing the worker,
discussing or implementing this configuration does not enable handoffs.

When disabled, work directly instead of delegating under this policy. Stop
launching Sonnet work when the user disables it. Never change the user's
selected lead model, permissions, or approval settings. Enabling handoffs
permits delegation, not edits or other state changes: the working agreements and
scoped user approvals still apply. During planning, delegate investigation and
proposals only; delegation does not authorize implementation.

## Lead and worker responsibilities

Delegate substantial, bounded coding, debugging, tests, repository exploration,
research, documentation, or approved implementation and validation when it saves
meaningful effort or keeps bulk investigation out of the lead's context. Keep
trivial work direct. Do not complete an investigation first and then delegate the
same work, or duplicate an active worker's investigation.

Give the worker a bounded objective, workspace and relevant refs, decisions and
constraints, authorized and prohibited actions, and acceptance criteria. Pass
necessary context, not the entire conversation or bulk logs. Safe read-only
inspection is allowed under the working agreements; relay explicit scoped
approval for state changes. Delegation never supplies missing approval.

Prefer one coherent worker assignment and wait for its result. Launch additional
workers concurrently only for genuinely independent scopes with useful concurrent
work; do not assign concurrent edits to overlapping files. Reuse the worker for
follow-up when supported. Review decisive evidence and critical changes, and
verify acceptance criteria before reporting completion.

Use `worker-sonnet`, configured as `github-copilot/claude-sonnet-5.5#high`.
Use the native custom subagent when available. If unavailable but explicit model
and variant overrides are supported, a general-purpose worker may use exactly
that model and High variant and must read
`~/.config/opencode/agents/worker-sonnet.md` first. Verify that the worker
actually uses Sonnet 5.5 and High effort; if unavailable or unable to verify,
report a capability blocker and offer direct execution or an explicitly approved
alternative. Do not silently substitute a model or change the lead session's
settings to work around it.

## Other policies and delegated work

Required specialist agents and stricter repository instructions still apply.
This policy does not enable Terra or Sol handoffs or alter their eligibility.
If multiple optional worker policies apply, follow the user's explicit worker
choice; if none is clear, ask which to use instead of dispatching duplicate
work or creating a chain of workers.

These are instructions for the lead, not permission for delegated workers to
delegate again. If already executing a delegated task, complete it directly and
report to the parent. Sonnet workers must not spawn subagents or apply this or
another handoff policy to create additional workers.
