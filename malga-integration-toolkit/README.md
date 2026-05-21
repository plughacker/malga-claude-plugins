# malga-integration-toolkit

> Malga full-product integration toolkit for Claude.
> Kit de integração completo da Malga para o Claude.

---

## English

Malga is a Brazilian payment orchestrator and provider — one integration, many gateways, with intelligent routing, antifraud, 3DS2, tokenization, split, recurrence, and analytics. This plugin gives Claude stable integration intelligence across the full Malga product so it can help developers, support engineers, and sales/solutions engineers ship integrations faster.

### What's inside

**28 skills** · **30 per-provider references** · **3 slash commands**

#### Skills (grouped by area)

| Area | Skills |
|---|---|
| Onboarding | `getting-started` |
| Backend REST + SDK | `api-charges`, `sdk-node`, `sessions`, `webhooks`, `customers-and-cards`, `merchants` |
| Payment methods | `payment-methods` (overview), `credit-card`, `pix`, `boleto` |
| Frontend SDKs | `checkout-sdk`, `tokenization` |
| Hosted UX | `payment-link` |
| Connector | `vtex-integration` |
| Orchestration | `smart-flows`, `three-ds-two`, `antifraud` |
| Marketplace / facilitator | `split-payments`, `vendors`, `payouts` |
| Recurrence | `recurrence` |
| Analytics | `analytics-reporting` |
| Reference and ops | `type-tables`, `dashboard`, `sandbox-testing`, `providers`, `release-notes-tracking` |

#### Per-provider references

30 reference summaries under `skills/providers/references/` covering the function × method matrix for each integrated provider: Adyen, Banco do Brasil, Banrisul, Barte, Bolt, Braintree, Braspag, BS2, Cielo, Drip, Getnet, Getnet SEP, Klap, Malga, Mapinvest, Mercado Pago, NuPay, OwemPay, Pagar.me, Pagar.me v5, PagSeguro, PayPal, PicPay, Rede, SafraPay, Sandbox, Stripe, VR, Worldpay, Zoop.

#### Slash commands

| Command | Purpose |
|---|---|
| `/malga-setup [lang] [method]` | Scaffold a starter Malga integration in the chosen language and method. |
| `/malga-review [path]` | Static review for Malga-specific issues (credentials, schema mismatch, signature algorithm, idempotency, status enum, etc.). |
| `/malga-decode [json\|file\|chargeId]` | Explain a Malga charge response, webhook event, or error payload in plain language. |

### Architecture

The skills carry the **stable integration intelligence** — payload shapes, decision trees, common pitfalls — content that changes slowly and is expensive to look up via docs every time. When Malga publishes a hosted MCP server in the future, it can be added to this plugin as a `.mcp.json` for live API access.

### Installation

This is a Claude plugin. Install through Claude's plugin UI (Cowork or Claude Code), or load the `.plugin` file directly.

### Audience

- **Developers** integrating Malga from a backend or frontend.
- **Support / CX** investigating a transaction or a failed flow.
- **Sales / Solutions** designing or demonstrating integration shapes for prospects.

### Conventions

- Code samples use environment variables (`MALGA_CLIENT_ID`, `MALGA_API_KEY`, `MALGA_MERCHANT_ID`). Never commit credentials.
- Money is always **integer cents** in BRL unless stated otherwise.
- Sandbox base URL is the same as production (`https://api.malga.io/v1/`); credentials differentiate the environment.

### Key links

- Docs: <https://docs.malga.io>
- API reference: <https://docs.malga.io/api-reference/about-apis>
- Documentation index (LLM-friendly): <https://docs.malga.io/llms.txt>
- Dashboard: <https://dashboard.malga.io>
- Status: <https://status.malga.io>
- Node SDK: <https://github.com/plughacker/malga-node>
- Tokenization SDK: <https://github.com/plughacker/malga-tokenization>

---

## Português

A Malga é um orquestrador e provedor de pagamentos brasileiro — uma integração, vários gateways, com roteamento inteligente, antifraude, 3DS2, tokenização, split, recorrência e analytics. Este plugin fornece ao Claude inteligência estável de integração em todo o produto Malga, ajudando desenvolvedores, equipes de suporte e sales/solutions a entregar integrações mais rápido.

### O que tem dentro

**28 skills** · **30 references por provedor** · **3 slash commands**

#### Skills (agrupadas por área)

| Área | Skills |
|---|---|
| Onboarding | `getting-started` |
| Backend REST + SDK | `api-charges`, `sdk-node`, `sessions`, `webhooks`, `customers-and-cards`, `merchants` |
| Métodos de pagamento | `payment-methods` (overview), `credit-card`, `pix`, `boleto` |
| SDKs frontend | `checkout-sdk`, `tokenization` |
| UX hospedada | `payment-link` |
| Conector | `vtex-integration` |
| Orquestração | `smart-flows`, `three-ds-two`, `antifraud` |
| Marketplace / facilitador | `split-payments`, `vendors`, `payouts` |
| Recorrência | `recurrence` |
| Analytics | `analytics-reporting` |
| Referência e operações | `type-tables`, `dashboard`, `sandbox-testing`, `providers`, `release-notes-tracking` |

#### References por provedor

30 resumos por provedor em `skills/providers/references/` com a matriz funções × métodos para cada provedor integrado: Adyen, Banco do Brasil, Banrisul, Barte, Bolt, Braintree, Braspag, BS2, Cielo, Drip, Getnet, Getnet SEP, Klap, Malga, Mapinvest, Mercado Pago, NuPay, OwemPay, Pagar.me, Pagar.me v5, PagSeguro, PayPal, PicPay, Rede, SafraPay, Sandbox, Stripe, VR, Worldpay, Zoop.

#### Slash commands

| Comando | Para que serve |
|---|---|
| `/malga-setup [lang] [method]` | Escafolda um starter de integração Malga na linguagem e método escolhidos. |
| `/malga-review [path]` | Revisão estática para problemas específicos do Malga (credenciais, mismatch de schema, assinatura, idempotência, status enum, etc.). |
| `/malga-decode [json\|arquivo\|chargeId]` | Explica em linguagem natural um payload de charge, evento de webhook ou erro. |

### Arquitetura

As skills carregam a **inteligência estável de integração** — formatos de payload, árvores de decisão, armadilhas comuns — conteúdo que muda pouco e é caro de buscar via docs toda hora. Quando a Malga publicar um servidor MCP hospedado no futuro, ele pode ser adicionado a este plugin como `.mcp.json` para acesso ao vivo à API.

### Instalação

Plugin para o Claude. Instale pela UI de plugins (Cowork ou Claude Code), ou carregue o arquivo `.plugin` direto.

### Público

- **Devs** integrando a Malga no backend ou frontend.
- **Suporte / CX** investigando uma transação ou um fluxo que falhou.
- **Sales / Solutions** desenhando ou demonstrando integrações para prospects.

### Convenções

- Os exemplos de código usam variáveis de ambiente (`MALGA_CLIENT_ID`, `MALGA_API_KEY`, `MALGA_MERCHANT_ID`). Nunca versione credenciais.
- Valores monetários estão sempre em **centavos inteiros** em BRL, salvo indicação contrária.
- A base URL de sandbox é a mesma de produção (`https://api.malga.io/v1/`); as credenciais é que diferenciam o ambiente.

### Links principais

- Docs: <https://docs.malga.io>
- Referência da API: <https://docs.malga.io/api-reference/about-apis>
- Índice de documentação (LLM-friendly): <https://docs.malga.io/llms.txt>
- Dashboard: <https://dashboard.malga.io>
- Status: <https://status.malga.io>
- SDK Node: <https://github.com/plughacker/malga-node>
- SDK de Tokenização: <https://github.com/plughacker/malga-tokenization>

---

## Versão / Version

`0.4.0` — third audit pass, this time against the actual SDK source code (`malga@0.0.2`). Confirmed and corrected: `webhooks.verify()` is **synchronous** (not async), refund REST endpoint is `POST /charges/{id}/void` (not `/refund`), full `MalgaErrorResponse` type schema documented including 4 error types and 24 declined codes, `AuthScope` enum is exported, `charges.create` has a dual mode (with/without sessionId).

`0.3.0` — second audit pass, this time against the Malga Mintlify docs source and the SDK reference. Significant corrections: `sdk-node` (real package name is `malga`, simplified SDK schema, real method namespaces, real error structure, real auth/webhook helpers), `checkout-sdk` (configuration via JS properties: `paymentMethods`, `transactionConfig`, `dialogConfig`; CSS-variable theming), `tokenization` (real package `@malga/tokenization`, fixed container IDs, `on()` + `tokenize()` methods returning `{tokenId, error}`), `api-charges/references` (`qrCodeData`/`qrCodeImageUrl` field names, full Boleto schema, split-rule required flags). See `CHANGELOG.md` at the marketplace root for the full change list.

`0.3.0` — segunda passada de auditoria, agora contra o source Mintlify da documentação e a referência do SDK. Correções significativas: `sdk-node` (nome do pacote correto é `malga`, schema simplificado do SDK, namespaces reais, estrutura real de erro, helpers reais de auth/webhook), `checkout-sdk` (configuração via propriedades JS: `paymentMethods`, `transactionConfig`, `dialogConfig`; tema via CSS variables), `tokenization` (pacote real `@malga/tokenization`, IDs fixos dos containers, métodos `on()` + `tokenize()` retornando `{tokenId, error}`), `api-charges/references` (nomes `qrCodeData`/`qrCodeImageUrl`, schema completo de Boleto, flags obrigatórias de split). Veja `CHANGELOG.md` na raiz do marketplace.
