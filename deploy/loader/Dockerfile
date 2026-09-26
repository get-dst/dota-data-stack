# The scheduled load: dlt (OpenDota → raw) then dbt (raw → marts), one container, run as
# a Cloud Run job. Everything a run needs is installed here, including DuckDB's
# MotherDuck extension, so a run starts without downloading anything.
#
#   docker build -f deploy/loader/Dockerfile -t dota-loader .     (from the repository root)
FROM python:3.12-slim
COPY --from=ghcr.io/astral-sh/uv:0.12.9 /uv /usr/local/bin/uv
WORKDIR /app
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy UV_PYTHON_DOWNLOADS=never \
    PATH=/app/.venv/bin:$PATH PYTHONUNBUFFERED=1
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project
COPY .dlt/config.toml .dlt/config.toml
COPY load/opendota_pipeline.py load/
COPY transform/dbt_project.yml transform/profiles.yml transform/
COPY transform/models transform/models
COPY transform/macros transform/macros
COPY transform/tests transform/tests
COPY deploy/loader/run.sh ./
# dlt keeps its working directory under load/, dbt writes target/ and logs/ under transform/.
RUN useradd --create-home --uid 10001 app && chown app load transform \
 && if [ -f transform/packages.yml ] || [ -f transform/dependencies.yml ]; then \
      cd transform && dbt deps && chown -R app dbt_packages; fi
USER app
RUN python -c "import duckdb; duckdb.sql('INSTALL motherduck')"
ENTRYPOINT ["/app/run.sh"]
