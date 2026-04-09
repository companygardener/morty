CREATE SCHEMA morty;

SET search_path=morty;

CREATE TABLE ledgers (
    ledger_id        SMALLSERIAL  PRIMARY KEY
  , ledger           TEXT         NOT NULL UNIQUE
  , last_closed_on   DATE
);

CREATE TABLE account_types (
    account_type_id  CHAR(1)      PRIMARY KEY     CHECK (account_type_id IN ('A', 'L', 'E', 'R', 'X'))
  , account_type     TEXT         NOT NULL UNIQUE
  , normal_balance   CHAR(2)      NOT NULL        CHECK (normal_balance IN ('DR', 'CR'))
);

CREATE TABLE accounts (
    account_id       SMALLSERIAL  PRIMARY KEY

  , account_type_id  CHAR(1)      NOT NULL REFERENCES account_types

  , active           BOOLEAN      NOT NULL DEFAULT TRUE
  , contra           BOOLEAN      NOT NULL DEFAULT FALSE
  , account          TEXT         NOT NULL UNIQUE
  , account_code     VARCHAR(20)           UNIQUE
);

CREATE TABLE activity_types (
    activity_type_id SMALLSERIAL  PRIMARY KEY
  , activity_type    TEXT         NOT NULL UNIQUE
);

CREATE TABLE activities (
    activity_id      BIGSERIAL    PRIMARY KEY
  , idempotent_uuid  UUID                  UNIQUE

  , activity_type_id SMALLINT     NOT NULL REFERENCES activity_types

  , source_id        INTEGER      NOT NULL

  , accounting_date  DATE         NOT NULL CHECK (accounting_date <= CURRENT_DATE)
  , effective_date   DATE         NOT NULL

  -- Use DECIMAL(20,8) to represent cryptocurrencies
  , activity_amount  DECIMAL(8,2) CHECK (activity_amount > 0)

  , cancels_id       BIGINT       REFERENCES activities

  , created_at       TIMESTAMPTZ  NOT NULL DEFAULT now()
  , updated_at       TIMESTAMPTZ

  -- is this right? do we want to support payments recorded today, but effective on some future date?
  , CHECK (effective_date <= accounting_date)

  -- Can't cancel yourself
  , CHECK (cancels_id <> activity_id)
);

CREATE        INDEX ON activities (source_id, effective_date);
CREATE        INDEX ON activities (activity_type_id);
CREATE        INDEX ON activities USING brin (accounting_date);
CREATE UNIQUE INDEX ON activities (cancels_id) WHERE cancels_id IS NOT NULL;

CREATE TABLE entry_types (
    entry_type_id     SMALLSERIAL  PRIMARY KEY

  , ledger_id         SMALLINT     NOT NULL DEFAULT 1 REFERENCES ledgers
  , dr_id             SMALLINT     NOT NULL           REFERENCES accounts
  , cr_id             SMALLINT     NOT NULL           REFERENCES accounts

  -- Avoid non-sensical txns
  , CHECK (dr_id <> cr_id)

  , UNIQUE (ledger_id, dr_id, cr_id)
);

CREATE TABLE entries (
    entry_id          BIGSERIAL    PRIMARY KEY

  , activity_id       BIGINT       NOT NULL REFERENCES activities
  , entry_type_id     SMALLINT     NOT NULL REFERENCES entry_types

  , amount            DECIMAL(8,2) NOT NULL CHECK (amount > 0)

  , created_at        TIMESTAMPTZ  NOT NULL DEFAULT now()

  , UNIQUE (activity_id, entry_type_id)
);

CREATE INDEX ON entries (entry_type_id);
CREATE INDEX ON entries USING BRIN (created_at);

CREATE VIEW drs AS
SELECT
    activity_id
  , entry_id
  , ledger
  , account
  , amount

FROM entries

JOIN entry_types USING (entry_type_id)
JOIN ledgers     USING (ledger_id)
JOIN accounts    ON dr_id = account_id
;

CREATE VIEW crs AS
SELECT
    activity_id
  , entry_id
  , ledger
  , account
  , -amount

FROM entries

JOIN entry_types USING (entry_type_id)
JOIN ledgers     USING (ledger_id)
JOIN accounts    ON cr_id = account_id
;

CREATE VIEW details AS
  SELECT * FROM drs JOIN activities USING (activity_id)
  UNION ALL
  SELECT * FROM crs JOIN activities USING (activity_id)
;

CREATE VIEW ledger_balances AS
SELECT
    ledger
  , account_type
  , account
  , SUM(amount) AS balance

FROM details

JOIN accounts      USING (account)
JOIN account_types USING (account_type_id)

GROUP BY ledger, account, account_type
;

CREATE VIEW balances AS
SELECT
    source_id
  , ledger
  , account
  , account_type
  , SUM(amount) AS balance
FROM details
JOIN accounts      USING (account)
JOIN account_types USING (account_type_id)
GROUP BY source_id, ledger, account, account_type;

CREATE VIEW trial_balance AS
SELECT
    ledger
  , SUM(amount) AS balance

FROM details

GROUP BY ledger
;

CREATE VIEW errors AS
SELECT * FROM (
  SELECT
      activity_id
    , ledger
    , activity_type
    , activity_amount
    , SUM(amount) AS entry_sum

  FROM activities

  JOIN activity_types USING (activity_type_id)
  JOIN entries        USING (activity_id)
  JOIN entry_types    USING (entry_type_id)
  JOIN ledgers        USING (ledger_id)

  WHERE activity_amount IS NOT NULL
  GROUP BY activity_id, ledger, activity_type, activity_amount
) sums

WHERE activity_amount <> entry_sum
;

CREATE SCHEMA morty_archive;

SET search_path=morty_archive;

CREATE TABLE activities (LIKE morty.activities INCLUDING ALL);
CREATE TABLE entries    (LIKE morty.entries    INCLUDING ALL);

DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT conname, conrelid::regclass AS table_name
    FROM pg_constraint
    WHERE contype = 'f'
      AND connamespace = 'morty_archive'::regnamespace
  LOOP
    EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %I', r.table_name, r.conname);
  END LOOP;
END $$;

CREATE VIEW drs AS
SELECT
    activity_id
  , entry_id
  , ledger
  , account
  , amount

FROM entries

JOIN morty.entry_types USING (entry_type_id)
JOIN morty.ledgers     USING (ledger_id)
JOIN morty.accounts    ON dr_id = account_id
;

CREATE VIEW crs AS
SELECT
    activity_id
  , entry_id
  , ledger
  , account
  , -amount

FROM entries

JOIN morty.entry_types USING (entry_type_id)
JOIN morty.ledgers     USING (ledger_id)
JOIN morty.accounts    ON cr_id = account_id
;

CREATE VIEW details AS
  SELECT * FROM drs JOIN activities USING (activity_id)
  UNION ALL
  SELECT * FROM crs JOIN activities USING (activity_id)
;

CREATE VIEW ledger_balances AS
SELECT
    ledger
  , account_type
  , account
  , SUM(amount) AS balance

FROM details

JOIN morty.accounts      USING (account)
JOIN morty.account_types USING (account_type_id)

GROUP BY ledger, account, account_type
;

CREATE VIEW balances AS
SELECT
    source_id
  , ledger
  , account
  , account_type
  , SUM(amount) AS balance
FROM details

JOIN morty.accounts      USING (account)
JOIN morty.account_types USING (account_type_id)

GROUP BY source_id, ledger, account, account_type;

CREATE VIEW morty.all_details AS
  SELECT * FROM morty.details
  UNION ALL
  SELECT * FROM morty_archive.details
;

CREATE VIEW morty.all_balances AS
SELECT
    source_id
  , ledger
  , account
  , account_type
  , SUM(amount) AS balance
FROM morty.all_details
JOIN morty.accounts      USING (account)
JOIN morty.account_types USING (account_type_id)
GROUP BY source_id, ledger, account, account_type;

CREATE VIEW morty.all_ledger_balances AS
SELECT
    ledger
  , account_type
  , account
  , SUM(amount) AS balance

FROM morty.all_details

JOIN morty.accounts      USING (account)
JOIN morty.account_types USING (account_type_id)

GROUP BY ledger, account_type, account;



-- Shared trigger functions
CREATE OR REPLACE FUNCTION morty.prevent_delete() RETURNS TRIGGER AS $$
BEGIN
  IF current_setting('morty.allow_mutations', true) = 'true' THEN
    RETURN OLD;
  END IF;
  RAISE EXCEPTION 'deletes not allowed on %', TG_TABLE_NAME;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION morty.prevent_update() RETURNS TRIGGER AS $$
BEGIN
  IF current_setting('morty.allow_mutations', true) = 'true' THEN
    RETURN NEW;
  END IF;
  RAISE EXCEPTION 'updates not allowed on %', TG_TABLE_NAME;
END;
$$ LANGUAGE plpgsql;



DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'morty.account_types',
    'morty.activities',
    'morty.entry_types',
    'morty.entries',

    'morty_archive.activities',
    'morty_archive.entries'
  ]
  LOOP
    EXECUTE format('CREATE TRIGGER no_delete BEFORE DELETE ON %s
      FOR EACH ROW EXECUTE FUNCTION morty.prevent_delete()', t);
    EXECUTE format('CREATE TRIGGER no_update BEFORE UPDATE ON %s
      FOR EACH ROW EXECUTE FUNCTION morty.prevent_update()', t);
  END LOOP;
END $$;



CREATE OR REPLACE FUNCTION morty.archive_source(p_source_id INTEGER)
RETURNS TABLE(archived_activities BIGINT, archived_entries BIGINT) AS $$
DECLARE
  activity_count BIGINT;
  entry_count    BIGINT;
BEGIN
  IF EXISTS (
    SELECT 1 FROM morty.activities a
    JOIN morty.entries e USING (activity_id)
    JOIN morty.entry_types et USING (entry_type_id)
    JOIN morty.ledgers l USING (ledger_id)
    WHERE a.source_id = p_source_id
      AND (l.last_closed_on IS NULL OR a.accounting_date > l.last_closed_on)
  ) THEN
    RAISE EXCEPTION 'source % has entries in an open period', p_source_id;
  END IF;

  PERFORM set_config('morty.allow_mutations', 'true', true);

  WITH moved AS (
    DELETE FROM morty.entries
    WHERE activity_id IN (
      SELECT activity_id FROM morty.activities WHERE source_id = p_source_id
    )
    RETURNING *
  )
  INSERT INTO morty_archive.entries SELECT * FROM moved;

  GET DIAGNOSTICS entry_count = ROW_COUNT;

  WITH moved AS (
    DELETE FROM morty.activities
    WHERE source_id = p_source_id
    RETURNING *
  )
  INSERT INTO morty_archive.activities SELECT * FROM moved;

  GET DIAGNOSTICS activity_count = ROW_COUNT;

  PERFORM set_config('morty.allow_mutations', '', true);

  RETURN QUERY SELECT activity_count, entry_count;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION morty.archive_through(p_through DATE)
RETURNS TABLE(archived_activities BIGINT, archived_entries BIGINT) AS $$
DECLARE
  activity_count BIGINT;
  entry_count    BIGINT;
BEGIN
  IF p_through >= CURRENT_DATE THEN
    RAISE EXCEPTION 'cannot archive current or future';
  END IF;

  IF EXISTS (
    SELECT 1 FROM morty.ledgers
    WHERE last_closed_on IS NULL OR last_closed_on < p_through
  ) THEN
    RAISE EXCEPTION 'all ledgers must be closed through % before archiving', p_through;
  END IF;

  PERFORM set_config('morty.allow_mutations', 'true', true);

  WITH moved AS (
    DELETE FROM morty.entries
    WHERE activity_id IN (
      SELECT activity_id FROM morty.activities WHERE accounting_date <= p_through
    )
    RETURNING *
  )
  INSERT INTO morty_archive.entries SELECT * FROM moved;

  GET DIAGNOSTICS entry_count = ROW_COUNT;

  WITH moved AS (
    DELETE FROM morty.activities
    WHERE accounting_date <= p_through
    RETURNING *
  )
  INSERT INTO morty_archive.activities SELECT * FROM moved;

  GET DIAGNOSTICS activity_count = ROW_COUNT;

  PERFORM set_config('morty.allow_mutations', '', true);

  RETURN QUERY SELECT activity_count, entry_count;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION morty.close_period(p_ledger_id SMALLINT, p_through DATE)
RETURNS VOID AS $$
DECLARE
  balance DECIMAL;
BEGIN
  IF p_through >= CURRENT_DATE THEN
    RAISE EXCEPTION 'cannot close current or future periods';
  END IF;

  SELECT SUM(amount) INTO balance
  FROM morty.details d
  WHERE d.ledger = (SELECT ledger FROM morty.ledgers WHERE ledger_id = p_ledger_id)
    AND d.accounting_date <= p_through;

  IF COALESCE(balance, 0) <> 0 THEN
    RAISE EXCEPTION 'ledger % does not balance through % (off by %)', p_ledger_id, p_through, balance;
  END IF;

  PERFORM set_config('morty.allow_mutations', 'true', true);

  UPDATE morty.ledgers
  SET last_closed_on = p_through
  WHERE ledger_id = p_ledger_id
    AND (last_closed_on IS NULL OR last_closed_on < p_through);

  PERFORM set_config('morty.allow_mutations', '', true);
END;
$$ LANGUAGE plpgsql;


/*
SELECT * FROM morty.archive_source(1234);
SELECT * FROM morty.archive_through('2025-12-31');
*/
