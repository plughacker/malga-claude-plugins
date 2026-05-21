---
name: payment-link
description: 'Accepting payments via Malga no-code Link de Pagamento. Triggers: "Malga Link de Pagamento", "cobrar sem site", "link de pagamento Malga", "session payment link", "cobrar via WhatsApp Malga".'
---

# Malga Link de Pagamento (no-code)

Link de Pagamento is Malga's hosted checkout reachable via a shareable URL. Zero frontend code required. Good fit for:

- Sales/CX teams collecting payment without integrating.
- Merchants who don't yet have an e-commerce site.
- One-off invoices or quotes paid by link (WhatsApp, email).

Reference: <https://docs.malga.io/documentations/payment-link/intro>

## Two ways to create a link

### 1. Dashboard (truly no-code)

In the Malga Dashboard, the merchant fills a form (amount, methods, customer optional, expiration) and gets a shareable URL. No engineering involvement.

### 2. Sessions API (programmatic)

Create a session via `POST /v1/sessions` — the response includes a hosted payment URL. This is the same Sessions API used by the Checkout SDK; the difference is that no SDK mounts on the merchant side. The customer pays through Malga's hosted page.

```bash
POST /v1/sessions
{
  "merchantId":          "<MERCHANT_ID>",
  "name":                "Consulta médica",
  "amount":              19900,
  "currency":            "BRL",
  "dueDate":             "2026-06-01T09:28:45.000Z",
  "paymentMethods": [
    { "paymentType": "credit", "installments": 1 },
    { "paymentType": "pix",    "expiresIn": 3600 },
    { "paymentType": "boleto", "expiresDate": "2026-06-05" }
  ],
  "items": [
    { "name": "Consulta", "description": "...", "unitPrice": 19900, "quantity": 1, "tangible": false }
  ],
  "description":         "Consulta agendada",
  "statementDescriptor": "MINHACLINICA"
}
```

Each entry in `paymentMethods` is an object (`{ paymentType, ... }`), not a string. The response includes the session id, a scoped `publicKey` for paying it, and the hosted-link URL where the customer can complete the payment. Session lifecycle methods (`cancel`, `update status`, `history`) still apply.

## Customizing the hosted page

The look-and-feel of the hosted link is controlled by the **Settings API** (`/v1/settings`) — logo, primary color, optional secondary brand. Endpoints:

- `POST /v1/settings/payment-link` — create or replace a config
- `GET /v1/settings/payment-link` — read current config
- `PATCH /v1/settings/payment-link` — update fields

Reference: <https://docs.malga.io/api-reference/settings/criar-configuracao-de-link-de-pagamento>

```json
PATCH /v1/settings/payment-link
{
  "logoUrl": "https://cdn.example.com/logo.png",
  "primaryColor": "#2FAC9B",
  "displayName": "Minha Loja"
}
```

## Webhooks for link payment

Configure webhooks for `charge.succeeded` / `charge.failed` / `session.paid` to update the merchant's internal system when a link is paid. See the `webhooks` skill.

## Typical sales/CX use cases

- **Recover a failed checkout**: CX agent generates a personalized link for the customer.
- **Outbound sales**: sales rep closes a deal and sends a Pix-or-card link via WhatsApp.
- **Field collection**: a service technician finishes a job and asks the customer to scan the link's QR code.

## Limitations

- A single link pays one session; for repeat collection use **Recurrence** (see `recurrence` skill) or generate a new link per invoice.
- Custom checkout fields are limited to what Sessions accepts (items, customer). For richer UX, use the Checkout SDK with custom frontend.
- Expirations are enforced server-side; expired sessions cannot be paid.
