Review the repository for the security findings described in `codex/security-audit/latest.md` and produce an implementation plan only.

Focus on:
- Removing the Toggl API secret from the Android client binary.
- Preserving app behavior while moving credential handling to a safer trust boundary.
- Defining and enforcing backup rules for app-private data.
- Identifying any product or infrastructure decisions needed before code changes.

Constraints:
- Do not make code changes yet.
- If a fix requires another role or permission boundary, split it into a separate prompt with the exact missing capability.
- Be explicit about what additional information is needed before implementation.
