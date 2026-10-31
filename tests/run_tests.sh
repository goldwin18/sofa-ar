#!/usr/bin/env bash
# Makes a virtual environment, installs the test tools, and runs every test.
# Needs Python 3.9+ and internet (first run downloads a test browser, about 150 MB).
#
# Optional: MODEL_VIEWER_JS=/path/to/model-viewer.min.js  (use a local copy instead of the CDN)
set -euo pipefail
cd "$(dirname "$0")/.."

python3 -m venv .venv
. .venv/bin/activate
pip install -q -r tests/requirements.txt
python -m playwright install chromium
python -m pytest tests -v "$@"
