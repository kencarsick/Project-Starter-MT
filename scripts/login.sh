#!/usr/bin/env bash
# scripts/login.sh — Pre-login browser session manager
# Opens a headed Chromium browser with persistent context at browser-data/.
# User logs into services, closes browser, session is saved for agent reuse.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=scripts/lib/config.sh
source "${SCRIPT_DIR}/lib/config.sh"

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

usage() {
  cat <<EOF
Usage: $(basename "$0") [url]

Opens a headed Chromium browser with persistent session stored in browser-data/.
Log into services, close the browser, and the session is saved.

Arguments:
  [url]    URL to open (default: https://google.com)

Examples:
  $(basename "$0")
  $(basename "$0") https://github.com
  $(basename "$0") https://app.example.com
EOF
  exit 0
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && usage

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

BROWSER_DATA_DIR="${PROJECT_ROOT}/browser-data"
mkdir -p "$BROWSER_DATA_DIR"

TARGET_URL="${1:-https://google.com}"

log_info "Opening browser with persistent session..."
log_info "Browser data: $BROWSER_DATA_DIR"
log_info "Target URL: $TARGET_URL"
log_info "Log in to your services, then close the browser to save the session."

if ! command -v node >/dev/null 2>&1; then
  log_error "Node.js is required for browser session management."
  log_info "Install Node.js: https://nodejs.org/"
  exit 1
fi

# Launch headed Chromium with persistent context via Playwright
node -e "
const { chromium } = require('playwright');
(async () => {
  const context = await chromium.launchPersistentContext('${BROWSER_DATA_DIR}', {
    headless: false,
    args: ['--start-maximized'],
  });
  const page = context.pages()[0] || await context.newPage();
  await page.goto('${TARGET_URL}');
  console.log('Browser opened. Log in, then close the browser window to save.');
  await new Promise(resolve => context.on('close', resolve));
  console.log('Browser closed. Session saved.');
})().catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
" || {
  log_error "Failed to launch browser. Ensure Playwright is installed: npm install playwright"
  exit 1
}

log_info "Session saved. Agents will use browser-data/ for authenticated sessions."
