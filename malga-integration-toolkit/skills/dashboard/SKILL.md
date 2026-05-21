---
name: dashboard
description: 'Non-developer users (CX, finance, ops) navigating the Malga Dashboard. Triggers: "Dashboard Malga", "Painel de Dados", "Insights Malga", "exportar Dashboard", "detalhe de cobrança Dashboard", "subcontas", "investigar transação Malga".'
---

# Malga Dashboard (for non-developer users)

The Malga Dashboard (<https://dashboard.malga.io>) is the operational surface for CX, finance, and operations teams who do not integrate via API. This skill orients those users to where things live and what each area does.

References: <https://docs.malga.io/documentations/dashboard/insights/intro> and the other dashboard pages.

## Main areas

| Area | URL pattern | Used by |
|---|---|---|
| Painel de Dados (Insights) | `/app/insights` | Operations, product, finance |
| Performance | `/app/performance` | Engineering, growth |
| Charge details | `/app/charges/...` | CX, finance |
| Subcontas (Merchants) | `/app/merchants` | Operations |
| Export data | (within charge listing) | Finance |
| Users | `/app/users` | Admin |

## Painel de Dados — Insights and Performance

Two tabs:

**Visão geral** consolidates **authorized and refused** charges by period:
- Status breakdown.
- Per-provider and per-card-brand split.
- Approval rate (overall and daily).
- Top reasons for refusal (linked to decline codes from `type-tables`).

**Performance** focuses on the **credit flow**, filtered by subconta (merchant):
- Approval rate **per attempt** (first try, fallback try, third try).
- Per-provider performance at each attempt.
- Charges **recovered** by fallback retries.
- Smart Flow history (which branch ran for each cohort).

The Performance tab is the right place to look when asking "is our Smart Flow actually helping?" — you can see the lift from each retry.

## Charges (transaction inspection)

The Charges listing is the entry point for CX investigations. Filter by:
- Date range.
- Merchant (subconta).
- Payment method.
- Status.
- Provider.
- Customer document or order id.
- Has split? Session id?

Clicking a charge opens the detail page, which has:
- The full lifecycle (every `transactionRequest`, including pre-auth, capture, void, antifraud).
- The webhook events emitted.
- The provider's response codes.
- Links to related entities (customer, card, session, subscription).

This is the right place to take a CX ticket like "the customer says the charge failed but they were billed" — you can see exactly what each provider attempt produced.

## Subcontas (Merchants)

Lists every merchant (subaccount). Use this area to:
- Rename a merchant (the name flows through to Smart Flows, Payment Links, exports).
- Inspect the active providers and methods.
- See the merchant detail (MCC, activation dates, contracted services).

See the `merchants` skill for the conceptual model.

## Export data

For CSV exports of charges (and other entities), use the export feature inside the listing area. The exports are configurable per column. Backend: this maps to the Reports API (see `analytics-reporting`).

## Users and permissions

`/app/users` is where the account admin manages who has access to the Dashboard. Roles control what each user can do (view-only, manage providers, manage subcontas, etc.).

## Common CX workflows

**"Cliente diz que foi cobrado mas não recebeu o produto."**
1. Find the charge by customer document, email, or order id.
2. Open detail; confirm `status: authorized`.
3. Check the merchant's settlement status (see `payouts` skill if it's about settled money).
4. If the charge is genuinely captured, the issue is on the merchant fulfillment side, not Malga.

**"Cliente diz que a transação dele falhou."**
1. Find the charge.
2. Confirm `status: failed`.
3. Open the `transactionRequests` — read the last one's `declinedCode`.
4. Look up the code in the `type-tables` skill for the ABECS guidance to relay to the customer.

**"Quanto vendemos ontem?"**
- Insights tab → filter by date → look at Visão geral.

**"Qual provedor está aprovando mais?"**
- Performance tab → filter by subconta and method → look at per-provider success rate.

**"Quero baixar um CSV de todas as vendas do mês."**
- Charges listing → filter by month → click Export → choose columns → download.

## Cross-references

- `merchants`: for the Subcontas area conceptual model.
- `analytics-reporting`: for the API-side equivalents of the Dashboard insights.
- `type-tables`: for decoding decline codes in the charge detail.
- `webhooks`: for what events fired during the charge lifecycle.
