# klikqris-notify

> Last synced with app v1.3.8. Used by both cart checkout and **Direct QRIS** — both flows store
> `paymentExternalId = order_id` so the worker can match either transaction type.

Cloudflare Worker that receives **KlikQRIS QRIS payment notifications** (webhook)
and updates the matching Supabase `transactions` row so the POS app picks up the
payment without manual polling/checking.

## Architecture

```
KlikQRIS -> POST Payment Notification -> Worker (klikqris-notify)
    -> optional signature presence check
    -> idempotency check via KV (order_id, 24h)
    -> PATCH Supabase transactions WHERE paymentExternalId = order_id
    -> 200 { status: true, message: "success" }
```

The Flutter app keeps its existing polling as fallback. The worker just makes
`paymentStatus` flip to `paid` on Supabase immediately; the device sees the change
on its next sync.

## Prerequisites

- Node 18+ (local dev)
- `wrangler` CLI (installed via `npm install`)
- Cloudflare account
- Supabase URL + service role key

## Local setup

```bash
npm install
cp .dev.vars.example .dev.vars   # fill in values
npm run dev
```

## Deploy

```bash
# 1. set secrets (required — never commit these)
npx wrangler secret put SUPABASE_URL
npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY

# 2. KV namespace for idempotency
npx wrangler kv namespace create KLIKQRIS_NOTIFY_KV
#   -> copy the id into wrangler.toml [[kv_namespaces]] block

# 3. deploy
npm run deploy
```

Get the worker URL: `https://klikqris-notify.<your-subdomain>.workers.dev`

## Register in KlikQRIS dashboard

In **Sandbox Settings** (and later Production), set **Callback URL (Webhook)** to
your worker URL, e.g. `https://klikqris-notify.<your-subdomain>.workers.dev/`.

## Signature validation

KlikQRIS webhook includes a `signature` that equals the one returned by
`POST /qris/create`. Validating it requires the worker to compare against a stored
signature (the app does not persist it yet). Until then:

- `KLIKQRIS_VERIFY_SIGNATURE=false` (default) — only checks presence.
- Set to `true` once signatures are stored in the `transactions` table.

## Status mapping

| Webhook `status` | `paymentStatus` |
| ---------------- | --------------- |
| `PAID`           | `paid`          |
| `EXPIRED`        | `failed`        |

> The Flutter app marks its local transaction `expired` when polling times out. The worker maps the
> webhook `EXPIRED` event to `failed`; both are terminal statuses and are not counted as revenue.

## Notes

- Idempotency: webhooks are deduped by `order_id` (24h TTL in KV) only **after** a
  successful Supabase update, so retries still apply.
- The Supabase PATCH uses the `service_role` key — treat it as highly sensitive.
- Direct QRIS transactions use the same `order_id` matching key; no extra worker configuration is needed.