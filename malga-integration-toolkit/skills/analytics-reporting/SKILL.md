---
name: analytics-reporting
description: Use this skill when querying Malga payment data for analytics, dashboards, or finance reconciliation. Triggers on questions about "Malga Analytics API", "Malga analytics", "exportar transações Malga", "Malga Reports API", "CSV export Malga", "taxa de aprovação Malga", "approval rate Malga", "Malga Dashboard analytics", "métricas de pagamento Malga", "reconciliação financeira Malga", "Malga settlement report". Covers the Analytics API for aggregated metrics, the Reports API for raw CSV exports, the Dashboard analytics module, and how the three fit together.
---

# Malga analytics and reporting

Three complementary surfaces:

| Surface | Use case |
|---|---|
| **Analytics API** | Aggregated metrics (approval rate, GMV by provider/method, by date) for embedding in the merchant's own dashboards. |
| **Reports API** | Raw `.csv` exports of charges / customers / providers — for finance, accounting, BI ingestion. |
| **Dashboard analytics** | Out-of-the-box web reports for operations teams (no integration needed). |

References:
- Analytics intro: <https://docs.malga.io/analytics/intro>
- Reports API: <https://docs.malga.io/api-reference/reports>

## Analytics API

Lives under `/v1/analytics`. Supports filters by `merchantId`, `paymentMethod`, `status`, date range, and provider. Returns aggregated counts and amounts.

Typical questions to answer:

- "Approval rate by provider, last 7 days" — group by `provider`, ratio of `captured` / `total`.
- "GMV by method, this month" — sum of `amount` where `status = captured`, grouped by `paymentMethod.type`.
- "Average ticket by customer cohort" — `sum(amount) / count(distinct customerId)` filtered by `createdAt`.

Cache results aggressively; the API is rate-limited and intended for periodic refresh, not request-time.

## Reports API — CSV exports

For row-level data, request an export and download the file when ready (async):

```bash
POST /v1/reports/exports
{
  "type": "charges",
  "filters": {
    "createdAtFrom": "2026-05-01T00:00:00Z",
    "createdAtTo":   "2026-05-31T23:59:59Z",
    "status":        ["captured", "refunded"]
  },
  "columns": ["id", "amount", "createdAt", "status", "paymentMethod.type", "provider", "customer.document"]
}
```

```bash
GET /v1/reports/exports/{exportId}              # poll status
GET /v1/reports/exports/{exportId}/download     # 302 to S3 URL
```

Custom column lists let the merchant shape the export to match their BI tooling. Exports for full months can take minutes — poll, don't block.

## Dashboard analytics

The Dashboard offers:

- Real-time charge volume and approval funnel.
- Per-provider and per-method breakdowns.
- Smart Flow performance (which branch is taking traffic, retry success).
- Settlement and payout views.

CX and Finance teams typically work directly in the Dashboard. Engineering uses Analytics + Reports APIs to feed internal BI.

## Reconciliation pattern

The recommended monthly close pattern:

1. Pull `charges` export (Reports API) filtered to the prior month.
2. Pull `payouts` export for the same window.
3. Match `chargeId` → `payoutOrderId` for split charges; per-marketplace.
4. Reconcile against the merchant's own ledger.

Match by Malga's `id` field, not by `orderId` (merchant-controlled and may collide).

## Pitfalls

- **Time zones** — Reports use UTC by default, while the Dashboard uses America/Sao_Paulo. Pass explicit ISO timestamps and document which zone your finance team expects.
- **Status windows** — `captured` does not mean "settled". For cash-flow reporting, join with payout data.
- **Approval rate denominators** — use **authorization attempts** as the denominator, not "all charges" (which includes pre-auth, voided, etc.).
- **Rate limits** — both APIs are throttled. For Analytics, cache and refresh on a schedule.
