---
name: checkout-sdk
description: Use this skill when implementing or customizing Malga's frontend Checkout SDKs (the drop-in Checkout SDK and the headless Checkout Full SDK). Triggers on questions about "Malga Checkout SDK", "Checkout Full SDK", "Malga frontend integration", "drop-in checkout Malga", "headless checkout Malga", "embed Malga checkout", customizar checkout Malga, eventos do checkout Malga, "Malga UI SDK". Covers when to pick each variant, mounting, events, theming, and how the checkout interacts with the Sessions API.
---

# Malga Checkout SDK (frontend)

Malga ships two UI SDKs for the browser. Both render a PCI-safe checkout backed by a Malga Session.

| SDK | Pick when |
|---|---|
| **Checkout SDK** | Drop-in. Renders a complete, pre-styled checkout. Minimal config. Fastest time-to-market. |
| **Checkout Full SDK** | Headless. Exposes the building blocks (card fields, Pix, Boleto) so the merchant fully controls layout and styling. |

Reference: <https://docs.malga.io/sdks/intro-sdk>

## How they fit with Sessions

The frontend never sees secret API keys. The flow is:

1. **Backend** creates a Malga Session (`POST /v1/sessions`) with the order, customer, and accepted payment methods. The response includes a `sessionId`.
2. **Backend** issues a **Client Token** (public, scoped) — see `tokenization` skill — and returns it plus the `sessionId` to the frontend.
3. **Frontend** mounts the Checkout SDK with the session and client token. The SDK handles card hosted-fields, tokenizes server-side, and pays the session.
4. The merchant listens to events (success, failure, change of method) to navigate the user.

## Checkout SDK — drop-in

```html
<script src="https://sdk.malga.io/checkout/v1/checkout.js"></script>
<div id="malga-checkout"></div>

<script>
  const checkout = window.Malga.Checkout({
    sessionId: '<SESSION_ID>',
    clientId: '<CLIENT_ID>',
    publicKey: '<CLIENT_TOKEN>',     // scoped public key
    container: '#malga-checkout',
    theme: { primaryColor: '#2FAC9B' },
  });

  checkout.on('success', (charge) => { /* redirect to thank-you */ });
  checkout.on('failure', (err)   => { /* show retry */ });
  checkout.mount();
</script>
```

## Checkout Full SDK — headless

Use when the merchant needs full layout control. The SDK exposes primitives:

- Card hosted fields (number, holder, expiry, CVV) — each in its own iframe, PCI-safe.
- Pix renderer (QR code + copy-paste).
- Boleto renderer (line + PDF).

```html
<script src="https://sdk.malga.io/checkout-full/v1/checkout-full.js"></script>
<div id="card-number"></div>
<div id="card-holder"></div>
<div id="card-expiry"></div>
<div id="card-cvv"></div>
<button id="pay">Pagar</button>

<script>
  const checkout = window.Malga.CheckoutFull({
    sessionId: '<SESSION_ID>',
    clientId: '<CLIENT_ID>',
    publicKey: '<CLIENT_TOKEN>',
  });

  await checkout.card.mount({
    fields: {
      number: '#card-number',
      holder: '#card-holder',
      expiry: '#card-expiry',
      cvv: '#card-cvv',
    },
    styles: { base: { color: '#111', fontSize: '16px' } },
  });

  document.getElementById('pay').addEventListener('click', async () => {
    const result = await checkout.card.pay({ installments: 1 });
    // result.charge contains the created charge
  });
</script>
```

## Theming

Both SDKs accept theme tokens (primary color, radius, font, error color). The Checkout SDK exposes higher-level theme; the Full SDK accepts per-field styles via `styles.base` / `styles.invalid` / `styles.focus`.

## Events

| Event | When |
|---|---|
| `ready` | SDK mounted, fields rendered |
| `change` | Field state changed (valid/invalid) |
| `tokenize` | Card token created on the SDK side |
| `success` | Session paid; payload contains the resulting charge |
| `failure` | Pay attempt failed; payload contains the error code |
| `cancel` | User canceled (only some flows) |

## Pitfalls

- Never expose the secret `X-Api-Key` to the browser. Only **Client Tokens** with scope `tokens` (and optionally `sessions:pay`) should reach the frontend.
- A session can only be paid once. After `success`, create a new session for a new order.
- The Full SDK requires that the four card fields each mount into a separate DOM node — they each become an isolated iframe.
- 3DS2 challenge is rendered by the SDK automatically when the antifraud / smart flow asks for it; see the `three-ds-two` skill.

## Examples

The Tokenization SDK examples repo also shows Checkout patterns: <https://github.com/plughacker/malga-tokenization/tree/main/examples/v2>.
