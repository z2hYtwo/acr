CREATE TABLE platform_baseline (
    id integer PRIMARY KEY CHECK (id = 1),
    version varchar(16) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO platform_baseline (id, version) VALUES (1, 'P0');
