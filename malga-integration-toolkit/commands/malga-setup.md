---
description: Scaffold a starter Malga integration in the chosen language and payment method.
argument-hint: "[language] [method] — e.g. node pix · python boleto · php credit"
---

# /malga-setup

Scaffold a starter Malga integration in the user's chosen language and payment method.

## Arguments

The user invokes `$ARGUMENTS` typically as `[language] [method]`. Parse loosely:

- **Language**: `node` (default), `python`, `php`, `ruby`, `java`, `go`, `csharp`, `react` (frontend with Tokenization + Checkout SDK).
- **Method**: `credit` (default), `pix`, `boleto`, `nupay`, `apple_pay`, `click_to_pay`. If the user says "todos" or omits, scaffold the most common one (`credit` + `pix`).

If the language or method is missing or ambiguous, ask **one** focused question. Do not assume silently.

## What to scaffold

Create a small, runnable starter project in the user's current working directory (or a subdirectory if the cwd already has code). Include:

1. **Project skeleton** appropriate to the language (e.g., `package.json` + `index.ts` for Node; `requirements.txt` + `main.py` for Python).
2. **Environment variables** template: `.env.example` with `MALGA_CLIENT_ID`, `MALGA_API_KEY`, `MALGA_MERCHANT_ID`. Add a clear comment that real values must come from <https://dashboard.malga.io>.
3. **Charge creation example** for the chosen method, using the official SDK when available:
   - Node: use the `malga` npm package (see `sdk-node` skill for the SDK schema).
   - Other languages: REST via the language's standard HTTP client (see `api-charges` skill for the REST schema).
4. **Idempotency** built-in (`X-Idempotency-Key` per call).
5. **Error handling** that inspects `MalgaErrorResponse` shape (`error.type`, `error.code`, `error.message`, `error.declinedCode`).
6. **Webhook receiver** stub (Ed25519 verification) if the method is async (`pix`, `boleto`) — see `webhooks` skill.
7. **README.md** explaining how to install, configure, run.
8. **`.gitignore`** that excludes `.env` and node_modules / venv / etc.

Use the per-method skill (`credit-card`, `pix`, `boleto`) for the correct request/response shapes.

## Style

- **Production-aware**: no hardcoded credentials, always env vars.
- **Minimal but real**: don't add scaffolding that isn't used. The user can grow from this base.
- **Comment the non-obvious**: idempotency, why amount is in cents, why Pix/Boleto need a webhook to confirm payment.
- **Match the user's existing project conventions** if they already have files in cwd (e.g., extend `package.json` rather than overwriting).

## After scaffolding

Print a brief next-steps message:
1. Where to get sandbox credentials.
2. How to run the example.
3. Pointer to the relevant skill for deeper customization (e.g., "for pre-auth + capture, see the `credit-card` skill").

## Decline gracefully

If the user asks for a combination Malga does not support (e.g., `php apple_pay` and PHP doesn't have an SDK), explain the gap and offer the REST equivalent.
