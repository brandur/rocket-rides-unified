BEGIN;

--
-- A relation representing a single ride by a user.
--
CREATE TABLE rides (
    id         BIGSERIAL   PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

--
-- A relation that holds our transactionally-staged log records.
--
CREATE TABLE staged_log_records (
    id     BIGSERIAL PRIMARY KEY,

    action TEXT      NOT NULL,
    data   JSONB     NOT NULL,
    object TEXT      NOT NULL
);

COMMIT;
