# dlt load → dbt transform → dst serve. `make all` runs the three in order.
# Target (duckdb | postgres) and credentials come from .env; see .env.example.
.PHONY: all load transform serve-dev apply test lint

all: load transform

load:            ## OpenDota → raw tables (dlt)
	uv run python load/opendota_pipeline.py

transform:       ## raw → staging → marts (dbt), with the grain tests
	cd transform && ../.venv/bin/dbt build --profiles-dir .

serve-dev:       ## a local dst server over the marts (Postgres for dst's own state via docker)
	cd serve && dst dev

apply:           ## push the semantic layer + lens to the dst server named in serve/.env
	cd serve && dst apply

test:            ## dst's eval lanes over the lens (certified corpus + behavioral cases)
	cd serve && dst test pro_meta

lint:
	uv run ruff check load && uv run ruff format --check load
