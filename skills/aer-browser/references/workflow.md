# CLI workflow

Read the live guide first. These examples describe the current task-based AER
CLI and help translate a user request into native commands. A future installed
guide takes precedence over examples here. All IDs, refs and destinations below
are placeholders; replace them with observed values.

Set a shell variable to the launcher in this skill, using its absolute path:

```bash
AER_LAUNCHER="<this-skill-directory>/scripts/aer-browser.sh"
bash "$AER_LAUNCHER" skill
bash "$AER_LAUNCHER" profiles
```

## Choose a session and page

Select the Profile that matches the user's request. If there is only one
appropriate running session, use its returned `session`; if the choice is
ambiguous, ask which Profile the user means. The same Profile can have multiple
sessions: use the exact session identifier instead of guessing by window focus.

```bash
AER_SESSION="<observed-session>"
bash "$AER_LAUNCHER" --profile "$AER_SESSION" tabs
```

Choose matching tab IDs from this result. The current CLI operates existing
HTTP(S) tabs. It can navigate a bound tab to another website, but has no command
to create, close, activate, group or silently claim arbitrary tabs. Reuse an
appropriate task tab only when consistent with the request and existing drafts;
otherwise ask the user to open one. Do not repurpose an unrelated working tab.

## Create and observe

```bash
bash "$AER_LAUNCHER" --profile "$AER_SESSION" create \
  '{"prompt":"Read the chosen page and find the requested topic","pages":[123],"manual":true}'
AER_TASK="<returned-task-id>"
bash "$AER_LAUNCHER" --profile "$AER_SESSION" show "$AER_TASK"
bash "$AER_LAUNCHER" --profile "$AER_SESSION" snapshot "$AER_TASK" 123
```

`manual:true` means Codex drives the task. Omitting it sends the task to AER's
configured model instead. Only execute tools when the manual task is `running`.
For `queued`, inspect `show` with a bounded wait; do not stop other tasks to jump
the queue. One task runs per Profile. Even read-only snapshots require a task.

Use snapshot `text` for content and `controls` for observed `role`, `name` and
`ref`. Control roles may be native tag names such as `input` or `select`, not
necessarily accessibility-tree roles. Text and controls are bounded; heed
`truncated`, and scroll/reobserve or export an article to obtain more content.
Snapshots do not expose existing private input values. Only report field values
when an observed result or explicit preview actually establishes them.

## Act and verify

These are separate examples, not a sequence to run blindly:

```bash
bash "$AER_LAUNCHER" --profile "$AER_SESSION" tool "$AER_TASK" \
  '{"action":"click","page":123,"ref":"@observed-ref"}'
bash "$AER_LAUNCHER" --profile "$AER_SESSION" tool "$AER_TASK" \
  '{"action":"fill","page":123,"ref":"@observed-ref","value":"Requested text"}'
bash "$AER_LAUNCHER" --profile "$AER_SESSION" tool "$AER_TASK" \
  '{"action":"scroll","page":123,"dy":500}'
bash "$AER_LAUNCHER" --profile "$AER_SESSION" tool "$AER_TASK" \
  '{"action":"navigate","page":123,"url":"https://example.com/"}'
bash "$AER_LAUNCHER" --profile "$AER_SESSION" tool "$AER_TASK" \
  '{"action":"wait","page":123,"text":"Expected visible result"}'
bash "$AER_LAUNCHER" --profile "$AER_SESSION" tool "$AER_TASK" \
  '{"action":"pages"}'
```

Observe the affected page after each action before another mutation or finish.
`wait` performs a short wait and returns `found` plus a fresh snapshot; false
means the condition was not observed. A dispatched click, input event or
navigation request alone does not establish business success. Every snapshot
refreshes refs: use only the latest refs for that page, with the observed label.
For a select, use an exact returned option value. Unsupported control types
need user interaction; do not invent CSS selectors, JavaScript or coordinates.

Use structured JSON serialization for dynamic values. Do not interpolate
untrusted page content into executable shell text. Prefer a subprocess argument
array when the host provides one; escape JSON and shell arguments separately.

## Confirmation and completion

`waiting_confirmation` means the action is pending. The CLI can take roughly
11 seconds to surface this status, so allow at least 20 seconds for a tool
command; other versions may have different timings. Explain the concrete field
or action and direct the user to AER's **智能体 → 网页任务** panel (older builds
call it **任务 / Tasks**). Keep the pending
task intact while awaiting confirmation; handoff would cancel its pending action.
After the user confirms, inspect `show`, take a new snapshot, and verify the
result. Do not resend the original fill/click or supply a `confirmed` parameter.

```bash
bash "$AER_LAUNCHER" --profile "$AER_SESSION" tasks
bash "$AER_LAUNCHER" --profile "$AER_SESSION" show "$AER_TASK"
bash "$AER_LAUNCHER" --profile "$AER_SESSION" snapshot "$AER_TASK" 123
bash "$AER_LAUNCHER" --profile "$AER_SESSION" finish "$AER_TASK"
```

Finish only after the verifying snapshot. `finish` returns an acknowledgement;
`show` confirms the final state. For a required manual step outside a pending
confirmation, hand off the owned task:

```bash
bash "$AER_LAUNCHER" --profile "$AER_SESSION" handoff "$AER_TASK"
bash "$AER_LAUNCHER" --profile "$AER_SESSION" resume "$AER_TASK" '{"pages":[123]}'
bash "$AER_LAUNCHER" --profile "$AER_SESSION" stop "$AER_TASK"
```

Resume only after the user returns control or asks to continue. Rebind currently
open page IDs and observe before continuing. Stop/handoff does not undo actions
already performed. Current runs are limited to 24 tool steps and 15 minutes;
reassess remaining work when interrupted rather than blindly replaying commands.

## Article and screenshot exports

Load the installed guide for the export kind before using it:

```bash
bash "$AER_LAUNCHER" skill aer-markdown
bash "$AER_LAUNCHER" skill aer-screenshot
bash "$AER_LAUNCHER" skill aer-wechat
bash "$AER_LAUNCHER" --profile "$AER_SESSION" export \
  '{"kind":"markdown","page":123,"directory":"/absolute/output-directory"}'
bash "$AER_LAUNCHER" --profile "$AER_SESSION" show "<export-task-id>"
```

Use one actual kind: `markdown`, `screenshot`, or `wechat`. Exports create their
own tasks on the same FIFO queue. Finish an active manual task first, or the
export waits behind it. Poll until `completed`, `failed` or `stopped`; read
`artifact.path` and `warnings`. Exports do not use `create`, `tool` or `finish`.
`stop` cancels them. Do not duplicate a queued export to retry it.

Markdown extracts article structure and keeps remote image links. Screenshot
saves a full-page PNG and restores scroll position; it is not an element-click
tool. WeChat archives a supported article and images to a chosen Obsidian vault;
consult its guide before selecting a destination. These are local deterministic
jobs; they do not require an AER model call. Reading their files into Codex still
places that content in the current conversation.
