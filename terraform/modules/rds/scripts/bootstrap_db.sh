#!/usr/bin/env bash
set -euo pipefail

DB_HOST="$1"
DB_PORT="$2"
DB_USER="$3"
DB_NAME="$4"
SCHEMA_FILE="$5"
SEED_FILE="$6"

if ! command -v mysql >/dev/null 2>&1; then
  echo "mysql client not found. Install mysql client before running DB bootstrap." >&2
  exit 1
fi

if [ -z "${MYSQL_PWD:-}" ]; then
  echo "MYSQL_PWD is not set. Aborting bootstrap." >&2
  exit 1
fi

echo "Bootstrapping database ${DB_NAME} on ${DB_HOST}:${DB_PORT}..."

mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -e "CREATE DATABASE IF NOT EXISTS \\`${DB_NAME}\\`;"

if [ -n "${SCHEMA_FILE}" ] && [ -f "${SCHEMA_FILE}" ]; then
  echo "Applying schema from ${SCHEMA_FILE}"
  mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" "${DB_NAME}" < "${SCHEMA_FILE}"
else
  echo "Schema file not provided or not found. Skipping schema bootstrap."
fi

if [ -n "${SEED_FILE}" ] && [ -f "${SEED_FILE}" ]; then
  echo "Applying seed data from ${SEED_FILE}"
  mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" "${DB_NAME}" < "${SEED_FILE}"
else
  echo "Seed file not provided or not found. Skipping seed data."
fi

echo "Database bootstrap completed."
