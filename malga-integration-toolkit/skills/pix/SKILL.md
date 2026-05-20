---
name: pix
description: Use this skill when implementing Pix charges on Malga in depth — QR code generation, async refund flow, amount drift, partial refunds, sandbox testing. Triggers on questions about "Pix Malga", "cobrança Pix Malga", "qrCodeData", "qrCodeImageUrl", "expiresIn Pix", "estorno Pix Malga", "refund_pending Pix", "Pix valor diferente", "amount drift Pix", "sandbox Pix Malga", "transaction.refund_pending". Covers the Pix lifecycle, provider support for partial refunds, the async refund flow (refund_pending → voided), and the BR Central Bank settlement rails.
---

# Malga Pix (deep-dive)

Pix is Brazil's instant payment rail (managed by the Banco Central). Funds settle in seconds, 24×7, and the integration model is QR-code based — Malga generates a dynamic QR code that the payer scans in their banking app.

Reference: <https://docs.malga.io/documentations/payment-methods/pix>

## Lifecycle

```
pending → authorized → voided                     (paid, then refunded)
        ↓ failed                                   (rejected before settlement)
        (pending → authorized via async webhook when bank confirms payment)

authorized → refund_pending → voided              (async refund path)
```

| Status | Meaning |
|---|---|
| `pending` | Charge registered with the Central Bank. QR code data available. Awaiting payment. |
| `authorized` | Payment confirmed by the participating bank. |
| `failed` | Rejected by the bank before settlement, or expired without payment. |
| `refund_pending` | Refund requested, awaiting bank confirmation. |
| `voided` | Refund (total or residual) confirmed. |

Webhook events: `transaction.pending`, `transaction.authorized`, `transaction.failed`, `transaction.refund_pending`, `transaction.voided`.

## Request shape

```json
POST /v1/charges
{
  "merchantId":   "<MERCHANT_ID>",
  "amount":       150,
  "currency":     "BRL",
  "capture":      true,
  "paymentMethod":{ "paymentType": "pix", "expiresIn": 3600 },
  "paymentSource":{
    "sourceType": "customer",
    "customer":   { "name": "...", "phoneNumber": "...", "email": "...", "document": { "number": "...", "type": "cpf", "country": "BR" } }
  }
}
```

`expiresIn` is the QR code validity in seconds (relative to now). After expiry, the charge auto-fails. Common values: 600 (10 min), 1800 (30 min), 3600 (1 hr), 86400 (24 hr).

## Response shape

```json
{
  "status": "pending",
  "paymentMethod": {
    "paymentType":    "pix",
    "expiresIn":      3600,
    "qrCodeData":     "00020101021126510014BR.GOV.BCB.PIX0129...",
    "qrCodeImageUrl": "https://..."
  },
  "paymentSource":   { "sourceType": "customer", "customerId": "..." }
}
```

- `qrCodeData` — copy-paste code (string). Show to the customer for "copy code" / "paste in banking app".
- `qrCodeImageUrl` — pre-rendered image URL. Show as a QR code on the page.

Both must be presented to the customer. Most checkouts show both side-by-side because some users prefer scanning, others prefer pasting.

## Amount drift

A Pix transaction may settle for a value **different** from the original `amount` — the payer's bank may apply interest, fees, or discount. Always read `amount` from the **webhook event payload** rather than assuming it equals the original charge amount.

This is a Pix-specific behavior; on credit and boleto it does not happen the same way.

## Partial and total refunds (async)

Pix refunds are asynchronous. The flow:

1. Merchant calls `POST /v1/charges/{id}/void { amount }`.
2. Charge status transitions to `refund_pending`.
3. A new `transactionRequest` with `requestType: void`, `requestStatus: processing` appears.
4. When the receiving bank confirms, a new `transactionRequest` with `requestStatus: success` is added.
5. Charge status moves to `voided` (or stays `authorized` if there is residual after a partial refund).

The `amount`/`originalAmount` distinction works the same as credit (see `credit-card` skill):
- `originalAmount` never changes.
- `amount` shrinks per partial refund.
- Status moves to `voided` only when `amount` reaches zero.

### Provider support for Pix refund

Not every Pix provider supports refunds. Per the official table:

| ProviderType | Total refund | Partial refund |
|---|---|---|
| `MERCADO_PAGO` | Yes | Yes |
| `PAGARME` | Yes | Yes |
| `BB` | Yes | Yes |
| `ZOOP` | Yes | Yes |
| `PAGSEGURO` | Yes | Yes |
| `ADYEN` | Yes | Yes |
| `SAFRAPAY` | Yes | Yes |
| `BS2` | No | No |
| `GETNET` | No | No |

If the merchant's Smart Flow routes a Pix charge through a non-refundable provider, void calls will fail. Route Pix that may be refunded through refund-capable providers.

## Customer payload pattern

Pix charges always use `paymentSource = { sourceType: "customer", customer: { ... } }` (or `customerId` if the customer was created earlier). Pix needs the payer's identification — there is no card.

## Sandbox testing

In `sandbox-api.malga.io`, manually advance a Pix charge:

```bash
POST https://sandbox-api.malga.io/v1/charges/{chargeId}
{ "status": "authorized" }
```

Supported transitions: `authorized`, `voided`, `refund_pending`, `charged_back`.

## Pitfalls

- **`expiresIn` is in seconds**, not minutes. `60` is one minute, not one hour.
- **Don't expose `qrCodeData` without rendering**. Many merchants show the long string raw to customers; pair it with a copy-to-clipboard button.
- **Amount drift is real.** Read settled `amount` from the webhook; do not assume it equals the original.
- **Async refund.** Tell the user "the refund will appear in your bank account within a few moments" — the immediate UI response is `refund_pending`, not `voided`.
- **Provider support varies for refunds.** If BS2 or Getnet is in the Smart Flow, the refund will fail.
- **Default `capture: true`.** Pix has no notion of pre-authorization; setting `capture: false` is ignored.

## Cross-references

- `webhooks` for the async event handling.
- `smart-flows` for routing only to refund-capable providers.
- `customers-and-cards` for the customer payload structure.
