---
description: Review code for Malga-specific integration issues (credentials, idempotency, signatures, schema drift).
argument-hint: "[path] — optional path or glob; defaults to the current directory"
---

# /malga-review

Review the user's code for problems specific to Malga integrations. The argument `$ARGUMENTS` is an optional path or glob (defaults to the current directory).

## Scope of the review

Walk the target files and look for the following classes of issues. For each finding, report:

- **File and line** (use Read with offset/limit if needed for precision).
- **Severity**: `critical` (will break or leak), `high` (likely bug), `medium` (best-practice violation), `low` (style).
- **Why it's a problem**, in one sentence.
- **Suggested fix**, with code.

## Checklist

### Credentials and secrets (critical)

- Hardcoded `X-Client-Id`, `X-Api-Key`, `MALGA_API_KEY`, `MALGA_CLIENT_ID`, `apiKey`, `clientId` values that look real (UUID format or non-placeholder strings).
- `.env` committed to git (check `.gitignore`).
- Secret keys passed to the **frontend** (browser bundle, React, Next.js client component). The only key that belongs in the browser is the **Client Token publicKey** (scoped) or a **session-scoped publicKey**.

### REST vs SDK schema mismatch (high)

The Malga REST API and the Node SDK use **different payload shapes**. Flag code that mixes them.

- REST uses `paymentMethod: { paymentType: "credit", installments }` + separate `paymentSource: { sourceType: "card", card: { cardNumber, cardCvv, cardExpirationDate, cardHolderName } }`.
- SDK uses `paymentMethod: { type: "credit", installments, card: { holderName, number, cvv, expirationDate } }`.

Common mistakes to flag:
- SDK code with `paymentMethod.paymentType` (should be `type`).
- SDK code with separate `paymentSource` block (card goes inside `paymentMethod`).
- REST code with `paymentMethod.type` (should be `paymentType`).
- REST code missing `paymentSource`.

### Idempotency (high)

- `POST /charges`, `POST /sessions`, `POST /subscriptions`, `POST /customers` without `X-Idempotency-Key`.
- SDK calls without an `idempotencyKey` option.
- Idempotency keys generated server-side without UUID/randomness (e.g., timestamps, sequential counters).

### Webhook receiver (critical)

- Receiver that **does not verify** the Ed25519 signature.
- `await malga.webhooks.verify(...)` — the method is **synchronous**, not async. The `await` indicates a misuse.
- Verification using HMAC (`crypto.createHmac`) — Malga uses Ed25519, not HMAC.
- Receiver missing the **5-minute replay protection** (rejecting events with `X-Plug-Date` older than 5 min).
- Receiver doing heavy processing inline (no queue), with a high risk of >5s response → retries.
- Receiver missing **idempotency on `X-Idempotency-Key`** (event deduplication).

### Refund / void URL (medium)

- REST code calling `POST /v1/charges/{id}/refund` — the correct endpoint is `POST /v1/charges/{id}/void`. The SDK exposes it as `refund(id, { amount })` but internally hits `/void`.

### Pix specifics (high)

- Code reading `paymentMethod.qrCode` or `paymentMethod.qrCodeUrl` — the real field names are `qrCodeData` and `qrCodeImageUrl`.
- Pix charges routed through providers that do not support Pix refund (BS2, Getnet) when the merchant needs refund — flag with severity high.

### Boleto specifics (medium)

- Code that attempts to refund a Boleto charge — Boleto **cannot** be refunded.
- Code that sets `capture: false` on a Boleto — Boleto auto-captures by definition.

### Error handling (medium)

- Catch block that prints `err.message` without inspecting `err.error.code` or `err.error.declinedCode`.
- Assuming HTTP 200 means success — Malga can return HTTP 201 with a failed `transactionRequest`. Check `result.status` and the last `transactionRequests[]` entry.

### Status enum (low)

- Code matching on `captured` or `refunded` as charge status — the real enum uses `authorized` (post-capture), `voided` (post-refund), plus `pre_authorized`, `failed`, `canceled`, `charged_back`, `refund_pending`, `capture_pending`.

### Sandbox traces (low)

- `https://sandbox-api.malga.io` URLs in code that will deploy to production.
- Test card numbers (ending in 0/1/4 for sandbox approval) in production paths.

### Smart Flow metadata (low)

- Using reserved metadata keys (`amount`, `currency`, `cardBin`, `installments`, `brand`, `paymentType`, `operation`) inside `paymentFlow.metadata` — these will fail validation. Suggest a prefix.

## Output

Print findings grouped by severity, most severe first. For each, include the file path with line, a one-sentence explanation, and the suggested fix. At the end, summarize with counts (`Critical: N, High: N, Medium: N, Low: N`).

If the scan finds **no issues**, congratulate the user and call out two or three best practices the code already follows (idempotency present, env vars used, signature verified, etc.). Be specific.

## What not to do

- Don't reformat code or fix typos unrelated to Malga.
- Don't propose refactors unless directly tied to a Malga-specific issue.
- Don't run the code; this is static review.
