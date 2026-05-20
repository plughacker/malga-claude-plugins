# Charges payloads — full examples (REST API)

These examples target the **REST API directly** (`POST https://api.malga.io/v1/charges`). If you are using the Node SDK, the payload shape is different — see the `sdk-node` skill.

Amounts are integers in cents (BRL). All POSTs accept `X-Idempotency-Key` (recommended UUID v4).

## Credit card — one-shot (raw card data)

> Only valid if the merchant holds its own PCI scope. For browser flows, use the Tokenization SDK and the tokenized variant below.

```json
POST /v1/charges
{
  "merchantId":          "<MERCHANT_ID>",
  "amount":              12990,
  "currency":            "BRL",
  "orderId":             "ord-2026-0001",
  "statementDescriptor": "MINHALOJA",
  "capture":             true,
  "paymentMethod": {
    "paymentType":  "credit",
    "installments": 3
  },
  "paymentSource": {
    "sourceType": "card",
    "card": {
      "cardNumber":         "5261424250184574",
      "cardCvv":            "321",
      "cardExpirationDate": "06/2028",
      "cardHolderName":     "JOAO DA SILVA"
    }
  },
  "customerId": "<CUSTOMER_ID>",
  "paymentFlow": { "metadata": { "channel": "web" } }
}
```

## Credit card — tokenized (from Tokenization SDK)

```json
POST /v1/charges
{
  "merchantId": "<MERCHANT_ID>",
  "amount":     12990,
  "paymentMethod": { "paymentType": "credit", "installments": 1 },
  "paymentSource": {
    "sourceType": "token",
    "tokenId":    "<TOKEN_FROM_SDK>"
  },
  "customerId": "<CUSTOMER_ID>"
}
```

## Credit card — vaulted (card on file)

```json
POST /v1/charges
{
  "merchantId": "<MERCHANT_ID>",
  "amount":     5000,
  "paymentMethod": { "paymentType": "credit", "installments": 1 },
  "paymentSource": {
    "sourceType": "card",
    "cardId":     "<CARD_ID>"
  },
  "customerId": "<CUSTOMER_ID>"
}
```

## Credit card — pre-authorization + capture

Set `capture: false` to pre-authorize. The charge enters `pre_authorized`.

```json
POST /v1/charges
{
  "merchantId":    "...",
  "amount":        12990,
  "capture":       false,
  "paymentMethod": { "paymentType": "credit", "installments": 1 },
  "paymentSource": { "sourceType": "card", "cardId": "<CARD_ID>" }
}
```

Capture later (partial captures supported by passing `amount` smaller than original):

```bash
POST /v1/charges/{chargeId}/capture
{ "amount": 12990 }
```

## Pix charge

```json
POST /v1/charges
{
  "merchantId": "<MERCHANT_ID>",
  "amount":     9900,
  "currency":   "BRL",
  "orderId":    "ord-2026-0002",
  "paymentMethod": {
    "paymentType": "pix",
    "expiresIn":   3600
  },
  "customerId": "<CUSTOMER_ID>"
}
```

Response includes the QR code in `paymentMethod.qrCodeData` (copy-paste string) and `paymentMethod.qrCodeImageUrl` (image URL). Status begins as `pending` and moves to `authorized` after payment confirmation. A `transaction.authorized` webhook fires when funds settle.

> **Note**: a Pix transaction may settle for a slightly different amount than originally requested (interest, fee, discount applied at the bank). Always read `amount` from the webhook event rather than assuming it equals the original charge amount.

## Boleto charge

```json
POST /v1/charges
{
  "merchantId": "<MERCHANT_ID>",
  "amount":     19900,
  "currency":   "BRL",
  "orderId":    "ord-2026-0003",
  "paymentMethod": {
    "paymentType":  "boleto",
    "expiresDate":  "2026-06-01",
    "instructions": "Não receber após o vencimento",
    "interest": {
      "days":       1,
      "amount":     100,
      "percentage": 0.5
    },
    "fine": {
      "days":       2,
      "amount":     200,
      "percentage": 2
    }
  },
  "customerId": "<CUSTOMER_ID>"
}
```

- `expiresDate` is ISO-Date format (`YYYY-MM-DD`). Default: 7 days from now.
- `instructions` is free text up to 255 characters. Use `\n` for line breaks.
- `interest` and `fine` are optional. `days` is the grace period after expiration; `amount` is in cents per day; `percentage` is a per-month / total percentage depending on the field.
- Boleto charges enter `pending` until settled. They cannot be pre-authorized or refunded; they auto-fail at the due date if unpaid.

## Refund (card and Pix only)

The refund operation at REST is `POST /v1/charges/{chargeId}/void` (not `/refund`):

```bash
POST /v1/charges/{chargeId}/void
{ "amount": 12990 }
```

Partial refund: pass `amount` smaller than the captured value. For Pix the refund may go through `refund_pending` first and then `voided` once the receiver bank confirms. The Node SDK exposes the same operation as `malga.charges.refund(id, { amount })` for ergonomics.

## Sandbox — force outcome

Supported transitions in sandbox: `authorized`, `voided`, `charged_back`.

```bash
POST /v1/charges/{chargeId}
{ "status": "charged_back" }
```

Useful to trigger webhook events without actual provider involvement.

## Split (marketplace)

```json
POST /v1/charges
{
  "merchantId":    "<MERCHANT_ID>",
  "amount":        10000,
  "paymentMethod": { "paymentType": "credit", "installments": 1 },
  "paymentSource": { "sourceType": "card", "cardId": "<CARD_ID>" },
  "splitRules": [
    { "sellerId": "<SELLER_A>",    "amount": 7000, "processingFee": false, "liable": false },
    { "sellerId": "<SELLER_B>",    "amount": 2500, "processingFee": false, "liable": false },
    { "sellerId": "<MARKETPLACE>", "amount":  500, "processingFee": true,  "liable": true  }
  ]
}
```

Required per `splitRules` entry: `sellerId`, `processingFee`, `liable`. Use `amount` (cents) or `percentage` (number). See the `split-payments` skill.

## 3DS2

Set the `threeDSecure2` block at the top level of the charge body. The fields are provider-specific.

```json
"threeDSecure2": {
  "deviceInfo":  { ... },
  "browserInfo": { ... },
  "returnUrl":   "https://example.com/return"
}
```

See the `three-ds-two` skill and the Charges API reference (<https://docs.malga.io/api-reference/charges/realizar-nova-cobranca>) for the exact subfields.

## Status enum (response)

The `status` field on a charge can be:

```
pending          → pre_authorized → authorized
                                  ↘ canceled (auth-only, not captured)
                                  ↘ voided    (auth + capture reversed)
                                  ↘ charged_back

failed           (issuer declined before authorization)
refund_pending   (async refund in progress, e.g., Pix)
capture_pending  (async capture in progress)
```

Decline codes used by `failed` status are listed in <https://docs.malga.io/documentations/type-tables/declined-code>. Retryable codes route automatically to the next provider in the Smart Flow branch; non-retryable codes terminate the charge immediately.
