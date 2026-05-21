<div align="center">
  <picture>
    <img alt="Malga" src="https://raw.githubusercontent.com/plughacker/malga-node/main/docs/assets/malga.png" width="85">
  </picture>
  <h1>Plugins da Malga para Claude</h1>
</div>

[English](./README.en.md) · Português

Marketplace oficial de plugins da Malga para Claude Code e Claude Cowork. Mantido pelo time de Developer Experience da Malga.

## Para que serve

Para quem desenvolve integrações com a Malga, esses plugins aceleram a primeira implementação. O Claude responde com base na documentação atual da Malga, sem você precisar abrir o navegador para conferir nomes de endpoint, formatos de payload ou regras do Fluxo Inteligente.

Para times de suporte e CX, ajudam a investigar transações que falharam. O Claude entende a sequência (antifraude, provedor, 3DS2, captura, webhook) e consegue apontar onde provavelmente a cobrança travou.

Para times de Vendas e Solutions, dá pra desenhar arquitetura de integração ao vivo na frente do prospect. O Claude conhece os trade-offs entre integração via API, SDKs e conectores, e adapta a recomendação ao stack que o cliente já usa.

## Plugin

| Plugin | Versão | Descrição |
|---|---|---|
| [`malga-integration-toolkit`](./malga-integration-toolkit) | 0.8.1 | Cobertura completa do produto Malga para devs, suporte e times de sales/solutions. |

## O que tem aqui

**28 skills** · **30 references por provedor** · **3 slash commands**

### Skills (por área)

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

### References por provedor

30 resumos por provedor em `providers/references/` com a matriz funções × métodos para: Adyen, Banco do Brasil, Banrisul, Barte, Bolt, Braintree, Braspag, BS2, Cielo, Drip, Getnet, Getnet SEP, Klap, Malga, Mapinvest, Mercado Pago, NuPay, OwemPay, Pagar.me, Pagar.me v5, PagSeguro, PayPal, PicPay, Rede, SafraPay, Sandbox, Stripe, VR, Worldpay, Zoop.

### Slash commands

| Comando | Para que serve |
|---|---|
| `/malga-setup [lang] [method]` | Escafolda um starter de integração Malga (Node, Python, PHP, etc. × cartão, pix, boleto, etc.) com env vars, idempotência, tratamento de erros e receiver de webhook opcional. |
| `/malga-review [path]` | Revisão estática procurando problemas específicos do Malga: credenciais hardcoded, schema REST/SDK errado, falta de idempotência, assinatura de webhook errada (HMAC vs Ed25519), URL de refund, nomes de campo do Pix, status enum incorreto. |
| `/malga-decode [json\|arquivo\|chargeId]` | Explica em linguagem natural um payload de charge, evento de webhook ou erro do Malga: linha do tempo, o que aconteceu, próximos passos. |

## Como instalar

### Claude Code (CLI)

```bash
claude plugin marketplace add plughacker/malga-claude-plugins
claude plugin install malga-integration-toolkit@malga
claude plugin list
```

Se você quer que todo o seu time instale automaticamente, adicione o marketplace no `.claude/settings.json` do projeto:

```json
{
  "extraKnownMarketplaces": ["plughacker/malga-claude-plugins"]
}
```

### Claude Cowork (app desktop)

1. Baixe o arquivo `.plugin` do release mais recente em [Releases](../../releases).
2. Abra o Claude Cowork, vá em Plugins, e arraste o arquivo para a janela.
3. Comece uma nova conversa para que as skills sejam carregadas.

## Documentação da Malga

A fonte primária de verdade continua sendo a documentação oficial:

- Documentação geral: <https://docs.malga.io>
- Referência da API: <https://docs.malga.io/api-reference/about-apis>
- Dashboard: <https://dashboard.malga.io>
- Status: <https://status.malga.io>

Os plugins consolidam o conhecimento estável dessa documentação em skills que o Claude carrega sob demanda.

## Como contribuir

Issues e pull requests são bem-vindos. Para trabalhar localmente:

```bash
git clone https://github.com/plughacker/malga-claude-plugins.git
cd malga-claude-plugins

# Registra esta pasta como marketplace local (apontando direto pro código fonte)
claude plugin marketplace add "$(pwd)"
claude plugin install malga-integration-toolkit@malga

# Valida o manifest do plugin
claude plugin validate malga-integration-toolkit/.claude-plugin/plugin.json
```

Edições nos arquivos das skills aparecem automaticamente em uma nova conversa do Claude. Não precisa reinstalar a cada mudança, apenas abrir um chat novo.

## Estrutura do repositório

```
malga-claude-plugins/
├── .claude-plugin/
│   └── marketplace.json          # define o marketplace e lista os plugins
├── malga-integration-toolkit/    # o plugin em si
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── skills/                   # 28 skills (uma pasta por skill) + 30 references por provedor
│   ├── commands/                 # 3 slash commands (/malga-setup, /malga-review, /malga-decode)
│   └── README.md
├── README.md                     # esta versão (PT-BR, default)
├── README.en.md                  # versão em inglês
└── LICENSE
```

## Licença

[MIT](./LICENSE), © 2026 Malga.
