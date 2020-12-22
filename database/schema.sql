CREATE TYPE trade_operation AS ENUM ('buy', 'sell');
CREATE TYPE trade_env AS ENUM ('PAPER', 'PROD');
CREATE SEQUENCE IF NOT EXISTS transaction_id_seq START 1;

CREATE TABLE IF NOT EXISTS algo_run (
    algo_run_id serial PRIMARY KEY,
    algo_name text NOT NULL,
    algo_env text NOT NULL,
    build_number text NOT NULL,
    parameters jsonb,
    start_time timestamp DEFAULT current_timestamp,
    end_time timestamp,
    end_reason text
);

CREATE TABLE IF NOT EXISTS trades (
    trade_id serial PRIMARY KEY,
    algo_run_id integer REFERENCES algo_run(algo_run_id),
    is_win bool,
    symbol text NOT NULL,
    qty integer NOT NULL check (qty > 0),
    buy_price decimal (8, 2) NOT NULL,
    buy_indicators jsonb NOT NULL,
    buy_time timestamp DEFAULT current_timestamp,
    sell_price decimal (8, 2),
    sell_indicators jsonb,
    sell_time timestamp,
    client_sell_time text,
    client_buy_time text
);
CREATE INDEX ON trades(symbol);
CREATE INDEX ON trades(algo_run_id);
CREATE INDEX ON trades(is_win);

CREATE TABLE IF NOT EXISTS new_trades (
    trade_id serial PRIMARY KEY,
    algo_run_id integer REFERENCES algo_run(algo_run_id),
    symbol text NOT NULL,
    operation trade_operation NOT NULL,
    qty integer NOT NULL check (qty > 0),
    price decimal (8, 2) NOT NULL,
    indicators jsonb NOT NULL,
    client_time text,
    tstamp timestamp DEFAULT current_timestamp
);
CREATE INDEX ON new_trades(symbol);
CREATE INDEX ON new_trades(algo_run_id);

ALTER TABLE new_trades ADD COLUMN stop_price decimal (8, 2);
ALTER TABLE new_trades ADD COLUMN target_price decimal (8, 2);

ALTER TYPE trade_operation ADD VALUE 'sell_short';
ALTER TYPE trade_operation ADD VALUE 'buy_short';

CREATE TABLE IF NOT EXISTS ticker_data (
    symbol text PRIMARY KEY,
    name text NOT NULL,
    description text NOT NULL,
    tags text[],
    similar_tickers text[],
    industry text,
    sector text,
    exchange text,
    short_ratio float,
    create_tstamp timestamp DEFAULT current_timestamp,
    modify_tstamp timestamp
);
CREATE INDEX ON ticker_data(sector);
CREATE INDEX ON ticker_data(industry);
CREATE INDEX ON ticker_data(tags);
CREATE INDEX ON ticker_data(similar_tickers);


ALTER TABLE algo_run ADD COLUMN batch_id text NOT NULL DEFAULT '';
CREATE INDEX ON algo_run(batch_id);

ALTER TABLE algo_run ADD COLUMN ref_algo_run integer REFERENCES algo_run(algo_run_id);

ALTER TABLE new_trades ADD COLUMN expire_tstamp timestamp;

CREATE TABLE IF NOT EXISTS trending_tickers (
    trending_id serial PRIMARY KEY,
    batch_id text NOT NULL,
    symbol text NOT NULL,
    create_tstamp timestamp DEFAULT current_timestamp
);

CREATE INDEX ON trending_tickers(batch_id);

INSERT INTO trending_tickers (symbol, batch_id)
    SELECT distinct t.symbol, r.batch_id
    FROM new_trades as t, algo_run as r
    WHERE
        t.algo_run_id = r.algo_run_id AND
        batch_id != '';

BEGIN;
alter table new_trades drop constraint "new_trades_qty_check";
alter table new_trades add check (qty != 0);
COMMIT;

CREATE TABLE IF NOT EXISTS stock_ohlc (
    symbol_id serial PRIMARY KEY,
    symbol text NOT NULL,
    symbol_date date NOT NULL,
    open float NOT NULL,
    high float NOT NULL,
    low float NOT NULL,
    close float NOT NULL,
    volume int NOT NULL,
    indicators JSONB,
    modify_tstamp timestamp,
    create_tstamp timestamp DEFAULT current_timestamp,
    UNIQUE(symbol, symbol_date)
);
CREATE INDEX ON stock_ohlc(symbol);
CREATE INDEX ON stock_ohlc(symbol_date);


CREATE TABLE IF NOT EXISTS gain_loss (
    gain_loss_id serial PRIMARY KEY,
    symbol text NOT NULL,
    algo_run_id integer NOT NULL REFERENCES algo_run(algo_run_id),
    gain_percentage decimal (5, 2) NOT NULL,
    gain_value decimal (8, 2) NOT NULL,
    tstamp timestamp DEFAULT current_timestamp,
    UNIQUE(symbol, algo_run_id)
);

CREATE INDEX ON gain_loss(symbol, algo_run_id);
CREATE INDEX ON algo_run(start_time);
CREATE INDEX ON new_trades(tstamp);

ALTER TABLE new_trades ALTER COLUMN algo_run_id SET NOT NULL;

CREATE TABLE IF NOT EXISTS trade_analysis (
    trade_analysis_id serial PRIMARY KEY,
    symbol text NOT NULL,
    algo_run_id integer NOT NULL REFERENCES algo_run(algo_run_id),
    start_tstamp timestamp with time zone NOT NULL,
    end_tstamp timestamp with time zone NOT NULL,
    gain_percentage decimal (5, 2) NOT NULL,
    gain_value decimal (8, 2) NOT NULL,
    r_units decimal(4,2),
    tstamp timestamp with time zone DEFAULT current_timestamp,
    UNIQUE(symbol, algo_run_id, start_tstamp)
);

ALTER TABLE
    trade_analysis
ADD COLUMN
    scanned_time timestamp with time zone
    NOT NULL
    DEFAULT current_timestamp;



