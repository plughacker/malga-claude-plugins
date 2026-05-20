---
name: split-payments
description: Use this skill when implementing Split de Pagamentos with Malga — distributing a single charge across multiple receivers (marketplaces, facilitators). Triggers on questions about "split de pagamentos Malga", "Malga marketplace split", "Malga Sellers API", "Malga Vendors API", "criar recebedor Malga", "seller Malga", "vendor facilitador Malga", "payout Malga", "repasse Malga", "saldo de payout Malga", "regras de split", "split percentage versus fixed", "submerchant Malga". Covers the Sellers / Vendors / Payouts data model, split rules on a charge, document-upload for KYC, and the payout lifecycle.
---

# Malga Split (marketplace and facilitator)

Split lets a single customer charge automatically distribute funds to multiple receivers — used by marketplaces (the customer pays one charge, three sellers receive their share) and facilitators (an aggregator processing payments on behalf of sub-merchants).

Reference: <https://docs.malga.io/documentations/split-payments> (general) and <https://docs.malga.io/api-reference/sellers> (API).

## Data model

| Entity | Purpose |
|---|---|
| **Seller** | A natural or legal person who receives money. Holds bank account, document, and KYC docs. Required for split on a charge. |
| **Vendor** | A "facilitated" merchant — used by payment facilitators that must identify the end beneficiary of each charge for regulatory compliance. |
| **Payment Batch / Payout** | The scheduled or on-demand transfer of accumulated balance to a Seller's bank account. |

Sellers are the receivers; Vendors are the entities a facilitator is enabling.

## Creating a seller

```bash
POST /v1/sellers
{
  "type": "individual",                      // or "company"
  "document": { "type": "CPF", "number": "12345678900" },
  "name": "Maria Silva",
  "bankAccount": {
    "bankCode": "260",
    "agency": "0001",
    "account": "1234567",
    "accountType": "checking"
  }
}
```

For KYC, upload documents:

```bash
POST /v1/sellers/{sellerId}/documents
multipart/form-data: type=identity, file=<...>
```

List / get / patch / delete endpoints exist for the seller lifecycle.

## Vendors (facilitators only)

Use the `/v1/vendors` endpoints if the merchant is a payment facilitator. Vendors carry the regulatory identification of the end commercial establishment for each charge.

## Splitting a charge

Add a `splits` (or `paymentFlow.split`) array to the charge payload:

```json
POST /v1/charges
{
  "merchantId": "...",
  "amount": 10000,
  "paymentMethod": { ... },
  "splits": [
    { "sellerId": "<SELLER_A>", "amount": 7000 },
    { "sellerId": "<SELLER_B>", "amount": 2500 },
    { "sellerId": "<MARKETPLACE>", "amount": 500 }
  ]
}
```

Amounts must sum to the charge `amount` (or use percentage-based, depending on the provider's capability). The marketplace's own cut is just another split line.

## Payouts

Once charges settle, Malga consolidates per-seller balance and dispatches payouts according to the configured schedule (D+1, D+7, weekly, on-demand).

| Action | Endpoint |
|---|---|
| Check balance | `GET /v1/payouts/balance?sellerId=...` |
| List batches | `GET /v1/payouts/batches` |
| Get batch | `GET /v1/payouts/batches/{id}` |
| List orders in batch | `GET /v1/payouts/batches/{id}/orders` |
| List all orders | `GET /v1/payouts/orders` |
| Get order | `GET /v1/payouts/orders/{id}` |

A "payout order" is the unit of money movement. A "batch" groups orders sent together to the bank.

## Webhooks

Configure webhooks for payout events (`payout.created`, `payout.processed`, `payout.failed`) so the marketplace updates seller dashboards in real time.

## Provider support

Not every payment provider supports split. The Smart Flow must route split-enabled charges through providers that do — configure this in the Dashboard. Failing that, the charge will succeed but split lines will be deferred to a manual payout reconciliation.

## Pitfalls

- **Document uploads are required** for sellers before payouts can run. Charges may proceed without docs in test mode but blocked from payout in production.
- **Sum mismatch** — split amounts must equal the charge total (including marketplace cut).
- **Refunds** — refunding a split charge reverses each leg pro-rata. Make sure your reconciliation expects that.
- **Card-not-present + split + 3DS** — supported but limited to providers that integrate all three. Confirm in the Dashboard.
