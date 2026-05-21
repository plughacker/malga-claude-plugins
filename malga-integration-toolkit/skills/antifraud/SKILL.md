---
name: antifraud
description: 'Configuring or troubleshooting antifraud on Malga charges. Triggers: "antifraude Malga", "ClearSale Malga", "Konduto Malga", "approved/reproved Malga", "runBeforeCharge", "captureOnApprove", "antifraude síncrono assíncrono".'
---

# Malga antifraud

Malga's antifraud sits inside the Smart Flow. The antifraud step runs **before pre-authorization**: the provider returns a decision (`pending`, `approved`, or `reproved`) and that decision drives whether the charge proceeds to a payment provider or terminates.

Reference: <https://docs.malga.io/documentations/anti-fraud/intro>

## Sync vs async vs hybrid lifecycles

Antifraud providers behave in one of three ways:

- **Sync** — evaluation finishes during the create-charge request. The response of `POST /charges` already includes the antifraud outcome.
- **Async** — evaluation returns a `pending` status. The final decision arrives later via a webhook event.
- **Hybrid** — the provider may behave either way per transaction. Configure these as async (`productType: "ASYNC"`).

The merchant choses the model per provider in the Dashboard.

## Configuration options (per merchant / provider)

When attaching an antifraud provider to a merchant in the Dashboard, the following knobs control automation:

| Option | Effect |
|---|---|
| `runBeforeCharge` | Run antifraud before the payment provider. Cannot be enabled for async or hybrid providers. |
| `captureOnApprove` | Auto-capture the charge when antifraud approves. |
| `refundOnReprove` | Auto-cancel or refund the charge when antifraud reproves. |
| `captureOnError` | Capture the charge when antifraud itself errors. |
| `refundOnError` | Refund the charge when antifraud itself errors. |
| `productType` | `SYNC` or `ASYNC`. For hybrid providers, use `ASYNC`. |

The "send unanalyzed transactions for calibration" option in the Dashboard lets you feed antifraud with transactions that bypassed it, improving the provider's model over time. Useful when calibrating a new provider before relying on it.

## Status outcomes

When the Smart Flow routes a charge through antifraud, a `transactionRequest` of type `anti_fraud` is created. It carries one of three statuses:

| Status | Meaning |
|---|---|
| `pending` | The transaction was sent for evaluation and the response is async. |
| `approved` | The antifraud provider approved the transaction. |
| `reproved` | The antifraud provider rejected the transaction. |

For async providers, `pending` resolves to `approved` or `reproved` once the provider posts back. Listen for the relevant webhook to learn the final outcome.

## Smart Flow integration

Each Smart Flow branch supports **one** antifraud provider. To run different antifraud strategies for different charges, use Smart Flow conditionals to route through different branches.

Patterns:

| Goal | Smart Flow rule |
|---|---|
| Antifraud only above a threshold | `transaction.amount >= 30000` → branch with antifraud; else branch without. |
| A/B test two antifraud providers | `math/random < 0.5` → ClearSale branch; else Konduto branch. |
| Bypass antifraud for trusted users | `metadata.customerTier = "vip"` → branch without antifraud. |
| Stricter for cross-border | `metadata.country != "BR"` → stricter antifraud branch. |

See the `smart-flows` skill for the operator and metadata mechanics.

## Fingerprints (device data)

Many antifraud providers require device fingerprint data to score risk accurately. Some require it mandatorily:

| Provider | Fingerprint required |
|---|---|
| ClearSale | **Yes** |
| Others | Recommended for quality |

Use the provider's SDK on the client side to capture the fingerprint and forward it in the charge payload (typically inside `fraudAnalysis` or a provider-specific block). Missing the fingerprint when required will cause the provider to deny or skip evaluation.

## Charge-level fields

The charge payload accepts a `fraudAnalysis` object for antifraud-relevant data:

```json
"fraudAnalysis": {
  "deviceId":     "<FROM_PROVIDER_SDK>",
  "ip":           "<CUSTOMER_IP>",
  "browserInfo":  { ... },
  "shippingAddress": { ... },
  ...
}
```

The exact schema depends on the chosen provider. Refer to <https://docs.malga.io/api-reference/charges/realizar-nova-cobranca> for the latest accepted fields.

## Sandbox testing

For sync providers, the `POST /charges` response already carries the outcome. For async or hybrid providers, the Dashboard allows manually pushing the antifraud outcome to trigger the downstream automation (capture or refund per the merchant's options).

Useful endpoints:

- `PATCH /v1/charges/{id}` to force the antifraud status to `approved` or `reproved` in sandbox.
- Charge sandbox status push: `POST /v1/charges/{id}` with `{ "status": "..." }` (see `api-charges` skill).

## Antifraud + 3DS2

These are independent layers and can run on the same branch:

- **Antifraud** is the merchant's risk scoring. It runs before authorization and can block.
- **3DS2** is the issuer's authentication. On success it grants liability shift.

Typical order on a high-risk branch: antifraud first (fast, no UX), then 3DS2 if the antifraud says `approved`. Configure both in the same Smart Flow branch.

## Supported providers

The list of supported antifraud providers is maintained in the Dashboard and at the type table page. Highlights: ClearSale, Konduto, B2E, and others. Source of truth: <https://docs.malga.io/documentations/type-tables/antifraude-providers>.

## Pitfalls

- **`runBeforeCharge` is sync-only**. Attempting to enable it on an async provider will be rejected.
- **`pending` is not a final state**. The merchant's downstream code (and the customer-facing UI) must handle the eventual `approved` / `reproved` notification.
- **Missing fingerprint** can quietly degrade the antifraud's confidence and increase false negatives, even when not strictly required.
- **`reproved` is not `denied`**. The word is `reproved` in Malga's API and dashboards; merchant-facing messaging should match.
- **Antifraud retries do not cross providers**. Once the antifraud chose a provider for a branch, the decision is locked. Don't expect "try ClearSale then Konduto" within a single branch.
