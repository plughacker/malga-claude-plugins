---
description: Decode a Malga charge response, webhook event, or error payload and explain in plain language.
argument-hint: "[payload-json-or-file-or-chargeId] — paste JSON, give a file path, or just the chargeId"
---

# /malga-decode

Take a Malga payload and explain it in plain language. Useful for CX investigating a failed charge, a developer reading a webhook for the first time, or anyone debugging.

The argument `$ARGUMENTS` is one of:

- **A JSON payload** pasted directly.
- **A file path** to a JSON file.
- **A `chargeId` UUID** (in which case ask for the corresponding charge JSON; this command doesn't have live API access).

## What to decode

The payload could be:

1. **Charge response** (`POST /v1/charges` response) — explain status, paymentMethod, paymentSource, transactionRequests timeline, providers that tried, final outcome, next steps.
2. **Webhook event** — explain the event type (`transaction.authorized`, `subscription.cycle_failed`, etc.), what triggered it, what to do.
3. **Error response** (`MalgaErrorResponse`) — translate `error.type` + `error.code` + `error.declinedCode` into a customer-facing message and a developer next step.
4. **Subscription / Customer / Card / Seller / Payout** payload — explain the entity state.

## How to explain

Structure the output as:

### 1. One-sentence summary

What this payload means at the highest level (e.g., "A R$ 150 credit card charge that was approved on first attempt by Stripe sandbox").

### 2. Key facts

A bullet list of the most important fields, decoded:

- `id`, `merchantId`, `customerId` — identifiers (truncate UUIDs to first 8 chars for readability).
- `amount` (and `originalAmount` if different) — value in BRL, not cents.
- `currency`, `status`, `capture`.
- `paymentMethod.paymentType` — readable name (Cartão / Pix / Boleto / etc.).
- For card: `paymentSource.card.brand`, last 4 digits.
- For Pix: whether QR code is present, expiration.
- For Boleto: due date, line of digits available.

### 3. Timeline (from `transactionRequests[]`)

Walk through each `transactionRequest` chronologically. For each, write:

- `providerType` (Stripe / Cielo / Adyen / Sandbox / etc.).
- `requestType` (`authorization`, `pre_authorization`, `capture`, `void`, `anti_fraud`).
- `requestStatus` (`success`, `failed`, `processing`).
- `responseTs` (response time in ms).
- If failed, the declined code translated into the ABECS guidance (see `type-tables` skill).

### 4. What happened in plain terms

A short narrative paragraph: "The first attempt at Stripe failed with `insufficient_funds` (cardholder has no funds). Smart Flow retried on Cielo, which approved. The charge is now `authorized`."

### 5. What to do next

Concrete action items based on the state:

- **`authorized` / `voided`**: nothing to do, transaction is final.
- **`pre_authorized`**: capture within 7 days or it auto-releases.
- **`pending`** (Pix / Boleto): wait for the customer to pay, or expire.
- **`refund_pending`**: wait for bank confirmation; will become `voided`.
- **`failed`**: read the `declinedCode`, decide whether to ask the customer to try again with a different method.
- **`charged_back`**: dispute opened; coordinate with finance.

For webhooks, suggest where to look in the receiver code if the event was unexpected.

For errors, suggest the right fix based on the `error.code` (400/401/409/422 each has a typical cause).

## Style

- **Plain language**, no jargon unless explaining a Malga-specific term once.
- **No invented details** — if a field is missing, say "this field isn't in the payload" instead of guessing.
- **Brazilian Portuguese if the user wrote in Portuguese**; English if they wrote in English.

## Cross-references

Point to relevant skills for deeper context:

- For status enum questions: `api-charges` skill.
- For declined codes: `type-tables` skill.
- For webhook events: `webhooks` skill.
- For specific methods: `credit-card`, `pix`, or `boleto` skill.
- For specific providers: `providers` skill and its references.
