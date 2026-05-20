# Pacote de testes — `malga-integration-toolkit`

Suite de prompts em PT-BR para validar que cada skill dispara no momento certo e que o conteúdo entregue está correto.

## Como usar

1. Garanta que o plugin está instalado/symlinkado (`ls ~/.claude/plugins/malga-integration-toolkit`).
2. **Abra uma nova conversa para cada teste.** Skills são carregadas no início da conversa; testar em sequência na mesma conversa contamina o resultado.
3. Cole o prompt exatamente como está.
4. Confira dois sinais:
   - **Trigger correto:** o Claude deve invocar a(s) skill(s) listada(s) em *Skill esperada* (você vê no painel de execução).
   - **Conteúdo correto:** a resposta deve mencionar os pontos listados em *O que verificar*.

Use a coluna *Status* para anotar `✓` ou `✗` enquanto roda.

---

## Nível 1 — Smoke tests (uma por skill)

Cada prompt aqui deve disparar **uma única skill** específica. Se duas skills disputarem a mesma pergunta, é sinal de que a `description` precisa ser mais específica.

### 1.1 `getting-started`

> Sou dev e nunca usei a Malga. Por onde começo a integração?

- **Skill esperada:** `getting-started`
- **O que verificar:** Dashboard, `X-Client-Id` + `X-Api-Key`, sandbox vs produção, tabela comparando os métodos de integração (API Charges, Sessions, SDK Node, Checkout, Link, VTEX).
- **Status:** ☐

### 1.2 `api-charges`

> Me mostra um exemplo de `POST /charges` para uma cobrança em cartão de crédito com tokenId, em curl.

- **Skill esperada:** `api-charges`
- **O que verificar:** base URL `https://api.malga.io/v1/`, header `X-Idempotency-Key`, `amount` em centavos, `paymentMethod.type = credit`, `card.tokenId`, menção a captura e estorno.
- **Status:** ☐

### 1.3 `sdk-node`

> Como instalo e configuro o SDK Node oficial da Malga? Quero ver um exemplo criando um charge.

- **Skill esperada:** `sdk-node`
- **O que verificar:** `npm install @malga/node`, `new Malga({ clientId, apiKey })`, `idempotencyKey`, tratamento com `MalgaError`/`MalgaValidationError`, link para o repo `plughacker/malga-node`.
- **Status:** ☐

### 1.4 `checkout-sdk`

> Quero embarcar o checkout da Malga no meu site sem precisar montar a UI dos campos de cartão. Qual a melhor opção?

- **Skill esperada:** `checkout-sdk`
- **O que verificar:** diferença entre Checkout SDK (drop-in) e Checkout Full (headless), uso de Session, Client Token na frente, lista de eventos (`success`, `failure`, `tokenize`).
- **Status:** ☐

### 1.5 `payment-link`

> Meu time de vendas quer cobrar um cliente por WhatsApp sem precisar de site. Como gero um link de pagamento da Malga?

- **Skill esperada:** `payment-link`
- **O que verificar:** opção Dashboard (no-code) vs Sessions API (programática), API de Settings para customizar logo/cor, webhooks para receber confirmação.
- **Status:** ☐

### 1.6 `vtex-integration`

> Tenho uma loja VTEX e quero adicionar a Malga como gateway. Como configuro?

- **Skill esperada:** `vtex-integration`
- **O que verificar:** instalação no VTEX Admin → Payments → Affiliations, configuração de payment conditions por método, Smart Flow aplicado automaticamente, troubleshooting de afiliação.
- **Status:** ☐

### 1.7 `smart-flows`

> Quero rotear cobranças acima de R$ 500 com 3DS2 obrigatório e abaixo disso sem antifraude. Como monto isso no Fluxo Inteligente?

- **Skill esperada:** `smart-flows` (com possível co-trigger de `three-ds-two`)
- **O que verificar:** operadores `gt/lt`, propriedade `transaction.amount` em centavos, conceito de branch/ramificação, no máximo 1 antifraude por branch.
- **Status:** ☐

### 1.8 `tokenization`

> Como tokenizo cartões no frontend sem entrar em escopo PCI?

- **Skill esperada:** `tokenization`
- **O que verificar:** Tokenization SDK v2, Hosted Fields em iframes, PCI DSS Level I, geração de Client Token via `POST /v1/auth` com `scope: ["tokens"]`, fluxo `tokenizer.tokenize()` → `tokenId`.
- **Status:** ☐

### 1.9 `three-ds-two`

> Quero ativar 3DS2 só para tickets altos. Como funciona o liability shift?

- **Skill esperada:** `three-ds-two`
- **O que verificar:** diferença frictionless vs challenge, liability shift no sucesso, integração via Checkout SDK (modal automático) ou `nextAction` em REST puro, MIT pulando 3DS em recorrência.
- **Status:** ☐

### 1.10 `antifraud`

> Como configuro um antifraude (ClearSale ou Konduto) na Malga, e como testo a recusa em sandbox?

- **Skill esperada:** `antifraud`
- **O que verificar:** configuração por branch no Smart Flow, decisões `approved`/`denied`/`review`/`not_analyzed`, endpoint sandbox `PATCH /charges/{id}/sandbox-antifraud-status`, importância de mandar `metadata` rico.
- **Status:** ☐

### 1.11 `split-payments`

> Tenho um marketplace e preciso dividir o pagamento entre 3 lojistas em uma única transação. Como faço com a Malga?

- **Skill esperada:** `split-payments`
- **O que verificar:** entidades Seller / Vendor / Payout, criação de seller com bankAccount e KYC, array `splits` no charge, soma dos splits igual ao total, refund pro-rata.
- **Status:** ☐

### 1.12 `recurrence`

> Quero criar uma assinatura mensal de R$ 49,90 com trial de 7 dias e retentativa em D+3, D+7 e D+14 em caso de falha.

- **Skill esperada:** `recurrence`
- **O que verificar:** `POST /v1/subscriptions`, `interval: { unit: month, count: 1 }`, `trialPeriodDays`, dunning, pause/cancel/reactivate, MIT pulando 3DS, necessidade de card vaultado (`card.id`).
- **Status:** ☐

### 1.13 `webhooks`

> Como verifico a assinatura HMAC de um webhook da Malga em Node.js? E como evito processar o mesmo evento duas vezes?

- **Skill esperada:** `webhooks`
- **O que verificar:** header `X-Malga-Signature: t=...,v1=...`, HMAC-SHA256 sobre `<t>.<rawBody>`, `crypto.timingSafeEqual`, idempotência via `X-Malga-Event-Id`, retry com backoff até ~24h, helper `verifyWebhookSignature` do SDK.
- **Status:** ☐

### 1.14 `analytics-reporting`

> Preciso exportar todas as cobranças capturadas do mês passado em CSV para fechar o financeiro.

- **Skill esperada:** `analytics-reporting`
- **O que verificar:** Reports API (`POST /v1/reports/exports`), filtros por `createdAtFrom`/`To` e `status`, lista custom de `columns`, download assíncrono via polling, diferença entre Analytics API (agregado) e Reports (linha-a-linha), cuidado com timezone (UTC vs São Paulo).
- **Status:** ☐

---

## Nível 2 — Jornadas multi-skill (cenários realistas)

Cada cenário deve acionar **duas ou mais skills**. O Claude pode invocá-las em sequência ou em paralelo.

### 2.1 Onboarding completo de um novo cliente

> Sou dev, acabei de criar conta na Malga. Quero processar Pix e cartão com 3DS2 acima de R$ 300, antifraude ClearSale sempre, e receber webhook quando a cobrança for capturada. Me guia.

- **Skills esperadas:** `getting-started`, `api-charges`, `smart-flows`, `three-ds-two`, `antifraud`, `webhooks`
- **O que verificar:** o Claude deve sugerir um plano de implementação cobrindo: credenciais, criação de charges Pix e cartão, montagem do Smart Flow com branches por amount + antifraude, configuração de webhook com verificação HMAC.
- **Status:** ☐

### 2.2 Marketplace com assinaturas

> Estou montando um marketplace SaaS B2B. Cada cliente meu paga uma assinatura mensal, e dessa assinatura 80% vai para mim e 20% para um parceiro afiliado. Como modelo isso na Malga?

- **Skills esperadas:** `recurrence`, `split-payments`, `tokenization`
- **O que verificar:** criação de seller para o afiliado + KYC, `subscriptions` com card vaultado, splits 80/20 aplicados a cada cycle, refund pro-rata se cancelar mid-cycle.
- **Status:** ☐

### 2.3 Checkout customizado mobile-first

> App nativo iOS/Android, quero coletar cartão num formulário próprio, tokenizar, e processar com fallback de provedor em caso de falha. Como?

- **Skills esperadas:** `tokenization`, `checkout-sdk` (Full), `smart-flows`, `api-charges`
- **O que verificar:** Hosted Fields via Checkout Full ou Tokenization SDK web view, geração de Client Token no backend, Smart Flow com 3 provedores em fallback, comportamento em erro retryable vs não-retryable.
- **Status:** ☐

### 2.4 CX investigando uma transação que falhou

> Cliente diz que a compra dele falhou mas ele foi cobrado. Como investigo isso na Malga e descubro se foi antifraude, 3DS, ou problema no provedor?

- **Skills esperadas:** `api-charges`, `antifraud`, `three-ds-two`, `analytics-reporting`
- **O que verificar:** `GET /charges/{id}` para status atual e histórico, campos `threeDSecure` e razões de declínio (declined-code), tabela de causas retryable vs não-retryable, Dashboard como ferramenta de inspeção.
- **Status:** ☐

### 2.5 Migração de gateway

> Hoje uso outro gateway. Quero migrar 10% do tráfego pra Malga primeiro, validar, e ir aumentando. E preciso preservar a base de cartões.

- **Skills esperadas:** `smart-flows`, `tokenization`, `getting-started`
- **O que verificar:** load balancing via `math/random`, migração de base de cartões coordenada com a Malga, plano gradual (ramp 10% → 50% → 100%), KPIs a observar (taxa de aprovação, chargeback).
- **Status:** ☐

### 2.6 Sales/Solutions desenhando proposta

> Estou apresentando a Malga para um cliente do varejo digital com 50k transações/mês, 60% cartão e 40% Pix, ticket médio R$ 200, operação BR. Que arquitetura recomendo?

- **Skills esperadas:** `getting-started`, `smart-flows`, `vtex-integration` (se mencionar VTEX), `analytics-reporting`
- **O que verificar:** sugestão de método de integração baseado no stack (loja própria → API/SDK; VTEX → conector), Smart Flow com 2-3 provedores por método, antifraude e 3DS2 condicional, Analytics para acompanhar.
- **Status:** ☐

---

## Nível 3 — Negativos (validar precisão dos triggers)

Esses prompts são para confirmar que skills **não disparam** quando não devem. Resposta esperada: Claude responde sem carregar nenhuma skill do plugin Malga, ou explicitamente diz que está fora do escopo.

### 3.1 Outro orquestrador

> Como faço uma cobrança Pix usando o gateway X (não Malga)?

- **Skill esperada:** nenhuma do plugin.
- **O que verificar:** se alguma skill da Malga disparar aqui, a `description` está vazando para concorrentes. Ajustar para mencionar Malga explicitamente nos triggers.
- **Status:** ☐

### 3.2 Conceito de pagamentos genérico

> O que é 3DS2 e por que ele é importante?

- **Skill esperada:** ambígua — pode ou não disparar `three-ds-two`. Aceitável disparar, mas o conteúdo deve mencionar Malga em algum ponto. Se disparar uma skill não relacionada, é falso positivo.
- **O que verificar:** se disparar `three-ds-two`, conteúdo Malga-aware (Smart Flow, Checkout SDK, etc.).
- **Status:** ☐

### 3.3 Pergunta fora de domínio

> Qual é a capital da França?

- **Skill esperada:** nenhuma.
- **O que verificar:** se qualquer skill da Malga disparar, há `description` mal calibrada.
- **Status:** ☐

### 3.4 Outro produto Brazilian fintech

> Como funciona o Stone Connect?

- **Skill esperada:** nenhuma.
- **O que verificar:** confirmação de que triggers Malga não capturam por engano produtos de competidores.
- **Status:** ☐

---

## Nível 4 — Qualidade de conteúdo (verificar exatidão)

Esses pedem que o Claude entregue um artefato específico. Avalie se o output passa em uma revisão técnica.

### 4.1 Webhook handler em Node

> Escreve um endpoint Express que recebe webhook da Malga, valida HMAC, deduplica por event id e enfileira pra processamento async. Pode usar Redis ou Bull.

- **Skill esperada:** `webhooks`, possivelmente `sdk-node`
- **O que verificar:** assinatura HMAC verificada com `timingSafeEqual` (não `===`), `rawBody` preservado (não JSON-parseado), idempotência via tabela/Redis com `X-Malga-Event-Id`, resposta `204` em até 3s, enqueue para job async.
- **Status:** ☐

### 4.2 Smart Flow para varejo

> Desenha em texto/pseudo-código um Smart Flow para um varejo brasileiro vendendo eletrônicos: dois provedores de cartão (Adyen primário, Stone fallback), antifraude ClearSale acima de R$ 500, 3DS2 acima de R$ 1.000.

- **Skill esperada:** `smart-flows`, `three-ds-two`, `antifraud`
- **O que verificar:** branching coerente, no máximo 1 antifraude e 3 provedores por branch, conditionals usando `transaction.amount` em centavos, ordem dos providers (Adyen → Stone) respeitada.
- **Status:** ☐

### 4.3 Diagrama da jornada

> Desenha um diagrama (Mermaid ou texto) da jornada de uma cobrança cartão com 3DS2 e antifraude na Malga, desde o checkout até o webhook de captura.

- **Skill esperada:** `api-charges`, `three-ds-two`, `antifraud`, `webhooks`
- **O que verificar:** ordem correta (frontend tokeniza → backend cria charge → Smart Flow → antifraude → pre-auth → 3DS challenge se necessário → captura → webhook). Antifraude antes da pre-auth. Webhook depois.
- **Status:** ☐

---

## Métricas para acompanhar

Anote em cada teste:

- **Trigger:** `✓` se a skill correta carregou; `✗` caso contrário.
- **Cobertura:** percentagem dos pontos de *O que verificar* presentes no output.
- **Precisão técnica:** marque se houver erro de fato (endpoint errado, header errado, valor não em centavos, etc.).
- **Linguagem:** o Claude respondeu em PT? (skills são bilíngues; espera-se PT quando o prompt é em PT).

## O que fazer com os resultados

- **Triggers errados** (`✗` no Nível 1 ou Nível 3): editar a `description` do frontmatter da skill correspondente. Adicione trigger phrases mais específicas se a skill não disparou; remova phrases ambíguas se ela disparou indevidamente.
- **Cobertura baixa** (< 70% dos pontos esperados): o corpo da `SKILL.md` está leve demais. Considere mover detalhes para `references/`.
- **Erros técnicos:** corrigir o conteúdo da skill com base na documentação oficial e validar com o time DX.
