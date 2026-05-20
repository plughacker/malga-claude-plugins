# Malga plugins for Claude

> Official Malga plugins marketplace for Claude Code and Claude Cowork.
> Marketplace oficial de plugins da Malga para Claude Code e Claude Cowork.

This repository hosts a Claude plugins marketplace maintained by the Malga Developer Experience team.

## What's inside

| Plugin | Version | Description |
|---|---|---|
| [`malga-integration-toolkit`](./malga-integration-toolkit) | 0.1.0 | Full-product integration toolkit: 14 skills covering Charges/Sessions, SDKs (Node, Checkout, Checkout Full), Payment Link, VTEX, Tokenization (Hosted Fields, PCI), Smart Flows (orchestration), 3DS2, Antifraud, Split, Recurrence, Webhooks, and Analytics. |

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

[MIT](./LICENSE) — © 2026 Malga (Plug Pagamentos S.A.)

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
