# Charges payloads — full examples

All amounts are integers in cents (BRL). Replace placeholders. Always send `X-Idempotency-Key` on POSTs.

## Credit card — single charge with token

```json
POST /v1/charges
{
  "merchantId": "<MERCHANT_ID>",
  "amount": 12990,
  "currency": "BRL",
  "orderId": "ord-2026-0001",
  "statementDescriptor": "MINHALOJA",
  "paymentMethod": {
    "type": "credit",
    "installments": 3,
    "card": {
      "tokenId": "<CARD_TOKEN>",
      "cvvCheck": true
    }
  },
  "customer": { "id": "<CUSTOMER_ID>" },
  "paymentFlow": {
    "metadata": { "channel": "web" }
  }
}
```

## Credit card — pre-authorization + capture

Pre-auth: same payload as above with `paymentMethod.capture = false`. The charge enters `pre_authorized`. Capture later:

```bash
POST /v1/charges/{chargeId}/capture
{ "amount": 12990 }
```

## Pix charge

```json
POST /v1/charges
{
  "merchantId": "<MERCHANT_ID>",
  "amount": 9900,
  "currency": "BRL",
  "orderId": "ord-2026-0002",
  "paymentMethod": {
    "type": "pix",
    "pix": {
      "expiresIn": 3600,
      "additionalInfo": [
        { "name": "Pedido", "value": "ord-2026-0002" }
      ]
    }
  },
  "customer": { "id": "<CUSTOMER_ID>" }
}
```

Response contains `paymentSource.pix.qrCode` (copy-paste string) and `qrCodeUrl` (image).

## Boleto charge

```json
POST /v1/charges
{
  "merchantId": "<MERCHANT_ID>",
  "amount": 19900,
  "currency": "BRL",
  "orderId": "ord-2026-0003",
  "paymentMethod": {
    "type": "boleto",
    "boleto": {
      "expiresDate": "2026-06-01",
      "instructions": "Não receber após o vencimento"
    }
  },
  "customer": { "id": "<CUSTOMER_ID>" }
}
```

## Refund

```bash
POST /v1/charges/{chargeId}/refund
{ "amount": 12990 }
```

Partial refund: pass `amount` smaller than the captured value.

## Sandbox — force outcome

```bash
POST /v1/charges/{chargeId}/sandbox-status
{ "status": "failed", "reason": "insufficient_funds" }
```

```bash
PATCH /v1/charges/{chargeId}/sandbox-antifraud-status
{ "status": "denied" }
```

## Declined-code mapping

The full table lives at <https://docs.malga.io/documentations/type-tables/declined-code>. Important categories:

- **Retryable** (Smart Flow continues to the next provider): `processing_error`, `gateway_timeout`, `try_again_later`.
- **Non-retryable** (charge ends): `card_declined`, `insufficient_funds`, `lost_card`, `stolen_card`, `do_not_honor`.
- **Fraud**: `fraudulent`, `suspected_fraud` — these are routed via antifraud, not provider retry.

## Status flow

```
pending → pre_authorized → captured           (happy path with pre-auth)
pending → authorized → captured                (happy path direct capture)
pending → failed                                (declined / non-retryable)
captured → refunded                             (after refund)
```
