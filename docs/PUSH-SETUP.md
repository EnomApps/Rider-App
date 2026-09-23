# Push notifications — rider app

Ported from the customer app, which proved the transport end to end on Android
first. Firebase project **`nexmile-e03c1`**, Android and iOS app id
**`com.nexmile.rider`**.

## Why this one matters more

Every other notification in Nexmile is a courtesy — the customer would find out
anyway by opening the app. `order.offer` is not: the board is **polled**, so a
rider with the app closed learns nothing, and an order sits going cold on a
counter until somebody's phone rings.

That is why a tapped offer **refetches the board** before the rider arrives at
it ([push_destination.dart](../lib/core/push/push_destination.dart)) rather than
trusting a board that may be a poll interval behind.

## Built

| Piece | Where | Note |
|---|---|---|
| Transport | [firebase_push_service.dart](../lib/core/push/firebase_push_service.dart) | FCM behind `PushService`. `start()` returns **null** rather than throwing when the build has no Firebase config, and [main.dart](../lib/main.dart) falls back to `NoopPushService` — a checkout without the config file still runs a shift. |
| Registration | [device_repository.dart](../lib/features/auth/data/device_repository.dart) | `POST /v1/devices` sends `token`, `platform` and **`app: "rider"`**. The server routes on that field. |
| Lifecycle | [device_registrar.dart](../lib/core/push/device_registrar.dart) | Registers after sign-in, on every token rotation, and at launch on a restored session. Withdraws on sign-out **before** the session is cleared — afterwards the call can only 401, and an orphaned row sends the next rider to hold this phone somebody else's shift alerts. |
| Tap routing | [push_destination.dart](../lib/core/push/push_destination.dart) | One destination, `AppRoutes.home`: what a rider may see is the API's decision, resolved in `RiderGateScreen`. A push naming a screen directly would be guessing at state the server owns — an offer already taken, a rider taken off duty. |
| Channel | `nexmile_orders` | Same id as the customer app, because the server posts by name; different display name ("Order alerts"). Created at launch — a mismatch is silent, Android drops the notification with no log line. |
| Sound | `android/app/src/main/res/raw/nexmile.wav`, `ios/Runner/nexmile.caf` | The spoken "Nexmile". Placeholder from the macOS `say` voice `Tara` (en_IN); swap both files keeping the names. |

## Left to do

1. **iOS** — an APNs auth key (`.p8`) uploaded to Firebase, plus the **Push
   Notifications** and **Background Modes → Remote notifications** capabilities
   on the Runner target in Xcode. Blocked on the Apple Developer account. iOS
   push cannot be tested on the simulator at all.
2. **A louder alert for `order.offer`.** It currently shares the order channel.
   A rider with a phone in a pocket on a road may need a full-screen intent or
   its own high-urgency channel — worth deciding after watching a real shift,
   not before.
3. **Retire the board poll?** Not yet. Push is a delivery best-effort: it is
   the *alert*, not the source of truth, and a poll that stops the day a token
   silently rotates is how orders go missing.

## Testing

```bash
flutter run                    # the FCM token is printed on launch, debug only
```

Send a test from Firebase console → Messaging, or ask the backend to fire one.
A console notification carries no `type`, so it will **not** exercise the
routing — that needs a data payload:

```json
{ "type": "order.offer", "order_id": "123" }
```
