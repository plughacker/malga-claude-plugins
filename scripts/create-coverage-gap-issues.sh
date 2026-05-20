#!/usr/bin/env bash
# Create GitHub Issues for coverage gaps in malga-integration-toolkit.
#
# Run from anywhere after `gh auth login` and `cd` into a checkout of this repo.
# Review each block; comment out (`#`) any issue you do not want filed.
#
# Required labels are created on first run.
#
# Usage:
#   ./scripts/create-coverage-gap-issues.sh
#
# Or run sections selectively by copy-pasting the relevant `gh issue create` block.

set -euo pipefail

REPO="plughacker/malga-claude-plugins"

# ---------------------------------------------------------------------------
# Ensure labels exist (safe to re-run; ignores 'already exists' errors).
# ---------------------------------------------------------------------------
gh label create "coverage-gap" --color "0e8a16" --description "Area of Malga not yet covered by a dedicated skill" --repo "$REPO" 2>/dev/null || true
gh label create "skill"        --color "1d76db" --description "Work that adds or substantially revises a skill"   --repo "$REPO" 2>/dev/null || true
gh label create "priority:high"   --color "b60205" --description "Foundational gap"        --repo "$REPO" 2>/dev/null || true
gh label create "priority:medium" --color "fbca04" --description "Refactor / extraction"   --repo "$REPO" 2>/dev/null || true
gh label create "priority:low"    --color "c5def5" --description "Nice-to-have reference"  --repo "$REPO" 2>/dev/null || true

# ---------------------------------------------------------------------------
# HIGH priority — foundational entity coverage that is currently missing
# ---------------------------------------------------------------------------

gh issue create --repo "$REPO" \
  --title "Add skill: customers-and-cards (entity model)" \
  --label "coverage-gap,skill,priority:high" \
  --body "$(cat <<'EOF'
The plugin's `tokenization` skill covers card vaulting but does not document the full Customers + Cards entity model. Many integrations need to manage customers and their cards independently of a tokenization flow.

## Scope of the new skill

- Customers API: create, list, get, update, delete (`POST /v1/customers`, etc.).
- Cards API: create from token, list, get details (`POST /v1/cards`, etc.).
- Customer-Card linkage: `POST /v1/customers/{id}/cards`, `GET /v1/customers/{id}/cards`.
- Customer.document shape (`type`, `number`, `country`).
- Customer.address shape.
- Customer auto-creation when included in a charge payload.
- Relationship to Subscriptions (cardId required).

## Sources to consult

- `malga-docs/api-reference/customers/*.mdx`
- `malga-docs/api-reference/cards/*.mdx`
- `malga-docs/sdks/api-sdks/docs/customers/*.mdx`
- `malga-docs/sdks/api-sdks/docs/cards/*.mdx`
- OpenAPI schemas: `Customer*`, `Card*`

## Acceptance criteria

- New skill `customers-and-cards` in `skills/`.
- Includes both REST and SDK examples.
- Cross-references the `tokenization`, `recurrence`, and `api-charges` skills.
- Description triggers on PT and EN queries about "criar customer Malga", "salvar cartão Malga", "customer card on file", etc.
EOF
)"

gh issue create --repo "$REPO" \
  --title "Add skill: merchants (subaccounts)" \
  --label "coverage-gap,skill,priority:high" \
  --body "$(cat <<'EOF'
The merchant entity is foundational on Malga (every charge needs `merchantId`) but the plugin does not have a dedicated skill explaining merchants as subaccounts, when to create more than one, and how to configure them.

## Scope

- What a `merchant` is in Malga (subaccount / store).
- When to use a single merchant vs. multiple (per-brand, per-region, per-business-line).
- Endpoints: list, create, get, delete, patch (`/v1/merchants`, `/v1/merchants/{id}`).
- Schema (from OpenAPI `Merchant`): `id`, `createdAt`, `clientId`, `mcc`, `status` (`active | deleted | pending`), `providers`.
- Configuration: providers, smart flows, settings per merchant.
- Dashboard-side ("Subcontas"): listing, edit, custom names — see `documentations/dashboard/merchants.mdx`.
- Relationship to facilitators (vendors) and marketplaces (sellers).
- SDK Node note: there is no `malga.merchants` namespace; manage merchants via REST or the Dashboard.

## Sources

- `malga-docs/api-reference/merchants/*.mdx` (5 endpoints)
- `malga-docs/documentations/dashboard/merchants.mdx`
- OpenAPI schemas: `Merchant`, `MerchantList`

## Acceptance criteria

- New skill `merchants` in `skills/`.
- Decision tree for single vs. multi-merchant setups.
- Explicit note that SDK Node does not cover merchants (REST only).
- Cross-references `getting-started`, `vtex-integration`, `split-payments`.
EOF
)"

gh issue create --repo "$REPO" \
  --title "Add skill: payouts (balance, batches, orders)" \
  --label "coverage-gap,skill,priority:high" \
  --body "$(cat <<'EOF'
Payouts are currently mentioned only briefly inside the `split-payments` skill. The Payouts API surface deserves its own skill because the lifecycle (balance → batch → order) is non-trivial and reconciliation depends on it.

## Scope (6 REST endpoints, all GET)

- `GET /v1/payouts/balance` — returns `{ available, receivable }` in cents; accepts `sellerId` query param.
- `GET /v1/payouts/payment-batches` — paginated list of batches with filters (`status`, `sellerId`, `startDate`, `endDate`, `paymentDate`, `page`, `limit`, `order`).
- `GET /v1/payouts/payment-batches/{id}` — single batch.
- `GET /v1/payouts/payment-batches/{id}/orders` — orders inside a batch.
- `GET /v1/payouts/orders` — all payment orders.
- `GET /v1/payouts/orders/{id}` — single payment order.

Payment batch fields (from the live docs): `id`, `createdAt`, `updatedAt`, `amount`, `feeAmount`, `totalFeeAmount`, `balanceAmount`, `creditAmount`, `refundAmount`, `debitAdjustmentAmount`, `creditAdjustmentAmount`, `finalBalance`, `withdrawalFeeAmount`, `reportUrl`, `paymentDate`, `payoutDate`, `status`, `feature` (e.g., `subacquirer`), `paymentMethod`, `paymentArrangement` (e.g., `VCC`), `error`.

Also cover:
- Reconciliation pattern (matching `chargeId` to a payment order).
- Webhook events for payouts (if any).
- The SDK Node has no `malga.payouts` namespace — REST only.

## Sources

- `https://docs.malga.io/api-reference/payouts/consultar-saldo-de-payouts`
- `https://docs.malga.io/api-reference/payouts/listar-payment-batches`
- `https://docs.malga.io/api-reference/payouts/consultar-payment-batch-pelo-id`
- `https://docs.malga.io/api-reference/payouts/listar-ordens-de-um-payment-batch`
- `https://docs.malga.io/api-reference/payouts/listar-ordens`
- `https://docs.malga.io/api-reference/payouts/consultar-ordem-pelo-id`
- Local source: `api-reference/payouts/` is not yet present in the malga-docs source repo on this branch; pull the latest, or use the live docs pages above as canonical until the .mdx files are in place.

## Acceptance criteria

- New skill `payouts` in `skills/`.
- Trim the payout section in `split-payments` to point at this new skill.
- Cross-reference with `analytics-reporting` for the reconciliation pattern.
- Explicit note that SDK Node does not cover payouts (REST only).
EOF
)"

# ---------------------------------------------------------------------------
# MEDIUM priority — refactors / extractions from existing skills
# ---------------------------------------------------------------------------

gh issue create --repo "$REPO" \
  --title "Extract Sessions deep-dive from api-charges into its own skill" \
  --label "coverage-gap,skill,priority:medium" \
  --body "$(cat <<'EOF'
The `api-charges` skill covers Sessions as a secondary topic (a few paragraphs). Sessions deserve a dedicated skill because they have their own lifecycle, scoped publicKey model, and tight integration with the Checkout SDK.

## Scope

- Session entity: items, payment methods, dueDate, scoped `publicKey`.
- Endpoints: create, find, list, pay (`POST /sessions/{id}/charge`), cancel, history, enable/disable.
- Session vs. Charge decision tree (when to use which).
- Integration with `<malga-checkout>` (session-scoped publicKey is what gets shipped to the browser).
- Sessions for Link de Pagamento.

## Sources

- `malga-docs/documentations/more/sessions.mdx`
- `malga-docs/api-reference/sessions/*.mdx`
- `malga-docs/sdks/api-sdks/docs/sessions/*.mdx`
- OpenAPI schemas: `Session*`

## Acceptance criteria

- New skill `sessions` in `skills/`.
- The `api-charges` skill keeps a brief pointer to `sessions`.
- The `payment-link` and `checkout-sdk` skills cross-reference `sessions`.
EOF
)"

gh issue create --repo "$REPO" \
  --title "Extract Vendors/facilitators into a dedicated skill" \
  --label "coverage-gap,skill,priority:medium" \
  --body "$(cat <<'EOF'
Vendors (the facilitator-mode entity for regulatory identification of the end commercial establishment) are mentioned briefly in `split-payments`. They deserve a standalone skill because the use case (payment facilitator) is distinct from marketplace split.

## Scope

- What a Vendor is (regulatory identification for end beneficiary).
- When to use Vendors (payment facilitators) vs. Sellers (marketplaces).
- Endpoints: list, create, update, get, delete (`/v1/vendors`).
- The `vendor` block on a charge payload.
- Relationship to provider rules and Brazilian regulatory requirements.

## Sources

- `malga-docs/api-reference/vendors/*.mdx`
- `malga-docs/documentations/vendors/` (if present)
- OpenAPI schemas: `Vendor*`

## Acceptance criteria

- New skill `vendors` (or rename `split-payments` → `split-and-marketplace` if it makes sense to keep them together).
- Decision tree for Seller vs. Vendor.
EOF
)"

gh issue create --repo "$REPO" \
  --title "Add per-method deep-dive skills (credit-card, pix, boleto)" \
  --label "coverage-gap,skill,priority:medium" \
  --body "$(cat <<'EOF'
The `payment-methods` skill is broad — one page for all paymentTypes. As integrators ask deeper questions per method (e.g., "Pix refund flow", "boleto interest calculation", "credit pre-auth window"), per-method dedicated skills will help.

## Scope (one new skill per method)

- `credit-card`: pre-auth + capture flow, installments, brand-specific behavior, revert-void, probe-void events.
- `pix`: QR code lifecycle, expiration semantics, async refund (`refund_pending` → `voided`), amount drift.
- `boleto`: due date semantics, interest/fine calculation, items, no-refund constraint.

## Sources

- `malga-docs/documentations/payment-methods/credit-card.mdx`
- `malga-docs/documentations/payment-methods/pix.mdx`
- `malga-docs/documentations/payment-methods/boleto.mdx`
- OpenAPI schemas: `PaymentMethodCardObject`, `PaymentMethodPixObject`, `PaymentMethodBoletoObject`

## Acceptance criteria

- Three new skills (`credit-card`, `pix`, `boleto`) in `skills/`.
- The existing `payment-methods` skill becomes a directory of pointers + the per-method comparison table only.
- Each new skill cross-references the others (e.g., refund semantics).
EOF
)"

# ---------------------------------------------------------------------------
# LOW priority — reference & helper skills
# ---------------------------------------------------------------------------

gh issue create --repo "$REPO" \
  --title "Add skill: type-tables (declined codes, banks, antifraud providers)" \
  --label "coverage-gap,skill,priority:low" \
  --body "$(cat <<'EOF'
The Malga docs have a "Tabela de tipos" section with reference data (declined codes, bank codes, antifraud providers, payment-methods-by-providers). This is high-value for support and reconciliation but is not surfaced as a skill.

## Scope

- Declined-code table (retryable vs. non-retryable, mapping to UX messages).
- Main banks code table.
- Payment methods × providers compatibility table.
- Antifraud providers and their supported flows.

## Sources

- `malga-docs/documentations/type-tables/*.mdx`

## Acceptance criteria

- New skill `type-tables` in `skills/`.
- Triggers on "código de recusa Malga", "decline code Malga", "qual provedor suporta X", etc.
- Used cross-skill (api-charges, antifraud, split-payments).
EOF
)"

gh issue create --repo "$REPO" \
  --title "Add skill: dashboard (for non-dev users — CX, finance, ops)" \
  --label "coverage-gap,skill,priority:low" \
  --body "$(cat <<'EOF'
The Malga Dashboard has a lot of operational functionality (Painel de Dados, Insights, Export Data) that non-developer users (CX, finance, ops) interact with. The plugin currently is developer-centric. A dashboard-focused skill would help support engineers and finance ops without forcing them to read API docs.

## Scope

- Navigating the Dashboard for common tasks (find a transaction, investigate a failed charge, export data).
- The Painel de Dados / Insights views.
- Smart Flow editor walkthrough (no code).
- Settlement and payout views.
- Webhook configuration UI.

## Sources

- `malga-docs/documentations/dashboard/*.mdx`

## Acceptance criteria

- New skill `dashboard` in `skills/`.
- Triggers on CX-style queries ("onde vejo X no painel?", "como exporto dados pelo dashboard").
- Cross-references `analytics-reporting` and `webhooks`.
EOF
)"

gh issue create --repo "$REPO" \
  --title "Add skill: sandbox-testing-guide" \
  --label "coverage-gap,skill,priority:low" \
  --body "$(cat <<'EOF'
Sandbox-specific testing knowledge is scattered across multiple existing skills (sandbox endpoint for charge status push, antifraud status, test cards). Consolidating into one skill speeds up QA.

## Scope

- sandbox-api.malga.io conventions.
- Test cards by brand.
- Manually pushing charge status (`POST /v1/charges/{id}` with `{ status }`).
- Manually pushing antifraud status (`PATCH /v1/charges/{id}/...`).
- Postman collection link.
- Recommended test scenarios per integration path.

## Sources

- `malga-docs/documentations/welcome/testing.mdx`
- `malga-docs/sdks/api-sdks/docs/sandbox/*.mdx`
- Postman collection link in `api-reference/about-apis`

## Acceptance criteria

- New skill `sandbox-testing` in `skills/`.
- Triggers on "como testo Malga sandbox", "test card Malga", "force charge status sandbox".
EOF
)"

gh issue create --repo "$REPO" \
  --title "Add skill: providers (configuring payment gateways)" \
  --label "coverage-gap,skill,priority:low" \
  --body "$(cat <<'EOF'
Providers (Stripe, Cielo, Adyen, PagSeguro, etc.) are mentioned in many skills but there is no dedicated coverage of how to configure them on a merchant in Malga.

## Scope

- List of supported providers and what each can do.
- How to configure provider credentials in the Dashboard.
- Provider-specific quirks (e.g., Braspag-only `fares`, Stripe sandbox behavior, etc.).
- `PATCH /v1/providers/configurations` semantics.
- Provider versions (e.g., Pagar.me v5 vs. legacy).

## Sources

- `malga-docs/documentations/providers/*.mdx`
- `malga-docs/api-reference/providers/*.mdx`

## Acceptance criteria

- New skill `providers` in `skills/`.
- Triggers on "configurar Stripe na Malga", "qual provedor suporta apple pay Malga".
EOF
)"

gh issue create --repo "$REPO" \
  --title "Add skill: tracking Malga release notes and API versioning" \
  --label "coverage-gap,skill,priority:low" \
  --body "$(cat <<'EOF'
Malga ships frequent release notes (`malga-docs/release-notes/`). Currently nothing in the plugin helps users discover what changed between versions or track upcoming changes. A small skill could surface this.

## Scope

- Where Malga publishes release notes.
- How to read a release-note entry (added, fixed, deprecated, breaking).
- API versioning conventions (e.g., webhook v1.0 → v1.1).
- How to know if your integration is impacted.
- Tracking SDK package versions.

## Sources

- `malga-docs/release-notes/*.mdx`
- npm package histories for `malga`, `@malga/tokenization`, `@malga-checkout/core`.

## Acceptance criteria

- New skill `release-notes-tracking` in `skills/`.
- Triggers on "saiu uma nova versão da Malga, sou afetado?", "release notes Malga".
EOF
)"

echo ""
echo "All issues created. Review them at: https://github.com/$REPO/issues"
