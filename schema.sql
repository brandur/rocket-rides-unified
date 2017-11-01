BEGIN;

--
-- A relation that allows consumers to track what they last consumed from the
-- stream.
--
CREATE TABLE checkpoints (
    id            BIGSERIAL PRIMARY KEY,
    name          TEXT      NOT NULL UNIQUE,
    last_redis_id TEXT      NOT NULL,
    last_ride_id  BIGINT    NOT NULL
);

--
-- A relation that tracks some state that consumers are tracking as they
-- consume the stream. In this case we're tracking the total distance of all
-- rides that have been initiated on the service. Consumers may update their
-- state at different times, but for any given checkpoint ID, they should
-- always show the same total.
--
CREATE TABLE consumer_states (
    id             BIGSERIAL        PRIMARY KEY,
    name           TEXT             NOT NULL UNIQUE,
    total_distance DOUBLE PRECISION NOT NULL
);

--
-- A relation representing a single ride by a user.
--
CREATE TABLE rides (
    id         BIGSERIAL        PRIMARY KEY,
    created_at TIMESTAMPTZ      NOT NULL DEFAULT now(),
    distance   DOUBLE PRECISION NOT NULL
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
