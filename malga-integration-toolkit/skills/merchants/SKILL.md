---
name: merchants
description: Use this skill when implementing, configuring, or managing Malga merchants (subcontas / subaccounts). Triggers on questions about "merchant Malga", "subconta Malga", "criar subconta", "merchant ID Malga", "MCC Malga", "configurar provedores do merchant", "PATCH /v1/merchants", "multiple merchants Malga", "qual merchantId usar", "store account Malga", "loja vs subconta". Covers the Merchant entity, when to use one vs. multiple, the REST endpoints, and the Dashboard "Subcontas" area.
---

# Malga Merchants (Subcontas)

A merchant in Malga is a **subaccount** representing a store, brand, or business unit. Every charge is tied to a `merchantId`. Merchants hold provider keys and Smart Flow configuration, so they are the unit of "what providers process which charges".

The Malga Node SDK does **not** expose a `merchants` namespace — manage merchants via the REST API or the Dashboard.

References:
- API: <https://docs.malga.io/api-reference/merchants/listagem-de-merchants-cadastrados>
- Dashboard guide: <https://docs.malga.io/documentations/dashboard/merchants>

## Merchant entity

```ts
{
  id:         string,
  clientId:   string,
  mcc:        string,                          // acquirer MCC code
  status:     'active' | 'pending' | 'deleted',
  providers:  ProviderDto,                     // active payment providers for this merchant
  createdAt:  string,
  updatedAt:  string
}
```

## REST endpoints

| Action | Endpoint |
|---|---|
| Create | `POST /v1/merchants` |
| List | `GET /v1/merchants` (paginated, returns `MerchantList`: `{ meta, items[] }`) |
| Get | `GET /v1/merchants/{id}` |
| Update settings | `PATCH /v1/merchants/{id}` |
| Delete | `DELETE /v1/merchants/{id}` |

Per-provider configuration of a merchant uses a separate endpoint:

| Action | Endpoint |
|---|---|
| Update provider configuration on a merchant | `PATCH /v1/providers/...` (see the `providers` skill) |

## When to use a single vs. multiple merchants

A Malga **account** can have many merchants. Decide as follows.

| Scenario | Recommendation |
|---|---|
| One brand, one storefront, one BR legal entity | **Single merchant.** Default. |
| Multiple brands sharing one account | **One merchant per brand** so each can have its own Smart Flow, look-and-feel for hosted checkout, and provider keys. |
| Single brand, multiple business lines with different fee structures | **One merchant per business line** to isolate financial reporting. |
| Multi-country (BR + LATAM) | **One merchant per country** because providers and MCC differ. |
| Marketplace with sellers | **Single merchant + Sellers** (see `split-payments`). Don't create one merchant per seller; that's the wrong abstraction. |
| Payment facilitator with sub-merchants | **Single Malga merchant + Vendors** (see the `vendors` skill if you're a facilitator). |

## Dashboard side: Subcontas

The Dashboard area "Subcontas" (<https://dashboard.malga.io/app/merchants>) lists every merchant in the account with:

- Update date.
- Merchant name (editable; defaults to a generic name).
- Merchant ID.
- Active providers.
- Active payment methods.

Each merchant has a detail page showing MCC, payment methods, providers (with name, type, id, status, activation date, contracted services). The Dashboard's Smart Flow editor and Payment Link area surface the merchant's name everywhere, so giving them human-readable names (instead of UUIDs) is worth doing early.

## Configuring providers per merchant

After creating a merchant, attach providers (Stripe, Cielo, Adyen, etc.) through the Dashboard or via `PATCH /v1/providers/...`. The Smart Flow for each `(merchant, paymentMethod)` pair then routes charges across those providers. See `providers` and `smart-flows` skills.

## charge → merchant relationship

Every charge **requires** `merchantId`. If a merchant has more than one provider for the chosen payment method, the merchant's Smart Flow decides the routing.

```json
POST /v1/charges
{
  "merchantId": "<MERCHANT_ID>",
  "amount": 5000,
  ...
}
```

The merchant chosen at charge time also determines:
- Which providers are eligible.
- Which Smart Flow runs.
- Which antifraud is consulted.
- Which Settings (Payment Link branding) apply.

## Pitfalls

- **SDK Node has no `malga.merchants` namespace.** Use REST or the Dashboard. Don't infer SDK methods that don't exist.
- **`mcc`** is the merchant category code assigned by the acquirer, not chosen freely by the merchant. Coordinate with Malga support to set it correctly at the time the merchant is created.
- **Don't create one merchant per customer or per order.** A merchant is a long-lived business entity; per-customer separation belongs in `customer` records.
- **Renaming a merchant** in the Dashboard updates the name across Smart Flows, Payment Links, and exports. Plan internal references against the `id`, not the name.
- **Deleting a merchant** is destructive for historical reporting. Prefer disabling or marking inactive over hard deletion.
- **Charges already created against a merchant remain queryable** even after the merchant is deleted; the `merchantId` survives in the charge record.
