# P0 PostgreSQL baseline

PostgreSQL 17.6; Java alone owns business persistence. Python has no database connection.

- `flyway_schema_history`: Flyway-managed immutable migration history.
- `platform_baseline`: singleton P0 infrastructure marker (`id` integer PK constrained to 1, `version` varchar(16), `created_at` timestamptz UTC).
- Migration authority: `backend/comic-boot/src/main/resources/db/migration/V1__platform_baseline.sql`.
- JPA `ddl-auto=validate`; never update schema automatically or edit an applied migration.
- Project/episode/media/model/task tables are intentionally deferred to P1/P2.
- Media files stay under storage, not in database blobs. Docker named volume persists across application restarts; stop scripts never remove it.
