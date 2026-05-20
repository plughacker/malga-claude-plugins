---
name: webhooks
description: Use this skill when configuring, securing, or debugging Malga webhooks (Webhooks v1.1). Triggers on questions about "webhook Malga", "Malga events", "transaction.authorized", "verificar assinatura webhook Malga", "ed25519 Malga", "X-Plug-Signature", "X-Plug-Date", "Malga webhook retry", "webhook receiver fila SQS Malga", "subscription event Malga", "seller event Malga". Covers webhook CRUD endpoints, the official event catalog (transaction.*, subscription.*, seller.*), Ed25519 signature verification, retry schedule (6 attempts), and idempotency via x-idempotency-key.
---

# Malga webhooks (v1.1)

Webhooks notify the merchant's system about asynchronous events: a transaction was authorized, a subscription cycle was processed, a seller was activated by a provider. They are the primary mechanism for keeping the merchant's database in sync with Malga.

Reference:
- Guide: <https://docs.malga.io/documentations/webhooks/webhook1-1>
- API reference: <https://docs.malga.io/api-reference/webhooks/criacao-de-novo-webhook-para-notificacao>
- Signature verification samples: <https://github.com/plughacker/plug-sample-signature-verify>

## Basic flow

1. The merchant exposes a public HTTPS endpoint that accepts POST.
2. The merchant registers the endpoint by creating a webhook via Malga API, choosing the event to subscribe to.
3. When the event happens, Malga sends a signed HTTP POST to the endpoint with the event payload.
4. The merchant verifies the Ed25519 signature, returns 200 or 201, and processes the event (preferably asynchronously via a queue).

## Webhook CRUD

| Action | Endpoint |
|---|---|
| List | `GET /v1/webhooks` |
| Create | `POST /v1/webhooks` |
| Detail | `GET /v1/webhooks/{id}` |
| Update | `PATCH /v1/webhooks/{id}` |
| Delete | `DELETE /v1/webhooks/{id}` |

## Create a webhook

The create payload subscribes the endpoint to **one event** (or to all events using the `*` wildcard). To listen for multiple events, create one webhook per event, or use a single webhook with `event: "*"`.

```bash
curl -X POST 'https://api.malga.io/v1/webhooks' \
  -H 'X-Client-Id: <YOUR_CLIENT_ID>' \
  -H 'X-Api-Key:   <YOUR_SECRET_KEY>' \
  -H 'Content-Type: application/json' \
  -d '{
    "event":    "transaction.authorized",
    "endpoint": "https://api.example.com/hooks/malga",
    "version":  1.1,
    "status":   true
  }'
```

Response includes the `id` of the webhook and the **Ed25519 public key** the merchant must store to verify incoming signatures:

```json
{
  "id":        "31c142ad-4c30-4964-ba24-2df0f2bbb745",
  "clientId":  "cc0b1e41-2936-45c5-947f-93995ffcdc00",
  "event":     "transaction.authorized",
  "endpoint":  "https://api.example.com/hooks/malga",
  "version":   1.1,
  "status":    true,
  "publicKey": "-----BEGIN PUBLIC KEY-----\nMCowBQYDK2VwAyEAIda0HljovhG1yKez/Du7MUoKup/cbXqPgwyGOATOiJQ=\n-----END PUBLIC KEY-----\n",
  "createdAt": "2021-07-06T21:03:36.590Z"
}
```

Persist `publicKey` securely. It does not change unless the webhook is recreated.

## Signature verification (Ed25519)

Every delivery includes two headers:

- `X-Plug-Date` — UTC Unix timestamp (ms) when the event was generated.
- `X-Plug-Signature` — hex-encoded Ed25519 signature (64 bytes).

The signed message is `{date}\n{payload}` (date + newline + raw body), and the signature is verified with the public key returned at webhook creation. Reject the event if the signature is invalid OR if `X-Plug-Date` is older than 5 minutes (replay protection).

### Node example

```ts
import crypto from 'crypto';

function verifyMalgaWebhook(args: {
  date: string;             // X-Plug-Date
  signatureHex: string;     // X-Plug-Signature
  rawBody: string;          // exact bytes received
  publicKeyPem: string;     // stored when webhook was created
}) {
  // Replay protection: reject if older than 5 minutes
  const ageMs = Date.now() - Number(args.date);
  if (ageMs > 5 * 60 * 1000) return false;

  const message = Buffer.from(`${args.date}\n${args.rawBody}`, 'utf8');
  const signature = Buffer.from(args.signatureHex, 'hex');
  const publicKey = crypto.createPublicKey(args.publicKeyPem);

  // Ed25519 verify: algorithm parameter is null
  return crypto.verify(null, message, publicKey, signature);
}
```

Working examples in Node, Python, Go, PHP, Ruby and others: <https://github.com/plughacker/plug-sample-signature-verify>.

## Event payload shape

Every event payload contains:

```json
{
  "id":        "<event-id-uuid>",
  "apiVersion":"1.1",
  "object":    "transaction" | "subscription" | "seller",
  "event":     "<event-name>",
  "data":      { ... object snapshot at the time of the event ... },
  "createdAt": "<ISO-8601>"
}
```

The `id` is also sent as the `x-idempotency-key` request header. Use it for deduplication on the receiver.

## Event catalog

### Transaction

| Event | When |
|---|---|
| `transaction.pending` | Charge is registered, payment data is available (typical for Pix and Boleto). |
| `transaction.pre_authorized` | Pre-authorization confirmed by the provider. |
| `transaction.authorized` | Capture confirmed. |
| `transaction.failed` | Charge declined by the issuer before authorization. |
| `transaction.canceled` | Authorized but not captured charge was canceled (no financial reversal). |
| `transaction.voided` | Authorized and captured charge was reversed (with financial reversal). |
| `transaction.charged_back` | Charge was disputed or unrecognized by the cardholder. |
| `transaction.dispute` | Dispute opened on the transaction. |
| `transaction.dispute_closed` | Dispute closed. If a `charged_back` is received instead, the cardholder won. |
| `transaction.refund_pending` | Refund pending (typical in async flows like Pix). |
| `transaction.revert_void` | Reversal of a successful refund. |
| `transaction.probe_void` | Duplicate-detection probe canceled a charge. |

### Subscription

| Event | When |
|---|---|
| `subscription.created` | New subscription created (when trial is not active). |
| `subscription.trial_started` | Subscription created with active trial. |
| `subscription.activated` | First payment approved. |
| `subscription.updated` | Value, items, or other config changed. |
| `subscription.paused` | Paused. |
| `subscription.resumed` | Reactivated from pause. |
| `subscription.unpaid` | Entered unpaid state. |
| `subscription.expired` | Expired. |
| `subscription.canceled` | Canceled manually. |
| `subscription.cycle_failed` | A payment cycle failed due to data inconsistency. |

### Seller

| Event | When |
|---|---|
| `seller.active` | Seller approved by a provider. Split transactions can now reference this seller. |
| `seller.inactive` | Seller deactivated manually or rejected by the provider. |

For seller events, the `data` object contains both `origin` (the provider that emitted the event) and `seller` (the full seller snapshot with all provider statuses).

## Retry schedule (6 attempts)

If the receiver does not return 200/201 within the response timeout, Malga retries on a fixed schedule:

| Attempt | Delay from previous | Response timeout |
|---|---|---|
| Created (1st delivery) | Immediate | 30 s |
| Retry 1 | +5 min | 5 s |
| Retry 2 | +45 min | 5 s |
| Retry 3 | +6 h | 5 s |
| Retry 4 | +1 day | 5 s |
| Retry 5 | +2 days | 5 s |
| Retry 6 | +4 days | 5 s |

After **6 failed attempts** (about 4 days), the webhook is **automatically disabled** to prevent overload. The merchant must reactivate it manually (Dashboard or `PATCH /v1/webhooks/{id}`). Delivery logs (request and response) are kept for **45 days**.

The 5-second timeout is tight. Always make the endpoint just receive, verify signature, enqueue, return 200. Do heavy processing in a worker.

## Idempotency on the receiver

Duplicate deliveries are possible. Always:

1. Read `x-idempotency-key` header (or the event `id` field, which is the same value).
2. Look it up in a `processed_events` table.
3. If already processed, return 200 without doing the work again.
4. Otherwise, process and record the id.

Event ordering is generally honored but **not guaranteed**. Use `createdAt` on the event payload to enforce chronological order on the consumer side. If an event arrives with an older `createdAt` than one already processed for the same object, the data is stale and the merchant decides whether to act.

## Recommended architecture (queue-based receiver)

Malga recommends the endpoint just receive, verify and enqueue. The actual business logic runs in a background worker. The Malga docs include a reference AWS SQS example: <https://docs.malga.io/documentations/webhooks/webhook-receiver-aws-sqs>.

```ts
app.post('/hooks/malga', async (req, res) => {
  const ok = verifyMalgaWebhook({
    date:         req.header('X-Plug-Date')!,
    signatureHex: req.header('X-Plug-Signature')!,
    rawBody:      req.rawBody,
    publicKeyPem: process.env.MALGA_WEBHOOK_PUBLIC_KEY!,
  });
  if (!ok) return res.status(401).end();

  await queue.send({
    eventId: req.body.id,
    type:    req.body.event,
    object:  req.body.object,
    payload: req.body,
  });
  res.status(200).end();
});
```

## Testing in sandbox

In `sandbox-api.malga.io` it's possible to manually push a charge into specific states to trigger webhook events:

```bash
curl -X POST 'https://api.malga.io/v1/charges/<CHARGE_ID>' \
  -H 'X-Client-Id: <YOUR_CLIENT_ID>' \
  -H 'X-Api-Key:   <YOUR_SECRET_KEY>' \
  -H 'Content-Type: application/json' \
  -d '{ "status": "charged_back" }'
```

Supported manual transitions in sandbox: `authorized`, `voided`, `charged_back`.

External tools like RequestBin or Pipedream are useful to inspect deliveries before wiring the real receiver.

## v1.0 vs v1.1

Webhooks v1.0 is deprecated. New integrations should use v1.1 (`version: 1.1`). Documentation for the obsolete version: <https://docs.malga.io/documentations/webhooks/webhook1-0>.

## Common pitfalls

- **HMAC instead of Ed25519** — Malga uses asymmetric crypto. There is no shared secret. The public key from webhook creation is the only material the receiver needs.
- **Reparsed body** — verifying against `JSON.stringify(req.body)` will fail because key order or whitespace may differ. Sign and verify against the **raw bytes**.
- **Wrong newline** — the message is `<date>\n<payload>` with a literal `\n` (LF), not `\r\n`.
- **No retry-after** — Malga's retry schedule is fixed, not based on a `Retry-After` header. Don't rely on the header.
- **Endpoint disabled after 6 failures** — production endpoints that go down for a few days will be auto-disabled. Reactivate manually after fixing the outage.
- **HTTP, not HTTPS** — Malga requires a public, internet-reachable HTTPS endpoint. Local dev requires a tunnel (ngrok, cloudflared).
