# Maintaining `malga-integration-toolkit`

Operating manual for keeping this plugin accurate and in sync with the Malga product. Encodes the lessons from the v0.1 → v0.4 audit cycle and the procedure for running future audits efficiently.

This file lives at the marketplace root, **not** inside the plugin, so it travels with the source repo but is not shipped to end users.

When asking Claude to update or audit the plugin, point at this file: "read MAINTAINING.md and then audit the plugin against the latest Malga release".

## Sources of truth, in priority order

Always consult them in this order. Lower-priority sources are useful for context but should not override a higher-priority one when they conflict.

1. **SDK source code** at `/Users/stefanosandes/Developer/malga/malga-node/` — single source of truth for the Node SDK (method signatures, payload shapes, error types, internal behavior).
2. **OpenAPI spec** at `/Users/stefanosandes/Developer/malga/malga-docs/api-reference/api-spec.yaml` — single source of truth for the REST API (endpoints, request/response schemas, status enums, validation rules).
3. **Mintlify docs source** at `/Users/stefanosandes/Developer/malga/malga-docs/` — guides, tutorials, examples. Source-controlled, current.
4. **Rendered online docs** at <https://docs.malga.io> — same content as #3 but rendered. Useful only when the source isn't mounted.
5. **Inference** — last resort. Always open a GitHub Issue labeled `inferred` describing what was inferred and what would confirm it.

When a fact appears in multiple sources, the higher-priority source wins. Examples:

- The SDK source said `webhooks.verify()` is synchronous; the online docs showed `await malga.webhooks.verify(...)`. The source wins.
- The OpenAPI says refund is `POST /charges/{id}/void`; the friendly doc page calls it "estornar". The OpenAPI wins for the URL.

## Per-skill source map

For each skill in the plugin, read these files before touching the SKILL.md:

| Skill | Read |
|---|---|
| `getting-started` | `malga-docs/documentations/welcome/*.mdx`, `malga-docs/docs.json` (for sitemap) |
| `api-charges` | `malga-docs/api-reference/api-spec.yaml` (Charges, Sessions schemas), `malga-docs/api-reference/charges/*.mdx`, `malga-docs/api-reference/sessions/*.mdx`, `malga-docs/documentations/more/idempotency.mdx`, `malga-docs/documentations/more/sessions.mdx` |
| `payment-methods` | `malga-docs/documentations/payment-methods/*.mdx`, OpenAPI schemas `PaymentMethodCardObject`, `PaymentMethodPixObject`, `PaymentMethodBoletoObject`, `PaymentMethodNuPay`, `PaymentMethodPicpay`, `PaymentMethodVoucher`, `PaymentMethodDrip`, `PaymentMethodApplePay` |
| `sdk-node` | `malga-node/package.json`, `malga-node/src/index.ts` (exports list), `malga-node/src/malga.ts` (main class), `malga-node/src/<each-namespace>/*.ts`, `malga-node/examples/`, `malga-docs/sdks/api-sdks/docs/*.mdx`, `malga-docs/sdks/api-sdks/quickstart/nodejs/*.mdx` |
| `checkout-sdk` | `malga-docs/sdks/intro-sdk.mdx`, `malga-docs/sdks/malga-checkout/*.mdx`, `malga-docs/sdks/malga-checkout-full/` (if present) |
| `tokenization` | `malga-docs/sdks/tokenization/v2/*.mdx`, `malga-docs/documentations/tokenization/*.mdx`, `malga-docs/api-reference/tokens/*.mdx`, `malga-docs/api-reference/cards/*.mdx` |
| `payment-link` | `malga-docs/documentations/payment-link/*.mdx`, `malga-docs/documentations/more/sessions.mdx`, `malga-docs/api-reference/sessions/*.mdx`, `malga-docs/api-reference/settings/*.mdx` |
| `vtex-integration` | `malga-docs/sdks/plugins/*.mdx` |
| `smart-flows` | `malga-docs/documentations/flow-guide/*.mdx`, `malga-docs/api-reference/flows/*.mdx` |
| `three-ds-two` | `malga-docs/documentations/3ds2-malga/*.mdx`, `malga-docs/api-reference/3ds2-malga/*.mdx`, OpenAPI schema `3DSecure2*` |
| `antifraud` | `malga-docs/documentations/anti-fraud/*.mdx`, `malga-docs/documentations/providers-antifraud/*.mdx` |
| `split-payments` | `malga-docs/documentations/split/*.mdx`, `malga-docs/api-reference/sellers/*.mdx`, `malga-docs/api-reference/vendors/*.mdx`, `malga-docs/api-reference/payouts/*.mdx`, OpenAPI `ChargeSplitRules` |
| `recurrence` | `malga-docs/api-reference/subscriptions/*.mdx`, `malga-docs/documentations/more/recurrence/` (if present), OpenAPI `Subscription*` schemas |
| `webhooks` | `malga-docs/documentations/webhooks/webhook1-1.mdx`, `malga-docs/api-reference/webhooks/*.mdx`, `malga-node/src/webhooks/webhooks.ts`, signature samples at <https://github.com/plughacker/plug-sample-signature-verify> |
| `analytics-reporting` | `malga-docs/analytics/`, `malga-docs/api-reference/reports/*.mdx` |

## SDK boundary: public API only

When documenting the Node SDK, **only** include items exported from `malga-node/src/index.ts`. Never document:

- Internal classes (`Api`, builders, handlers).
- File paths inside `src/` (irrelevant to consumers).
- Test files.
- Private constructor wiring.

If the `index.ts` re-exports something, it is fair game. If it does not, leave it out, even if it is visible in the source.

Same boundary applies to other SDKs:
- Tokenization SDK: only what `@malga/tokenization` exports as its public API.
- Checkout SDK: only what the `<malga-checkout>` web component exposes as attributes, JS properties, events, and CSS variables.

## Audit workflow (the procedure)

Run this end-to-end whenever the Malga team ships a new release or you suspect the plugin is out of date.

### Step 1: Sync the sources

```bash
cd /Users/stefanosandes/Developer/malga/malga-docs && git pull
cd /Users/stefanosandes/Developer/malga/malga-node && git pull
# Note current versions:
cat /Users/stefanosandes/Developer/malga/malga-node/package.json | grep version
ls /Users/stefanosandes/Developer/malga/malga-docs/release-notes/ | sort | tail -5
```

If either repo is missing, ask the user to clone or to add the folder to Cowork.

### Step 2: Sitemap and changes

Read `malga-docs/docs.json` to see the full sitemap. Look in `malga-docs/release-notes/` for the most recent entries to spot what changed.

### Step 3: Audit each skill

For each skill in the per-skill source map above:

1. Read every listed file in full (not just the first paragraph).
2. Compare against the current `SKILL.md`. Look for:
   - Field name drift (`paymentType` vs `type`, `qrCode` vs `qrCodeData`).
   - URL drift (`/refund` vs `/void`).
   - Status enum drift (added or removed values).
   - Method signature drift (sync vs async, new parameters).
   - Package name drift (a rare but high-impact mistake).
   - New events or new payload fields.
3. For any drift, update the SKILL.md and (if applicable) the `references/` files.
4. Record the change in `CHANGELOG.md`.

### Step 4: SDK-specific cross-check

The Node SDK is a special case: its payload shape differs from the REST API. When updating `sdk-node`, also re-check the simplified SDK schema against `malga-node/src/charges/builders/` (which translates SDK input → REST). When the SDK changes, both `sdk-node` and the SDK examples in `api-charges` may need updates.

### Step 5: Mark inferences

Anything you write that is not directly verified by a source file should open a GitHub Issue labeled `inferred`. Be honest. Future audits will revisit and close the issue when confirmation arrives from the Malga team.

### Step 6: Bump version

Use semver:

- **Patch** (0.x.y → 0.x.(y+1)): small content fixes, typo corrections.
- **Minor** (0.x.0 → 0.(x+1).0): meaningful content updates from a new audit, added or significantly revised skill content.
- **Major** (0.x.0 → 1.0.0 or above): breaking change to the plugin's structure or skill names.

Update both:
- `malga-integration-toolkit/.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json` (the marketplace `metadata.version` AND the plugin entry's `version`)

### Step 7: Validate structure

```bash
cd /Users/stefanosandes/Developer/malga/malga-claude-docs-plugin
# Each SKILL.md must have name + description in frontmatter
for f in malga-integration-toolkit/skills/*/SKILL.md; do
  head -5 "$f" | grep -q "^name:" || echo "MISSING name: $f"
  head -5 "$f" | grep -q "^description:" || echo "MISSING description: $f"
done
# plugin.json must be valid JSON
python3 -c "import json; json.load(open('malga-integration-toolkit/.claude-plugin/plugin.json')); print('plugin.json OK')"
# marketplace.json must be valid JSON
python3 -c "import json; json.load(open('.claude-plugin/marketplace.json')); print('marketplace.json OK')"
# skill name kebab-case check
for d in malga-integration-toolkit/skills/*/; do
  name=$(basename "$d")
  echo "$name" | grep -E "^[a-z0-9-]+$" >/dev/null || echo "BAD NAME: $name"
done
```

### Step 8: Repackage

```bash
cd /Users/stefanosandes/Developer/malga/malga-claude-docs-plugin/malga-integration-toolkit
zip -r /tmp/malga-integration-toolkit.plugin . -x "*.DS_Store"
cp /tmp/malga-integration-toolkit.plugin ../malga-integration-toolkit.plugin
```

Confirm the zip does NOT include:
- `TEST_PROMPTS.md` (not part of the plugin).
- `CHANGELOG.md` (lives at marketplace root, not inside the plugin).
- `MAINTAINING.md` (this file, lives at marketplace root).
- Any other internal-only docs.

### Step 9: Commit and release

```bash
cd /Users/stefanosandes/Developer/malga/malga-claude-docs-plugin
git status
git add -A
git commit -m "feat(vX.Y.Z): <summary>

<changelog>

See CHANGELOG.md."
git push

gh release create vX.Y.Z malga-integration-toolkit.plugin \
  --title "vX.Y.Z — <title>" \
  --notes-file CHANGELOG.md
```

## Pitfalls and lessons (from v0.1 → v0.4)

These are the specific traps that caught me in past audits. Watch for them.

### Don't transfer conventions from other gateways

The first version of this plugin had several Stripe-like assumptions that turned out wrong for Malga:

- HMAC signatures → real is **Ed25519**.
- `X-Stripe-Signature` style → real is `X-Plug-Signature` + `X-Plug-Date`.
- Event names `charge.succeeded` → real is `transaction.authorized`.

When in doubt, **assume Malga is unique**. Read the dedicated page for the area.

### REST and SDK schemas differ

The SDK takes a friendlier payload than the REST API. Examples:

- REST: `paymentMethod.paymentType: "credit"` + separate `paymentSource: { sourceType: "card", card: { cardNumber, cardCvv, cardExpirationDate, cardHolderName } }`.
- SDK: `paymentMethod: { type: "credit", card: { holderName, number, cvv, expirationDate } }`.

Never paste a REST schema into an SDK example or vice versa. Each skill should be clear about which it documents.

### Friendly names hide URLs

Doc pages with friendly titles ("Estornar cobrança aprovada") may not surface the underlying URL. Always cross-check the URL in:
1. The OpenAPI spec.
2. The SDK source code (it shows the URL it calls).

In v0.4 we found that "refund" hits `POST /charges/{id}/void` at the REST level.

### Sync vs async at the API edge

Online docs sometimes show `await` in JavaScript examples even when the underlying method is synchronous. Read the SDK source to confirm. Example: `malga.webhooks.verify()` is sync.

### Enum values aren't always listed in prose

`MalgaErrorResponse.type` is documented as "string" in some places but is actually a closed enum of 4 values. `MalgaErrorResponse.declinedCode` is a closed enum of 24 values. Always check the TypeScript types file (`src/common/interfaces/malga.ts`).

### Mark inferences explicitly

If you write a sentence that is not directly backed by a source you read, open a GitHub Issue with the `inferred` label describing the claim and what would confirm it.

## Checklist (paste at the top of each audit PR)

```
- [ ] malga-docs pulled to latest
- [ ] malga-node pulled to latest
- [ ] Skills reviewed:
      [ ] getting-started [ ] api-charges [ ] payment-methods
      [ ] sdk-node [ ] checkout-sdk [ ] tokenization
      [ ] payment-link [ ] vtex-integration [ ] smart-flows
      [ ] three-ds-two [ ] antifraud [ ] split-payments
      [ ] recurrence [ ] webhooks [ ] analytics-reporting
- [ ] CHANGELOG.md updated with this release section (Added / Fixed / Changed; no "inferred" items)
- [ ] GitHub Issues opened (label: `inferred`) for any unconfirmed claims
- [ ] Version bumped in plugin.json
- [ ] Version bumped in marketplace.json (metadata + plugin entry)
- [ ] Validation step passes (structure, JSON, kebab-case)
- [ ] .plugin repackaged and copied to repo root
- [ ] README.md and README.pt-BR.md version references updated
- [ ] Commit message references the version
- [ ] gh release created with .plugin attached
```

## When this plugin is the wrong tool

If the user wants to **add a new feature** to the plugin (new skill, new MCP, custom argument-driven command), don't just edit files. Use the `create-cowork-plugin` or `cowork-plugin-customizer` skills as a north-star for plugin architecture. MAINTAINING.md is for **maintenance** of existing content, not for designing new components.
