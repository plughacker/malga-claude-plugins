---
name: providers
description: Use this skill when configuring or choosing payment gateways (providers) on Malga. Triggers on questions about "provedor de pagamento Malga", "configurar Adyen na Malga", "Cielo Malga", "Stripe Malga", "PagSeguro Malga", "Getnet Malga", "Pagar.me Malga", "Banrisul Malga", "qual provedor suporta X Malga", "Malga gateway", "PATCH /v1/providers". Covers the 30+ providers integrated by Malga, the per-provider feature matrix, configuration via Dashboard or REST, and the decision framework for picking providers.
---

# Malga Providers (payment gateways)

Malga integrates with 30+ payment providers (gateways and acquirers). The merchant attaches one or more providers to each merchant subaccount, then the Smart Flow routes charges across them. This is the orchestration value proposition — same integration, multiple gateways.

Reference: <https://docs.malga.io/documentations/providers/> (one page per provider) and <https://docs.malga.io/documentations/type-tables/payment-methods-by-providers> for the matrix.

## Supported providers (current)

Adyen, Banco do Brasil, Banrisul, Barte, Bolt, Braintree, Braspag, BS2, Cielo, Drip, Getnet, Getnet SEP, Klap, Malga (own subadquirente), Mapinvest, Mercado Pago, NuPay, OwemPay, Pagar.me, Pagar.me v5, PagSeguro, PayPal, PicPay, Rede, SafraPay, Sandbox, Stripe, VR, Worldpay, Zoop.

Each has a dedicated page at `documentations/providers/<name>` documenting:
- Methods supported (credit, pix, boleto, voucher, apple_pay, etc.).
- Features per method (pre-auth, partial capture, refund total/partial, split, antifraud, 3DS, network tokens, zero-dollar, recurrence flag, dispute/chargeback notifications, multi-currency).
- Provider-specific quirks.

When integrating, **always read the provider's page** for the merchant's chosen gateway before designing the Smart Flow.

## Per-provider feature matrix (template)

Each provider page has a table of services × methods. Example (Adyen):

| Service | Credit | Pix | Boleto | Voucher | Apple Pay |
|---|---|---|---|---|---|
| Cobrança | ✅ | ✅ | ✅ | — | (limited) |
| Pré-autorização | ✅ | — | — | — | (limited) |
| Captura parcial | ✅ | — | — | — | (limited) |
| Estorno total | ✅ | ✅ | — | — | (limited) |
| Estorno parcial | ✅ | ✅ | — | — | (limited) |
| Split | (limited) | (limited) | (limited) | — | — |
| Antifraude próprio | ✅ | — | — | — | — |
| 3DS | ✅ | — | — | — | — |
| Token de Bandeira | ✅ | — | — | — | — |
| Validação de cartão (zero dollar) | (limited) | — | — | — | — |
| Flag de recorrência | (limited) | — | — | — | — |
| Notificação de disputa | ✅ | — | — | — | — |
| Notificação de chargeback | ✅ | — | — | — | — |
| Suporte a moedas internacionais | ✅ | ✅ | ✅ | ✅ | — |

Always check the live provider page for the latest matrix. Features get added over time.

## Configuration

Providers are configured per merchant. Two paths:

### Dashboard (recommended)

1. Open the merchant (Subconta) in the Dashboard.
2. In the providers area, add the gateway and paste the provider's credentials (typically an API key + secret + merchant id on the provider's side).
3. Activate the methods you want (credit, pix, boleto).
4. The provider appears in the Smart Flow editor for that merchant + method.

### REST API

```bash
PATCH /v1/providers/configurations
{
  "merchantId": "<MALGA_MERCHANT_ID>",
  "provider": "ADYEN",
  "credentials": { ... provider-specific keys ... },
  "methods": ["credit", "pix"]
}
```

(Schema is provider-specific. See `api-reference/providers/atualizar-configuracoes-de-provider-de-merchant`.)

## How to pick providers for a merchant

Common decision factors:

| Factor | Drives |
|---|---|
| **Approval rate** for the merchant's BIN profile | Primary provider choice. Some providers approve more in BR (Cielo, Rede, Getnet) for domestic cards. |
| **Cross-border** | Adyen, Stripe, PayPal for international cards. |
| **Lowest fees** for the merchant's ticket size | Provider negotiation. Malga doesn't set the rate. |
| **Split required** | Pagar.me, Braspag, Cielo support split. Stripe doesn't in the BR context. |
| **Antifraude built-in** | Adyen, Pagar.me have own antifraud. Otherwise pair with ClearSale or Konduto separately. |
| **3DS2** | Adyen, Cielo, Rede have mature 3DS2 implementations. |
| **Pix** | BB, Mercado Pago, Pagar.me, PagSeguro, SafraPay, BS2, Adyen, Banrisul, Getnet SEP. |
| **NuPay** | Dedicated NuPay provider; not all gateways carry it. |
| **Apple Pay** | Adyen, Stripe, Cielo (varies). |

The Smart Flow then chains 2-3 providers per method/branch so that a failure on provider 1 retries on provider 2.

## Provider-specific gotchas to know

These are real ones that show up in support tickets:

- **Adyen** supports refund-reversal (`revert_void`) — listen for `transaction.revert_void` in webhook handlers. See the `credit-card` skill.
- **BS2 and Getnet do not support Pix refunds**. If your Smart Flow routes a Pix charge through them, refund will fail.
- **Mercado Pago** is broadly supported but has its own settlement timing (T+14 by default).
- **Pagar.me** has two API versions (`PAGARME` and `PAGARME_V5`); they are configured separately. v5 is the recommended path for new merchants.
- **Sandbox** is treated as a regular provider in the Dashboard so QA flows look identical to production wiring.
- **Stripe** in the Smart Flow is fine but limited for BR-domestic optimizations.
- **Mapinvest, OwemPay, Worldpay, Bolt** are newer or niche; coordinate with Malga support on capabilities before relying.

## Cross-references

- `smart-flows`: how to route across providers.
- `type-tables`: the official `payment-methods-by-providers` and `additional-services` tables.
- `antifraud`: separate from payment providers but configured similarly per merchant.
- `merchants`: the entity that holds provider configuration.
- `payouts`: settlement (especially Malga subadquirente).

## Pitfalls

- **Provider feature matrices change.** Don't memorize them; always check the provider's doc page when designing a flow.
- **Don't expose provider names to end users.** They are merchant-facing implementation detail; customers don't need to see "your transaction is being processed by Adyen".
- **Provider credentials are sensitive.** Store in Malga's Dashboard, not in the merchant's environment.
- **Adding a new provider to a merchant** doesn't automatically route through it — update the Smart Flow.
- **Removing a provider** can break in-flight charges. Coordinate the removal with the operations team.
- **Sandbox-mode credentials of a real provider** (Adyen sandbox, Cielo sandbox) differ from Malga's `SANDBOX` provider, which is a Malga-managed simulator.
