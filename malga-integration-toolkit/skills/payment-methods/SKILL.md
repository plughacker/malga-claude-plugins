---
name: payment-methods
description: Use this skill when the user is choosing or implementing specific payment methods supported by Malga. Triggers on questions about "métodos de pagamento Malga", "cartão de crédito Malga", "Pix Malga", "Boleto Malga", "NuPay Malga", "Drip Malga", "Voucher Malga", "PicPay Malga", "Apple Pay Malga", "Click to Pay Malga", "qual método de pagamento usar Malga", "diferença Pix Boleto Malga", "expiresIn Pix Malga", "dueDate boleto Malga". Covers each supported paymentType, the relevant fields per method, when each is appropriate, and reversal / cancellation semantics per method.
---

# Malga payment methods

The `paymentMethod.paymentType` field in the Charges API determines the rails Malga uses. This skill summarizes each supported method, the paired `paymentSource`, when to use it, and the cancel / refund semantics.

For deep coverage of the three most common methods, see the dedicated skills: **`credit-card`** (pre-auth/capture, partial refunds, revert_void, multi-currency), **`pix`** (QR codes, async refund, amount drift), **`boleto`** (no refund, interest/fine, items).

Reference: <https://docs.malga.io/api-reference/charges/realizar-nova-cobranca> (the `paymentMethod` and `paymentSource` schemas list all variants).

## Quick reference

| paymentType | paymentSource | Typical use | Settlement |
|---|---|---|---|
| `credit` | `card` (raw / cardId / token) | Card payments, BR + cross-border | T+30 or T+1 with anticipation |
| `pix` | (none required) | Instant payment BR, low fee | T+0 |
| `boleto` | (none required) | Slow but no card needed | T+1 after settlement |
| `nupay` | NuPay variant | Nubank in-app pay | T+0/T+1 |
| `drip` | Drip variant | Drip wallet | provider-specific |
| `voucher` | Voucher (e.g., VR/VA) | Meal/food vouchers | provider-specific |
| `picpay` | PicPay variant | PicPay wallet | T+0 |
| `apple_pay` | Apple Pay variant | Apple wallet | T+30 (acts as credit) |
| `click_to_pay` | Click to Pay variant | Network-hosted wallet | T+30 (acts as credit) |

## Credit card (`credit`)

The most common method. Use one of the paymentSource variants from the `tokenization` skill: raw card data, `tokenId` (from the Tokenization SDK), `cardId` (vaulted), or `customer.cardId`.

Key fields:

```json
"paymentMethod": { "paymentType": "credit", "installments": 1 }
"paymentSource": { "sourceType": "card", "card": { ... } }
```

Pre-authorization: set `capture: false`. Capture later via `POST /charges/{id}/capture`. See the `api-charges` skill for examples.

Notable behaviors:
- **Reversal automático de estorno (revert void)**: in rare cases a successful refund may need to be reversed. The webhook event is `transaction.revert_void`. Reference: <https://docs.malga.io/documentations/payment-methods/credit-card#reversao-automatica-de-um-estorno-revert-void>.
- **Probe void**: Malga's duplicate-detection probe may cancel a charge automatically. The webhook event is `transaction.probe_void`.

## Pix (`pix`)

Instant payment rail in Brazil. No `paymentSource` is required when used with a `customerId` — Malga generates a QR code and the customer pays via their bank app.

```json
"paymentMethod": {
  "paymentType": "pix",
  "expiresIn":   3600
}
```

- `expiresIn` is seconds until the Pix invoice expires.
- Response includes `paymentMethod.qrCodeData` (copy-paste string) and `paymentMethod.qrCodeImageUrl` (image URL).
- The charge enters `pending` until paid; on payment it transitions to `authorized`.
- A `transaction.authorized` webhook fires when funds settle.
- Refunds may go through `refund_pending` then `voided` (async path).
- The settled `amount` may differ from the original (interest, discount). Always read `amount` from the webhook.

## Boleto (`boleto`)

Brazilian bank slip. Slower (1-3 business days to settle), no card data needed. Common for adults without cards or for B2B invoices.

```json
"paymentMethod": {
  "paymentType":  "boleto",
  "expiresDate":  "2026-06-01",
  "instructions": "Não receber após o vencimento",
  "interest": {
    "days":       1,
    "amount":     100,
    "percentage": 0.5
  },
  "fine": {
    "days":       2,
    "amount":     200,
    "percentage": 2
  },
  "items": [
    { "id": "sku-1", "title": "Produto", "unitPrice": 9900, "quantity": 2 }
  ]
}
```

- `expiresDate` is ISO-Date (`YYYY-MM-DD`). Default: 7 days from now.
- `instructions` is free text up to 255 characters. Use `\n` for line breaks.
- `interest` and `fine` are optional. `days` is the grace period after expiration; `amount` is in cents per day; `percentage` is a per-month or total percentage.
- Boleto **cannot be refunded** and does not support pre-authorization or capture.
- Auto-fails (`status: failed`) at the due date if unpaid.

## NuPay (`nupay`)

Nubank's in-app pay. Customer scans a code in the Nubank app to pay. Often used as a low-friction alternative to Pix for Nubank users.

```json
"paymentMethod": { "paymentType": "nupay", ... }
"paymentSource": { "sourceType": "nupay", ... }
```

Exact fields and `paymentSource` structure are NuPay-specific. Refer to the Charges API schema for `paymentMethod.nupay` and `paymentSource.nupay`.

## Drip (`drip`)

Drip wallet. Less common; check Dashboard provider availability before integrating.

## Voucher (`voucher`)

Meal and food benefit cards (VR, VA, Sodexo, Ben, etc.). Restricted to compatible providers. Useful for the food / restaurant industry.

## PicPay (`picpay`)

PicPay wallet payment.

## Apple Pay (`apple_pay`)

Wraps a card from the Apple Wallet. Behaves as a credit card from the merchant's perspective (installments, capture, refund). Requires Apple's domain verification and merchant identifier configuration. See <https://docs.malga.io/documentations/payment-methods/apple-pay>.

## Click to Pay (`click_to_pay`)

Card-network-hosted wallet (Visa Click to Pay, Mastercard Click to Pay). Customer authenticates once with the network and pays across merchants without re-entering card data.

## Choosing the right method (decision tree)

If the merchant is asking which methods to enable:

- **B2C e-commerce in BR**: start with `credit`, `pix`, `boleto`. They cover most of the market.
- **B2C high-volume (subscription, ride-hailing, food)**: prioritize `credit` + `pix`. Boleto rarely needed for impulsive purchases.
- **B2B**: `boleto` is often expected; combine with `pix` for faster settlement.
- **Premium / Apple-heavy demographic**: add `apple_pay` and `click_to_pay`.
- **Subscriptions / recurring**: card-on-file (`credit` with `cardId`); rarely Pix or Boleto since recurrence requires a stored method.

## Method × Smart Flow

The Smart Flow is bound per **method**. A merchant can have different Smart Flows for `credit` and for `pix` even on the same merchant id, routing each to a tailored set of providers.

## Method × refund support

| Method | Refund | Notes |
|---|---|---|
| `credit` | Yes (full and partial) | Standard chargeback risk applies. |
| `pix` | Yes (async, returns to payer) | `refund_pending` then `voided`. |
| `boleto` | **No** | Boleto is not refundable through Malga. Reconcile manually if needed. |
| `nupay`, `picpay`, `voucher`, `drip` | Provider-specific | Check Dashboard. |
| `apple_pay`, `click_to_pay` | Yes (as credit) | Same as credit refund. |

## Pitfalls

- **Each method needs at least one configured provider** in the Smart Flow branch. A merchant with no Pix provider configured will fail Pix charges with a routing error.
- **`installments` only applies to `credit`**. Sending it on other methods is silently ignored or may cause validation errors.
- **Pix and Boleto `expiresIn` / `expiresDate` are not optional in practice**. Without them, defaults vary by provider and may surprise the customer.
- **Refund semantics vary by method**. Always check the method-specific page on docs.malga.io before promising "instant refund" to the customer.
- **NuPay / Drip / Voucher** require coordinated activation with Malga and the chosen provider; do not assume Dashboard-only setup is enough.
