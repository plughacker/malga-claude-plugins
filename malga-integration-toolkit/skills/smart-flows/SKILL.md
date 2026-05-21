---
name: smart-flows
description: 'Designing Malga Fluxos Inteligentes (payment orchestration). Triggers: "Fluxos Inteligentes Malga", "Smart Flow Malga", "orquestração de pagamentos", "fallback de provedor", "metadata paymentFlow", "math/random load balancing".'
---

# Malga Smart Flows (Fluxos Inteligentes)

Smart Flows are Malga's payment orchestration engine. Each Smart Flow is bound to a `merchant` + `payment method` and decides — per charge — which providers process it and in what order. Smart Flows drive Malga's approval-rate optimization and provider failover.

Reference: <https://docs.malga.io/documentations/flow-guide/introduction>

## Core concepts

- **Branch (ramificação)** — a unique path through the flow chosen by a conditional. A branch may chain up to **three payment providers** (priority order) and **one antifraud provider**.
- **Conditional operator** — a comparator on charge properties that splits the flow. Available operators: `lt`, `gt`, `le`, `ge`, `eq`, `ne`, `and`, `or`.
- **Retry behavior** — if a charge fails on provider 1 with a *retryable* error, the flow moves to provider 2, then provider 3. Non-retryable errors (e.g., `card_declined`) terminate the charge immediately.
- **Antifraud retries happen during pre-authorization only.** Once a charge is pre-authorized on a provider, it stays on that provider until capture or final failure.

## Properties available in conditionals

| Property | Type | Notes |
|---|---|---|
| `transaction.amount` | number | Cents |
| `transaction.currency` | string | ISO 4217 |
| `transaction.cardBin` | string | First 6 digits |
| `transaction.brand` | string | Card brand only |
| `transaction.installments` | number | Credit only |
| `transaction.metadata.<key>` | varies | User-defined |
| `math/random` | number (0..1) | Load balancing |

**Reserved metadata keys (do not use):** `currency`, `cardBin`, `installments`, `amount`, `brand`, `paymentType`, `operation`.

## Sending metadata to drive the flow

Charges (and Sessions) carry an arbitrary `paymentFlow.metadata` object that the flow can read.

```json
{
  "merchantId": "...",
  "amount": 12000,
  "paymentMethod": { "type": "credit", ... },
  "paymentFlow": {
    "metadata": {
      "channel": "app",
      "daysToEvent": 45,
      "isPreOrder": true
    }
  }
}
```

A conditional like `transaction.metadata.daysToEvent > 60` then routes to a branch with no antifraud.

## Load balancing

Use `math/random` to A/B test providers or split traffic:

```
math/random < 0.6  →  branch "provider-A"  (60%)
otherwise          →  branch "provider-B"  (40%)
```

## Example design patterns

| Goal | Design |
|---|---|
| Maximize approval | Branch by `brand` or `cardBin`; route each to the historically best-performing provider; fallback to 2nd. |
| Reduce cost | Branch by `amount` thresholds; cheap providers for low-ticket, premium for high-ticket. |
| High-risk protection | Add antifraud only when `amount >= 50000` or `metadata.channel = "anonymous"`. |
| Provider migration | `math/random < 0.1` → new provider; rest → incumbent. Ramp gradually. |
| Skip antifraud for known-good | `metadata.trustedCustomer = true` → branch with no antifraud. |

## Inspecting flows programmatically

Smart Flows are **managed exclusively in the Dashboard**. The REST API is **read-only**:

- `GET /v1/flows` — list flows (paginated).
- `GET /v1/flows/{id}` — details of one flow including branches and rules.

There are no `POST`, `PATCH`, or `DELETE` endpoints for flows. To change a flow, edit it in the Dashboard; the changes apply immediately to new charges. Use the GET endpoints to verify which flow a merchant has active and to confirm changes after editing in the Dashboard.

## Common pitfalls

- **One antifraud per branch** — you cannot chain two antifraud providers.
- **Reserved-word metadata** — using `amount` as a metadata key causes errors. Prefix your keys (e.g., `mintAmount`).
- **Failed charge with no retry** — the error was non-retryable. See declined-code table: <https://docs.malga.io/documentations/type-tables/declined-code>.
- **Pre-auth + capture across providers** — captures stay on the pre-authorizing provider; cross-provider capture is not supported.

## References

- Conditionals: <https://docs.malga.io/documentations/flow-guide/conditional>
- Examples: <https://docs.malga.io/documentations/flow-guide/examples>
- Error handling: <https://docs.malga.io/documentations/flow-guide/errors>
- Dashboard editor: <https://docs.malga.io/documentations/flow-guide/flow-dash>
