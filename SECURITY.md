# Security Architecture & Safety Policy

## Project: NovaClean
**Security Mandate**: *Zero irreversible damage, zero accidental data loss, and explicit user consent.*

---

## 1. Safety-First Deletion Model

### 1.1 macOS Trash API Over `rm -rf`
NovaClean **never** executes destructive permanent deletions (`rm -rf`) by default.
All file cleanup and uninstallation tasks use the native Apple Trash API:
```swift
// Native safe deletion allowing user undo via Finder Trash
try FileManager.default.trashItem(at: fileURL, resultingItemURL: nil)
```

### 1.2 System Integrity Protection (SIP) & Protected Paths
NovaClean maintains a hardcoded exclusion list that can **never** be modified or targeted for deletion:
- `/System` and all subdirectories
- `/usr`, `/bin`, `/sbin`, `/etc`, `/var` (except explicitly verified user-owned temporary folders)
- `/Library/CoreServices`
- Essential macOS keychain and security databases (`~/Library/Keychains`, `/var/db`)
- Active running application bundles

---

## 2. Dry-Run & Review Guarantees

1. **Mandatory Preview**: Every clean operation executes a read-only scan first, calculating exact file paths and byte totals.
2. **Granular Checkboxes**: Users can inspect individual files and uncheck any folder before proceeding.
3. **Audit Logging**: All moved items are logged locally to `~/Library/Logs/NovaClean/operations.log` with timestamps and original source paths.

---

## 3. Privilege Escalation & Authorization

- Operations that require administrator access (e.g. system-level cache purges or system daemon management) use Apple's standard `AuthorizationServices` / `SMAppService` APIs.
- NovaClean never prompts for passwords in insecure plain-text inputs.

---

## 4. Reporting Security Issues

If you discover a security vulnerability in NovaClean:
- Please do **not** open a public issue.
- Email the maintainers directly or open a GitHub Private Vulnerability Report.
- Vulnerabilities are triaged and patched within 48 hours.
