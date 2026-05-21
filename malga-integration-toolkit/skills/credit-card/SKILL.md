---
name: credit-card
description: 'Deep coverage of Malga credit card charges. Triggers: "cartão Malga", "pré-autorização Malga", "capturar cobrança", "estorno parcial cartão", "revert_void Malga", "originalAmount vs amount", "cobrança em USD Malga".'
---

# Malga Credit Card (deep-dive)

Credit card is the primary payment method for most Malga integrations. This skill goes beyond the high-level `payment-methods` overview to cover pre-auth/capture, partial refunds, revert_void semantics, and multi-currency.

Reference: <https://docs.malga.io/documentations/payment-methods/credit-card>.

## Lifecycle

```
pending → pre_authorized → authorized
                                     ↘ voided        (canceled after capture; with financial reversal)
                                     ↘ charged_back  (cardholder dispute / fraud)
        ↓ canceled  (canceled before capture; no financial reversal)
        ↓ failed    (issuer declined before authorization)
```

| Status | Meaning |
|---|---|
| `pending` | Created in Malga, awaiting provider response. |
| `pre_authorized` | Provider reserved funds on the card; capture still required. |
| `authorized` | Funds captured; settlement scheduled. |
| `canceled` | Pre-auth canceled (or reversed before capture). No money moved. |
| `voided` | Captured charge was reversed (money returned to cardholder). |
| `charged_back` | Cardholder disputed the charge. |
| `failed` | Issuer declined before authorization. |

Webhook event names follow the same pattern with the `transaction.` prefix (`transaction.pre_authorized`, `transaction.authorized`, `transaction.voided`, `transaction.charged_back`, `transaction.canceled`, `transaction.failed`).

## Pre-authorization and capture

Two flows:

| Flow | `capture` flag | Result |
|---|---|---|
| Auto-capture | `true` | Charge goes straight to `authorized`. Settlement scheduled. |
| Pre-auth then manual capture | `false` | Charge enters `pre_authorized`. Funds reserved, not captured. |

**Why pre-auth?** Time to run a custom antifraud check, confirm inventory, or get manual approval before committing. The benefit: if you decide not to proceed, a void on a `pre_authorized` charge shows up immediately on the cardholder's statement. A void on an already `authorized` charge can take up to **30 days** to appear, depending on the issuer.

**Capture window.** A pre-auth that is not captured within **7 days** can be auto-released by the acquirer (the reserved funds return to the cardholder). Capture explicitly via `POST /v1/charges/{id}/capture` (or `malga.charges.capture(id, { amount })`).

Partial capture is supported by passing `amount` smaller than the original:

```bash
POST /v1/charges/{id}/capture
{ "amount": 8000 }
```

## Refund — total and partial (REST endpoint is `/void`)

The REST refund endpoint is `POST /v1/charges/{id}/void`. The SDK exposes it as `malga.charges.refund(id, { amount })`.

```bash
POST /v1/charges/{id}/void
{ "amount": 150 }
```

Partial refund: pass `amount` smaller than the current `amount`. After processing, the charge object updates:

- `originalAmount` — **never changes** after the initial authorization. Use this as the "original ticket value".
- `amount` — **shrinks** with each partial refund. Use this as the "current outstanding amount".

The charge stays `authorized` (or `pre_authorized`) while there is residual value. It moves to `voided` only when `amount` reaches zero.

| Step | Operation | Operation amount | Charge `amount` | Status |
|---|---|---|---|---|
| 1 | Authorize / capture | 100 | 100 | `authorized` |
| 2 | Partial refund | 10 | 90 | `authorized` |
| 3 | Partial refund | 20 | 70 | `authorized` |
| 4 | Full refund of residual | 70 | 0 | `voided` |

Multiple partial refunds are allowed; each one is added to `transactionRequests[]` with `requestType: void`. The refund amount cannot exceed the residual `amount`.

## Revert void (Adyen and similar)

Rarely, a successful refund can be reversed by the card network after the fact — typically when a chargeback was opened just before the refund completed.

- The webhook event is `transaction.revert_void`.
- A new entry appears in `transactionRequests[]` with `requestType: revert_void`.
- The charge's `amount` increases back by the reversed refund amount, and the status returns to `authorized`.

Example (full refund reverted):

| # | Operation | Op amount | `amount` | Status |
|---|---|---|---|---|
| 1 | Authorize / capture | 100 | 100 | `authorized` |
| 2 | Partial refund | 10 | 90 | `authorized` |
| 3 | Full refund | 90 | 0 | `voided` |
| 4 | Provider reverses refund | 10 | 10 | `authorized` |

Reference: <https://docs.adyen.com/online-payments/refund/#refund-failed>.

## Handling capture/refund errors

When a capture or void fails at the provider level, Malga returns **HTTP 201** with a new `transactionRequest` of status `failed`, but does **not** change the charge's `status`. Always check the returned charge or the first `transactionRequests[]` entry before assuming success.

```ts
const result = await malga.charges.refund(chargeId, { amount });
const lastRequest = result.transactionRequests?.[0];

if (lastRequest?.requestStatus === 'failed') {
  // Provider rejected the void; charge is still authorized
}
```

## Multi-currency charges

Malga supports charges in currencies other than BRL — the `currency` field on the charge body accepts ISO 4217 uppercase codes (`USD`, `EUR`, etc.). Default is `BRL`.

Caveats:
- Provider support varies. Confirm with Malga support that the configured provider can process the chosen currency.
- The cardholder may pay foreign-exchange fees if the card currency differs from the charge currency.
- Even when same-currency, cross-border (different country) charges may carry issuer fees.

See <https://docs.malga.io/documentations/type-tables/currency-not-supportted> for currency support per provider.

## Card-on-file (recurring) flow

To charge the same card more than once, vault it as a Card first:

1. Frontend: Tokenization SDK → `tokenId`.
2. Backend: `POST /v1/cards` with `{ tokenId, customerId? }` → `cardId`.
3. Subsequent charges: `paymentSource = { sourceType: "card", cardId }`.

For full coverage of vaulting and customer linkage, see the `customers-and-cards` skill. For subscriptions, see `recurrence`.

## Example: pre-auth + capture (REST)

```bash
POST /v1/charges
{
  "merchantId": "...",
  "amount":     12990,
  "currency":   "BRL",
  "capture":    false,                 // pre-auth
  "paymentMethod": { "paymentType": "credit", "installments": 3 },
  "paymentSource": { "sourceType": "card", "cardId": "..." }
}
→ status: "pre_authorized"

POST /v1/charges/{id}/capture
{ "amount": 12990 }
→ status: "authorized"
```

## Example: SDK (Node)

```ts
const charge = await malga.charges.create({
  merchantId,
  amount: 12990,
  capture: false,
  paymentMethod: {
    type: 'credit',
    installments: 3,
    card: { holderName, number, cvv, expirationDate }
  }
});

await malga.charges.capture(charge.id, { amount: 12990 });

// Later, partial refund:
await malga.charges.refund(charge.id, { amount: 5000 });
```

(The SDK uses `paymentMethod.type` and nests `card` inside it; see `sdk-node` for the SDK vs REST schema distinction.)

## Pitfalls

- **`originalAmount` vs `amount`.** After any partial refund, query the charge and use `amount` for outstanding, `originalAmount` only for historical reference.
- **Capture window** of about 7 days for `pre_authorized` charges — acquirers may auto-release older holds.
- **Refund timing on the cardholder statement.** Pre-auth voids show up immediately; post-capture voids can take up to 30 days. Communicate this in customer-facing UX.
- **`revert_void` is rare but real.** Don't assume "refunded = final"; listen for the event and reconcile.
- **HTTP 201 on capture/refund failure** — the provider failure is in `transactionRequests[0].requestStatus`, not the HTTP status code.
- **Currency support is provider-dependent.** Don't assume any provider handles all currencies.
- **`charged_back`** terminates the charge from the merchant's perspective; the dispute is resolved through the acquirer's process, not via the Malga API. See `webhooks` for `transaction.dispute` / `transaction.dispute_closed`.
