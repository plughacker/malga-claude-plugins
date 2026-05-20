---
name: antifraud
description: Use this skill when configuring or troubleshooting antifraud on Malga charges. Triggers on questions about "antifraude Malga", "Malga antifraud providers", "Clearsale Malga", "Konduto Malga", "fraud score Malga", "ClearSale risk Malga", "denied antifraud Malga", "manual review Malga", "challenge antifraud Malga", "Smart Flow antifraud branch", "device fingerprint Malga". Covers supported antifraud providers, how antifraud fits inside the Smart Flow, score-based decisions, sandbox forcing of antifraud status, and the interaction between antifraud and 3DS2.
---

# Malga antifraud

Malga supports multiple antifraud providers configured per Smart Flow branch. The antifraud step runs **before pre-authorization** and the decision (`approved`, `denied`, `review`, `not_analyzed`) drives whether the charge proceeds to a payment provider.

Reference: <https://docs.malga.io/documentations/anti-fraud>

## Supported providers (Dashboard configurable)

Malga integrates with the main BR antifraud vendors — ClearSale, Konduto, Cybersource, Riskified, Signifyd, and others. Exact list and configuration steps live in the Dashboard under "Provedores de antifraude". The merchant pastes the antifraud-provider's credentials there.

## Smart Flow integration

Each Smart Flow branch supports **one** antifraud provider. The flow:

1. Charge arrives → Smart Flow selects branch (by conditional rules).
2. If the branch has an antifraud provider, Malga calls it with charge + customer + metadata.
3. Antifraud responds with a decision and (usually) a score.
4. On `approved` → charge proceeds to the first payment provider in the branch.
   On `denied` → charge terminates as `failed` with reason `antifraud_denied`.
   On `review` → charge is held pending manual review.

To skip antifraud, design a branch with no antifraud provider — useful for low-risk segments (e.g., known customers, recurring renewals).

## Routing strategies

| Pattern | Smart Flow rule |
|---|---|
| Antifraud only above threshold | `transaction.amount >= 30000` → branch with antifraud; else branch without |
| Test two antifraud providers | `math/random < 0.5` → ClearSale branch; else Konduto branch |
| Bypass for trusted users | `metadata.customerTier = "vip"` → branch without antifraud |
| Stricter for cross-border | `metadata.country != "BR"` → stricter antifraud branch |

## Sandbox helpers

Force an antifraud outcome on sandbox:

```bash
PATCH /v1/charges/{chargeId}/sandbox-antifraud-status
{ "status": "denied" }
```

Useful for testing the merchant's downstream behavior (notifications, retry policies, CX dashboards) without real antifraud calls.

## Antifraud + 3DS2

These are independent layers:

- Antifraud — merchant's own scoring layer; can route or block.
- 3DS2 — issuer-side authentication; grants liability shift on success.

Both can run in the same branch. Typical order: antifraud first (fast, no UX), then 3DS2 only if the charge is high-risk after antifraud says `approved`. Configure both in the same Smart Flow branch.

## Manual review queue

Charges in `review` state sit pending in the Malga Dashboard until a CX agent (or an automated webhook consumer) decides. To advance them programmatically, listen for the `charge.review` event and use the agent's decision endpoint (per provider — typically Dashboard-only).

## Pitfalls

- **Antifraud retries do not cross providers**. Once pre-authorized on a provider, the antifraud decision is locked. Don't expect "try ClearSale, then Konduto" inside one branch.
- **Metadata is what antifraud sees**. Send rich customer/device data via `paymentFlow.metadata` (channel, deviceId, IP geolocation hints) — antifraud quality depends on signal richness.
- **`not_analyzed`** usually means the provider was unreachable or configuration is missing. Check Dashboard logs.
