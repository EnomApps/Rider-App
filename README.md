# Nexmile Rider — delivery partner app

**Fast Delivery. Fresh Smiles.**

Flutter front-end for Nexmile delivery partners, targeting Android and iOS.
Built against the Nexmile REST API (`document.json`, OpenAPI 3.1).

The splash, language and sign-in screens are carried over from the customer
app unchanged — same animation, same 23 languages, same two-call OTP flow.
Everything after sign-in is different, and that difference is the whole point
of this repository.

---

## How a rider differs from a customer

| | Customer app | Rider app |
|---|---|---|
| Sign in | OTP request → verify | identical, plus `intended_role: rider` |
| Status after verify | `active` — ready immediately | `pending` — cannot work yet |
| Next screen | home | onboarding wizard |
| Onboarding | save an address (GPS required) | 11 detail fields + 6 documents + submit → wait for admin |
| Gate for main UI | none | `can_accept_orders` from `/rider/profile` |

One line makes the shared OTP flow create a rider instead of a customer:

```dart
// lib/core/config/app_config.dart
static const String intendedRole = 'rider';
```

Everything else follows from `status: pending`. A rider who verifies a code
has an account but no permission to work, so sign-in cannot navigate to a
home screen — it navigates to a gate that asks the API what this rider is
entitled to see.

---

## Current state

| Area | Status |
|---|---|
| Splash animation | Done — 3s scripted sequence, copied verbatim |
| Language selection | Done — English + all 22 Eighth Schedule languages |
| Sign-in (OTP) | Done — wired to the live API as a rider |
| Rider gate | Done — resolves onboarding / review / blocked / ready |
| Onboarding wizard | Done — 7 steps, 11 detail fields, server-driven document checklist |
| KYC submission | Done — `POST /v1/rider/kyc/submit`, with confirmation |
| Waiting + rejection screens | Done — shows the admin's reason, reopens the wizard |
| Rider home | Done — duty toggle, deliveries, rating |
| Profile | Done — read-only, user fields plus KYC status and vehicle |
| Live order dispatch | **Not built.** No endpoints for it in the spec yet |

---

## Running it

```bash
flutter pub get
flutter run
flutter build apk --release
flutter build ipa --release        # needs macOS + Xcode
```

### Pointing at a backend

The base URL defaults to production. Override it at build time:

```bash
# Android emulator -> host machine's localhost
flutter run --dart-define=NEXMILE_API_BASE_URL=http://10.0.2.2:8000/api

# Physical device -> your machine on the LAN
flutter run --dart-define=NEXMILE_API_BASE_URL=http://192.168.1.5:8000/api
```

`http://` traffic is blocked by default on both platforms. For local
development against a plain-HTTP server you will need a debug-only
network-security config on Android and an ATS exception on iOS.

### Getting a code while there is no SMS gateway

The API writes OTP codes to `storage/logs/laravel.log` instead of sending
them, and returns the code in `data.debug_code` outside production. The OTP
screen renders that as a one-tap "Development code" card, gated on
`kReleaseMode` so a misconfigured production response can never leak a live
code into a shipped build.

---

## Screen flow

```
splash (3s)
  ├─ no language chosen ──────▶ language screen ──▶ login
  ├─ language chosen, no session ─────────────────▶ login
  └─ session restored ────────────────────────────▶ rider gate
                                                       │
login ──▶ OTP verify ──────────────────────────────────┤
                                                       ▼
                                            GET /v1/rider/profile
                                            GET /v1/rider/kyc
                                                       │
        ┌──────────────────┬───────────────┬───────────┴────────┬─────────────┐
        ▼                  ▼               ▼                    ▼             ▼
  can_accept_orders   kyc: submitted   kyc: rejected      kyc: pending    fetch failed
        │                  │               │                    │             │
        ▼                  ▼               ▼                    ▼             ▼
   rider home        waiting room     reason + retry     onboarding      retry / sign out
   (duty toggle)     (check again)    (reopens wizard)     wizard
```

The gate swaps its **body**, it does not push routes. A rider's stage changes
underneath them — submitting moves them into the waiting room, an approval
landing during a pull-to-refresh moves them onto the home screen — and a route
stack would have to be unwound on every one of those transitions.

---

## The onboarding wizard

Seven steps, each saving on its own. That is not just a layout choice:
`PATCH /v1/rider/kyc/details` takes every field as optional, so a rider who
fills in three steps and closes the app keeps those three. Holding the whole
form in memory until one final save would throw all of it away.

| Step | Fields | Endpoint |
|---|---|---|
| 1. About you | full name, date of birth | `PATCH /v1/rider/profile` |
| 2. Your vehicle | type, **vehicle number**, **RC number** | `PATCH /v1/rider/profile` + `kyc/details` |
| 3. Identity numbers | **Aadhaar**, **PAN** | `PATCH /v1/rider/kyc/details` |
| 4. Licence and insurance | **licence no**, **licence expiry**, **policy no**, **policy expiry** | `PATCH /v1/rider/kyc/details` |
| 5. Where you get paid | **account name**, **account number**, **IFSC** | `PATCH /v1/rider/kyc/details` |
| 6. Your documents | the checklist below | `POST /v1/rider/kyc/documents` |
| 7. Check and submit | — | `POST /v1/rider/kyc/submit` |

The eleven **bold** fields are the eleven the API's `kyc/details` endpoint
accepts. Step order follows what a rider has to hand: name and vehicle come
from memory, the reference numbers need the documents in front of them, and
bank details sit last because that is the one people go and fetch a passbook
for.

### The document checklist is server-driven

Nothing in the UI hard-codes "six documents". The list comes from
`allowed_documents` and what is outstanding from `missing_documents`, both on
`GET /v1/rider/kyc`. Retiring the PAN card or adding a police verification is
a backend change that this app picks up on its next fetch.

`DocumentCatalogue` only decides how a *known* type is dressed — its icon,
whether the camera or the file browser opens first, and a translated name. A
type it has never seen still renders, falling back to a generic icon and the
label the API supplied.

### Resuming

The wizard opens on the first step the rider has not answered. It works that
out from what the API echoes back, which is deliberately not everything:
Aadhaar and bank details are hidden on the model and never returned, so those
fields start blank on a return visit and the bank step cannot be detected as
done. `pan`, `driving_licence_no` and `insurance_expiry` are the three KYC
fields `RiderResource` does return, and the resume logic works from exactly
those.

---

## Why `can_accept_orders` is the only gate

`RiderController.stage` never recomputes eligibility from the KYC status. The
server weighs document expiry and account suspension as well as the KYC
decision, and a client that guessed would eventually guess wrong in the
permissive direction — putting a rider with a lapsed licence on the road.

So a rider whose KYC reads `verified` but whose `can_accept_orders` is false
gets the **blocked** screen, not the home screen. There is a test for exactly
that case, because it is the one a naive implementation gets wrong.

The same discipline applies to the duty toggle. `POST /v1/rider/duty-status`
answers 403 when a licence or insurance has lapsed; the home screen reports
that verbatim rather than optimistically flipping the switch.

---

## Uploads

`ApiClient.upload` sends `multipart/form-data` and takes **bytes**, not a
path. Two reasons:

* a multipart request cannot be re-sent once its stream is consumed, and this
  call has to survive the same 401-refresh-and-retry as every other;
* an Android gallery pick is a content URI that a plain `File` cannot always
  reopen later.

Camera captures are downscaled to 1600px on the long edge at quality 82. A
modern phone camera produces 8-12 MB frames, which the API rejects outright at
5 MB; 1600px keeps a licence number comfortably legible, lands well inside the
limit, and is far kinder to a rider's data plan.

Replacing a document deletes the old one first. The API keys a document by
type, so uploading twice without deleting would either 422 or leave two rows
for the same slot, and neither is recoverable from inside the app.

---

## Localisation

23 languages: English plus all 22 Eighth Schedule languages, with Urdu,
Kashmiri and Sindhi laid out right-to-left.

**The rider-specific strings are translated into English, Hindi and Tamil —
the three locales `preferred_locale` accepts on the API.** The other 20
locales fall back to English for those strings only; everything carried over
from the customer app is still translated in all 23. `flutter gen-l10n`
reports the gap on every run.

That was a deliberate call rather than an oversight: machine-translating
onboarding copy into Bodo, Santali, Manipuri and Dogri would produce text that
*looks* authoritative and cannot be verified, on a form where a
misunderstanding costs a rider their bank details. English is the honest
fallback until a human translator supplies the rest.

---

## Testing

```bash
flutter test
flutter analyze
```

83 tests. Beyond the customer app's suite, the rider additions cover:

* **the gate** — each of the five stages lands on the right screen, including
  verified-but-not-dispatchable;
* **the wizard** — validation refuses to advance, the number plate is
  normalised before it is sent, submit stays inert until the API says
  `can_submit`, and submitting moves the rider into the waiting room;
* **the duty toggle** — the right wire value goes out, and a 403 is reported
  rather than swallowed;
* **decoding** — an unrecognised KYC status degrades to editable rather than
  throwing, documents keyed by slug decode as well as a plain list, and
  `KycDetails` omits what was never filled in so a partial save cannot blank an
  earlier step;
* **layout** — every wizard step and both decision screens pumped in all 23
  locales, since Flutter surfaces clipped and overlapping text as exceptions.

`FakeRiderRepository` models the API's behaviour rather than returning fixed
payloads: saving details recomputes `can_submit`, submitting flips the status,
and only the three KYC fields the real API echoes back are readable.

---

## Permissions

Camera and photo-library access are needed for KYC capture.

* **Android** — requested at runtime by `image_picker`; no manifest entry is
  required on API 23+.
* **iOS** — `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription`
  are in `Info.plist`. iOS terminates the app if a picker opens without them,
  so both are present even though a rider only ever sees one at a time.

---

## What's next

* **Live dispatch.** The spec has no order endpoints for riders yet — no
  assignment, acceptance, pickup or delivery confirmation. The home screen is
  where that plugs in.
* **Location reporting.** Going online implies the backend can find the rider;
  there is no endpoint for it in this version of the spec.
* **Editing after approval.** `PATCH /v1/rider/profile` stays open for name,
  date of birth and vehicle. KYC reference numbers lock on verification by
  design, so changing a licence has to go through support.
* **The remaining 20 translations.** See [Localisation](#localisation).
