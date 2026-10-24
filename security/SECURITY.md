# StepSecure — Security Model

Status: **rules written, not yet run against the emulator** (see "Verification").
Scope: the Flutter app, Firebase Auth, Cloud Firestore, Realtime Database (RTDB).
The wearable firmware and the backend that creates alerts are out of scope here
but are named where the design depends on them.

## 1. What is being protected

| Asset | Why it matters |
|---|---|
| Fall alerts | Integrity: a fake alert causes panic; a hidden or deleted one can cost a life. Confidentiality: shows when someone is hurt or alone |
| Live sensor data and device status | Reveals activity, presence and routine of an elderly or vulnerable person |
| Emergency contacts (names, phones, emails) | Personal data of third parties |
| Caregiver profile (name, phone) | Personal data |
| Device ↔ account link | Whoever controls it receives the wearer's data and alerts |

## 2. Trust boundaries and actors

- **The app is untrusted.** Anyone can extract the Firebase config from the APK or
  call the databases directly with a valid login. The rules, not the UI, are the
  enforcement.
- **A signed-in caregiver** is trusted only for their own `users/{uid}` subtree.
- **The wearable** is semi-trusted: it may write its own readings only.
- **The backend (Admin SDK)** is fully trusted and bypasses rules. It creates alerts
  and device links. It does not exist yet.

## 3. Threats and the control that answers each

| # | Threat | Control | Test |
|---|---|---|---|
| T1 | User reads another user's alerts, contacts or profile | Every path is `users/{uid}/…` with `request.auth.uid == uid`; default deny elsewhere | `another user cannot read…` |
| T2 | Attacker forges an alert (fake emergency) | `alerts` create is `false` for clients; only the backend creates them | `app cannot create alerts` |
| T3 | Evidence destruction: delete an alert, or "un-acknowledge" it | Alert delete is `false`; the only allowed update is `pending → acknowledged`, touching only `status` and `acknowledgedAt` | `cannot un-acknowledge…`, `never be deleted` |
| T4 | Back-dating or rewriting alert details | `acknowledgedAt` must equal server `request.time`; other fields are immutable | `must use server time`, `cannot rewrite other fields` |
| T5 | Claiming someone else's wearable to receive its data | `userDevices/*` is not writable by clients; RTDB sensor reads require a link in `userDevices/{auth.uid}/{deviceId}` | `cannot link a device to themselves` |
| T6 | Spoofed sensor readings or heartbeats from the app | `sensors/*` is not writable by app users. Only a device holding a backend-minted `deviceId` claim for that exact device can write | `app users cannot write sensor data`, `cannot write another device` |
| T7 | Malformed or oversized data (injection, UI breakage, storage abuse) | Strict schemas: field allow-lists, types, lengths, E.164 phone, enum values, battery 0–100, `$other: false` in RTDB | `invalid contacts are rejected`, device validation test |
| T8 | Privilege escalation through the profile (`role: admin`, extra flags) | Profile keys allow-listed; `role` must be `caregiver` and is immutable | `cannot grant itself another role` |
| T9 | Back-dated `createdAt` | Must equal `request.time` on create and cannot change | `createdAt cannot be back-dated` |
| T10 | Account enumeration through login / reset | App shows the same neutral message for "forgot password" and a generic error for bad credentials | app code (`login_screen.dart`, `auth_service.dart`) |
| T11 | Sensitive state shown from stale or fabricated data | Connection state derived from heartbeat age; missing data shown as "No data"; no default or hardcoded device id | app code |
| T12 | Hardcoded secrets or admin credentials on the device | Device never receives Admin credentials; fall events go to a backend endpoint (see `hardware_data_contract.md`) | design rule |

## 4. Deliberate decisions and trade-offs

1. **`email_verified` is not required by the rules.** The ID token's
   `email_verified` claim only refreshes when the token does (up to an hour), so
   enforcing it in rules would lock users out right after they verify. The app
   gates the UI on verification, but that is not a security boundary. To enforce it
   in rules, call `getIdToken(true)` after verification and require
   `request.auth.token.email_verified == true` on alerts and contacts.
2. **Clients cannot mark alerts `resolved`.** That is a backend or support action.
   The deprecated `updateAlertStatus` and `addAlert` in the app will be denied.
3. **Contact count is not limited by the rules** (rules cannot count documents).
   A user could fill their own subtree. The risk is cost only, not data exposure.
   Mitigate with App Check and budget alerts.
4. **Device authentication is a proposal.** The RTDB rule trusts a custom-token
   claim `deviceId`. Until a backend mints those tokens, no device can write, which
   is the safe default.
5. **Phone numbers in the profile are free text (5–25 chars)**, because the
   registration form stores a formatted number. Contacts are strict E.164.

## 5. Residual risks (not solved by rules)

- **No backend exists yet.** Alerts, device pairing and notification delivery are
  all missing, so the system cannot yet deliver an alert end to end.
- **Pairing flow undefined.** Anyone who learns a `deviceId` can try to get it
  linked. Pairing needs a one-time code printed on or shown by the device,
  verified by the backend.
- **App Check is not enabled.** Without it, any client holding the API key can hit
  Firebase. Enable Play Integrity / App Attest and enforce it per service.
- **API key restrictions.** Restrict the Android and iOS keys to the app's package
  name / bundle id and SHA-1 in Google Cloud Console. The iOS bundle id is still the
  `com.example…` placeholder.
- **Device compromise.** A stolen wearable with a valid token can send false
  readings for itself only. Per-device revocation (disable the device record,
  rotate its token) is needed.
- **Transport and storage.** Firebase uses TLS. Nothing sensitive should be logged
  or kept in `SharedPreferences` (only the theme choice is kept there now).
- **Local data.** Firestore offline persistence caches alerts and contacts on the
  phone, so an unlocked, rooted or stolen phone exposes them.
- **Password policy.** Enforced client-side only (8+ characters, digit and symbol).
  Set the project's password policy in Firebase Auth to enforce it server-side, and
  turn on email-enumeration protection.
- **Notifications (FCM).** Not built. Payloads must not carry sensitive detail,
  and device tokens must be stored per user.

## 6. Verification

The rules are covered by `rules.test.js` (about 30 cases using
`@firebase/rules-unit-testing`). **They have not been executed**: the environment
they were written in could not download the Firebase emulator. Run them yourself:

```bash
cd security
npm install
npm test        # needs Java 11+
```

Also use the Rules Playground in the Firebase Console as a second check.

## 7. Deploying

```bash
firebase deploy --only firestore:rules,database
```

Create the Realtime Database first (Console → Build → Realtime Database), since
the app's config has no `databaseURL` yet. Then rerun `flutterfire configure`.
Until a backend exists, link a test device by hand in the Console by adding
`userDevices/<uid>/<deviceId>`, and add a test alert document under
`users/<uid>/alerts/<id>` with `status: "pending"` and a `timestamp` of Timestamp
type.
