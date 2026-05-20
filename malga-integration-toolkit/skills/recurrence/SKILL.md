---
name: recurrence
description: Use this skill when implementing recurring payments or subscriptions with Malga. Triggers on questions about "recorrência Malga", "assinatura Malga", "Malga subscriptions API", "criar plano Malga", "Malga cycles", "pause subscription Malga", "Malga billing cycle", "subscription dunning", "Malga update payment method subscription", "merchant-initiated transaction MIT". Covers the Subscriptions API (`/v1/subscriptions`), the cycle lifecycle, pause/resume/cancel, customer-payment-method updates, retry/dunning strategy, and how recurrence interacts with 3DS2 and antifraud.
---

# Malga Recorrência / Subscriptions

Malga's Subscriptions API drives recurring charges. A `subscription` references a `customer`, a payment method on file (typically a vaulted `card`), and a billing schedule. Malga generates `cycles` — one cycle per billing period — and creates a charge for each cycle automatically.

Reference: <https://docs.malga.io/api-reference/subscriptions>

## Resources

| Action | Endpoint |
|---|---|
| Create | `POST /v1/subscriptions` |
| List | `GET /v1/subscriptions` |
| Detail | `GET /v1/subscriptions/{id}` |
| Update | `PUT /v1/subscriptions/{id}` |
| Cancel | `PATCH /v1/subscriptions/{id}/cancel` |
| Pause | `PATCH /v1/subscriptions/{id}/pause` |
| Reactivate | `PATCH /v1/subscriptions/{id}/reactivate` |
| List cycles | `GET /v1/subscriptions/{id}/cycles` |
| Cycle detail | `GET /v1/subscriptions/{id}/cycles/{cycleId}` |
| Update customer settings | `PATCH /v1/subscriptions/{id}/customer-settings` |
| Get customer settings | `GET /v1/subscriptions/{id}/customer-settings` |

## Creating a subscription

```json
POST /v1/subscriptions
{
  "merchantId": "<MERCHANT_ID>",
  "customer": { "id": "<CUSTOMER_ID>" },
  "paymentMethod": {
    "type": "credit",
    "card": { "id": "<VAULTED_CARD_ID>" }
  },
  "amount": 4990,
  "currency": "BRL",
  "interval": { "unit": "month", "count": 1 },
  "trialPeriodDays": 7,
  "startDate": "2026-06-01"
}
```

Once created, Malga schedules the first cycle (or immediately, if no trial), then continues monthly until canceled.

## Cycles

Each billing period generates a `cycle`. Important cycle fields: `status` (`pending`, `succeeded`, `failed`, `skipped`), `chargeId`, `attemptCount`, `nextRetryAt`.

## Pause / Cancel / Reactivate

- **Pause** — stops generating new cycles but preserves the subscription. Useful for "snooze 1 month" UX.
- **Cancel** — terminates the subscription. Cannot be reactivated; create a new one instead.
- **Reactivate** — resume a paused subscription.

## Updating the payment method

When a card expires or is replaced:

```bash
PATCH /v1/subscriptions/{id}/customer-settings
{ "paymentMethod": { "card": { "id": "<NEW_VAULTED_CARD_ID>" } } }
```

Future cycles use the new card. For seamless updates, listen to issuer card-update events (network tokens make this automatic).

## Dunning (retry on failure)

Failed cycles enter a retry schedule defined per merchant (configurable). Default: retry after 3 / 7 / 14 days, then mark `past_due` and pause. Best practices:

- Combine with **smart flow fallback** so the first retry uses an alternative provider — boosts recovery by 5–15%.
- Surface `cycle.failed` and `subscription.past_due` webhooks to email customers a card-update link.
- Use **Network Tokens** to silently refresh card credentials when issuers reissue cards.

## 3DS2 and antifraud on recurring charges

Recurring charges are **merchant-initiated transactions (MIT)** — they typically bypass 3DS challenge because there's no customer present. In Smart Flow:

- Send `metadata.initiator = "merchant"` (or your chosen key) on the recurring charge.
- Route to a branch with 3DS2 disabled.
- Antifraud can stay enabled if desired (low-friction).

The very first charge of a subscription is usually customer-initiated and can carry a 3DS2 challenge to "anchor" the consent.

## Pitfalls

- **Card-on-file required.** Subscriptions don't accept ad-hoc tokens — vault first via `POST /v1/cards`, then reference by `card.id`.
- **Time zones.** `startDate` is interpreted in America/Sao_Paulo by default. Pass an explicit timezone if needed.
- **Pause window.** While paused, no cycles generate — be explicit in the UI that billing is on hold, not free service.
- **Cycle vs. charge.** Reports and analytics distinguish them. Reconcile by `cycleId`, not by `chargeId`.
