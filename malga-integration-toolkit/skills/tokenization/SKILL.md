---
name: tokenization
description: Use this skill when implementing card tokenization with Malga to stay PCI-compliant and to enable card-on-file or one-click flows. Triggers on questions about "tokenização cartão Malga", "Malga Tokenization SDK", "Hosted Fields Malga", "PCI DSS Level I Malga", "client token Malga", "chave pública Malga", "Malga card vault", "migração de base de cartões Malga", "network tokens Malga", "POST /tokens Malga". Covers when to tokenize on the client (Tokenization SDK / Hosted Fields) versus on the server, how Client Tokens (public keys) work, the Cards API, and migration patterns.
---

# Malga tokenization

Malga handles card data via tokens so the merchant's servers and frontends never touch PAN. Two tokenization paths:

- **Tokenization SDK (Hosted Fields)** — recommended. Card inputs are iframes hosted by Malga; the merchant only sees a `tokenId`. Compliant with **PCI DSS Level I**. Repo: <https://github.com/plughacker/malga-tokenization>.
- **Server-side `POST /v1/tokens`** — only valid if the merchant has its own PCI scope. Used for migrating an existing card vault.

Reference: <https://docs.malga.io/sdks/tokenization/v2/intro>

## Client Token (public key) — required for browser flows

The frontend cannot use the secret `X-Api-Key`. Instead, the backend mints a **Client Token** scoped to `tokens` (and optionally other limited scopes) with a finite expiration. The Client Token is safe to ship to the browser.

```bash
POST https://api.malga.io/v1/auth
Headers: X-Client-Id, X-Api-Key
Body:
{
  "scope": ["tokens"],
  "expires": 31104000
}
```

Response includes `publicKey`. Send that to the browser, not the secret key.

## Tokenization SDK (Hosted Fields) — recommended

```html
<script src="https://sdk.malga.io/tokenization/v2/tokenization.js"></script>
<div id="number"></div>
<div id="holder"></div>
<div id="expiry"></div>
<div id="cvv"></div>

<script>
  const tokenizer = window.Malga.Tokenization({
    clientId: '<CLIENT_ID>',
    publicKey: '<CLIENT_TOKEN>',
  });

  await tokenizer.mount({
    fields: {
      cardNumber:   '#number',
      cardHolder:   '#holder',
      cardExpiration: '#expiry',
      cardCvv:      '#cvv',
    },
    styles: {
      base:    { color: '#111', fontSize: '16px', fontFamily: 'system-ui' },
      invalid: { color: '#c00' },
      focus:   { borderColor: '#2FAC9B' },
    },
  });

  const { tokenId } = await tokenizer.tokenize();
  // send tokenId to your backend; backend uses it on POST /charges
</script>
```

The merchant's DOM **never receives** the raw card number. Each field is an isolated iframe. Customization is full via CSS-in-JS-style style objects.

## Cards API — vaulting a token for reuse

A `tokenId` from the SDK is single-use by default for `POST /charges`. To save a card on file, persist it as a card:

```bash
POST /v1/cards
{
  "tokenId": "<TOKEN_ID>",
  "customerId": "<CUSTOMER_ID>"
}
```

Future charges reference the card by `card.id` instead of `card.tokenId`. List and detail endpoints:

- `GET /v1/cards?customerId=...`
- `GET /v1/cards/{id}`
- `GET /v1/customers/{id}/cards`

## Network Tokens

Malga supports network tokens (Visa Token Service, Mastercard MDES) where the card is replaced by an issuer-managed token, improving approval rates and refresh on card reissue. Configured in the Dashboard per merchant. Reference: <https://docs.malga.io/documentations/tokenization/network-tokens>.

## Card-base migration

When migrating from another gateway, Malga can ingest existing tokens (subject to provider cooperation). Process:

1. Coordinate with Malga and the previous gateway to export the token vault securely.
2. Malga imports the vault and maps existing tokens to Malga `cardId`s.
3. Customer-on-file charges continue without re-collecting card data.

This is a managed migration — contact Malga support to start.

## Pitfalls

- Treat the Client Token as short-lived. Generate it per session, not per app deploy.
- Hosted Fields require running on **HTTPS** (and on supported browsers). Local dev: use `https://localhost` via mkcert or run behind a proxy.
- Reserved Smart Flow metadata keys still apply when sending the resulting `tokenId` in a charge (see `smart-flows`).
