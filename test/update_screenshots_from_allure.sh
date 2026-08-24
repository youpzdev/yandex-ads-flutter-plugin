#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PYTHON="${PYTHON:-python3}"

exec "${PYTHON}" "${ROOT_DIR}/plugin-tests-support/update_screenshots_from_allure.py" \
  --screenshots "${SCRIPT_DIR}/screenshots" \
  "$@"
