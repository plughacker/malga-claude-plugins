---
name: release-notes-tracking
description: 'Tracking Malga product changes and evaluating release impact. Triggers: "release notes Malga", "novidades Malga", "novo release", "API versioning Malga", "deprecation Malga", "webhook v1.1 Malga".'
---

# Tracking Malga release notes and API versioning

Malga ships frequent changes — new providers, new methods, antifraud updates, SDK versions. The release notes are published as Mintlify pages organized by date (and aggregated yearly). This skill covers how to discover and triage them.

References:
- All releases index: <https://docs.malga.io/release-notes/releases>
- Latest: see the most recent entry on the index page.

## Where releases live

```
malga-docs/release-notes/
├── 2025-01-15-Release-Notes.mdx
├── ...
├── 2025-12-22-Release-Notes.mdx
├── 2026-01-05-Release-Notes.mdx
├── 2026-01-06-Release-Notes.mdx
├── 2026-01-15-Release-Notes.mdx
└── releases.mdx                  # index by year
```

The naming convention is `YYYY-MM-DD-Release-Notes.mdx`. The `releases.mdx` index page lists releases grouped by year.

## Format of a release note

Each entry is short and structured:

- **Title** (e.g., "Banrisul", "PayPal", "Zero Dollar Safra Pay").
- **Author** profile.
- **Description**: what changed and the business context.
- **Tip / Features block** listing the concrete additions:
  - Payment method affected (`credit`, `pix`, `boleto`).
  - Provider involved.
  - Specific feature (e.g., "Zero Dollar", "3DS2", "split").
- Often a link to the relevant provider/feature page in the docs.

## How to triage a release

When a new release lands, ask these questions in order:

1. **Is the change additive or breaking?** New providers, new methods, new features are typically additive — no action required. Breaking changes (e.g., a webhook version cutover, a removed field) require coordination.
2. **Does it affect a provider in my merchant's Smart Flow?** Check the merchant's Dashboard → providers. If the changed provider is configured, read the detail.
3. **Does it affect a method I use?** If the merchant accepts Pix and the release adds Pix support to a new provider, you can consider adding it as a fallback.
4. **Does it change SDK behavior?** Check the npm package versions: `malga` (Node SDK), `@malga/tokenization`, `@malga-checkout/core`, `@malga-checkout-full/core`.
5. **Is there a deprecation timeline?** Look for words like "deprecated", "v1.0 obsolete", "será descontinuado em". Plan migration ahead.

## API versioning conventions

Malga uses several versioning surfaces:

| Surface | How it's versioned |
|---|---|
| REST API path | `/v1/` prefix. v2 has not landed at time of writing. |
| Webhooks | `version: 1.0` (legacy) and `version: 1.1` (current with Ed25519). v1.0 is deprecated. |
| Node SDK (`malga`) | npm semver. Read the package.json + the repo CHANGELOG. |
| Tokenization SDK | npm semver. Currently `@malga/tokenization` v2. v1 marked deprecated in docs. |
| Checkout SDK | npm semver. Pin to a specific version in production. |

## What to watch for in releases

These categories tend to actually affect integrations:

| Category | Action |
|---|---|
| **New provider integration** | If relevant, add to Smart Flow as fallback. |
| **New payment method on existing provider** | Update Smart Flow if you accept that method. |
| **Antifraude provider addition** | Consider A/B testing against current. |
| **3DS2 enhancements per provider** | Re-evaluate Smart Flow for high-ticket charges. |
| **Webhook event additions** | Update receiver to handle new event types. |
| **Webhook version cutovers** | Plan migration from v1.0 to v1.1 if not done. |
| **Deprecation of a field or endpoint** | Track sunset date; refactor before. |
| **SDK major version bump** | Read the migration guide; test in sandbox before upgrading production. |
| **Dashboard UX changes** | Inform CX/ops teams; usually no code impact. |

## How to monitor releases programmatically

The Malga docs are open-source on GitHub at <https://github.com/plughacker/malga-docs>. To monitor:

- **Watch the repo** on GitHub for new files in `release-notes/`.
- **RSS / Atom** — Mintlify-rendered sites typically expose feeds; check <https://docs.malga.io/release-notes/> for a feed link.
- **Newsletter / blog** — Malga's blog at <https://malga.io/blog/> sometimes summarizes releases.
- **Manual check** — bookmark the releases index and review weekly.

## Recommended cadence

For an active integration:

- **Weekly** — scan the latest 1-2 release notes; flag anything relevant.
- **Monthly** — review the SDK package versions; upgrade if a patch or minor is available; test in sandbox.
- **Quarterly** — full audit of the integration against the latest docs (use `MAINTAINING.md` procedure).

## Pitfalls

- **Don't ignore deprecation timelines.** Webhook v1.0 is deprecated; integrations still on it will eventually break.
- **Pin SDK versions in production.** `@malga-checkout/core@latest` is convenient but introduces hidden upgrades. Pin to a specific version.
- **A new provider in the docs ≠ available to your account.** Some providers require Malga support to enable per-account.
- **Release notes don't always state "breaking".** Read the body of a release before assuming it's safe.
- **The malga-docs repo is the source of truth.** The rendered site can lag behind by minutes.

## Cross-references

- `MAINTAINING.md` at the marketplace root for the audit procedure after a relevant release.
- `providers` skill for the per-provider page that may be the target of a release.
- `webhooks` for v1.0 → v1.1 migration context.
- `sdk-node` for SDK version tracking.
