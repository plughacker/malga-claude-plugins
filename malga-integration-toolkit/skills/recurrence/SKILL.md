---
name: recurrence
description: 'Implementing Malga subscriptions and recurring payments. Triggers: "recorrência Malga", "assinatura Malga", "Malga subscriptions", "criar plano Malga", "cycles Malga", "pausar assinatura", "MIT Malga".'
---

# Malga Recorrência / Subscriptions

The Subscriptions API drives recurring charges. A subscription references a `customer`, a payment method on file (typically a vaulted `card`), one or more `items`, and a `recurrence` schedule. Malga generates `cycles` (one per billing period) and creates a charge for each cycle automatically.

References:
- API list: <https://docs.malga.io/api-reference/subscriptions/criacao-de-uma-nova-assinatura>
- Webhook payloads for `subscription.*` events: <https://docs.malga.io/documentations/webhooks/webhook1-1>

## Subscription endpoints

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

## Subscription shape

The model is structured around items and a recurrence schedule, not a single flat amount.

```json
{
  "id":          "<SUBSCRIPTION_ID>",
  "name":        "Assinatura Premium",
  "clientId":    "<CLIENT_ID>",
  "merchantId":  "<MERCHANT_ID>",
  "customerId":  "<CUSTOMER_ID>",
  "referenceKey":"SUB-PREMIUM-001",
  "currency":    "BRL",
  "items": [
    {
      "name":        "Ingresso VIP Mensal",
      "description": "Acesso VIP premium",
      "amount":      29900,
      "quantity":    1
    }
  ],
  "recurrence": {
    "interval":    "monthly",
    "startAt":     "2026-06-01",
    "nextDueDate": "2026-07-01"
  },
  "paymentMethod": {
    "type": "credit",
    "card": { "cardId": "<VAULTED_CARD_ID>" },
    "installments": 1
  },
  "status": "active",
  "amount": 29900,
  "liveMode": false
}
```

Notes:

- The total `amount` is the sum of items.
- `recurrence.interval` accepted values: `weekly`, `monthly`, `quarterly`, `yearly` (per the OpenAPI spec). Note: the `Subscription` response schema in the spec sometimes lists only `weekly | monthly | yearly`; `quarterly` is accepted in the request but may not appear in all response payloads. Confirm with the Malga team if you depend on `quarterly`.
- `paymentMethod.card.cardId` references a vaulted card. Ad-hoc tokens are not accepted; vault first via `POST /v1/cards` (see the `tokenization` skill).
- `referenceKey` is a merchant-controlled identifier for reconciliation.

## Status lifecycle

Observed statuses from the webhook event catalog:

| Status | Meaning |
|---|---|
| `created` | New subscription, not yet active. |
| `trial_started` | Subscription created with active trial. |
| `active` | First payment approved; cycles will run. |
| `paused` | Paused; no new cycles generated. |
| `unpaid` | A cycle failed and the subscription is in past-due state. |
| `expired` | Subscription reached its end. |
| `canceled` | Canceled manually. |

## Cycles

Each billing period creates a `cycle` with its own `chargeId`, status, scheduled date and an attempt history. From a real payload:

```json
"cycle": {
  "id":          "<CYCLE_ID>",
  "customerId":  "<CUSTOMER_ID>",
  "merchantId":  "<MERCHANT_ID>",
  "cycle":       1,
  "status":      "authorized",
  "amount":      29900,
  "scheduledAt": "2026-06-01",
  "paymentHistory": [
    {
      "id":            "<ATTEMPT_ID>",
      "createdAt":     "...",
      "executedAt":    "...",
      "chargeId":      "<CHARGE_ID>",
      "attemptNumber": 1,
      "paymentMethod": { ... },
      "error":         null
    }
  ]
}
```

A `cycle.paymentHistory` entry per attempt, including failures (`error` populated) and retries. Use `chargeId` to look up the underlying transaction.

## Pause, cancel, reactivate

- **Pause** (`PATCH /v1/subscriptions/{id}/pause`) stops generating new cycles but preserves the subscription. Useful for "snooze 1 month" UX.
- **Cancel** (`PATCH /v1/subscriptions/{id}/cancel`) terminates the subscription. To resume billing after cancellation, create a new subscription.
- **Reactivate** (`PATCH /v1/subscriptions/{id}/reactivate`) resumes a paused subscription.

## Updating the payment method (customer settings)

When a card expires or is replaced, update the customer settings:

```bash
PATCH /v1/subscriptions/{id}/customer-settings
{
  "paymentMethod": {
    "type": "credit",
    "card": { "cardId": "<NEW_VAULTED_CARD_ID>" }
  }
}
```

The next cycle will use the new card. For seamless renewals on card reissue, enable network tokens (see the `tokenization` skill).

## Dunning (retry on failure)

When a cycle fails (`subscription.cycle_failed`), the merchant's retry policy applies. Each retry creates a new entry in `paymentHistory` with the incremented `attemptNumber`. Best practices:

- Combine with **Smart Flow fallback**: the first retry routes to a different provider, often recovering 5-15% of failed cycles.
- Listen for `subscription.cycle_failed` and `subscription.unpaid` events to email customers a card-update link.
- Use **Network Tokens** for silent card-credential refresh on issuer reissue.

## 3DS2 and antifraud on recurring charges

Recurring cycles are **merchant-initiated transactions (MIT)**. They typically bypass 3DS challenge because there is no customer present. In the Smart Flow, route MIT cycles through a branch with 3DS2 disabled. Possible patterns:

- Use a metadata key on the underlying charge to signal MIT (e.g., `metadata.initiator = "merchant"`), and conditionally route to a no-3DS branch.
- The very first charge of a subscription is usually customer-initiated and can carry a 3DS2 challenge to anchor the consent.

Antifraud can stay enabled on recurring charges if the merchant wants ongoing risk scoring; the friction (no UX, sync decisions) is acceptable.

## Webhook events

| Event | When |
|---|---|
| `subscription.created` | New subscription created (when trial is not active). |
| `subscription.trial_started` | Subscription created with active trial. |
| `subscription.activated` | First payment approved. |
| `subscription.updated` | Value, items, or other config changed. |
| `subscription.paused` | Paused. |
| `subscription.resumed` | Reactivated. |
| `subscription.unpaid` | A cycle failed and the subscription is past-due. |
| `subscription.expired` | Expired. |
| `subscription.canceled` | Canceled. |
| `subscription.cycle_failed` | A cycle could not be processed. |

See the `webhooks` skill for signature verification, retry schedule, and event payload structure.

## Pitfalls

- **Card-on-file required.** Subscriptions don't accept ad-hoc tokens. Vault first via `POST /v1/cards`, then reference by `card.cardId`.
- **Time zones.** `startAt` and `scheduledAt` are interpreted in America/Sao_Paulo by default. Be explicit about TZ in customer-facing UIs.
- **Pause window.** While paused, no cycles generate. Surface this clearly on the customer's billing screen so they understand billing is on hold, not free service.
- **Cycle vs. charge.** Reports and analytics distinguish `cycleId` and `chargeId`. Reconcile by `cycleId` for billing-cycle reporting, and by `chargeId` for transaction-level reporting.
- **`recurrence.interval` valid values.** Verify with the API reference for the merchant's plan; assume `monthly` works and check before relying on others.
