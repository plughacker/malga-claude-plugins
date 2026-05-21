---
name: tokenization
description: 'Implementing Malga card tokenization (PCI-safe Hosted Fields). Triggers: "tokenização Malga", "@malga/tokenization", "Hosted Fields Malga", "PCI DSS Level I", "Client Token", "network tokens Malga", "zero dollar".'
---

# Malga tokenization

> Related: **`customers-and-cards`** for the broader Customer/Card entity model (create customers, link cards to customers, list a customer's cards). This skill focuses on the Tokenization SDK and the PCI surface.



Malga handles card data via tokens so the merchant's servers and frontends never touch raw PAN. Two tokenization paths:

- **Tokenization SDK v2 (`@malga/tokenization`)** — recommended for any browser or app flow. Card inputs are iframes hosted by Malga (Hosted Fields). Compliant with **PCI DSS Level I**. Repo: <https://github.com/plughacker/malga-tokenization>.
- **Server-side `POST /v1/tokens`** — valid only if the merchant has its own PCI scope. Used during card-base migration or rare server-to-server tokenization.

Reference: <https://docs.malga.io/sdks/tokenization/v2/intro>

## Client Token (public key) — required for browser flows

The frontend cannot use the secret `X-Api-Key`. The backend mints a **Client Token** scoped to one or more operations with a finite expiration. The Client Token is safe to ship to the browser.

### Via the SDK Node

```ts
const { publicKey, expires, scope } = await malga.auth.createPublicKey({
  scope:   ['tokens'],
  expires: 60                   // seconds
});
```

### Via raw REST

```bash
POST https://api.malga.io/v1/auth
Headers: X-Client-Id, X-Api-Key
Body:
{
  "scope":   ["tokens"],
  "expires": 60
}
```

Available scopes: `customers`, `cards`, `tokens`, `charges`, `webhooks`, `sessions`, `auth`, `reports`, `flows`, `sellers`. Combine if the same public key has to do more than one thing on the frontend. Treat Client Tokens as short-lived (per-session, not per-deploy).

## Tokenization SDK (`@malga/tokenization`)

Install:

```bash
npm install @malga/tokenization
# or
yarn add @malga/tokenization
# or
pnpm add @malga/tokenization
```

Render four containers with **fixed IDs** (the SDK matches against these):

```html
<form>
  <div id="card-number"></div>
  <div id="card-holder-name"></div>
  <div id="card-cvv"></div>
  <div id="card-expiration-date"></div>
</form>
```

Initialize the SDK with the credentials, the field config, and the sandbox flag:

```ts
import { MalgaTokenization } from '@malga/tokenization';

const malgaTokenization = new MalgaTokenization({
  apiKey:   '<CLIENT_TOKEN_PUBLIC_KEY>',  // from POST /v1/auth
  clientId: '<CLIENT_ID>',
  options: {
    sandbox: true,
    config: {
      fields: {
        cardNumber:         { container: 'card-number',         placeholder: 'Card number',     needMask: true,  defaultValidation: true },
        cardHolderName:     { container: 'card-holder-name',    placeholder: 'Holder name',     needMask: false, defaultValidation: true },
        cardCvv:            { container: 'card-cvv',            placeholder: 'CVV',             needMask: true,  defaultValidation: true },
        cardExpirationDate: { container: 'card-expiration-date',placeholder: 'MM/YY',           needMask: true,  defaultValidation: true }
      },
      preventAutofill: false,
      styles: { /* see Styles doc */ }
    }
  }
});
```

Field-config naming:
- HTML container `id` is **kebab-case** (`card-number`, `card-holder-name`, `card-cvv`, `card-expiration-date`).
- Field config key is **camelCase** (`cardNumber`, `cardHolderName`, `cardCvv`, `cardExpirationDate`).

Built-in masks (when `needMask: true`):
- `card-number`: `9999 9999 9999 9999` (up to 16 digits) or `9999 9999 9999 999999` (longer).
- `card-expiration-date`: `MM/YY`.

Default validations (when `defaultValidation: true`): length checks, card brand detection on `card-number`, expiration date in the future, etc.

## Methods

```ts
malgaTokenization.on(eventType, callback);
const { tokenId, error } = await malgaTokenization.tokenize();
```

### Events

| Event | Fires when |
|---|---|
| `cardTypeChange` | `card-number` content changes; payload contains the detected card brand. |
| `validity` | Any field's validation state changes. Payload: `{ field, valid, error, empty, potentialValid, parentNode }`. |
| `focus` | A field gains focus. |
| `blur` | A field loses focus. |

```ts
malgaTokenization.on('validity', (state) => {
  console.log(state.field, 'valid?', state.valid, 'error', state.error?.message);
});

malgaTokenization.on('cardTypeChange', ({ card }) => {
  console.log('Brand', card?.niceType);
});
```

### `tokenize()` — return value

`tokenize()` returns `{ tokenId, error }` — it does **not** throw on validation or tokenization errors. Check both fields:

```ts
const { tokenId, error } = await malgaTokenization.tokenize();

if (error) {
  // error.type, error.code, error.message, error.details, error.declinedCode
  return;
}

// send tokenId to your backend; the backend uses it on POST /charges
```

## Using a token in a charge

After tokenization, pay through Charges. The shape depends on whether you use the REST API or the SDK Node — see the `api-charges` and `sdk-node` skills.

REST:
```json
"paymentSource": { "sourceType": "token", "tokenId": "<TOKEN_FROM_SDK>" }
```

A `tokenId` is single-use for charges. To save a card on file for reuse, persist it as a Card (see below) or pass `linkCardToCustomer: true` on the create-charge call (SDK convenience).

## Cards API (vaulting)

| Action | Endpoint |
|---|---|
| Create card from token | `POST /v1/cards` |
| List | `GET /v1/cards?customerId=...` |
| Get one | `GET /v1/cards/{id}` |
| List customer's cards | `GET /v1/customers/{id}/cards` |

Future charges reference the card via `paymentSource.cardId` (REST) or by setting `cardId` in the SDK schema.

## Token CVV

To capture only the CVV on a follow-up purchase using a vaulted card (PCI-safe CVV re-entry), use the Token CVV flow. The Tokenization SDK supports rendering only the CVV field. Reference: <https://docs.malga.io/documentations/tokenization/token-cvv>.

In a charge (REST):
```json
"paymentSource": { "sourceType": "card", "cardId": "<CARD_ID>", "tokenCvv": "<TOKEN_CVV>" }
```

## Zero-dollar validation

A zero-dollar charge validates a card with the issuer without billing it. Useful during vaulting. Reference: <https://docs.malga.io/documentations/tokenization/zero-dollar>.

In the Checkout SDK, enable it on the `credit` payment method:
```js
checkout.paymentMethods = { credit: { cvvCheck: true, cvvCheckMerchantId: '<MERCHANT_ID>' } };
```

In the SDK Node, pass `zeroDollar` inside the card object:
```ts
paymentMethod: {
  type: 'credit',
  installments: 1,
  card: {
    holderName: '...',
    number:     '...',
    cvv:        '...',
    expirationDate: '...',
    zeroDollar: { merchantId: '<MERCHANT_ID>', cvvCheck: true }
  }
}
```

## Network Tokens (Tokenização de Bandeira)

Network tokens replace the card PAN with an issuer-managed token (Visa Token Service / Mastercard MDES), improving approval rates and refreshing automatically when the card is reissued.

- **Must be enabled** by Malga support — contact the team in the Dashboard to turn it on.
- Supports **Visa and Mastercard only**.
- Auto-tokenizes only **valid cards** (cards with at least one prior successful transaction or a successful zero-dollar validation).
- Cryptograms are generated automatically per transaction; no payload change required.
- Per-brand opt-out is available.

Lifecycle status enum:

| Status | Meaning |
|---|---|
| `active` | Available for transactions. |
| `suspended` | Temporarily unavailable; can be reactivated. |
| `deleted` | Removed; cannot be reactivated. |
| `failed` | Token creation failed. |

Supported providers: Adyen, Cielo, Getnet, PagSeguro, Mercado Pago (all for Visa + Master). Reference: <https://docs.malga.io/documentations/tokenization/network-tokens>.

## Card-base migration

When migrating from another gateway, an existing card vault can be ingested. This is a support-led process. Reference: <https://docs.malga.io/documentations/tokenization/card-migrations>.

## Pitfalls

- **Don't rename the container IDs**. The SDK looks for exact strings `card-number`, `card-holder-name`, `card-cvv`, `card-expiration-date`.
- **`tokenize()` doesn't throw**. Always check `{ tokenId, error }`.
- **Single-use token**. After consuming a `tokenId` in a charge, it cannot be reused. To allow repeated charges, persist as a card via `POST /v1/cards`.
- **Public key is short-lived**. Generate per session, not per deploy. The `expires` is in seconds.
- **HTTPS required**. Hosted Fields and the iframe runtime do not load on plain HTTP.
- **Network Tokens is opt-in**. Don't assume it is enabled by default; contact Malga support.
