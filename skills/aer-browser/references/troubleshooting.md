# Troubleshooting and handoff

| Observation | Next action |
| --- | --- |
| Launcher cannot locate AER | Read `install.md`; select the installed app. Do not download an unrelated browser. |
| `profiles` is empty | Open the selected AER app normally, then retry discovery. No session is available yet. |
| Profile selection is ambiguous | Use a returned session ID matching the intended Profile. Ask if the user's intent does not distinguish them. |
| `tabs` has no usable target | Ask the user to open an appropriate HTTP(S) tab; the current CLI cannot create one. |
| Task is `queued` | Inspect `show` with bounded polling. Another task or confirmation owns this Profile's queue. |
| `waiting_confirmation` | Let the user review the native pending preview. Do not resend, finish or hand off while awaiting that approval. |
| `STALE_REF`, `USER_EDIT`, `OBSCURED`, changed context | Read task state and take a fresh snapshot when running. Reassess the intended control and user edits. Scroll if appropriate; never guess a ref. |
| `USER_REQUIRED` or unsupported field/control | Explain the unsupported step and hand off. The preview may be impossible to capture completely, or a secret field may be involved. |
| `CONNECTOR_SCOPE` | AER requires a permitted connector action for this site. Do not circumvent it through page scripts or another browser. Report the boundary. |
| Connection loss or command timeout | Inspect `show` before retrying. A mutation may have executed already. Re-observe the page; do not duplicate a submission. |
| User has taken control / `handed_off` | Wait until control is returned or continuation requested. Resume with explicit current pages and a new snapshot. |
| Browser restart / `interrupted` | Discover the new session and page IDs; task history is not evidence of current page state. Resume deliberately after reviewing remaining work. |
| `finish` is rejected | Check for pending confirmation, another task, or missing observation. Verify the affected page first; do not force completion. |
| Export stays queued | Finish or hand off your own active manual task; do not cancel someone else's task. |
| Export failed or has warnings | Report the concrete reason/omissions. A file path alone does not prove a complete article or screenshot. |

## Current capability boundaries

Ordinary HTTP(S) main-frame DOM controls in the viewport are supported. The
current public CLI does not expose arbitrary JavaScript, CDP, Node.js, shell
execution inside the browser, cookies/storage APIs, iframe or shadow-root
traversal, canvas hit targets, uploads, tab creation/closing, automatic login,
or a full DOM/subtree query. Read the installed guide for future changes.

Do not treat browser automation as permission to reset cookies, clear cache,
erase a Profile, import browser data, or reinstall the app. There is no
documented AER CLI command for those operations. A stale ref or login wall is
not evidence that browser data needs clearing.

When blocked, report the page and exact step that needs the user's help, plus
what has already been verified. Keep task state consistent with whether the
user is approving a pending action or taking over the page manually.
