---
name: three-ds-two
description: Use this skill when implementing 3DS2 (3-D Secure 2) authentication on credit card transactions through Malga. Triggers on questions about "3DS2 Malga", "3-D Secure Malga", "liability shift Malga", "challenge flow 3DS Malga", "frictionless 3DS Malga", "Malga authenticate card", "chargeback prevention Malga", "PSD2 Malga", "Mastercard Identity Check", "Visa Secure Malga". Covers how 3DS2 fits inside Smart Flows, the challenge versus frictionless flow, integration with the Checkout SDK, and when to enable it (default: high-ticket or LATAM-cross-border).
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

3DS2 challenge UI is rendered by the **Checkout SDK** or **Checkout Full SDK** automatically when the flow demands it. The merchant doesn't host the challenge — Malga's SDK opens a modal iframe served by the issuer's ACS.

For pure REST integrations without the SDK, the response from `POST /charges` may include a `nextAction` of type `3ds-challenge` with a URL. The merchant must redirect the customer or open it in an iframe and wait for the result webhook.

## Listening for the outcome

After the customer completes the challenge, Malga continues the charge automatically. The merchant learns the outcome via:

- The `success` / `failure` event from the Checkout SDK.
- The `charge.succeeded` / `charge.failed` webhook.
- A poll of `GET /charges/{id}`.

The charge response includes `threeDSecure` info (`flow`: `frictionless` / `challenge`, `liabilityShift`: boolean, `eci`, `cavv`).

## Pitfalls

- A merchant **cannot** ship a card charge through 3DS2 if the chosen provider doesn't support it. Configure 3DS2-capable providers in the same branch.
- 3DS2 increases conversion in the long term (fewer chargebacks) but adds friction. Measure approval rate before vs after for fair comparison.
- Subscription recurring charges (`merchantInitiated`) typically skip 3DS — set Smart Flow conditional on `metadata.initiator = "merchant"` (or whatever metadata the merchant chooses) to bypass.
- Liability shift is granted **only** on `challenge_success` or `frictionless` outcomes. Other outcomes still let the charge through if the merchant chooses, but without protection.
