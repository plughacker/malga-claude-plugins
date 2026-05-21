---
name: boleto
description: 'Deep coverage of Malga Boleto charges. Triggers: "boleto Malga", "barcodeData", "expiresDate boleto", "instructions boleto", "interest fine boleto", "boleto não estorna Malga".'
---

# Malga Boleto (deep-dive)

Boleto is a Brazilian bank slip — a paper-like instrument that the payer scans or types into their banking app to pay. Slower than Pix (1-3 business days to settle) but useful for adults without cards and for B2B invoices.

Reference: <https://docs.malga.io/documentations/payment-methods/boleto>

## Lifecycle

```
pending → authorized                              (paid before expiration)
        ↓ failed                                   (expiration reached, auto-canceled by Malga)
```

| Status | Meaning |
|---|---|
| `pending` | Boleto registered at the BR Central Bank. Awaiting payment. |
| `authorized` | Bank confirmed the payment. |
| `failed` | Boleto reached `expiresDate` without payment; Malga auto-canceled. |

Webhook events: `transaction.pending`, `transaction.authorized`, `transaction.failed`.

**Hard constraints (different from credit and Pix):**

- **No refund.** Boleto charges cannot be voided through the API. If the merchant needs to reverse a paid boleto, reconcile manually with the customer.
- **No pre-authorization or capture.** `capture: true` is the only valid mode; setting `capture: false` is ignored.

## Request shape

```json
POST /v1/charges
{
  "merchantId":   "<MERCHANT_ID>",
  "amount":       150,
  "currency":     "BRL",
  "capture":      true,
  "paymentMethod":{
    "paymentType":  "boleto",
    "expiresDate":  "2026-12-31",
    "instructions": "Não receber após o vencimento\nReferência: Pedido #231",
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
      { "id": "sku-1", "title": "Produto A", "unitPrice": 9900,  "quantity": 1 },
      { "id": "sku-2", "title": "Produto B", "unitPrice": 5100,  "quantity": 1 }
    ]
  },
  "paymentSource": {
    "sourceType": "customer",
    "customer":   { "name": "...", "phoneNumber": "...", "email": "...", "document": { "number": "...", "type": "cpf", "country": "BR" } }
  }
}
```

Field semantics:

| Field | Notes |
|---|---|
| `expiresDate` | ISO date (`YYYY-MM-DD`). Default: **7 days** from now. Boleto auto-fails after this date. |
| `instructions` | Free text up to **255 characters**. Use `\n` for line breaks. Appears printed on the boleto. |
| `interest` | Optional. `days` is the grace period after expiry; `amount` is cents per day; `percentage` is a monthly rate. |
| `fine` | Optional. `days` is the grace period; `amount` is a flat fine in cents; `percentage` is a total percentage. |
| `items` | Optional cart-style breakdown for the boleto detail. |

## Response shape

```json
{
  "status": "pending",
  "paymentMethod": {
    "paymentType":     "boleto",
    "expiresDate":     "2026-12-31",
    "barcodeData":     "412343241324321431241341",
    "barcodeImageUrl": "https://...."
  },
  "paymentSource":   { "sourceType": "customer", "customerId": "..." }
}
```

- `barcodeData` — the line of digits (linha digitável). Customer can paste this in their banking app.
- `barcodeImageUrl` — pre-rendered image (PDF or PNG depending on provider). Print or display.

Show both: the digit line for typing, the image for printing or scanning.

## Amount drift on paid boletos

A boleto can be paid for a value **different** from the original `amount` — the bank may apply interest (juros) or fine (multa) at the time of payment, raising the total above the original ticket. Always read `amount` from the webhook payload, not from the original request.

## Customer payload pattern

Boleto charges always use `paymentSource = { sourceType: "customer", customer: { ... } }` (or `customerId`). The customer's identification (CPF/CNPJ, name, address) is required to register the boleto.

## Sandbox testing

In `sandbox-api.malga.io`, manually transition a boleto:

```bash
POST https://sandbox-api.malga.io/v1/charges/{chargeId}
{ "status": "authorized" }
```

Supported manual transitions: `authorized`, `voided`, `charged_back` (sandbox only — production boletos are immutable once issued).

## When to recommend boleto

| Audience | Boleto fit |
|---|---|
| B2B invoicing | High — common payment vehicle. |
| Adults without cards or unbanked customers | High. |
| Impulse / urgent purchases | Low — settlement is 1-3 days. |
| Subscriptions | No — boleto is one-shot, not recurring-friendly. |
| Refund-prone scenarios | Avoid — no refund support. |

## Pitfalls

- **No refund.** If a refund is needed, handle it outside Malga (bank transfer to the customer). Don't promise refundability in the customer-facing UX.
- **No pre-auth / capture.** Boleto is auto-capture by definition.
- **`expiresDate` is a calendar date in BR business day terms.** Bank holidays can extend the effective due date.
- **`instructions` is capped at 255 chars.** Anything longer is truncated by the provider.
- **`interest.amount` is per-day in cents.** Don't pass a total — pass the daily rate.
- **Amount drift.** A boleto paid late will settle for `amount + interest + fine`. Update the merchant's ledger from the webhook, not the original create response.
- **Don't pair with `customerId` of an unknown customer.** The CPF/CNPJ has to match the boleto registration; the provider may reject if it doesn't.

## Cross-references

- `webhooks` for the `transaction.authorized` event that signals payment.
- `customers-and-cards` for the customer payload.
- `payment-methods` for the comparison table across all methods.
