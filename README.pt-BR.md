[English](./README.md) · Português

# Plugins da Malga para Claude

Marketplace oficial de plugins da Malga para Claude Code e Claude Cowork. Mantido pelo time de Developer Experience da Malga.

## O que tem aqui

| Plugin | Versão | Descrição |
|---|---|---|
| [`malga-integration-toolkit`](./malga-integration-toolkit) | 0.1.0 | Kit completo de integração com a Malga. Tem 14 skills cobrindo as APIs de Charges e Sessions, os SDKs (Node, Checkout, Checkout Full), o Link de Pagamento, o conector VTEX, Tokenização (Hosted Fields, PCI), Fluxos Inteligentes (orquestração), 3DS2, Antifraude, Split, Recorrência, Webhooks e Analytics. |

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

## Para que serve

Para quem desenvolve integrações com a Malga, esses plugins aceleram a primeira implementação. O Claude responde com base na documentação atual da Malga, sem você precisar abrir o navegador para conferir nomes de endpoint, formatos de payload ou regras do Fluxo Inteligente.

Para times de suporte e CX, ajudam a investigar transações que falharam. O Claude entende a sequência (antifraude, provedor, 3DS2, captura, webhook) e consegue apontar onde provavelmente a cobrança travou.

Para times de Vendas e Solutions, dá pra desenhar arquitetura de integração ao vivo na frente do prospect. O Claude conhece os trade-offs entre integração via API, SDKs e conectores, e adapta a recomendação ao stack que o cliente já usa.

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
│   ├── skills/                   # 14 skills, uma pasta por área de produto
│   └── README.md
├── README.md                     # versão em inglês
├── README.pt-BR.md               # esta versão
└── LICENSE
```

## Licença

[MIT](./LICENSE), © 2026 Malga.
