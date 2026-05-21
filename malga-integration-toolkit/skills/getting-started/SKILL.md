---
name: getting-started
description: 'Initial Malga integration journey. Triggers: "começar Malga", "X-Client-Id", "X-Api-Key", "sandbox vs produção Malga", "ativar conta Malga", "qual método integrar Malga", "Malga onboarding".'
---

# Getting started with Malga

Malga is a Brazilian payment orchestrator and provider. A single integration gives merchants access to multiple payment gateways, antifraud providers, intelligent routing (Fluxos Inteligentes), tokenization, 3DS2, split, recurrence, and analytics.

Use this skill when the user is at the start of their integration journey or is unsure which integration path to take.

## Account and credentials

1. **Create an account** at <https://dashboard.malga.io>. The Dashboard is where merchants manage credentials, merchants (subaccounts), providers, smart flows, webhooks, and analytics.
2. **Obtain credentials** from the Dashboard:
   - `X-Client-Id` — the client identifier
   - `X-Api-Key` — the secret API key
   - A default `merchant` is provisioned so charges can be created immediately.
3. **Keep keys secret.** Never commit them, never put them in client-side code, and prefer environment variables. For client-side use cases, generate a **Client Token** (public key) — see the `tokenization` skill.

All API calls authenticate via HTTP headers:

```bash
curl --location --request GET 'https://api.malga.io/v1/' \
  --header 'X-Client-Id: <YOUR_CLIENT_ID>' \
  --header 'X-Api-Key: <YOUR_SECRET_KEY>'
```

Base URL: `https://api.malga.io/v1/`

## Environments

- **Sandbox** — free, no activation needed. Use it to test the full integration: charges, smart flows, 3DS2, antifraud, webhooks. Sandbox-only endpoints exist to force a charge or antifraud status (useful for QA): `POST /charges/{id}/sandbox-status` and `PATCH /charges/{id}/sandbox-antifraud-status`.
- **Production** — requires account activation. From the Dashboard, click "Falar com o time" to start activation. The Malga team configures provider keys, smart flows, and helps with go-live.

## Choosing an integration method

Recommend the path based on the merchant's context:

| Scenario | Recommend | Why |
|---|---|---|
| Full backend control, custom UX | **API Charges** (direct REST) | Maximum flexibility; works with any frontend |
| Hosted checkout, minimal backend | **API Sessions** + Malga Checkout | Sessions describe an order; Malga renders the checkout |
| Node.js backend | **SDK Node** (`@malga/node`) | Typed client wrapping the REST API |
| Drop-in frontend, fast time-to-market | **Checkout SDK** or **Checkout Full** | Pre-built UI components; PCI-safe |
| No-code, sell without a site | **Link de Pagamento** | Create a link in Dashboard or via Sessions API |
| Already on VTEX | **VTEX connector** | Native plugin; Smart Flows + antifraud + Pix/Card/Boleto |

Always confirm:
- Which payment methods? (Cartão, Pix, Boleto, Nupay, Drip, Voucher, wallets)
- Marketplace? → also load `split-payments`
- Subscriptions? → also load `recurrence`
- Need card vaulting / one-click? → also load `tokenization`
- Need fraud protection / liability shift? → load `antifraud` and/or `three-ds-two`

## Recommended starter flow (sandbox)

1. Get credentials from Dashboard.
2. Try a Pix charge via API Charges (no card data needed, fastest sandbox win).
3. Configure a webhook to receive `charge.succeeded`.
4. Try a credit-card charge using a tokenization SDK on the frontend.
5. Configure a basic Smart Flow with one provider, then add a fallback to test orchestration.
6. Activate production via Dashboard.

## Key links

- Dashboard: <https://dashboard.malga.io>
- API reference: <https://docs.malga.io/api-reference/about-apis>
- Status: <https://status.malga.io>
- Documentation index for LLMs: <https://docs.malga.io/llms.txt>

## Out of scope

Do not embed sample credentials in any code you generate. Always reference environment variables (e.g., `MALGA_CLIENT_ID`, `MALGA_API_KEY`).
