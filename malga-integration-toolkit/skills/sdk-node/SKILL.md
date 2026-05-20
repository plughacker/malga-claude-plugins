---
name: sdk-node
description: Use this skill when integrating Malga from a Node.js or TypeScript backend using the official `malga` npm package. Triggers on questions about "Malga Node SDK", "malga npm", "@malga/node", "import Malga from malga", "Malga TypeScript", "como criar charge com SDK Node Malga", "malga.charges.create", "malga.auth.createPublicKey", "malga.webhooks.verify", "Malga server-side integration JavaScript". Covers installation, client setup, idempotency, error structure, and the SDK's simplified payload schema (which differs from the REST API).
---

# Malga Node.js SDK

The official Node SDK is the npm package **`malga`** (just `malga`, not scoped). Repository: <https://github.com/plughacker/malga-node>. Working examples: <https://github.com/plughacker/malga-node/tree/main/examples>.

## Installation

```bash
npm install malga
# or
yarn add malga
# or
pnpm add malga
```

## Client setup

```ts
import { Malga } from 'malga';

const malga = new Malga({
  apiKey:   process.env.MALGA_API_KEY!,
  clientId: process.env.MALGA_CLIENT_ID!,
  options: {
    sandbox: true,            // optional, defaults to false
    http: {
      retries:    3,          // optional, retries on 5xx / network errors
      retryDelay: 10000       // ms between retries
    }
  }
});
```

Required: `apiKey`, `clientId`. The `options.sandbox` flag toggles between sandbox and production; the same credentials cannot belong to both environments, but the flag changes the base URL the SDK calls.

Never hardcode credentials. Always read from environment variables or a secrets manager.

## Important: SDK payload schema differs from REST

The SDK exposes a friendlier, normalized payload that gets translated into the REST API call. **Do not mix the REST schema and the SDK schema** in code that uses the SDK.

### SDK shape (input)

```ts
await malga.charges.create({
  merchantId: '<MERCHANT_ID>',
  amount: 100,
  paymentMethod: {
    type: 'credit',
    installments: 1,
    card: {
      holderName:     'João da Silva',
      number:         '5453881028277600',
      cvv:            '170',
      expirationDate: '10/2030'
    }
  }
});
```

Notes:
- SDK uses **`paymentMethod.type`** (not `paymentMethod.paymentType`).
- Card data is nested **inside `paymentMethod.card`** (not in a separate `paymentSource`).
- Card field names are **`holderName`, `number`, `cvv`, `expirationDate`** (not `cardHolderName`, `cardNumber`, etc.).

### REST shape (response)

The same call returns the REST API's response shape: `paymentMethod: { paymentType, installments }` and `paymentSource: { sourceType, cardId }`. So writing code that *reads* the response uses the REST conventions, while writing code that *calls* the SDK uses the SDK conventions. Keep that in mind when reading the SDK source vs the API reference.

For raw REST calls (when the SDK doesn't cover an endpoint, or for non-Node runtimes), see the `api-charges` skill for the REST schema.

## Idempotency

The SDK accepts a per-call `idempotencyKey` in the second argument. The SDK forwards it as the `X-Idempotency-Key` HTTP header.

```ts
import { randomUUID } from 'crypto';

await malga.charges.create(
  { merchantId, amount, paymentMethod: { ... } },
  { idempotencyKey: randomUUID() }
);
```

Treat idempotency as required for any `create` call. See the `api-charges` skill for race-condition handling (the `options.http.retries` config helps automatically on transient errors).

## Resource coverage

Confirmed by reading the package source (`malga@0.0.2`):

| Namespace | Methods | REST routes |
|---|---|---|
| `malga.auth` | `createPublicKey({ scope, expires }, options?)` | `POST /auth` |
| `malga.charges` | `create`, `find`, `list`, `capture`, `refund` | `POST /charges`, `GET /charges/{id}`, `GET /charges`, `POST /charges/{id}/capture`, **`POST /charges/{id}/void`** (refund) |
| `malga.cards` | `create`, `find`, `list`, `tokenization`, `tokenizationCvv` | `POST /cards`, `GET /cards/{id}`, `GET /cards`, etc. |
| `malga.customers` | `create`, `find`, `list`, `update`, `remove`, `linkCard`, `listCards` | `POST /customers`, etc. |
| `malga.sessions` | `create`, `find`, `list`, `cancel`, `enable`, `disable` | `POST /sessions`, `GET /sessions/{id}`, etc. |
| `malga.sellers` | `create`, `find`, `list`, `update`, `remove` | `POST /sellers`, etc. |
| `malga.webhooks` | `verify({ payload, publicKey, signature, signatureTime })` | Local (Ed25519 verification, no HTTP) |
| `malga.sandbox` | `changeChargeStatus`, `changeAntifraudStatus`, `generateCard` | Various sandbox endpoints |

Note: `charges.refund(id, { amount })` calls the REST endpoint `POST /charges/{id}/void`. The "refund" is implemented as a void on the REST side.

The canonical source for method signatures is the package source itself: <https://github.com/plughacker/malga-node/tree/main/src> and examples at <https://github.com/plughacker/malga-node/tree/main/examples>.

## Client Token (public key) via SDK

```ts
import { AuthScope } from 'malga';

const { publicKey, expires, scope, createdAt } = await malga.auth.createPublicKey({
  scope:   ['tokens', 'cards'],   // or '*' for everything
  expires: 600                     // seconds
});
```

Supported scopes: `customers`, `cards`, `tokens`, `charges`, `webhooks`, `sessions`, `auth`, `reports`, `flows`, `sellers`. Pass them as an array, or `'*'` for a wildcard key with access to every scope.

The `AuthScope` enum is exported for typed usage (`AuthScope.Tokens`, `AuthScope.Cards`, etc.).

## Webhook signature verification

The SDK includes the Ed25519 verification helper. It is **synchronous** (returns the boolean directly, do not `await`).

```ts
const ok = malga.webhooks.verify({
  payload:       rawBodyString,                            // raw POST body
  publicKey:     storedPublicKeyPem,                       // from webhook creation
  signature:     req.header('X-Plug-Signature')!,          // hex string
  signatureTime: Number(req.header('X-Plug-Date'))         // number (Unix ms)
});

if (!ok) return res.status(401).end();
```

Internally it does `crypto.verify(null, Buffer.from(\`\${signatureTime}\\n\${payload}\`), publicKey, Buffer.from(signature, 'hex'))`. Enforce the 5-minute replay window on `signatureTime` yourself. See the `webhooks` skill for full details.

## Error handling

All errors returned by the SDK follow a unified structure (`MalgaErrorResponse`):

```ts
interface MalgaErrorResponse {
  error: {
    type:          'api_error' | 'bad_request' | 'invalid_request_error' | 'card_declined';
    code:          number;          // HTTP status
    message:       string;          // short summary
    details?:      string | string[];
    declinedCode?: 'card_not_supported' | 'expired_card' | 'fraud_confirmed' | 'fraud_suspect' |
                   'generic' | 'insufficient_funds' | 'invalid_amount' | 'invalid_cvv' |
                   'invalid_data' | 'invalid_installment' | 'invalid_merchant' | 'invalid_number' |
                   'invalid_pin' | 'issuer_not_available' | 'lost_card' | 'not_permitted' |
                   'pickup_card' | 'pin_try_exceeded' | 'restricted_card' | 'security_violation' |
                   'service_not_allowed' | 'stolen_card' | 'transaction_not_allowed' | 'try_again';
  };
}
```

```ts
try {
  await malga.charges.create({ ... });
} catch (err: any) {
  if (err.error?.code === 409) {
    // Idempotency race; retry after delay
  } else if (err.error?.code === 422) {
    // Validation; inspect err.error.details
  } else {
    // Other; log err.error.message and the requestId from headers
  }
}
```

For decline-code-driven UX (e.g., "card declined, try another"), inspect `error.declinedCode`. The full mapping is at <https://docs.malga.io/documentations/type-tables/declined-code>.

## Sandbox helpers

The SDK exposes the sandbox-only operations under `malga.sandbox`:

- `malga.sandbox.changeChargeStatus({ chargeId, status })` — force a charge into `authorized`, `voided`, or `charged_back`.
- `malga.sandbox.changeAntifraudStatus({ chargeId, status })` — push the antifraud outcome.
- `malga.sandbox.generateCard()` — produce a test card.

These trigger the corresponding webhook events, useful for verifying the receiver end-to-end.

## When to drop down to REST

The SDK lags new endpoints by a few weeks sometimes. If a recently released endpoint is missing, drop to a raw HTTP call with the same `X-Client-Id` and `X-Api-Key` headers (see the `api-charges` skill). The SDK and raw REST can coexist in the same codebase.

## Pitfalls

- **Wrong field names**: writing `cardNumber` or `cardHolderName` inside the SDK's `paymentMethod.card` will fail validation. Use `number`, `holderName`, `cvv`, `expirationDate`.
- **Don't reuse the REST schema as SDK input**. The SDK has its own shape (see above).
- **`expires` is in seconds** for `auth.createPublicKey`. `60` = one minute; `31104000` = one year.
- **`webhooks.verify` returns a boolean**, it does not throw on invalid signatures. Always check the return value.
- **HTTP retries with idempotency**. When you set `options.http.retries`, those retries reuse the same idempotency key, which is what you want for safety. Without an idempotency key, retries on a `create` might cause duplicates if the first call partially landed.
