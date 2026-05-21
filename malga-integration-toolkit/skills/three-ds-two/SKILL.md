---
name: three-ds-two
description: 'Implementing 3DS2 authentication on Malga credit card transactions. Triggers: "3DS2 Malga", "3-D Secure Malga", "liability shift", "challenge flow 3DS", "threeDSecure2 block", "chargeback prevention Malga".'
---

# Malga 3DS2

3DS2 (3-D Secure 2) is the modern card-authentication protocol. When a charge passes 3DS2 successfully, the **liability for fraudulent chargebacks shifts to the card issuer** — a major chargeback-cost reducer. Malga offers `3DS2 - Malga` as a service available inside the Smart Flow.

Reference: <https://docs.malga.io/api-reference/about-apis> → "3DS2 Malga"

## When to enable 3DS2

- Always for **high-ticket** charges (`amount >= 30000` is a common starting threshold).
- Always for **chargeback-prone categories** (electronics, jewelry, travel, digital goods).
- For markets with regulatory requirements (PSD2 in Europe, RBI in India — though Malga is BR-focused).
- Optional for low-ticket / high-volume retail, where step-up friction hurts conversion. Use Smart Flow conditionals to enable only above a threshold or for specific BINs.

## Flow types

| Flow | What happens |
|---|---|
| **Frictionless** | Issuer authenticates silently from device data. No customer interaction. Liability shift granted. |
| **Challenge** | Issuer asks for an OTP / app confirmation. Customer steps through a modal. Liability shift granted on success. |
| **Failed / unavailable** | Authentication couldn't complete. Merchant decides whether to proceed without 3DS (no liability shift) or fail the charge. |

## Smart Flow integration

3DS2 is configured per branch in the Smart Flow editor. Conditional examples:

- `transaction.amount > 30000` → branch with 3DS2 active.
- `transaction.metadata.requestedBy = "subscription_renewal"` → branch with 3DS2 disabled (recurring auth doesn't need step-up).

The Smart Flow decides whether to invoke 3DS2 before pre-authorization.

## Frontend integration

3DS2 challenge UI is rendered by the **Checkout SDK** or **Checkout Full SDK** automatically when the flow demands it. The merchant does not host the challenge directly: Malga's SDK opens a modal iframe served by the issuer's ACS.

For pure REST integrations without the SDK, the charge response carries a `threeDSecure2` block with the authentication context. The merchant uses `redirectURL` to send the customer through the challenge and `requestorURL` as the return origin, then waits for the result via webhook (`transaction.authorized` or `transaction.failed`).

### Request — what the merchant sends

The charge payload accepts a `threeDSecure2` block with the browser, address and cardholder details required by the issuer:

```json
"threeDSecure2": {
  "browser": {
    "acceptHeader":     "...",
    "colorDepth":       24,
    "javaEnabled":      false,
    "javaScriptEnabled":true,
    "language":         "pt-BR",
    "screenHeight":     1080,
    "screenWidth":      1920,
    "timeZoneOffset":   "-180",
    "userAgent":        "...",
    "ip":               "203.0.113.5"
  },
  "billingAddress":  { ... },
  "shippingAddress": { ... },
  "cardHolder":      { "email": "...", "mobilePhone": "..." },
  "redirectURL":     "https://example.com/return",
  "requestorURL":    "https://example.com"
}
```

### Response — what comes back (`3DSecure2Response`)

The charge response includes a `threeDSecure2` block with these fields:

| Field | Meaning |
|---|---|
| `setupId` | Authentication session id (Malga-managed 3DS2 only). |
| `dataOnly` | `true` if the transaction was data-only (no challenge). |
| `requiresLiabilityShift` | `true` when liability shifted to the issuer. |
| `redirectURL` | URL to send the customer through the challenge. |
| `requestorURL` | Origin URL for the redirect. |
| `browser`, `billingAddress`, `shippingAddress`, `cardHolder` | Echo of the request data. |
| `authData` | Provider-specific authentication payload (eci, cavv, etc.). |

The Charges API reference is the source of truth for the full schema: <https://docs.malga.io/api-reference/charges/realizar-nova-cobranca>.

## Listening for the outcome

After the customer completes the challenge, Malga continues the charge automatically. The merchant learns the outcome via:

- The `success` / `failure` event from the Checkout SDK.
- The `charge.succeeded` / `charge.failed` webhook.
- A poll of `GET /charges/{id}`.

The charge response includes `threeDSecure` info (`flow`: `frictionless` / `challenge`, `liabilityShift`: boolean, `eci`, `cavv`).

## Pitfalls

- A merchant **cannot** ship a card charge through 3DS2 if the chosen provider does not support it. Configure 3DS2-capable providers in the same Smart Flow branch.
- 3DS2 increases conversion in the long term (fewer chargebacks) but adds friction in the short term. Measure approval rate and chargeback rate before vs after for a fair comparison.
- Subscription recurring charges are merchant-initiated transactions (MIT) and typically skip 3DS. Route them through a Smart Flow branch with 3DS2 disabled. The exact metadata key to flag MIT is a merchant convention; see the `smart-flows` skill for conditional patterns.
- Liability shift is granted **only** on `frictionless` or `challenge_success` outcomes. Other outcomes still let the charge through if the merchant chooses, but without protection.
- The `threeDSecure2` payload schema and challenge mechanics differ per provider. Always cross-check with the Charges API reference when wiring the integration.
