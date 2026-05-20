---
name: vtex-integration
description: Use this skill when integrating Malga as a payment provider on a VTEX store using the Malga VTEX connector (plugin). Triggers on questions about "Malga VTEX", "VTEX connector Malga", "instalar plugin VTEX Malga", "configurar VTEX com Malga", "Malga gateway VTEX", "VTEX affiliation Malga", "Malga + VTEX Pix/Cartão/Boleto", "VTEX Smart Flow Malga". Covers installation, affiliation configuration, supported features, antifraud and smart flow interaction in VTEX, and limitations versus a direct API integration.
---

# Malga VTEX connector

The VTEX connector lets a VTEX merchant accept payments through Malga without writing checkout code. Malga is registered as a payment provider in VTEX Admin, and the connector translates VTEX's payment requests into Malga API calls.

Reference: <https://docs.malga.io/sdks/plugins/vtex-connector>

## Supported features

Per the official VTEX connector docs:

| Feature | VTEX connector |
|---|---|
| Cartão, Pix, Boleto | Yes |
| Tokenização de cartão | Yes |
| PCI compliance | Yes |
| Provedores de pagamento via Malga | Yes |
| Antifraude | Yes |
| Fluxo Inteligente (Smart Flow) | Yes (exceto envio de campo personalizado na cobrança) |
| Estorno e captura pelo painel VTEX | Yes |
| Acompanhamento via Dashboard Malga | Yes |
| Exportação .csv, Analytics API, Painel de Dados | Yes |
| Gestão do fluxo pelo Dashboard Malga | Yes |

## Setup flow

The connector is activated by Malga support, not self-service. Steps:

1. **Request credentials from Malga**. Email **suporte@malga.io** asking for the VTEX connector activation. The Malga team generates and sends back a pair of credentials: **Token de aplicação** and **Chave de aplicação** (these are different from the regular `X-Client-Id` and `X-Api-Key` — they are VTEX-Provider-Protocol specific).
2. **In VTEX Admin → Pagamentos → Provedores**, activate the Malga connector and paste the two credentials.
3. **Configure payment conditions** in VTEX (one per accepted method: Credit, Pix, Boleto) and tie each to the Malga affiliation.
4. **In the Malga Dashboard**, configure providers (gateways) and the Smart Flow for the merchant. Changes take effect immediately for new VTEX orders.
5. **Test end-to-end** in VTEX's sandbox with a low-value order, validating Smart Flow + antifraud + 3DS2 behave as expected.
6. **Go-live** once the smoke test passes.

The integration is built on VTEX's Payment Provider Protocol and is PCI-compliant. Reference: <https://docs.malga.io/sdks/plugins/vtex-connector>.

## How orchestration works in VTEX

VTEX delegates the full authorization decision to Malga. The connector calls `POST /charges` (or Sessions, depending on flow), Malga runs the Smart Flow (provider routing + antifraud), and returns the result to VTEX. VTEX shows the customer success / failure based on Malga's reply.

This means:
- Approval-rate optimizations (fallback, retry) happen automatically — no VTEX-side change needed.
- Antifraud decisions surface as transaction failures with a reason — VTEX merchants can correlate with Malga Dashboard.
- Changing the Smart Flow in Malga Dashboard takes effect immediately for new VTEX orders.

## When not to use the VTEX connector

Use a **direct API or Checkout SDK** integration instead when:
- The merchant runs a custom storefront on VTEX IO that wants full control over checkout UX.
- The merchant needs payment flows VTEX's affiliations don't model well (e.g., complex split, save-card flows outside checkout).
- The merchant wants to A/B-test checkout layouts.

## Troubleshooting

- **Affiliation auth fails** — double-check `X-Client-Id` and `X-Api-Key`; ensure they belong to the same Malga account as the configured `merchantId`.
- **Pix doesn't appear** — payment condition not enabled or Pix provider not configured in the Malga Smart Flow for that merchant.
- **3DS challenge missing** — make sure the antifraud provider in the Smart Flow has 3DS enabled, and that the VTEX payment condition allows challenge.

## References

Plugin docs: <https://docs.malga.io/sdks/plugins/vtex-connector>
