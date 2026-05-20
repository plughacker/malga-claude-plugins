---
name: checkout-sdk
description: Use this skill when implementing or customizing Malga's frontend Checkout SDKs. Triggers on questions about "Malga Checkout SDK", "@malga-checkout/core", "<malga-checkout> web component", "Checkout Full SDK", "embed Malga checkout", "drop-in checkout Malga", "paymentSuccess Malga", "paymentFailed Malga", "transactionConfig Malga", "paymentMethods checkout Malga", "dialogConfig Malga", "tema Malga Checkout CSS variables". Covers the web component, its props (HTML attributes and JS properties), the per-method configuration objects, theme customization via CSS variables, and integration with Sessions.
---

# Malga Checkout SDK (frontend)

Malga ships two UI SDKs for the browser. Both render a PCI-safe checkout backed by Malga.

| SDK | Pick when |
|---|---|
| **Checkout SDK** (`@malga-checkout/core`) | Drop-in web component (`<malga-checkout>`). Renders a complete, themable checkout. Available as React, Vue, Angular and Vanilla JS wrappers. |
| **Checkout Full SDK** | Headless variant with full layout control. |

Reference: <https://docs.malga.io/sdks/intro-sdk>, <https://docs.malga.io/sdks/malga-checkout/js>.

## How the Checkout fits with Sessions

The frontend never sees the secret API key. The flow is:

1. **Backend** mints a **Client Token** scoped to the operations the checkout will perform (typically `tokens`, `charges`, `sessions`) — see the `tokenization` skill.
2. (Optional) **Backend** creates a Session (`POST /v1/sessions`) that pre-builds the order. The response includes a session-scoped `publicKey` and `id`.
3. **Frontend** mounts `<malga-checkout>` with the merchant's `client-id`, the public key, and either a `merchant-id` (for direct charges) or a `session-id` (for paying a session).
4. **Frontend** configures the checkout via JS properties (`paymentMethods`, `transactionConfig`, `dialogConfig`) and listens for `paymentSuccess` / `paymentFailed`.

## Drop-in Checkout SDK — minimal example

```html
<script
  type="module"
  src="https://unpkg.com/@malga-checkout/core@latest/dist/malga-checkout/malga-checkout.esm.js"
></script>

<malga-checkout
  sandbox="false"
  public-key="<PUBLIC_KEY>"
  client-id="<CLIENT_ID>"
  merchant-id="<MERCHANT_ID>"
></malga-checkout>

<script>
  const checkout = document.querySelector('malga-checkout');

  checkout.paymentMethods = {
    credit: { installments: { quantity: 1, show: true }, showCreditCard: true },
    pix:    { expiresIn: 600 },
    boleto: { expiresDate: '2026-12-31', instructions: 'Pagar até a data de vencimento' }
  };

  checkout.transactionConfig = {
    statementDescriptor: 'MINHALOJA',
    amount: 19990,                // total in cents
    description: 'Pedido #231',
    orderId: 'ord-2026-0001',
    customerId: '<CUSTOMER_ID>',  // or set `customer` for auto-creation
    currency: 'BRL',
    capture: false                // pre-auth; capture later if needed
  };

  checkout.addEventListener('paymentSuccess', (event) => {
    // event.detail contains the resulting charge
    window.location.href = '/thank-you';
  });

  checkout.addEventListener('paymentFailed', (event) => {
    console.error('Payment failed', event.detail);
  });
</script>
```

## Attributes (HTML-level)

| Attribute | Purpose |
|---|---|
| `client-id` | Merchant's `X-Client-Id`. |
| `public-key` | Client Token public key, OR a session-scoped `publicKey` when using Sessions. |
| `merchant-id` | Subaccount identifier on Malga. Required for direct charges. |
| `session-id` | Session identifier (when paying a session instead of creating a charge directly). |
| `sandbox` | `"true"` or `"false"`. Defaults to `false`. |
| `locale` | `pt-BR`, `pt_BR`, `pt`, `en-US`, `en_US`, `en`. Defaults to browser language. |
| `idempotency-key` | Optional; the component generates a UUIDv4 if omitted. |

## JS properties (set on the element)

These are objects, not attributes. Assign them in JavaScript after the element exists.

### `paymentMethods`

Configures which methods to render and their per-method options.

```js
checkout.paymentMethods = {
  pix:    { expiresIn: 600 },
  boleto: { expiresDate: '2026-12-31', instructions: '...', interest: { days: 1, amount: 100 }, fine: { days: 2, amount: 200 } },
  credit: { installments: { quantity: 1, show: true }, checkedSaveCard: false, showCreditCard: true, cvvCheck: false, cvvCheckMerchantId: '' },
  drip:   { items: [...], browser: { ipAddress, browserFingerprint }, successRedirectUrl: '...', cancelRedirectUrl: '...' },
  nupay:  { taxValue: 10, delayToAutoCancel: 60, orderUrl: '...' }
};
```

Methods omitted from the object are not shown to the customer.

### `transactionConfig`

Configures the transaction the checkout will create.

```js
checkout.transactionConfig = {
  statementDescriptor:  'MINHALOJA',
  amount:               19990,         // cents
  description:          'Pedido #231',
  orderId:              'ord-2026-0001',
  currency:             'BRL',
  capture:              false,
  customerId:           '<CUSTOMER_ID>',
  customer:             { name, email, phoneNumber, document: { type, number, country }, address: { ... } },
  fraudAnalysis:        { browserFingerprint, usePartialCustomer, cart: [...], customer: {...} },
  paymentFlowMetadata:  { yourKey: yourValue },
  splitRules:           [{ sellerId, percentage, amount, processingFee, liable, fares: { mdr, fee } }],
  providerReferenceKey: 'optional-ref'
};
```

- `paymentFlowMetadata` feeds Smart Flow conditionals (see the `smart-flows` skill). Reserved keys still apply.
- `splitRules` uses `processingFee` and `liable` flags — required for split charges.
- `customerId` and `customer` are alternatives: provide one or the other.

### `dialogConfig`

Configures the success/error modal that appears after submission.

```js
checkout.dialogConfig = {
  show:                       true,
  actionButtonLabel:          'Continuar',
  successActionButtonLabel:   'Continuar',
  errorActionButtonLabel:     'Tentar novamente',
  successRedirectUrl:         'https://example.com/thanks',
  pixWaitingPaymentMessage:   'Pedido aguardando pagamento!',
  boletoWaitingPaymentMessage:'Pedido aguardando pagamento!',
  pixImportantMessages:       ['...', '...'],
  pixFilledProgressBarColor:  '#2FAC9B',
  pixEmptyProgressBarColor:   '#D8DFF0'
};
```

Set `dialogConfig.show = false` to render the checkout without the modal (useful when wrapping it in a custom layout).

## Events

| Event | When | `event.detail` |
|---|---|---|
| `paymentSuccess` | The transaction succeeded | The created charge object |
| `paymentFailed`  | The transaction failed | The error object |

These are dispatched via standard `addEventListener`. The component also exposes them as `paymentSuccess` / `paymentFailed` callback props in the React / Vue / Angular wrappers (see <https://docs.malga.io/sdks/malga-checkout/react>).

## Theme (CSS variables)

Theme is fully controlled via CSS variables on `:root`. No theme prop. Override variables in the host page's stylesheet:

```css
:root {
  --malga-checkout-color-brand-normal: #39bfad;
  --malga-checkout-color-brand-middle: #2fac9b;
  --malga-checkout-color-brand-dark:   #147f70;
  --malga-checkout-typography-family:  'Inter', sans-serif;
  --malga-checkout-border-radius-default: 4px;
  --malga-checkout-border-radius-lg:      20px;
  /* see full list at https://docs.malga.io/sdks/malga-checkout/js */
}
```

A demo with the full variable list is at <https://github.com/plughacker/demo-malga-checkout-vanilla>.

## Framework wrappers

The same component ships as React, Vue, and Angular wrappers with framework-idiomatic prop and event APIs.

| Wrapper | Package | Doc |
|---|---|---|
| React | `@malga-checkout/react` | <https://docs.malga.io/sdks/malga-checkout/react> |
| Vue | `@malga-checkout/vue` | <https://docs.malga.io/sdks/malga-checkout/vue> |
| Angular | `@malga-checkout/angular` | <https://docs.malga.io/sdks/malga-checkout/angular> |
| Vanilla / Web Component | `@malga-checkout/core` | <https://docs.malga.io/sdks/malga-checkout/js> |

## Checkout Full SDK — headless variant

For merchants who need more control over UI, the Checkout Full SDK ships as a separate web component (`<malga-checkout-full>` from `@malga-checkout-full/core`).

```html
<script
  type="module"
  src="https://unpkg.com/@malga-checkout-full/core@latest/dist/malga-checkout-full/malga-checkout-full.esm.js"
></script>

<malga-checkout-full
  sandbox="false"
  public-key="<PUBLIC_KEY>"
  client-id="<CLIENT_ID>"
  merchant-id="<MERCHANT_ID>"
></malga-checkout-full>
```

The configuration model is the same as the drop-in (JS properties `paymentMethods`, `transactionConfig`, `dialogConfig`, events `paymentSuccess` / `paymentFailed`, theming via CSS variables). Available wrappers:

| Wrapper | Package | Doc |
|---|---|---|
| React | `@malga-checkout-full/react` | <https://docs.malga.io/sdks/malga-checkout-full/react> |
| Vue | `@malga-checkout-full/vue` | <https://docs.malga.io/sdks/malga-checkout-full/vue> |
| Angular | `@malga-checkout-full/angular` | <https://docs.malga.io/sdks/malga-checkout-full/angular> |
| Vanilla / Web Component | `@malga-checkout-full/core` | <https://docs.malga.io/sdks/malga-checkout-full/js> |

Pick the Full SDK only when the drop-in's CSS-variable theming is not enough.

## Pitfalls

- **Don't ship the secret API key** to the browser. Only `publicKey` (Client Token or session-scoped) belongs in the frontend.
- **One session, one payment**. After a successful pay, the session is consumed. Create a new session for a new order.
- **Both `merchant-id` and `session-id` together are unusual**. Use one or the other based on flow.
- **`paymentMethods` is an object, not an array**. Keys are the method names; values are the per-method config.
- **Pin the version** in production: `@malga-checkout/core@<exact-version>` rather than `@latest`.
- **HTTPS required**. Hosted Fields and 3DS challenge depend on a secure origin.
- **CSS variables only**. There is no JS theme prop.
- **`addEventListener` vs JS property**: both work for `paymentSuccess`/`paymentFailed`. Use whichever fits your framework.
