# Changelog

All notable changes to `malga-integration-toolkit` are documented here. Format inspired by [Keep a Changelog](https://keepachangelog.com/).

## [0.7.0] — 2026-05-20

### Added

- **30 per-provider references** in `skills/providers/references/`, one file per integrated provider: Adyen, Banco do Brasil, Banrisul, Barte, Bolt, Braintree, Braspag, BS2, Cielo, Drip, Getnet, Getnet SEP, Klap, Malga (subadquirente), Mapinvest, Mercado Pago, NuPay, OwemPay, Pagar.me (legacy), Pagar.me v5, PagSeguro, PayPal, PicPay, Rede, SafraPay, Sandbox, Stripe, VR, Worldpay, Zoop.
- Each reference contains the provider's full feature × method matrix (Crédito, Pix, Boleto, Voucher, Apple Pay × all 14 feature rows) with **✓** / **✗** / **—** semantics, derived from the official `documentations/providers/<slug>.mdx` pages.

### Changed

- `providers` skill now points at the per-provider references and includes the full index. The example feature matrix in the skill body was removed (Adyen-specific data is in its reference now).

## [0.6.0] — 2026-05-20

### Added (13 new skills closing every coverage gap)

**Foundational (HIGH priority):**

- `customers-and-cards` — Customer + Card entity model. Covers customer create/list/get/update/delete, customer.document and address shape, customer auto-creation from charge, the Cards API (`POST /v1/cards`, `GET /v1/cards`, etc.), card lifecycle (status, fingerprint), token-vs-card distinction, customer-card linkage, zero-dollar at vault time, server-side tokenization. Includes SDK Node methods (`malga.customers.*`, `malga.cards.*`).
- `merchants` — Merchant (subconta) entity. REST endpoints, schema (id, clientId, mcc, status: active|deleted|pending, providers), single-vs-multiple-merchants decision tree, Dashboard "Subcontas" area, explicit note that the SDK Node has no merchants namespace.
- `payouts` — Balance, payment batches, payment orders. Six REST endpoints with full schemas from the live docs (batch fields: amount, feeAmount, totalFeeAmount, finalBalance, status `pending|paid|failed|offset`, feature, paymentArrangement, etc.; order fields: chargeId, grossAmount, paymentBatchId, installment, etc.). Reconciliation pattern. Explicit note that the SDK Node has no payouts namespace.

**Extractions and per-method depth (MEDIUM priority):**

- `sessions` — Extracted Sessions from `api-charges` into its own skill. Lifecycle (created → paid / canceled / expired with isActive gate), 7 REST endpoints, SDK Node methods including `enable`/`disable`, the scoped `publicKey` model, integration with Checkout SDK and Payment Link, session-vs-charge decision tree.
- `vendors` — Extracted Vendors (payment facilitator identification per Bacen Circular 3978/2020) from `split-payments`. Vendor entity, 5 REST endpoints, when to use vs Sellers, supported providers with paymentFacilitatorId requirement (Adyen, Cielo, Rede, Getnet, SafraPay, Sandbox), example charge with `vendor` block.
- `credit-card` — Deep-dive: pre-auth + capture with 7-day acquirer hold window, partial refunds with `originalAmount`/`amount` distinction, revert_void semantics (Adyen), capture/refund error handling (HTTP 201 with failed transactionRequest), multi-currency support.
- `pix` — Deep-dive: QR code (`qrCodeData`/`qrCodeImageUrl`), `expiresIn` semantics, async refund flow (`refund_pending` → `voided`), amount drift on settlement, per-provider refund support table (Mercado Pago/Pagar.me/BB/Zoop/PagSeguro/Adyen/SafraPay yes; BS2/Getnet no), sandbox testing.
- `boleto` — Deep-dive: lifecycle (only `pending → authorized | failed`), no refund / no pre-auth constraint, `instructions` (255 chars, `\n` supported), `interest`/`fine` with days+amount+percentage, items list, response fields (`barcodeData`/`barcodeImageUrl`), amount drift on late payment.

**Reference and helper skills (LOW priority):**

- `type-tables` — Catalog of the eight Malga reference tables (decline codes, antifraud providers, currency support, document by country, MCC, main banks, additional services, payment-methods-by-providers). Practical use of the decline-code table with ABECS guidance, key codes to know (`card_not_supported`, `expired_card`, `insufficient_funds`, `fraud_confirmed`, `lost_card`, etc.).
- `dashboard` — Non-developer orientation to the Malga Dashboard (Painel de Dados Insights and Performance, Charges, Subcontas, Export, Users). Common CX workflows (investigating "fui cobrado mas não recebi", "transação falhou", "vendas de ontem", etc.).
- `sandbox-testing` — Consolidated testing guide: sandbox base URL, the last-digit card rule (0/1/4 approved, 2/3/5/6/7 various failures, 8 random), CVV `0` validates, manual status push for Pix/Boleto/Credit, antifraud sandbox by document last digit, `991` amount for capture/refund failure, SDK sandbox helpers, webhook testing with request.bin/pipedream, Postman collection link.
- `providers` — 30+ supported providers with feature matrix template (cobrança, pré-autorização, captura parcial, estorno total/parcial, split, antifraude próprio, 3DS, network token, zero dollar, recurrence flag, dispute notification, multi-currency). Provider-specific gotchas (Adyen revert_void, BS2/Getnet no Pix refund, Pagar.me v5 vs legacy, etc.). Decision factors for provider selection.
- `release-notes-tracking` — How to discover and triage Malga releases. File naming convention, format of a release note, triage decision tree, API versioning conventions (REST `/v1/`, webhook v1.0 deprecated / v1.1 current), what to watch (new provider, new method, antifraud changes, 3DS2 enhancements, SDK bumps, deprecations), monitoring options, recommended cadence (weekly/monthly/quarterly).

### Changed

- `payment-methods` skill now points at the dedicated `credit-card`, `pix`, and `boleto` skills for deep coverage.
- `api-charges` skill now points at the dedicated `sessions` skill for the deep Sessions material.
- `split-payments` skill now points at `vendors` and `payouts` for those areas.
- `tokenization` skill now points at `customers-and-cards` for the broader Customer/Card entity model.

### Coverage

Plugin grew from 15 to **28 skills**. Every coverage gap previously tracked in `AUDIT_NOTES.md` is now closed.

## [0.5.0] — 2026-05-20

### Fixed (closed every "still inferred" item from prior audits, all verified against the docs source)

- `checkout-sdk`: documented the Checkout Full SDK with the real web component (`<malga-checkout-full>` from `@malga-checkout-full/core`) and the four framework wrappers (React, Vue, Angular, Vanilla JS). Same JS-property configuration model as the drop-in.
- `recurrence`: `recurrence.interval` accepted values confirmed as `weekly`, `monthly`, `quarterly`, `yearly` (the request schema includes all four; the response schema sometimes lists only `weekly | monthly | yearly`, so `quarterly` should be confirmed with the Malga team if you depend on it).
- `smart-flows`: confirmed Smart Flow API is **read-only** (`GET /v1/flows`, `GET /v1/flows/{id}`). No POST/PATCH/DELETE on flows. Flow editing happens in the Dashboard.
- `vtex-integration`: setup flow updated with the real navigation (VTEX Admin → Pagamentos → Provedores) and the real credentials process (Token de aplicação + Chave de aplicação, generated by Malga support via suporte@malga.io). Supported-features table updated from the official connector doc (including the "exceto envio de campo personalizado na cobrança" caveat for Smart Flow).
- `analytics-reporting`: Reports API endpoints confirmed and de-softened: `POST /v1/reports`, `GET /v1/reports/{id}`, `GET /v1/reports/{id}/files/{pageNumber}`. Documented that downloads are paginated via a `files[]` array.
- `three-ds-two`: replaced the speculative "nextAction" framing with the real `3DSecure2Response` schema documented in the OpenAPI spec — fields are `setupId`, `dataOnly`, `requiresLiabilityShift`, `redirectURL`, `requestorURL`, `browser`, `billingAddress`, `shippingAddress`, `cardHolder`, `authData`. Added a worked example of the request `threeDSecure2` block.
- `tokenization`: SDK init signature confirmed (already correct in 0.3.0): `new MalgaTokenization({ apiKey, clientId, options: { sandbox, config: { fields, preventAutofill, styles } } })`.

### Process

The "Still inferred" running list (previously in `AUDIT_NOTES.md`) was retired. From this release onward, any unconfirmed claim opens a GitHub Issue labeled `inferred` (per `MAINTAINING.md`).

## [0.4.0] — 2026-05-20

### Fixed (from reading the SDK source code, `malga@0.0.2`)

- `sdk-node`: `malga.webhooks.verify()` is **synchronous**, not async. Remove `await` from calls. Returns `boolean` directly.
- `sdk-node`: `malga.charges.refund(id, { amount })` calls REST endpoint `POST /charges/{id}/void` — the SDK exposes a friendlier "refund" name but the REST operation is `void`.
- `sdk-node`: documented the full `MalgaErrorResponse` shape:
  - `error.type` is a closed enum: `'api_error' | 'bad_request' | 'invalid_request_error' | 'card_declined'`.
  - `error.declinedCode` is a closed enum of 24 values (`card_not_supported`, `expired_card`, `fraud_confirmed`, `fraud_suspect`, `insufficient_funds`, `invalid_cvv`, `lost_card`, `stolen_card`, etc.).
- `sdk-node`: `AuthScope` enum is **exported** from the package for typed scope usage.
- `sdk-node`: `AuthCreatePublicKeyPayload.scope` accepts `'*'` (wildcard) or an array of scope strings.
- `sdk-node`: `MalgaConfigurations` schema: `{ apiKey, clientId, options?: { sandbox?: boolean; http?: { retries?: number; retryDelay?: number } } }`. Constructor throws synchronously if `apiKey` or `clientId` is missing.
- `sdk-node`: `charges.create` has two modes detected from payload shape: with `sessionId` + `publicKey` (calls `POST /sessions/{sessionId}/charge`), or without (calls `POST /charges`).
- `api-charges`: REST refund endpoint is `POST /v1/charges/{id}/void`, not `/refund`. Updated SKILL.md table and `references/charges-payloads.md`.

## [0.3.0] — 2026-05-20

### Fixed (from auditing against the Mintlify docs source)

- `sdk-node` (rewrite): package name is **`malga`** (not `@malga/node`, not `malga-node`). The SDK uses a **simplified schema** that differs from the REST API:
  - SDK uses `paymentMethod.type` (REST uses `paymentMethod.paymentType`).
  - SDK nests card data inside `paymentMethod.card` (REST uses a separate `paymentSource` block).
  - SDK card fields are `holderName`, `number`, `cvv`, `expirationDate` (REST uses `cardHolderName`, `cardNumber`, `cardCvv`, `cardExpirationDate`).
- `sdk-node`: `options.sandbox` and `options.http: { retries, retryDelay }` for environment selection and built-in retry. Real method namespaces: `auth`, `charges`, `cards`, `customers`, `sessions`, `sellers`, `webhooks`, `sandbox`.
- `sdk-node`: `auth.createPublicKey({ scope, expires })` — `expires` is in seconds.
- `sdk-node`: `malga.webhooks.verify({ payload, publicKey, signature, signatureTime })` exists with Ed25519 verification.
- `checkout-sdk` (rewrite): `<malga-checkout>` web component from `@malga-checkout/core`. Added missing `merchant-id` attribute, plus `session-id`, `idempotency-key`, `locale`.
- `checkout-sdk`: configuration is via **JS properties** on the element instance, not HTML attributes:
  - `paymentMethods` (object, per-method config).
  - `transactionConfig` (statementDescriptor, amount, customer, fraudAnalysis, paymentFlowMetadata, splitRules, etc.).
  - `dialogConfig` (success/error modal customization).
- `checkout-sdk`: theme is **only** via CSS variables on `:root`. Wrappers: `@malga-checkout/react`, `@malga-checkout/vue`, `@malga-checkout/angular`.
- `tokenization` (rewrite): real package is **`@malga/tokenization`**. HTML container IDs are fixed: `card-number`, `card-holder-name`, `card-cvv`, `card-expiration-date`. Field config keys are camelCase.
- `tokenization`: SDK init `new MalgaTokenization({ apiKey, clientId, options: { sandbox, config: { fields, preventAutofill, styles } } })`. Methods: `on(eventType, callback)` and `tokenize()`. Events: `cardTypeChange`, `validity`, `focus`, `blur`. `tokenize()` returns `{ tokenId, error }` and does not throw.
- `api-charges/references/charges-payloads.md`: Pix request is `{ paymentType, expiresIn }` only (no `additionalInfo`). Pix response field names are `qrCodeData` and `qrCodeImageUrl`. Boleto request includes `instructions`, `interest`, `fine`, `items`. Boleto is **not refundable**. Split rules require `processingFee` and `liable` flags per entry.
- `payment-methods`: same corrections as the references file.

## [0.2.0] — 2026-05-19

### Added

- New `payment-methods` skill covering every `paymentType` (`credit`, `pix`, `boleto`, `nupay`, `drip`, `voucher`, `picpay`, `apple_pay`, `click_to_pay`).

### Fixed (first audit pass against the rendered online docs)

- `webhooks` (full rewrite): real Malga webhook v1.1 protocol:
  - Create payload is `{ event, endpoint, version, status }`. One event per webhook, or `*` wildcard.
  - Signature is **Ed25519**, not HMAC-SHA256. Public key is returned at webhook creation.
  - Headers: `X-Plug-Signature` (hex Ed25519 signature) and `X-Plug-Date` (UTC Unix ms). Signed message: `{date}\n{payload}`.
  - Idempotency header on incoming events is `x-idempotency-key` (same value as event `id`).
  - Retry schedule: 6 attempts at fixed intervals (5 min → 45 min → 6 h → 1 day → 2 days → 4 days), each with 5 s timeout. After 6 failed attempts the webhook is auto-disabled.
  - Event catalog uses real names: `transaction.*` (e.g., `transaction.authorized`, `transaction.pre_authorized`, `transaction.failed`, `transaction.canceled`, `transaction.voided`, `transaction.charged_back`, `transaction.dispute`), `subscription.*`, `seller.*`.
  - Delivery logs retained for 45 days.
- `api-charges` (full rewrite): `paymentMethod` and `paymentSource` are **separate top-level objects**. Discriminator is `paymentMethod.paymentType` (not `paymentMethod.type`). Status enum: `pending`, `pre_authorized`, `authorized`, `failed`, `canceled`, `voided`, `charged_back`, `refund_pending`, `capture_pending`.
- `api-charges`: `customerId` at top level. Sandbox status push uses `POST /v1/charges/{id}` with `{ "status": "..." }`. Added top-level optional blocks `appInfo`, `fraudAnalysis`, `splitRules`, `vendor`, `paymentFlow`, `threeDSecure2`. Idempotency race condition documented (409 / 400 with explicit retry semantics).
- `checkout-sdk` (full rewrite): real `<malga-checkout>` web component (not a `Malga.Checkout()` constructor). Events are `paymentSuccess` and `paymentFailed`.
- `sdk-node` (de-fabricated): removed invented class names (`MalgaError`, `MalgaValidationError`) and helper functions. Pointed at the repository examples folder as the canonical source.
- `antifraud` (full rewrite): outcome statuses are `pending`, `approved`, `reproved`. Added sync / async / hybrid lifecycle taxonomy with `productType: SYNC | ASYNC`. Documented configuration options (`runBeforeCharge`, `captureOnApprove`, `refundOnReprove`, `captureOnError`, `refundOnError`). Noted fingerprint requirements (ClearSale mandatory).
- `recurrence` (full rewrite): subscription shape around `items`, `recurrence: { interval, startAt, nextDueDate }`, `paymentMethod.card.cardId`, `referenceKey`. Cycle shape with `paymentHistory[]` including `attemptNumber`, `chargeId`, `error`. Status enum: `created`, `trial_started`, `active`, `paused`, `unpaid`, `expired`, `canceled`.
- `tokenization` (revised): field names match the API field names. Token CVV and Zero-Dollar flows added. Network Tokens (Tokenização de Bandeira) requires Malga support enablement; Visa/Master only.
- `split-payments`: charge field renamed `splits` → `splitRules`.
- `payment-link`: Sessions `paymentMethods` is array of objects (`{ paymentType, ... }`), not strings. Added the scoped `publicKey` returned from session creation.
- `three-ds-two` (softened): added the `threeDSecure2` block in charge payload. Removed invented MIT metadata key recommendations.
- `analytics-reporting` (softened): replaced fabricated endpoint paths with conceptual descriptions; pointed to canonical API reference.
- `vtex-integration` (softened): specific VTEX Admin menu paths softened (they shift across UI revisions).

## [0.1.0] — 2026-05-19

### Added

- Initial release: 14 skills covering Charges/Sessions, SDK Node, Checkout SDK, Payment Link, VTEX, Tokenization, Smart Flows, 3DS2, Antifraud, Split Payments, Recurrence, Webhooks, Analytics, Getting Started.
- Bilingual descriptions (PT-BR + EN trigger phrases) with body content primarily in English.
- Smart Flows skill grounded in `documentations/flow-guide/introduction` (operators, properties, metadata, reserved keys, load balancing).
