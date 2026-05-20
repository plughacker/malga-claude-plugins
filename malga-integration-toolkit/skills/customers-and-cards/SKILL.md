---
name: customers-and-cards
description: Use this skill when implementing or troubleshooting Customer and Card management on Malga, beyond the in-browser tokenization flow covered by the `tokenization` skill. Triggers on questions about "criar customer Malga", "cliente cadastrado Malga", "vincular cartão ao customer", "card on file Malga", "salvar cartão", "linkCard Malga", "customer document CPF", "customer address Malga", "tokenizar cartão server-side", "Token CVV Malga", "Card API Malga", "customer.cards", "POST /v1/customers", "POST /v1/cards". Covers the Customer entity (document, address, contact), the Card entity (lifecycle, fingerprint, expiration), how to link cards to customers, and how tokens differ from cards.
---

# Malga Customers and Cards

The Customer entity holds the buyer's identity (document, contact, address) so it can be reused across charges, subscriptions, and refunds. The Card entity is the vaulted form of a payment card, ready to charge again without re-tokenizing.

These two entities sit next to each other because most card-on-file flows manipulate both: tokenize → create card → link to customer → charge by `customerId`.

References:
- Customers API: <https://docs.malga.io/api-reference/customers/listagem-de-customers-cadastrados>
- Cards API: <https://docs.malga.io/api-reference/cards/listar-cartoes>
- Tokens API: <https://docs.malga.io/api-reference/tokens/criar-um-novo-token>
- SDK docs: <https://docs.malga.io/sdks/api-sdks/docs/customers/create-customer>, <https://docs.malga.io/sdks/api-sdks/docs/cards/create-card>

## Customer entity

```ts
{
  id:           string,
  clientId:     string,
  name:         string,
  email:        string,
  phoneNumber:  string,
  document:     { type: 'cpf' | 'cnpj' | string; number: string; country: string },
  address:      {
                  city: string, country: string, district: string, state: string,
                  street: string, streetNumber: string, zipCode: string,
                  complement?: string
                },
  createdAt:    string,
  updatedAt:    string
}
```

`document.type` is `'cpf'` for individuals and `'cnpj'` for companies in Brazil. Other countries use the locally appropriate type identifier.

### REST endpoints

| Action | Endpoint |
|---|---|
| Create | `POST /v1/customers` |
| List | `GET /v1/customers` (paginated) |
| Get | `GET /v1/customers/{id}` |
| Update | `PATCH /v1/customers/{id}` |
| Delete | `DELETE /v1/customers/{id}` |
| List cards | `GET /v1/customers/{customer_id}/cards` |
| Link card | `POST /v1/customers/{customer_id}/cards` |

### SDK Node methods

```ts
malga.customers.create({ name, email, phoneNumber, document, address });
malga.customers.find(customerId);
malga.customers.list({ page, limit, ... });
malga.customers.update(customerId, { ...fields });
malga.customers.remove(customerId);
malga.customers.linkCard(customerId, { cardId });
malga.customers.listCards(customerId);
```

## Card entity

```ts
{
  id:              string,
  status:          'active' | 'inactive' | ...,
  clientId:        string,
  customerId:      string | null,        // null until linked
  brand:           string,                // 'Visa' | 'Mastercard' | 'Elo' | ...
  cardHolderName:  string,
  cvvChecked:      boolean,               // true after a zero-dollar check
  fingerprint:     string,                // stable per-card hash; same card = same fingerprint
  first6digits:    string,
  last4digits:     string,
  expirationMonth: string,
  expirationYear:  string,
  createdAt:       string,
  updatedAt:       string
}
```

The `fingerprint` is the cleanest way to detect "same card across multiple customers" without storing PAN. Two card vaultings of the same PAN produce identical fingerprints.

### REST endpoints

| Action | Endpoint |
|---|---|
| Create from token | `POST /v1/cards` |
| List | `GET /v1/cards` (paginated) |
| Get | `GET /v1/cards/{id}` |

### SDK Node methods

```ts
malga.cards.create({ tokenId, zeroDollar?: { merchantId, cvvCheck } });
malga.cards.find(cardId);
malga.cards.list({ page, limit, customerId? });
malga.cards.tokenization({ holderName, number, cvv, expirationDate });   // server-side token (needs PCI scope)
malga.cards.tokenization({ cvv });                                        // tokenize CVV only (for vaulted card reuse)
```

`malga.cards.tokenization()` is the server-side equivalent of the Tokenization SDK's `tokenize()` — use it only when the merchant has its own PCI scope (typically during card-base migration). For browser flows, use the `@malga/tokenization` SDK and just pass the resulting `tokenId` to `malga.cards.create({ tokenId })`.

## Tokens vs Cards

| Token | Card |
|---|---|
| Single-use reference to card data | Long-lived vaulted card |
| Created by Tokenization SDK or `POST /v1/tokens` | Created by `POST /v1/cards` from a token |
| Used as `paymentSource.tokenId` on a one-shot charge | Used as `paymentSource.cardId` for repeat charges |
| Disappears after use | Survives until deleted |
| No customer linkage | Can be linked to a customer |

The recommended pattern for card-on-file:

```
Frontend (Tokenization SDK) → tokenId
       ↓
Backend: POST /v1/cards { tokenId, customerId? } → cardId
       ↓
Future charges: paymentSource = { sourceType: "card", cardId }
```

## Customer auto-creation in a charge

A charge payload can include a full `customer` object (instead of just `customerId`). When `customer` is sent and there is no `customerId`, Malga creates the customer and links it to the charge automatically. Useful for guest checkouts where the customer is captured at purchase time.

```json
{
  "merchantId":    "...",
  "amount":        12990,
  "paymentMethod": { "paymentType": "credit", "installments": 1 },
  "paymentSource": { "sourceType": "card", "card": { ... } },
  "customer": {
    "name":         "Maria Silva",
    "email":        "maria@example.com",
    "phoneNumber":  "11999998888",
    "document":     { "type": "cpf", "number": "12345678900", "country": "BR" },
    "address":      { ... }
  }
}
```

The same shorthand works in the SDK Node's `malga.charges.create({ ..., customer: { ... } })`.

## Zero-dollar validation when creating a card

To validate a card with the issuer at vault time (without billing), pass `zeroDollar`:

```ts
await malga.cards.create({
  tokenId: '<TOKEN_FROM_SDK>',
  zeroDollar: {
    cvvCheck: true,
    merchantId: '<MERCHANT_ID>'  // a merchant whose provider supports zero-dollar
  }
});
```

The resulting card has `cvvChecked: true`. See the `tokenization` skill for the full Zero-Dollar / Token CVV context and provider compatibility.

## Subscriptions cross-reference

Recurring billing requires a **vaulted card** (`cardId`), not a token. Vault the card first via `POST /v1/cards`, then reference it on the subscription's `paymentMethod.card.cardId`. See the `recurrence` skill.

## Pitfalls

- **`customerId` vs `customer`** at the charge level: pass one or the other, not both. Passing `customer` without `customerId` triggers auto-create.
- **Single-use token**: a `tokenId` is consumed by either `POST /charges` or `POST /cards`. To use the same card multiple times, vault it as a card.
- **Server-side tokenization requires PCI scope**. For browser flows, always use the Tokenization SDK on the client and send just the `tokenId` to the backend.
- **The `fingerprint`** is the right identifier for "same card seen before". Don't try to dedupe by `first6digits + last4digits` — those collide.
- **Document numbers** are not validated for checksum on the API side in all cases. Validate client-side before posting if the integration depends on valid CPF/CNPJ.
