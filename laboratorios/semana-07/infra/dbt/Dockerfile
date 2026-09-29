FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir "dbt-snowflake~=1.12.0"

WORKDIR /usr/app/dbt
ENV DBT_PROFILES_DIR=/usr/app/dbt

ENTRYPOINT ["dbt"]
