# Skill: macOS Security & Deletion Safety Audit

## Purpose
Enforces strict security boundaries, safe deletion practices, and privilege restrictions across all Olive codebase modifications.

## Rules & Verification Checklist

### 1. File Deletion Guardrails
- [ ] Verify that `FileManager.default.trashItem(at:resultingItemURL:)` or `NSWorkspace.shared.recycle` is used for all deletions.
- [ ] Ensure that raw `rm`, `unlink`, or `removeFileAtPath` is NEVER used without explicit sandbox protection.
- [ ] Check that path inputs are sanitized against directory traversal (`../`) and shell injection when passed to sub-processes.

### 2. Protected System Path Blacklist
Ensure every scanning and deletion routine explicitly skips paths matching:
- `/System/**`
- `/Library/Apple/**`
- `/usr/**`, `/bin/**`, `/sbin/**`
- `~/Library/Keychains/**`
- `~/Library/Accounts/**`

### 3. Concurrency & Performance
- [ ] Ensure long-running disk scans run inside background `Task` blocks with cooperative cancellation checks (`Task.isCancelled`).
- [ ] Verify that live sensor polling timers do not leak across view lifecycles.
