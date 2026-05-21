---
name: analytics-reporting
description: 'Querying Malga payment data for analytics, dashboards, finance reconciliation. Triggers: "Malga Analytics API", "exportar transações Malga", "Reports CSV Malga", "taxa de aprovação Malga", "reconciliação financeira Malga".'
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

For row-level data, request an export, poll until it is ready, then download the file(s):

| Action | Endpoint |
|---|---|
| Create export | `POST /v1/reports` |
| Get export details | `GET /v1/reports/{id}` |
| Download file (paginated) | `GET /v1/reports/{id}/files/{pageNumber}` |

Exports may produce multiple CSV files (paginated). The detail response includes a `files` array with URLs (e.g., `https://api.malga.io/v1/reports/{id}/files/1`).

Reference: <https://docs.malga.io/api-reference/reports/exportar-dados-da-base>.

Tips:

- Filter `status` aligned with the Charges status enum (`authorized`, `voided`, `charged_back`, `refund_pending`, etc., see `api-charges` skill).
- Exports for a full month can take minutes. Poll the detail endpoint; do not block.
- Cap the custom `columns` list to what the BI tooling actually needs. Wider exports take longer.
- For very large windows, expect pagination: iterate over the `files[]` array to fetch all pages.

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

- **Time zones**. Pass explicit ISO timestamps with timezone offsets in queries and exports. Confirm with the merchant's finance team whether they expect UTC or America/Sao_Paulo.
- **Status windows**. `authorized` does not mean "settled". For cash-flow reporting, join with payout data via the Payouts API.
- **Approval rate denominators**. Use authorization attempts as the denominator, not "all charges". `pre_authorized` and `capture_pending` should be excluded from the denominator depending on the question being asked.
- **Rate limits**. Both APIs are throttled. For Analytics, cache and refresh on a schedule; do not call per page-view.
