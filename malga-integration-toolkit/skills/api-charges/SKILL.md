---
name: api-charges
description: Use this skill when implementing or troubleshooting direct REST integrations against Malga's Charges and Sessions APIs. Triggers on questions about "criar cobrança Malga", "POST /charges", "Malga charge API", "capture pre-authorized", "estorno", "refund", "Malga Sessions API", "criar sessão", "pagar sessão", "cancelar sessão", "session history", idempotência em cobrança Malga, status de cobrança Malga, sandbox charge status. Covers payload structure for credit card, Pix and Boleto charges, the charge status enum, the Charges versus Sessions decision, and common errors.
---

# Malga Charges and Sessions APIs

Malga exposes two complementary payment APIs.

- **Charges** — one transaction per call. The merchant builds the full payload (payment method, amount, customer, payment flow). Best fit when the merchant owns the UX and just needs to process a payment.
- **Sessions** — represents an **order** (cart with items, customer, and accepted payment methods). The session is then *paid* through the API, a payment link, or the Malga Checkout SDK. A session can be paid **only once**. Best fit when the order is paid via the Malga-hosted UI or when the same order may be paid through multiple channels.

References:
- API entry point: <https://docs.malga.io/api-reference/about-apis>
- Create charge: <https://docs.malga.io/api-reference/charges/realizar-nova-cobranca>
- Sessions guide: <https://docs.malga.io/documentations/more/sessions>
- Idempotency: <https://docs.malga.io/documentations/more/idempotency>

## Authentication and base URL

Every request needs both headers:

```
X-Client-Id:   <YOUR_CLIENT_ID>
X-Api-Key:     <YOUR_SECRET_KEY>
Content-Type:  application/json
```

Base URL: `https://api.malga.io/v1/`

Sandbox uses the same URL with sandbox credentials. The merchant's credentials decide the environment.

## Idempotency

For any `POST` that creates a resource (charges, sessions, subscriptions), send an `X-Idempotency-Key` header with a unique value per logical operation (typically a UUID v4 generated on the merchant side). Retries with the same key return the original response instead of creating duplicates.

The Malga service stores the key plus the request body, then returns the same response (success **or** error) for subsequent calls. If the validation phase failed on the first attempt, no idempotent response is stored.

**Race condition:** if two requests with the same idempotency key arrive simultaneously, one may succeed and another may fail with HTTP 409 `Transaction is processing` or HTTP 400 `There is a transaction with the same idempotency key in transaction at that time`. The recommendation is to retry on 409/400 with at least a 10-second interval, up to 3-5 attempts.

## Charge payload structure

The charge body has three top-level required pieces (`merchantId`, `amount`, `paymentMethod`, `paymentSource`) and several optional objects.

```json
{
  "merchantId":          "<MERCHANT_ID>",
  "amount":              150,
  "currency":            "BRL",
  "statementDescriptor": "LOJA JOAO",
  "description":         "Pedido #231",
  "orderId":             "ord-2026-0001",
  "customerId":          "<CUSTOMER_ID>",
  "capture":             false,
  "paymentMethod": {
    "paymentType":  "credit",
    "installments": 1
  },
  "paymentSource": {
    "sourceType": "card",
    "card":       { "cardNumber": "...", "cardCvv": "...", "cardExpirationDate": "06/2028", "cardHolderName": "JOAO DA SILVA" }
  },
  "fraudAnalysis": { ... },
  "splitRules":    [ ... ],
  "vendor":        { ... },
  "paymentFlow":   { "metadata": { ... } },
  "threeDSecure2": { ... },
  "appInfo":       { "platform": { ... }, "device": { ... }, "system": { ... } }
}
```

Important shape notes:

- `amount` is integer cents (BRL by default).
- `paymentMethod` and `paymentSource` are **separate top-level objects**. `paymentMethod` describes *what* (credit, pix, boleto, nupay, drip, voucher, picpay, apple_pay, click_to_pay). `paymentSource` describes the source of funds (card data, tokenId, cardId, customerId, wallet info).
- `capture: false` creates a pre-authorization; capture it later. `capture: true` (or omitting) auto-captures.
- `customerId` is at the top level (not nested in a `customer` object).
- `paymentFlow.metadata` feeds Smart Flow conditionals. See the `smart-flows` skill.

## paymentSource variants (most common)

| Variant | Shape |
|---|---|
| One-shot card | `{ "sourceType": "card", "card": { "cardNumber": "...", "cardCvv": "...", "cardExpirationDate": "06/2028", "cardHolderName": "..." } }` |
| Vaulted card | `{ "sourceType": "card", "cardId": "<CARD_ID>" }` |
| Token (from Tokenization SDK) | `{ "sourceType": "token", "tokenId": "<TOKEN_ID>" }` |
| Customer card-on-file | `{ "sourceType": "customer", "customerId": "<CUSTOMER_ID>" }` |
| Card + tokenCvv | `{ "sourceType": "card", "cardId": "...", "tokenCvv": "<TOKEN_CVV>" }` |

For Pix and Boleto, `paymentSource` is often unused (the channel provides the funds).

## Status lifecycle

The charge `status` enum is:

```
pending → pre_authorized → authorized
                                     ↘ voided
                                     ↘ charged_back
       ↓ failed
       ↓ canceled
       ↓ capture_pending
       ↓ refund_pending
```

| Status | Meaning |
|---|---|
| `pending` | Created, awaiting provider action (typical for Pix, Boleto). |
| `pre_authorized` | Card pre-authorization succeeded. |
| `authorized` | Captured (default outcome of `capture: true`). |
| `capture_pending` | Capture in progress (async path). |
| `failed` | Declined by issuer. |
| `canceled` | Authorized but not captured charge was canceled. |
| `voided` | Authorized + captured charge was reversed. |
| `charged_back` | Disputed by cardholder. |
| `refund_pending` | Refund in progress (async path, e.g., Pix). |

## Charge operations

| Action | Endpoint |
|---|---|
| Create | `POST /v1/charges` |
| List | `GET /v1/charges` (paginated, filterable) |
| Get one | `GET /v1/charges/{id}` |
| Capture pre-auth | `POST /v1/charges/{id}/capture` |
| Refund (a.k.a. void) | `POST /v1/charges/{id}/void` |
| Sandbox force status | `POST /v1/charges/{id}` with `{ "status": "authorized" \| "voided" \| "charged_back" }` |
| Sandbox antifraud status | `PATCH /v1/charges/{id}/...` (see `antifraud` skill) |

The refund operation is implemented as a void at the REST level (`POST /charges/{id}/void`). The SDK exposes it as `malga.charges.refund(id, { amount })` — same operation, friendlier name.

## Sessions

> For the full Sessions deep-dive (lifecycle, scoped publicKey, decision tree, history), see the **`sessions`** skill. The summary below is just the integration touchpoint from a charges perspective.

Use Sessions when the merchant prefers to delegate the actual checkout UI to Malga or wants a unified order object that can be paid via the API, a hosted link, or the Malga Checkout SDK.

### Create

```bash
POST /v1/sessions
{
  "merchantId":          "<MERCHANT_ID>",
  "name":                "Pedido 1",
  "amount":              100,
  "currency":            "BRL",
  "dueDate":             "2026-06-01T09:28:45.000Z",
  "paymentMethods":      [{ "paymentType": "pix", "expiresIn": 30 }],
  "items":               [{ "name": "Item 1", "description": "...", "unitPrice": 1000, "quantity": 1, "tangible": false }],
  "description":         "Pedido Black Friday",
  "statementDescriptor": "LOJA JOAO"
}
```

The response includes the session `id` and a **scoped `publicKey`** that the frontend uses to pay the session safely without exposing the secret API key.

### Pay

The frontend or Malga Checkout SDK pays the session at `POST /v1/sessions/{id}/charge` using the scoped `publicKey` as `X-Api-Key`:

```bash
POST /v1/sessions/{id}/charge
X-Client-Id: <YOUR_CLIENT_ID>
X-Api-Key:   <SESSION_PUBLIC_KEY>
{
  "merchantId":   "...",
  "amount":       150,
  "currency":     "BRL",
  "paymentMethod":{ "paymentType": "credit", "installments": 1 },
  "paymentSource":{ "sourceType": "card", "card": { ... } }
}
```

| Action | Endpoint |
|---|---|
| Create | `POST /v1/sessions` |
| Get | `GET /v1/sessions/{id}` |
| Update status | `PATCH /v1/sessions/{id}` |
| Pay | `POST /v1/sessions/{id}/charge` |
| Cancel | `POST /v1/sessions/{id}/cancel` |
| History | `GET /v1/sessions/{id}/history` |
| Settings-enriched view | `GET /v1/sessions/{id}/settings` |

## Smart Flow attachment

Both charges and sessions can carry a `paymentFlow.metadata` object that feeds Smart Flow rules. Reserved keys (cannot be used): `currency`, `cardBin`, `installments`, `amount`, `brand`, `paymentType`, `operation`. See the `smart-flows` skill.

```json
"paymentFlow": {
  "metadata": {
    "channel": "app",
    "highTicket": true,
    "daysToEvent": 45
  }
}
```

## appInfo for traceability

The optional `appInfo` block lets the merchant tag charges with platform / device / system metadata. Useful when the same Malga account ingests traffic from multiple frontends, plugins, or POS terminals.

```json
"appInfo": {
  "platform": { "integrator": "malga", "name": "vtex-plugin", "version": "1.12" },
  "device":   { "name": "iOS", "version": "17.4" },
  "system":   { "name": "VTEX", "version": "13.12" }
}
```

## Common errors

- `401` / `403` — invalid key or scope-limited key being used for a forbidden operation.
- `400` / `422` — payload validation. The response `details` array points to the offending field.
- `409` — idempotency conflict (concurrent request with the same key, or a race condition). Retry after 10 s.
- `failed` charge — Smart Flow has already routed retries. Check `transactionRequests[]` in the response to see which providers were attempted and the declined codes.

## References

See `references/charges-payloads.md` for full payload examples (credit card with installments, Pix, Boleto, pre-auth + capture, refund, sandbox status change).
