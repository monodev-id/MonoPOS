# ⚠️ DEPRECATED — doku-notify (use `../klikqris-notify`)

> Doku SNAP retired in v1.2.6. Active webhook: `cloudflare/klikqris-notify/`.
> This worker is kept as archive only.

# doku-notify (ARCHIVE)

Cloudflare Worker that receives **Doku SNAP QRIS payment notifications** (webhook)
and updates the matching Supabase `transactions` row so the POS app picks up the
payment without polling.

## Architecture

```
Doku SNAP -> POST Payment Notification -> Worker (doku-notify)
    -> verify X-SIGNATURE (HMAC-SHA512)
    -> idempotency check via KV (X-EXTERNAL-ID)
    -> PATCH Supabase transactions WHERE paymentExternalId = originalPartnerReferenceNo
    -> 200 { responseCode: "2002700", responseMessage: "success" }
```

The Flutter app keeps its existing Supabase sync + polling as fallback. The worker
just makes `paymentStatus` flip to `paid` on Supabase immediately; the device sees
the change on its next sync.

## Prerequisites

- Node 18+ (local dev)
- `wrangler` CLI (installed via `npm install`)
- Cloudflare account (free tier is enough for this worker)
- Doku SNAP credentials: `clientId`, `clientSecret`, RSA private key (PKCS#8)

## Local setup

```bash
npm install
cp .dev.vars.example .dev.vars   # fill in values
npm run dev
```

## Deploy

```bash
# 1. set secrets (required — never commit these)
npx wrangler secret put DOKU_CLIENT_ID
npx wrangler secret put DOKU_CLIENT_SECRET
npx wrangler secret put DOKU_PRIVATE_KEY
npx wrangler secret put SUPABASE_URL
npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY

# 2. (optional) KV namespace for idempotency + token cache
npx wrangler kv namespace create DOKU_NOTIFY_KV
#   -> copy the id into wrangler.toml [[kv_namespaces]] block

# 3. deploy
npm run deploy
```

Get the worker URL: `https://doku-notify.<your-subdomain>.workers.dev`

## Register in Doku dashboard

In the Doku Dashboard, set the merchant **Payment Notification URL** to your worker
URL. If your URL has no path, `DOKU_NOTIFY_PATH` defaults to `/`.

> Note: Doku signs the notification using the **relative path of the Notification URL**
> as the `EndpointUrl` component of `stringToSign`. Keep this consistent with
> `DOKU_NOTIFY_PATH` (e.g. register `https://doku-notify.x.workers.dev/` and leave
> `DOKU_NOTIFY_PATH=/`). If you register a path like `/doku/notify`, set
> `DOKU_NOTIFY_PATH=/doku/notify` as a var or in `wrangler.toml`.

## Verification logic

Per Doku docs (Symmetric Signature + Get Token):

```
stringToSign = POST:<NotificationUrlPath>:<AccessToken>:<lowercase hex sha256(minify(body))>:<X-TIMESTAMP>
X-SIGNATURE  = base64(HMAC_SHA512(clientSecret, stringToSign))
```

The worker fetches a B2B access token (RSA-SHA256 signed), caches it in KV (TTL ~840s),
and verifies the incoming signature. On mismatch it refreshes the token once and retries,
in case the token rotated between Doku signing and worker verification.

## Status mapping

| `latestTransactionStatus` | `paymentStatus` |
| ------------------------- | --------------- |
| `00` | `paid` |
| `03` | `pending` |
| `04` | `refunded` |
| `05` | `canceled` |
| `06` | `failed` |

## Notes

- Idempotency: notifications are deduped by `X-EXTERNAL-ID` (24h TTL in KV) only
  **after** a successful Supabase update, so Doku retries still apply.
- Signature verification can be disabled for sandbox testing with
  `DOKU_VERIFY_SIGNATURE=false` (not recommended in production).
- The Supabase PATCH uses the `service_role` key — treat it as highly sensitive.