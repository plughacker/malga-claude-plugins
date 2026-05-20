---
name: api-charges
description: Use this skill when implementing or troubleshooting direct REST integrations against Malga's Charges and Sessions APIs. Triggers on questions about "criar cobrança Malga", "POST /charges", "Malga charge API", "capture pre-authorized", "estorno", "refund", "Malga Sessions API", "criar sessão", "pagar sessão", "cancelar sessão", "session history", idempotência em cobrança Malga, status de cobrança, sandbox charge status, listing charges by client. Covers payload structure for credit card, Pix, and Boleto charges, the Charges versus Sessions decision, and common errors.
---

# Malga Charges and Sessions APIs

Malga exposes two complementary payment APIs.

- **Charges** — one transaction at a time. The merchant builds the full payload (payment method, amount, customer, payment flow). Best fit when the merchant owns the UX and just needs to process a payment.
- **Sessions** — represents an **order** with items, customer, and accepted payment methods. The session is then *paid* through the API, a payment link, or the Malga Checkout SDK. Best fit when the same order may be paid through multiple channels.

## Authentication

Every request needs both headers:

```
X-Client-Id: <YOUR_CLIENT_ID>
X-Api-Key:   <YOUR_SECRET_KEY>
Content-Type: application/json
```

Base URL: `https://api.malga.io/v1/`

## Idempotency

For any `POST` that creates a resource (charges, sessions, subscriptions), send an `X-Idempotency-Key` header with a unique value per logical operation (typically a UUID generated on the merchant side). Retries with the same key return the original response instead of creating duplicates. Reference: <https://docs.malga.io/documentations/more/idempotency>.

## Create a charge — minimal credit-card example

```bash
curl -X POST 'https://api.malga.io/v1/charges' \
  -H 'X-Client-Id: $MALGA_CLIENT_ID' \
  -H 'X-Api-Key: $MALGA_API_KEY' \
  -H 'X-Idempotency-Key: 9b2c0d3a-...' \
  -H 'Content-Type: application/json' \
  -d '{
    "merchantId": "<MERCHANT_ID>",
    "amount": 5000,
    "currency": "BRL",
    "orderId": "order-123",
    "paymentMethod": {
      "type": "credit",
      "installments": 1,
      "card": { "tokenId": "<CARD_TOKEN>" }
    },
    "customer": { "id": "<CUSTOMER_ID>" }
  }'
```

`amount` is in **cents** (BRL). `paymentMethod.type` accepts at least `credit`, `pix`, and `boleto`. For Pix, omit `card` and add `pix` config; for Boleto, add `boleto` config (due date, instructions).

## Charge lifecycle

A charge can be in states like `pending`, `pre_authorized`, `authorized`, `captured`, `failed`, `refunded`. Key operations:

| Action | Endpoint |
|---|---|
| List charges | `GET /charges` (paginated, filter by status/date) |
| Get one | `GET /charges/{id}` |
| Capture pre-auth | `POST /charges/{id}/capture` |
| Refund | `POST /charges/{id}/refund` |
| Sandbox: force status | `POST /charges/{id}/sandbox-status` |
| Sandbox: force antifraud | `PATCH /charges/{id}/sandbox-antifraud-status` |

## Sessions — when to use

Use Sessions when:
- The order has multiple items and you want Malga to render the checkout (Checkout SDK or Payment Link).
- You need the same order payable through different channels (link, hosted, embedded).
- You want history of session events (`GET /sessions/{id}/history`).

Session lifecycle endpoints:

| Action | Endpoint |
|---|---|
| Create | `POST /sessions` |
| Get | `GET /sessions/{id}` |
| Update status | `PATCH /sessions/{id}/status` |
| Pay | `POST /sessions/{id}/pay` |
| Cancel | `POST /sessions/{id}/cancel` |
| History | `GET /sessions/{id}/history` |
| Get with company settings | `GET /sessions/{id}/settings` |

Reference: <https://docs.malga.io/documentations/more/sessions>.

## Smart Flow attachment

Both charges and sessions can carry a `paymentFlow.metadata` object that feeds Smart Flow rules. See the `smart-flows` skill for operators, available properties, and reserved keys.

```json
"paymentFlow": {
  "metadata": {
    "channel": "app",
    "highTicket": true,
    "daysToEvent": 45
  }
}
```

## Common errors

- `401 / 403` — invalid or scope-limited key. If using a Client Token, the call may not be allowed; use the secret API key from the backend.
- `409 / duplicate` — idempotency key collision. Reuse the original response.
- `422` — payload validation. Check the `details` array for the offending field.
- `failed` with retryable error — Smart Flow will already have tried the next provider. If still failed, see the declined-code table: <https://docs.malga.io/documentations/type-tables/declined-code>.

## References

See `references/charges-payloads.md` for full payload examples (credit card with installments, Pix, Boleto, pre-auth + capture, refund) and the declined-code mapping.
