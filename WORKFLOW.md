# WORKFLOW.md - Git Workflow

## Commit Messages

Follow **Conventional Commits** format:

```
<type>: <description>
```

| Type       | Usage                                |
| ---------- | ------------------------------------ |
| `feat`     | New feature                          |
| `fix`      | Bug fix                              |
| `refactor` | Code refactoring (no behavior change)|
| `chore`    | Maintenance, dependency updates      |
| `docs`     | Documentation changes                |
| `test`     | Adding or updating tests             |
| `style`    | Formatting, code style changes       |

Description is written in **Bahasa Indonesia** and can be multi-clause (comma-separated) when a commit covers multiple related changes.

### Examples

```
feat(qris): tambah transaksi QRIS langsung dari nominal
fix: perbaiki layout list keranjang, snapshot satuan produk, dan lookup barcode dari database
feat: tambah pencatatan pembelian supplier dan detail laporan pendapatan
feat: manajemen akun karyawan + role-based access control (admin/kasir)
```

When a change affects architecture, schema, routes, or user-facing flows, update the matching Markdown
docs in the same PR (`README.md`, `CLAUDE.md`, `UI.md`, `DATABASE.md`, `SYNC.md`, `WORKFLOW_SYSTEM.md`,
and the relevant `cloudflare/*/README.md`).

## Branch Naming

```
<type>/<description>
```

| Type       | Example                        |
| ---------- | ------------------------------ |
| `feature/` | `feature/thermal-print`        |
| `fix/`     | `fix/firestore-query`          |
| `refactor/`| `refactor/riverpod-migration`  |
| `chore/`   | `chore/flutter-upgrade`        |

Use lowercase with hyphens for description.

## Workflow

1. Create a branch from `main` using the naming convention above
2. Make changes and commit with conventional commit messages
3. Push branch and create a pull request to `main`
4. Merge via merge commit (preserve full history)

> **Note:** For small/urgent fixes, direct commits to `main` are acceptable when branch + PR overhead is not justified.

## Code Quality

- Format before committing: `dart format lib/ test/ --line-length=120`
- Lint for large changes: `flutter analyze`
- Skip lint for small changes (few files) — IDE diagnostics are sufficient
- No CI/CD pipeline or pre-commit hooks are configured — formatting relies on developer discipline
- See `CLAUDE.md` for full coding conventions and architecture rules

## Environment

- **Backend:** Supabase (auth, database, S3-compatible storage)
- **Env vars (recommended):** Runtime via **Account → Supabase Sync** (URL + anon key in `SharedPreferences`, restart to apply). One binary serves many stores.
- **Env vars (legacy build-time):** Passed via `--dart-define` / `--dart-define-from-file config.json` (see `config.example.json`). Runtime credentials take precedence.
- **Local DB:** SQLite via `sqflite` (runs on-device, no server needed)
- **Secrets:** `.env`, `config.json`, and `config.example.json` values are gitignored; never commit credentials. `SUPABASE_SERVICE_ROLE_KEY` lives only in Cloudflare Workers, never in the app.
