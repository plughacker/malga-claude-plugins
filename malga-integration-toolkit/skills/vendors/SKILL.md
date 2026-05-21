---
name: vendors
description: 'Implementing Malga Vendors API for payment facilitators (Bacen Circular 3978/2020). Triggers: "facilitador Malga", "vendor Malga", "paymentFacilitatorId", "Bacen 3978", "marketplace identificação beneficiário".'
---

# Malga Vendors (payment facilitators)

The Vendors API lets **payment facilitators** identify the end commercial beneficiary on each transaction. Required for businesses operating under Bacen Circular 3978/2020 (marketplaces, franchises, delivery apps, etc.). This is different from `split-payments`, which is about splitting money across recipients — Vendors is about regulatory identification on the wire.

References:
- Guide: <https://docs.malga.io/documentations/vendors/intro>
- Supported providers: <https://docs.malga.io/documentations/vendors/provedores>
- API: <https://docs.malga.io/api-reference/vendors/criacao-de-um-novo-vendedor>

## When to use Vendors

| Business model | Use Vendors? |
|---|---|
| Marketplace (you process payments and forward to sellers) | **Yes** |
| Franchise (franchisor processes on behalf of franchisees) | **Yes** |
| Delivery app (you collect for restaurants) | **Yes** |
| SaaS billing your own customers | **No** |
| Single-store e-commerce | **No** |

If unsure, the rule of thumb is: are you a regulatory **facilitator** between the cardholder and another commercial entity? If yes, Vendors. If no, just use the regular charge flow.

For splitting money (vs. identifying the beneficiary), see `split-payments`.

## Vendor entity

```ts
{
  id:            string,
  referenceId:   string,             // your internal id, ≤15 chars, required
  identityType:  'CPF' | 'CNPJ',
  identity:      string,             // document number; ≤14 chars
  mcc:           string,              // ≤10 chars; segment code at the acquirer
  name:          string,              // legal name; ≤100 chars
  email?:        string,              // ≤100 chars
  phoneNumber?:  string,              // 13 chars (BR format)
  website?:      string,              // ≤100 chars
  address: {
    country:      string,              // ISO 3166-1 alpha-2; required
    state:        string,              // 2 chars; required
    city:         string,              // ≤20 chars; required
    district:     string,              // ≤20 chars; required
    zipCode:      string,              // ≤10 chars; required
    street:       string,              // ≤100 chars; required
    streetNumber: string,              // ≤5 chars; required
    complement?:  string               // ≤20 chars
  },
  createdAt:     string,
  updatedAt:     string
}
```

## REST endpoints (no SDK Node coverage)

| Action | Endpoint |
|---|---|
| Create | `POST /v1/vendors` |
| List | `GET /v1/vendors` (paginated) |
| Get | `GET /v1/vendors/{id}` |
| Update | `PATCH /v1/vendors/{id}` |
| Delete | `DELETE /v1/vendors/{id}` |

The Node SDK does not expose a `malga.vendors` namespace — use REST directly.

## Creating a vendor

```bash
POST /v1/vendors
{
  "referenceId":  "12345",
  "identityType": "CNPJ",
  "identity":     "12345678000199",
  "mcc":          "1234",
  "name":         "Empresa Exemplo Ltda",
  "email":        "contato@empresaexemplo.com",
  "phoneNumber":  "5511999999999",
  "website":      "https://www.empresaexemplo.com",
  "address": {
    "country":      "BR",
    "state":        "SP",
    "city":         "São Paulo",
    "district":     "Centro",
    "zipCode":      "01001-000",
    "street":       "Avenida Paulista",
    "number":       "1000",
    "complement":   "Apto 101"
  }
}
```

Response includes the `id` to use on subsequent charges.

## Attaching a vendor to a charge

Add a `vendor` block to the charge payload with the `id` and the bandeira-specific `paymentFacilitatorId`:

```bash
POST /v1/charges
{
  "merchantId":    "...",
  "amount":        150,
  "paymentMethod": { "paymentType": "credit", "installments": 1 },
  "paymentSource": { ... },
  "vendor": {
    "id":                   "db56bd6a-10d7-4039-9c68-fc4405a1a3e1",
    "paymentFacilitatorId": "123456"
  }
}
```

`paymentFacilitatorId` is provided by each card network (Visa, Mastercard) to the facilitator. Consult the bandeira directly — Malga does not issue this code.

## Supported providers

| Provider | Requires `paymentFacilitatorId` |
|---|---|
| Adyen | Yes |
| Cielo | Yes |
| Rede | Yes |
| Getnet | No |
| SafraPay | No |
| Sandbox | No |

Providers not in this table do not support the vendor flow. If the merchant's Smart Flow routes through an unsupported provider, the vendor block is silently dropped.

## Vendors vs Sellers (split-payments)

This is the most common source of confusion. They are different concerns:

| Concept | Purpose |
|---|---|
| **Vendor** (this skill) | Regulatory identification of the **commercial beneficiary** on the wire. No money movement implication. |
| **Seller** (`split-payments` skill) | Recipient of part of the charge amount. Drives `splitRules` and payouts. |

A marketplace using Malga typically uses **both**:
- A Vendor per merchant of the marketplace, for compliance.
- A Seller per merchant of the marketplace, for the split + payout.

These are separate entities with separate ids; the merchant's data ends up duplicated. That's by design.

## Regulatory context

The Vendors flow exists to comply with **Bacen Circular 3978 (Jan 23, 2020)**: payment facilitators must identify the end establishment to the acquirer on every transaction. Failing to do so can mean:

- Card networks (Visa, Mastercard) deny the merchant continued facilitator status.
- Acquirers report incorrectly to Bacen.
- Risk of regulatory action.

For Brazilian marketplaces this is not optional.

## Pitfalls

- **`paymentFacilitatorId` comes from the card network**, not Malga. Each bandeira has its own code; consult Visa, Mastercard, Elo, etc.
- **`referenceId`** is capped at 15 characters. If your internal id is a UUID, hash or truncate before passing.
- **`mcc`** must match what the acquirer has on file for that vendor. Mismatch causes the provider to reject the transaction.
- **Not the same as Sellers.** Don't try to reuse a Seller id where a Vendor is needed.
- **Providers without facilitator support**: if your Smart Flow includes them in the same branch, the regulatory identification fails silently for charges routed through them. Audit the Smart Flow against the supported-providers table.
- **No SDK Node coverage**: do not look for `malga.vendors.*` — it does not exist.

## Cross-references

- `split-payments` for the money-splitting side.
- `smart-flows` for routing only to facilitator-capable providers.
- `merchants` for understanding the Malga subaccount structure.
