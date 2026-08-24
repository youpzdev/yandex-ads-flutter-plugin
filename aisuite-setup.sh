#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# AUTO-GENERATED FILE — DO NOT EDIT DIRECTLY.
#
# This script is rendered from a shared template. If you need to change the
# behaviour (add flags, fix a bug, tweak help text, etc.), edit the TEMPLATE
# and run the GENERATOR — do NOT patch the generated copies one by one, they
# will be overwritten on the next regeneration.
#
#   Template:  adv/pcode/mobileadssdk/sdk/scripts/shards/aisuite-setup.template.sh
#   Generator: adv/pcode/mobileadssdk/sdk/scripts/shards/generate-aisuite-setup.sh
#
# To regenerate the copies in every SDK directory:
#
#   adv/pcode/mobileadssdk/sdk/scripts/shards/generate-aisuite-setup.sh
#
# To add/remove SDKs, edit the TARGETS array in the generator.
# =============================================================================
#
# Runs `ya tool aisuite setup` from this SDK's path inside an arcadia
# checkout, and writes the output into the directory containing this script.
#
# Usage:
#   ./aisuite-setup.sh                          # uses ~/arcadia as arc root
#   ./aisuite-setup.sh --arc-root /path/to/arc  # custom arc root
#   ./aisuite-setup.sh --arc-root=/path/to/arc

SDK_REL_PATH="adv/pcode/mobileadssdk/sdk/flutter"
ARC_ROOT="${HOME}/arcadia"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --arc-root)
            ARC_ROOT="$2"
            shift 2
            ;;
        --arc-root=*)
            ARC_ROOT="${1#*=}"
            shift
            ;;
        -h|--help)
            sed -n '22,28p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Expand leading ~ in arc root.
ARC_ROOT="${ARC_ROOT/#~/$HOME}"

ARC_SDK_DIR="${ARC_ROOT%/}/${SDK_REL_PATH}"

if [[ ! -d "$ARC_SDK_DIR" ]]; then
    echo "SDK path not found in arc root: $ARC_SDK_DIR" >&2
    echo "Pass a correct path via --arc-root=<path>." >&2
    exit 1
fi

cd "$ARC_SDK_DIR"
exec ya tool aisuite setup --agent cursor --agent claude --output-dir="$SCRIPT_DIR"
