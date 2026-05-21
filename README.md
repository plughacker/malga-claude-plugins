English · [Português](./README.pt-BR.md)

# Malga plugins for Claude

> Official Malga plugins marketplace for Claude Code and Claude Cowork.

This repository hosts a Claude plugins marketplace maintained by the Malga Developer Experience team.

## Plugin

| Plugin | Version | Description |
|---|---|---|
| [`malga-integration-toolkit`](./malga-integration-toolkit) | 0.8.0 | Full Malga product coverage for developers, support, and sales/solutions teams. |

## What's inside

**28 skills** · **30 per-provider references** · **3 slash commands**

### Skills (by area)

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

### Provider references

30 per-provider summaries inside `providers/references/` covering the feature × method matrix for: Adyen, Banco do Brasil, Banrisul, Barte, Bolt, Braintree, Braspag, BS2, Cielo, Drip, Getnet, Getnet SEP, Klap, Malga, Mapinvest, Mercado Pago, NuPay, OwemPay, Pagar.me, Pagar.me v5, PagSeguro, PayPal, PicPay, Rede, SafraPay, Sandbox, Stripe, VR, Worldpay, Zoop.

### Slash commands

| Command | Purpose |
|---|---|
| `/malga-setup [lang] [method]` | Scaffold a starter Malga integration (Node, Python, PHP, etc. × credit, pix, boleto, etc.) with env vars, idempotency, error handling, and an optional webhook receiver stub. |
| `/malga-review [path]` | Static review for Malga-specific issues: hardcoded credentials, REST/SDK schema mismatch, missing idempotency, wrong webhook signature (HMAC vs Ed25519), refund URL drift, Pix field names, status enum mistakes. |
| `/malga-decode [json\|file\|chargeId]` | Explain a Malga charge response, webhook event, or error payload in plain language: timeline, what happened, what to do next. |

## Install

### Claude Code (CLI)

```bash
claude plugin marketplace add plughacker/malga-claude-plugins
claude plugin install malga-integration-toolkit@malga
claude plugin list
```

To configure automatic installation for an entire team, add to `.claude/settings.json` in the project:

```json
{
  "extraKnownMarketplaces": ["plughacker/malga-claude-plugins"]
}
```

### Claude Cowork (desktop app)

1. Download the `.plugin` file from the latest [Release](../../releases).
2. Open Claude Cowork → Plugins → drag-and-drop the file.
3. Start a new conversation.

## What can these plugins do for you

- **Developers** — accelerate first integration; get answers grounded in current Malga API docs without leaving your terminal/editor.
- **Support / CX** — investigate transactions, decode failure codes, understand which provider/antifraud step failed.
- **Sales / Solutions** — design integration architectures live for prospects with Malga-aware guidance.

## Documentation

- Malga product docs: <https://docs.malga.io>
- API reference: <https://docs.malga.io/api-reference/about-apis>
- Dashboard: <https://dashboard.malga.io>
- Status: <https://status.malga.io>

## Contributing

Issues and pull requests welcome. To work on a plugin locally:

```bash
git clone https://github.com/plughacker/malga-claude-plugins.git
cd malga-claude-plugins

# Register this folder as a local marketplace
claude plugin marketplace add "$(pwd)"
claude plugin install malga-integration-toolkit@malga

# Validate any plugin manifest
claude plugin validate malga-integration-toolkit/.claude-plugin/plugin.json
```

Edits to the skill files reflect in the next new Claude conversation — no reinstall needed.

## License

[MIT](./LICENSE) — © 2026 Malga

---

## Português

Marketplace oficial de plugins da Malga para Claude Code e Claude Cowork.

### Instalar (Claude Code)

```bash
claude plugin marketplace add plughacker/malga-claude-plugins
claude plugin install malga-integration-toolkit@malga
```

### Desenvolvimento local

```bash
git clone https://github.com/plughacker/malga-claude-plugins.git
cd malga-claude-plugins
claude plugin marketplace add "$(pwd)"
claude plugin install malga-integration-toolkit@malga
```

Edições nas skills aparecem na próxima conversa nova — sem reinstalar.
