---
name: vtex-integration
description: Use this skill when integrating Malga as a payment provider on a VTEX store using the Malga VTEX connector (plugin). Triggers on questions about "Malga VTEX", "VTEX connector Malga", "instalar plugin VTEX Malga", "configurar VTEX com Malga", "Malga gateway VTEX", "VTEX affiliation Malga", "Malga + VTEX Pix/Cartão/Boleto", "VTEX Smart Flow Malga". Covers installation, affiliation configuration, supported features, antifraud and smart flow interaction in VTEX, and limitations versus a direct API integration.
---

# Malga VTEX connector

The VTEX connector lets a VTEX merchant accept payments through Malga without writing checkout code. Malga is registered as a payment provider in VTEX Admin, and the connector translates VTEX's payment requests into Malga API calls.

Reference: <https://docs.malga.io/sdks/plugins/vtex-connector>

## Supported features (parity with native integration)

| Feature | VTEX connector |
|---|---|
| Cartão, Pix, Boleto | Yes |
| Nupay, Drip, Voucher | Yes |
| Smart Flows | Yes |
| Antifraud | Yes |
| 3DS2 | Yes |
| Tokenization | Yes (vault) |
| Card base migration | Yes |
| Webhooks | Yes |
| Split | Yes |
| Custom transaction field | Yes |
| Sending customer without document | Limited (depends on flow) |

## Setup flow

1. **In Malga Dashboard:** create a merchant for the VTEX store, configure providers (gateways) and Smart Flows for the methods you'll accept.
2. **In VTEX Admin → Payments → Settings → Affiliations:** add a new affiliation, pick the Malga gateway, paste `X-Client-Id` and `X-Api-Key` from Malga, and set the merchant ID.
3. **Payment conditions:** create one per method (Credit, Pix, Boleto, ...), tying each to the Malga affiliation.
4. **Test in VTEX sandbox / Malga sandbox** with a low-value real order or sandbox provider.
5. **Promote to production** once tested. The connector reuses the affiliation key configured.

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
