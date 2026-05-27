#!/bin/bash
#
# CTF Environment Setup Script
# Thin cloud-init bootstrap. The actual setup logic lives in setup/.
#
set -euo pipefail

exec > >(tee /var/log/ctf_setup.log) 2>&1

DONE_MARKER="/var/lib/cloud/instance/ctf-setup.done"
LEGACY_DONE_MARKER="/var/log/setup_complete"
PROJECT_STATE_DIR="/var/lib/linux-ctfs"
PROJECT_DONE_MARKER="$PROJECT_STATE_DIR/setup.done"
PROJECT_FAILED_MARKER="$PROJECT_STATE_DIR/setup.failed"
UV_ROOT="/opt/uv"

if [ -f "$DONE_MARKER" ]; then
    echo "CTF setup already completed. Skipping."
    mkdir -p "$PROJECT_STATE_DIR"
    touch "$PROJECT_DONE_MARKER"
    touch "$LEGACY_DONE_MARKER"
    exit 0
fi

on_error() {
    local exit_code=$?
    echo "ERROR: ctf_setup.sh failed on line $1" >&2
    mkdir -p "$PROJECT_STATE_DIR"
    touch "$PROJECT_FAILED_MARKER"
    exit "$exit_code"
}
trap 'on_error "$LINENO"' ERR

mkdir -p "$(dirname "$DONE_MARKER")" "$PROJECT_STATE_DIR" "$UV_ROOT"/{cache,python,tools}
rm -f "$PROJECT_FAILED_MARKER"

if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh
fi

cat > /etc/profile.d/uv.sh <<'EOF'
export PATH="/usr/local/bin:$PATH"
EOF
chmod 644 /etc/profile.d/uv.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export UV_CACHE_DIR="$UV_ROOT/cache"
export UV_PYTHON_INSTALL_DIR="$UV_ROOT/python"
export UV_TOOL_DIR="$UV_ROOT/tools"
export UV_TOOL_BIN_DIR="/usr/local/bin"

uv python install 3.13
uv run --python 3.13 --project "$SCRIPT_DIR/setup" "$SCRIPT_DIR/setup/main.py"
uv tool install --python 3.13 --force "$SCRIPT_DIR/verify"

chmod -R a+rX "$UV_ROOT"
uv cache clean

touch "$DONE_MARKER"
touch "$LEGACY_DONE_MARKER"
touch "$PROJECT_DONE_MARKER"
echo "CTF environment setup complete!"
