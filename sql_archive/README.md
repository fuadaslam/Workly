# Archived SQL

These files are **not the live schema** and must not be re-run against the database. They are kept for historical reference only.

`saas/01_core_tables.sql` through `saas/04_rls_policies.sql` are the current source of truth for schema and RLS policies. Several files archived here (`supabase_schema.sql`, the `fix_*`/`repair_*`/`resolve_*` patches, `supabase_enquiries_migration.sql`) predate multi-tenancy or were superseded by `saas/04_rls_policies.sql` and contain policies that are **not** org-scoped — re-applying them would reopen cross-tenant access.

Verified against the live project (2026-06-18): the legacy unscoped `work_orders`/`payments`/`task_history` policies in these files were never actually applied live. The one gap that *was* live — unscoped `enquiries` RLS policies from `supabase_enquiries_migration.sql` — was fixed directly on the database (migration `scope_enquiries_rls_to_org`).
