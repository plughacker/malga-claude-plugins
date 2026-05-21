---
name: type-tables
description: 'Looking up Malga reference tables (decline codes, banks, MCC, providers compat). Triggers: "código de recusa Malga", "decline code Malga", "tabela de bancos", "MCC Malga", "qual provedor suporta Pix", "ABECS Malga".'
---

# Malga Type Tables (reference data)

Malga publishes eight reference tables that an integration consults at runtime or for analytics:

| Table | URL | Used by |
|---|---|---|
| Decline codes | `documentations/type-tables/declined-code` | Customer-facing error messages, retry logic, analytics |
| Antifraud providers | `documentations/type-tables/antifraude-providers` | Antifraud configuration, Smart Flow design |
| Currency support | `documentations/type-tables/currency-not-supportted` | Multi-currency charges |
| Document type per country | `documentations/type-tables/customer-document-by-country` | Customer creation |
| MCC codes | `documentations/type-tables/mcc-code` | Merchant configuration |
| Main banks | `documentations/type-tables/main-banks` | Seller bank account creation, Pix routing |
| Additional services | `documentations/type-tables/additional-services` | Feature availability per provider |
| Payment methods × providers | `documentations/type-tables/payment-methods-by-providers` | Smart Flow design, provider selection |

Always consult the live source — these tables change as Malga onboards new providers, methods, and currencies.

## Decline codes (most common lookup)

A failed charge has a `declinedCode` on its `transactionRequests[0]`. Use the table to translate to a user-facing message and decide retry behavior.

The table has four columns: `DeclinedCode`, `ResponseMessage`, **Retentável** (Sim/Não), **O que fazer (ABECS)** (the standard guidance per ABECS — Associação Brasileira das Empresas de Cartões de Crédito e Serviços).

Practical use:

- **Retentável = Sim**: the Smart Flow can route to the next provider. The merchant can also offer a retry button to the customer with a different card.
- **Retentável = Não**: terminal failure. Do not retry; show the appropriate ABECS guidance ("UTILIZE FUNÇÃO DÉBITO", "VERIFIQUE OS DADOS", "TRANSAÇÃO NÃO PERMITIDA — NÃO TENTE NOVAMENTE", etc.).

A few high-value entries to know by heart:

| DeclinedCode | Retentável | ABECS guidance |
|---|---|---|
| `bad_request` | Sim | "VERIFIQUE OS DADOS" |
| `blocked_card` | Sim* | "TRANSAÇÃO NÃO PERMITIDA PARA O CARTÃO — NÃO TENTE NOVAMENTE" |
| `canceled_card` | Sim* | "TRANSAÇÃO NÃO PERMITIDA PARA O CARTÃO — NÃO TENTE NOVAMENTE" |
| `card_not_supported` | Não | "UTILIZE FUNÇÃO DÉBITO" |
| `expired_card` | Não | (Customer needs a new card) |
| `insufficient_funds` | Sim | (Customer can try another card / payment method) |
| `fraud_confirmed` | Não | (Do not retry) |
| `fraud_suspect` | Não | (Do not retry) |
| `lost_card` / `stolen_card` | Não | (Do not retry, may be reported to fraud team) |

*Note: "Retentável = Sim" means the **Smart Flow** can try another provider. The customer-facing ABECS message may still say "não tente novamente" because the card is bad regardless of provider. The two facts live in different columns; respect both.

The full list lives at <https://docs.malga.io/documentations/type-tables/declined-code>. The SDK also exposes a TypeScript enum of declined codes (see `sdk-node` skill, `MalgaErrorResponse.declinedCode`).

## Payment methods × providers (most common Smart Flow lookup)

This table tells you which providers support which payment methods (credit, pix, boleto, nupay, drip, voucher, picpay, apple_pay, click_to_pay). Use it when:

- Designing a Smart Flow branch for a method — only include providers that support it.
- Reviewing a failed charge — confirm the routed provider supports the method.
- Estimating fallback capacity — count how many providers can serve as the second/third option.

Reference: <https://docs.malga.io/documentations/type-tables/payment-methods-by-providers>.

## Antifraud providers

Lists the antifraud providers integrated with Malga (ClearSale, Konduto, Cybersource, Riskified, Signifyd, etc.), their lifecycle (sync vs async vs hybrid), and any mandatory fingerprint requirements.

ClearSale, in particular, requires fingerprint per integration policy. See the `antifraud` skill.

Reference: <https://docs.malga.io/documentations/type-tables/antifraude-providers>.

## Currency support

Lists which currencies are accepted by which providers. The merchant's Smart Flow must route foreign-currency charges through a provider that supports the target currency, otherwise the charge fails.

Reference: <https://docs.malga.io/documentations/type-tables/currency-not-supportted>.

## Customer document by country

Lists the valid `document.type` values per country in the customer payload (`cpf`, `cnpj` for BR; other locales have their own types). Use during customer creation to validate input before sending.

Reference: <https://docs.malga.io/documentations/type-tables/customer-document-by-country>.

## MCC codes

The merchant category code assigned by the acquirer. Set at merchant creation; the value drives interchange rates, regulatory category, and antifraud risk scoring. Coordinate with Malga support to set the right MCC for each merchant.

Reference: <https://docs.malga.io/documentations/type-tables/mcc-code>.

## Main banks

Lists the BR bank codes (Itaú = 341, Bradesco = 237, Banco do Brasil = 001, etc.) used in seller `bankAccount.bank` and Pix routing. Use during seller onboarding (`split-payments` skill).

Reference: <https://docs.malga.io/documentations/type-tables/main-banks>.

## Additional services

Lists per-provider feature support beyond the core methods — pre-auth, partial capture, partial refund, split, antifraud, 3DS, network tokens, zero-dollar validation, recurrence flag, dispute notifications, multi-currency, etc.

This is the most useful single table when picking providers for a new merchant. Don't promise a feature you can't deliver based on the actual provider mix.

Reference: <https://docs.malga.io/documentations/type-tables/additional-services>.

## Pitfalls

- **Don't hardcode the tables in the skill.** The tables drift over time as Malga onboards new providers. Always link to the live URL.
- **"Retentável" in the decline-codes table is from the Smart Flow's perspective**, not the customer's. Don't tell the customer "try again" just because the column says Sim — read the ABECS column too.
- **MCC is not user-chosen.** Don't expose an MCC input in the merchant onboarding form unless the operator is informed.
- **`fraud_confirmed` and `fraud_suspect`** are different (one is "confirmed by issuer", the other is "suspicious"). Both are non-retryable but their downstream handling can differ.

## Cross-references

- `api-charges`: the charge response's `declinedCode` ties back to this table.
- `antifraud`: the antifraud providers table is the canonical source.
- `smart-flows`: the payment-methods × providers table drives flow design.
- `split-payments`: the main-banks table is needed for seller setup.
- `customers-and-cards`: the document-by-country table validates customer input.
