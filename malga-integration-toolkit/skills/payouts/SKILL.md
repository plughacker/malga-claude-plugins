---
name: payouts
description: 'Malga payouts (balance, batches, orders) for finance reconciliation. REST-only (no SDK). Triggers: "saldo Malga", "payout Malga", "repasse Malga", "payment batch", "finalBalance", "reconciliação Malga".'
---

# Malga Payouts

Payouts are the money-movement side of Malga: how settled charges become balance, how balance becomes a batch, and how a batch lands in a seller's bank account. The Payouts REST API is **read-only** — Malga's subadquirente schedules and executes the actual transfers. There is **no SDK Node coverage** for payouts; use the REST endpoints directly.

References:
- API reference: <https://docs.malga.io/api-reference/payouts/consultar-saldo-de-payouts>
- Index: <https://docs.malga.io/api-reference/about-apis> (Payouts section)

## Model: balance → batch → order

```
charges (settled) → balance (per seller/account)
                          ↓
                       payment batch (scheduled per payment date)
                          ↓
                     payment orders (one per charge included in the batch)
```

- **Balance** is the running total of `available` (transferable today) and `receivable` (future, e.g., installments).
- A **Payment Batch** is a money-out event: Malga's subadquirente pays out the consolidated `finalBalance` on a given `payoutDate`.
- A **Payment Order** is one individual receivable inside a batch (typically one per `chargeId`).

## REST endpoints (read-only)

| Action | Endpoint | Notes |
|---|---|---|
| Get balance | `GET /v1/payouts/balance` | Optional `sellerId` query to filter. Returns `{ available, receivable }` (cents). |
| List batches | `GET /v1/payouts/payment-batches` | Paginated. Filters: `sellerId`, `status`, `startDate`, `endDate`, `paymentDate`, `page`, `limit`, `order`. |
| Get batch | `GET /v1/payouts/payment-batches/{id}` | Optional `sellerId` query. |
| Orders in a batch | `GET /v1/payouts/payment-batches/{id}/orders` | Paginated. |
| List orders | `GET /v1/payouts/orders` | Filters: `sellerId`, `chargeId`, date range, page/limit/order. |
| Get order | `GET /v1/payouts/orders/{id}` | — |

All endpoints require `X-Client-Id` + `X-Api-Key` headers.

## Balance shape

```json
GET /v1/payouts/balance
→
{
  "available": 1500000,
  "receivable": 320000
}
```

Both values are integers in **cents**. `sellerId` query filters to a single seller.

## Payment batch shape

```json
{
  "id":                     "<UUID>",
  "createdAt":              "2026-04-25T18:00:00.000Z",
  "updatedAt":              "2026-04-25T18:00:00.000Z",
  "amount":                 250000,
  "feeAmount":              5000,
  "totalFeeAmount":         7500,
  "balanceAmount":          0,
  "creditAmount":           0,
  "refundAmount":           0,
  "debitAdjustmentAmount":  0,
  "creditAdjustmentAmount": 0,
  "finalBalance":           242500,
  "withdrawalFeeAmount":    0,
  "reportUrl":              null,
  "paymentDate":            "2026-04-28",
  "payoutDate":             "2026-04-28",
  "status":                 "paid",
  "feature":                "subacquirer",
  "paymentMethod":          "credit",
  "paymentArrangement":     "VCC",
  "error":                  null
}
```

Field semantics:

| Field | Meaning |
|---|---|
| `amount` | Gross sum of orders in the batch (cents). |
| `feeAmount` | Provider fees applied (cents). |
| `totalFeeAmount` | All fees (provider + Malga + any adjustments) (cents). |
| `balanceAmount` | Negative-balance compensation from previous batches (cents). |
| `creditAmount` | Manual credits applied to this batch (cents). |
| `refundAmount` | Refunds netted against this batch (cents). |
| `debitAdjustmentAmount` / `creditAdjustmentAmount` | Manual adjustments (cents). |
| `finalBalance` | Net amount paid out to the seller (cents). |
| `withdrawalFeeAmount` | Transfer/withdrawal fee (cents). |
| `reportUrl` | Detailed report URL when available (else `null`). |
| `paymentDate` | Scheduled settlement date (`YYYY-MM-DD`). |
| `payoutDate` | Effective payout date; `null` while pending. |
| `status` | `pending` (scheduled), `paid` (settled), `failed`, `offset` (compensated against another batch). |
| `feature` | Origin: `subacquirer`, `nupay`, `general`. |
| `paymentMethod` | Method of the underlying orders: `credit`, `pix`, `nupay`. |
| `paymentArrangement` | E.g., `VCC` (Visa Credit) — settlement arrangement. |
| `error` | Populated when `status = failed`. |

## Payment order shape

```json
{
  "id":                 "<UUID>",
  "chargeId":           "<CHARGE_UUID>",
  "amount":             9700,
  "grossAmount":        10000,
  "totalFeeAmount":     300,
  "currency":           "BRL",
  "installment":        1,
  "totalInstallments":  1,
  "paymentMethod":      "credit",
  "type":               "capture",
  "paymentArrangement": "VCC",
  "paymentScheduledAt": "2026-04-28",
  "paymentBatchId":     "<BATCH_UUID>",
  "createdAt":          "2026-04-20T15:30:00.000Z",
  "updatedAt":          "2026-04-20T15:30:00.000Z"
}
```

- `chargeId` is the **link back to the original charge** — use this for reconciliation.
- `amount` is the net amount this order contributes to the batch (after fees); `grossAmount` is the original charge value.
- `installment` / `totalInstallments` track the parcela for installment plans.
- `type` indicates the operation that originated the order (typically `capture`).

## Reconciliation pattern

To reconcile the merchant's internal ledger with Malga settlements:

1. Pull all charges captured in the period (`GET /v1/charges?status=authorized&...`).
2. Pull all payment orders for the same period (`GET /v1/payouts/orders?startDate=...&endDate=...`).
3. Match by `chargeId` — one charge can produce multiple orders (e.g., one per installment).
4. Pull batches (`GET /v1/payouts/payment-batches?startDate=...&endDate=...`).
5. Sum `finalBalance` across batches → net cash received.
6. Diff against the merchant's bank-statement deposits.

Tips:
- **Match by `chargeId`, not `orderId`** (the merchant's own order id can collide).
- For installments, expect `totalInstallments` rows per charge across multiple batches.
- A charge with status `voided` will produce a corresponding negative entry (`refundAmount` on a future batch).
- A batch with `status: offset` was netted against another batch; don't double-count.

## Pitfalls

- **No SDK Node coverage.** `malga.payouts.*` does not exist. Use REST.
- **`finalBalance` ≠ sum of order `amount`s** — also subtract `balanceAmount`, `refundAmount`, `withdrawalFeeAmount` and add `creditAmount` / `creditAdjustmentAmount`. The batch object has the math already done.
- **Timezone gotcha.** `createdAt` / `updatedAt` are RFC 3339 with timezone; `paymentDate` / `payoutDate` are pure date strings (`YYYY-MM-DD`) in BR business calendar. Don't mix them in the same comparison.
- **Batches with `status: pending`** are scheduled but not yet settled. Don't count `finalBalance` until status is `paid`.
- **`status: offset`** means the batch's net was applied to compensate a negative balance on another batch — the merchant didn't physically receive this money in this batch.
- **The `chargeId`** on an order references the **original** charge; a refunded charge keeps the same `chargeId` but produces an offsetting order.

## Cross-references

- `analytics-reporting` for CSV exports including payout data via Reports API.
- `split-payments` for the seller-level setup that drives per-seller payouts.
- `api-charges` for the charge side that feeds payouts.
