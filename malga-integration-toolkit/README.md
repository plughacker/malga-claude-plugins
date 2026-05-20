# malga-integration-toolkit

> Malga full-product integration toolkit for Claude.
> Kit de integração completo da Malga para o Claude.

---

## English

Malga is a Brazilian payment orchestrator and provider — one integration, many gateways, with intelligent routing, antifraud, 3DS2, tokenization, split, recurrence, and analytics. This plugin gives Claude stable integration intelligence across the full Malga product so it can help developers, support engineers, and sales/solutions engineers ship integrations faster.

### What's inside

Fifteen skills, one per product area:

| Skill | Covers |
|---|---|
| `getting-started` | Account setup, credentials, sandbox vs production, choosing an integration method |
| `api-charges` | Direct REST: Charges and Sessions APIs, idempotency, status lifecycle |
| `payment-methods` | Each `paymentType` (credit, pix, boleto, nupay, drip, voucher, picpay, apple_pay, click_to_pay): when to use, refund semantics, fields |
| `sdk-node` | Official Node SDK: client setup, idempotency, pitfalls, where to find current method shapes |
| `checkout-sdk` | Drop-in `<malga-checkout>` web component and headless Checkout Full SDK |
| `payment-link` | Hosted no-code payment link via Dashboard or Sessions API |
| `vtex-integration` | VTEX connector: install, configure, supported features |
| `smart-flows` | Payment orchestration: operators, properties, metadata, load balancing, retries |
| `tokenization` | Hosted Fields, PCI DSS Level I, Client Tokens, Cards API, network tokens, zero-dollar |
| `three-ds-two` | 3DS2 in Smart Flows, frictionless vs challenge, liability shift |
| `antifraud` | Sync/async/hybrid lifecycles, automation options, fingerprints, Smart Flow integration |
| `split-payments` | Sellers, Vendors, marketplace splits, payouts |
| `recurrence` | Subscriptions API, items, cycles, dunning, pause/cancel/reactivate, MIT |
| `webhooks` | Ed25519 signature verification, event catalog (transaction.*, subscription.*, seller.*), retry schedule |
| `analytics-reporting` | Analytics API, Reports CSV exports, Dashboard analytics |

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

Quatorze skills, uma por área de produto:

| Skill | Cobre |
|---|---|
| `getting-started` | Criação de conta, credenciais, sandbox vs produção, escolha do método de integração |
| `api-charges` | REST direto: APIs de Charges e Sessions, idempotência, ciclo de vida do status |
| `sdk-node` | SDK `@malga/node`, client tipado, tratamento de erros, verificação de webhook |
| `checkout-sdk` | Checkout SDK (drop-in) e Checkout Full SDK (headless) |
| `payment-link` | Link de pagamento hospedado (no-code) via Dashboard ou Sessions API |
| `vtex-integration` | Conector VTEX — instalação, configuração, recursos suportados |
| `smart-flows` | Orquestração de pagamentos: operadores, propriedades, metadata, distribuição de carga, retries |
| `tokenization` | Hosted Fields, PCI DSS Level I, Client Tokens, API de Cards, network tokens |
| `three-ds-two` | 3DS2 no Smart Flow, fluxo frictionless vs challenge, liability shift |
| `antifraud` | Provedores antifraude, decisões por score, branches no Smart Flow |
| `split-payments` | Sellers, Vendors, splits para marketplace, payouts |
| `recurrence` | API de Subscriptions, cycles, dunning, pause/cancel/reactivate |
| `webhooks` | Catálogo de eventos, verificação HMAC, retry/idempotência |
| `analytics-reporting` | Analytics API, exports CSV via Reports API, analytics no Dashboard |

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
