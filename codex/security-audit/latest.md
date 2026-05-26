# Security Audit Report

- Run time: 2026-05-26 10:24:06 JST
- Scope: repository-wide static review
- Status: manual run completed

## Findings

### High: Toggl API token is embedded in the app binary

- Evidence:
  - [`app/build.gradle.kts`](file:///Users/yuuto/learn_lab/AleartMyController/app/build.gradle.kts) lines 24-39 load `TOGGL_API_TOKEN` from `local.properties` and inject it into `BuildConfig`.
  - [`app/src/main/java/com/example/aleartmycontroller/di/NetworkModule.kt`](file:///Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/di/NetworkModule.kt) lines 87-95 send that token as HTTP Basic auth.
  - [`app/src/main/java/com/example/aleartmycontroller/data/repository/TogglRepository.kt`](file:///Users/yuuto/learn_lab/AleartMyController/app/src/main/java/com/example/aleartmycontroller/data/repository/TogglRepository.kt) lines 21-58 use the token as a runtime gate for Toggl calls.
- Risk:
  - Any secret compiled into an Android APK can be extracted from the distributed app package.
  - If this token is real and has API access, an attacker can reuse it outside the app and operate on the associated Toggl account.
- Recommendation:
  - Do not ship a long-lived Toggl secret in the client app.
  - Move Toggl access behind a backend/proxy, or switch to a user-owned OAuth flow where the client only holds short-lived user credentials.
  - If a backend is not possible, treat the current token as non-secret and restrict its scope as tightly as the provider allows, then rotate it.

### Medium: Automatic backup is enabled without explicit exclusions

- Evidence:
  - [`app/src/main/AndroidManifest.xml`](file:///Users/yuuto/learn_lab/AleartMyController/app/src/main/AndroidManifest.xml) line 26 sets `android:allowBackup="true"`.
  - [`app/src/main/res/xml/backup_rules.xml`](file:///Users/yuuto/learn_lab/AleartMyController/app/src/main/res/xml/backup_rules.xml) is still the sample template and does not exclude app databases or preference files.
  - [`app/src/main/res/xml/data_extraction_rules.xml`](file:///Users/yuuto/learn_lab/AleartMyController/app/src/main/res/xml/data_extraction_rules.xml) is also the sample template.
- Risk:
  - App-private data such as Room databases and DataStore preferences can be included in device/cloud backup unless explicitly excluded.
  - This app appears to store personal records, event metadata, and potentially sensitive user activity, so backup leakage is a privacy risk.
- Recommendation:
  - Decide whether app-private data should be backed up at all.
  - If not, set `android:allowBackup="false"` and add explicit backup/data-extraction exclusions.
  - If backup is required, exclude only the sensitive datasets and document why they are safe to restore.

## Notes

- `android:usesCleartextTraffic="false"` is already set, so cleartext HTTP is not allowed.
- The launcher activity is exported, which is expected for a normal app entry point.
- FileProvider and WorkManager startup providers are not exported.
- No obvious SQL injection, command injection, or cleartext transport issue was found in the reviewed surface.

## Change Plan

1. Remove client-side storage of the Toggl API token.
2. Decide the trust model for Google Calendar access and verify whether the API key field is still needed.
3. Define backup policy for app-private data, then update manifest and backup XML accordingly.
4. Add a regression check or review note so future credential additions cannot be committed into `BuildConfig` casually.

## Missing Information

- Whether Toggl access can move to a server-side proxy or whether this app must remain fully offline/client-only for that integration.
- Whether the app should preserve Room/DataStore data across device backup/restore.
- Whether any of the stored personal records are regulated or particularly sensitive in the intended deployment.

## Responsibility Split

- Client app can detect and report the risk.
- Backend or infrastructure owner is needed if Toggl credentials must stop living in the APK.
- Product/security owner should decide the backup policy and acceptable data retention model.
