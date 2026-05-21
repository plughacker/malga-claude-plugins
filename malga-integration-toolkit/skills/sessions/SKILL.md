---
name: sessions
description: 'Implementing Malga Sessions (order-based payments via API, Link, or Checkout SDK). Triggers: "Malga Session API", "POST /v1/sessions", "pagar sessão", "session publicKey scoped", "isActive sessão", "session history Malga".'
---

# Malga Sessions

A Session is an **order**: items, total amount, accepted payment methods, optional due date and customer. Once created, the session can be paid **once** through the API, a hosted Payment Link, or the Malga Checkout SDK. Sessions exist so the merchant can build the order in the backend and let the customer pay it through different channels without re-issuing credentials.

References:
- Guide: <https://docs.malga.io/documentations/more/sessions>
- API: <https://docs.malga.io/api-reference/sessions/criar-nova-sessao>
- SDK docs: <https://docs.malga.io/sdks/api-sdks/docs/sessions/create-session>

## Session lifecycle

```
created → (optional disable / enable) → paid           (happy path)
                                       ↘ canceled      (manual cancel)
                                       ↘ expired       (past dueDate)
```

Sessions also have an `isActive` boolean that gates whether the session accepts payment at the current moment (the merchant can disable/enable without canceling).

## REST endpoints

| Action | Endpoint |
|---|---|
| Create | `POST /v1/sessions` |
| Get | `GET /v1/sessions/{id}` |
| List | `GET /v1/sessions` (paginated) |
| Update status | `PATCH /v1/sessions/{id}/status` |
| Pay | `POST /v1/sessions/{id}/charge` |
| Cancel | `POST /v1/sessions/{id}/cancel` |
| History | `GET /v1/sessions/{id}/history` |
| Get with company settings | `GET /v1/sessions/{id}/settings` |

## SDK Node methods

```ts
await malga.sessions.create({ ... });
await malga.sessions.find(sessionId);
await malga.sessions.list({ page, limit, ... });
await malga.sessions.cancel(sessionId);
await malga.sessions.enable(sessionId);     // sets isActive = true
await malga.sessions.disable(sessionId);    // sets isActive = false
```

## Create — typical payload

```ts
await malga.sessions.create({
  merchantId: '<MERCHANT_ID>',
  name: 'Link de Pagamento',
  amount: 19990,                       // cents
  currency: 'BRL',
  dueDate: '2026-06-01T03:00:00.000Z',
  paymentMethods: [
    { paymentType: 'credit', installments: 1 },
    { paymentType: 'pix',    expiresIn: 3600 },
    { paymentType: 'boleto', expiresDate: '2026-06-05' },
    { paymentType: 'drip' },
    { paymentType: 'nupay' }
  ],
  items: [
    { name: 'Produto 1', unitPrice: 19990, quantity: 1 }
  ]
});
```

Notes:
- `paymentMethods` is an **array of objects** (not strings). Each entry carries per-method config (e.g., `installments` for credit, `expiresIn` for Pix).
- `amount` is the total in cents; `items.unitPrice * items.quantity` should sum to `amount`.
- `name` is what the customer sees on the hosted page (and what the merchant sees in dashboards).
- `dueDate` is when the session expires.

Response includes:
- `id` — the session id.
- `publicKey` — a **session-scoped public key**, restricted to paying *this* session. Safe to ship to the browser.
- `isActive` — defaults to `true`.
- `status` — `created` after creation.

## The scoped `publicKey`

This is the key reason to prefer Sessions over raw charges when paying through any browser flow. The session-scoped `publicKey`:

- Authorizes **only the pay-session call** for that specific session id.
- Does not work for other sessions or arbitrary charge creation.
- Eliminates the need to ship the merchant's Client Token (which has broader scopes) to the browser.

Use it as `X-Api-Key` on `POST /v1/sessions/{id}/charge`:

```bash
POST /v1/sessions/{id}/charge
Headers:
  X-Client-Id: <YOUR_CLIENT_ID>
  X-Api-Key:   <SESSION_PUBLIC_KEY>
Body:
{
  "merchantId":   "<MERCHANT_ID>",
  "amount":       19990,
  "paymentMethod":{ "paymentType": "credit", "installments": 1 },
  "paymentSource":{ "sourceType": "card", "card": { ... } }
}
```

## Session × Checkout SDK

The Malga Checkout SDK accepts `session-id` and the session-scoped `publicKey` instead of `merchant-id` + a broader public key. This is the recommended pattern for hosted-checkout integrations:

1. Backend creates session → receives `{ id, publicKey }`.
2. Backend sends `{ id, publicKey }` to the frontend.
3. Frontend mounts `<malga-checkout session-id={id} public-key={publicKey} client-id={...}>`.
4. The Checkout pays the session and emits `paymentSuccess`.

See the `checkout-sdk` skill for the mount example.

## Session × Payment Link

The session lifecycle is the backbone of the no-code Payment Link feature. The hosted page that customers reach via the link is a renderer for an underlying session. See the `payment-link` skill for the no-code variants.

## Session vs Charge: which to use

| Pick Charge (`POST /v1/charges`) when... | Pick Session when... |
|---|---|
| The merchant owns the UX and just needs to process a transaction. | The merchant wants Malga to render the checkout (drop-in or hosted link). |
| There is no notion of "order" beyond a single payment. | The order has items, a name, a due date, or multiple accepted methods. |
| The same payment will not be retried through another channel. | The same order may be paid through API, link, or SDK. |
| Pre-authorization + delayed capture is needed. | Pay-once semantics fit (a session is paid exactly once). |

## history and audit

`GET /v1/sessions/{id}/history` returns the chronological events on the session (created, status changes, payment attempts, payment success). Useful for CX investigations: "what happened to session X?".

`GET /v1/sessions/{id}/settings` returns the session enriched with the company-level settings (payment-link branding, locale). Useful when the frontend wants both pieces in one call.

## Pitfalls

- **A session is paid once.** After `paymentSuccess`, the session is consumed. Create a new session for a new order.
- **`disable` ≠ `cancel`.** Disabling keeps the session alive but blocks payment; canceling marks it terminated. Use disable for temporary suspensions (out-of-stock), cancel for definitive ones (order voided).
- **`dueDate` is mandatory in practice** for hosted-link flows so the session can expire on its own. Without it, the merchant must cancel manually.
- **Don't expose the merchant's Client Token to the browser when a session-scoped key would suffice.** The scoped key minimizes blast radius.
- **`amount` must equal `sum(items.unitPrice * items.quantity)`.** If they diverge, the create call rejects.
- **PATCH `/v1/sessions/{id}/status`** is for explicit status transitions (not the same as `enable`/`disable`). Most merchants don't need to call this directly.
