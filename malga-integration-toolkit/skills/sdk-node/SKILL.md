---
name: sdk-node
description: Use this skill when integrating Malga from a Node.js backend using the official SDK. Triggers on questions about "Malga Node SDK", "@malga/node", "malga-node npm", "Malga TypeScript", "como criar charge com SDK Node Malga", "Malga client Node", "Malga server-side integration JavaScript". Covers installation, client configuration, charges, sessions, customers, webhooks, and error handling patterns idiomatic to Node/TypeScript. Also useful when the user is choosing between direct REST calls and the SDK.
---

# Malga Node.js SDK

The official Node SDK (`@malga/node`, repo: <https://github.com/plughacker/malga-node>) wraps the REST API in a typed client. Prefer the SDK over raw `fetch` when working in Node — it handles auth headers, idempotency, retries, and types automatically.

## Installation

```bash
npm install @malga/node
# or
pnpm add @malga/node
yarn add @malga/node
```

## Client setup

```ts
import { Malga } from '@malga/node';

export const malga = new Malga({
  clientId: process.env.MALGA_CLIENT_ID!,
  apiKey: process.env.MALGA_API_KEY!,
  // base URL defaults to https://api.malga.io/v1/; override for staging if provided
});
```

Never hardcode credentials. Always read from environment variables or a secrets manager.

## Create a charge

```ts
import { randomUUID } from 'crypto';

const charge = await malga.charges.create({
  idempotencyKey: randomUUID(),
  body: {
    merchantId: process.env.MALGA_MERCHANT_ID!,
    amount: 5000,           // cents
    currency: 'BRL',
    orderId: 'ord-123',
    paymentMethod: {
      type: 'credit',
      installments: 1,
      card: { tokenId: cardToken },
    },
    customer: { id: customerId },
  },
});
```

## Idempotency

Always pass `idempotencyKey` on creates. The SDK forwards it as `X-Idempotency-Key`. On retry, Malga returns the original response — safe to call from a queue worker.

## Other resources

The SDK exposes a method per API resource. Common patterns:

```ts
await malga.sessions.create({ idempotencyKey, body });
await malga.sessions.pay(sessionId, { body });
await malga.customers.create({ idempotencyKey, body });
await malga.subscriptions.cancel(subscriptionId);
await malga.webhooks.create({ body });
await malga.tokens.create({ body });   // server-side tokenization (rare; prefer Tokenization SDK)
await malga.flows.list();              // read-only inspection
await malga.reports.export({ body });
```

The exact method names may shift across versions — check the repo `examples/` directory: <https://github.com/plughacker/malga-node/tree/main/examples>.

## Error handling

The SDK throws `MalgaError` subclasses for API errors. Catch the right one:

```ts
import { MalgaError, MalgaValidationError } from '@malga/node';

try {
  await malga.charges.create({ ... });
} catch (err) {
  if (err instanceof MalgaValidationError) {
    // 422 — fix payload
  } else if (err instanceof MalgaError) {
    // other API error — inspect err.statusCode, err.code
  } else {
    throw err; // unexpected
  }
}
```

Always log `err.requestId` (returned in `X-Request-Id`) when reporting issues to Malga support.

## Webhook signature verification

When receiving webhooks, verify the HMAC signature using the SDK helper instead of hand-rolling the comparison:

```ts
import { verifyWebhookSignature } from '@malga/node';

app.post('/webhooks/malga', (req, res) => {
  const valid = verifyWebhookSignature({
    rawBody: req.rawBody,
    signature: req.header('X-Malga-Signature'),
    secret: process.env.MALGA_WEBHOOK_SECRET!,
  });
  if (!valid) return res.status(401).end();
  // process event...
  res.status(204).end();
});
```

## When to fall back to REST

The SDK covers the main flows. If a new endpoint isn't yet in the SDK (it lags release notes by a few weeks sometimes), drop down to a raw `fetch` with the same auth headers — see the `api-charges` skill for headers and base URL.

## Examples

Live examples: <https://github.com/plughacker/malga-node/tree/main/examples>. The repository is the source of truth for current method shapes.
