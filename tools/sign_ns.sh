#!/usr/bin/env bash
# Sign a TF-M non-secure image with the same MCUboot parameters as the SPE build.
#
# One command:
#   ./tools/sign_ns.sh path/to/tfm_ns.bin
#
# Defaults:
#   input  = build_ns/bin/tfm_ns.bin
#   output = <input_dir>/tfm_ns_signed.bin
#   SPE    = build_s/api_ns   (or $SPE / --spe)
#
# SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

usage() {
    cat <<'EOF'
Sign a non-secure TF-M firmware image (MCUboot wrapper, same args as CMake).

Usage:
  ./tools/sign_ns.sh [unsigned.bin] [-o signed.bin] [--spe /path/to/api_ns]

Examples:
  ./tools/sign_ns.sh
  ./tools/sign_ns.sh build_ns/bin/tfm_ns.bin
  ./tools/sign_ns.sh my_ns.bin -o out/tfm_ns_signed.bin
  SPE=/path/to/api_ns ./tools/sign_ns.sh my_ns.bin
EOF
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SPE="${SPE:-}"
IN_BIN=""
OUT_BIN=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --spe)
            SPE="$2"
            shift 2
            ;;
        -o|--output)
            OUT_BIN="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
        *)
            if [[ -z "$IN_BIN" ]]; then
                IN_BIN="$1"
            else
                echo "Unexpected argument: $1" >&2
                usage >&2
                exit 2
            fi
            shift
            ;;
    esac
done

if [[ -z "$SPE" ]]; then
    if [[ -f "$ROOT/build_s/api_ns/cmake/spe_config.cmake" ]]; then
        SPE="$ROOT/build_s/api_ns"
    elif [[ -f "$PWD/api_ns/cmake/spe_config.cmake" ]]; then
        SPE="$PWD/api_ns"
    fi
fi

if [[ -z "$IN_BIN" ]]; then
    if [[ -f "$ROOT/build_ns/bin/tfm_ns.bin" ]]; then
        IN_BIN="$ROOT/build_ns/bin/tfm_ns.bin"
    fi
fi

if [[ -z "$IN_BIN" ]]; then
    echo "No unsigned NS image given, and build_ns/bin/tfm_ns.bin was not found." >&2
    usage >&2
    exit 2
fi

if [[ -z "$OUT_BIN" ]]; then
    OUT_BIN="$(cd "$(dirname "$IN_BIN")" && pwd)/tfm_ns_signed.bin"
fi

if [[ -z "$SPE" || ! -f "$SPE/cmake/spe_config.cmake" ]]; then
    echo "SPE export not found. Pass --spe /path/to/api_ns or set SPE=." >&2
    exit 1
fi

SPE="$(cd "$SPE" && pwd)"
IN_BIN="$(cd "$(dirname "$IN_BIN")" && pwd)/$(basename "$IN_BIN")"
mkdir -p "$(dirname "$OUT_BIN")"
OUT_BIN="$(cd "$(dirname "$OUT_BIN")" && pwd)/$(basename "$OUT_BIN")"

CFG="$SPE/cmake/spe_config.cmake"
LAYOUT="$SPE/image_signing/layout_files/signing_layout_ns.o"
KEY="$SPE/image_signing/keys/image_ns_signing_private_key.pem"
WRAPPER="$SPE/image_signing/scripts/wrapper.py"
SCRIPTS="$SPE/image_signing/scripts"

for f in "$CFG" "$LAYOUT" "$KEY" "$WRAPPER" "$IN_BIN"; do
    if [[ ! -f "$f" ]]; then
        echo "Missing required file: $f" >&2
        exit 1
    fi
done

cmake_val() {
    local key="$1"
    local line
    line="$(grep -E "^set\\(${key}[[:space:]]" "$CFG" | tail -n 1 || true)"
    if [[ -z "$line" ]]; then
        echo ""
        return 0
    fi
    line="${line#set(${key}}"
    line="${line%%CACHE*}"
    line="${line%)}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    printf '%s' "$line"
}

VERSION="$(cmake_val MCUBOOT_IMAGE_VERSION_NS)"
HEADER_SIZE="$(cmake_val BL2_HEADER_SIZE)"
ALIGN="$(cmake_val MCUBOOT_ALIGN_VAL)"
SEC_CNT="$(cmake_val MCUBOOT_SECURITY_COUNTER_NS)"
ENC_KEY_LEN="$(cmake_val MCUBOOT_ENC_KEY_LEN)"
S_MIN_VER="$(cmake_val MCUBOOT_S_IMAGE_MIN_VER)"
HW_KEY="$(cmake_val MCUBOOT_HW_KEY)"
MEASURED="$(cmake_val MCUBOOT_MEASURED_BOOT)"
ENC_IMAGES="$(cmake_val MCUBOOT_ENC_IMAGES)"
CONFIRM="$(cmake_val MCUBOOT_CONFIRM_IMAGE)"
UPGRADE="$(cmake_val MCUBOOT_UPGRADE_STRATEGY)"

VERSION="${VERSION:-0.0.0}"
HEADER_SIZE="${HEADER_SIZE:-0x400}"
ALIGN="${ALIGN:-16}"
SEC_CNT="${SEC_CNT:-1}"
ENC_KEY_LEN="${ENC_KEY_LEN:-128}"
S_MIN_VER="${S_MIN_VER:-0.0.0+0}"

if [[ "$HW_KEY" == "ON" ]]; then
    PUB_FMT="full"
else
    PUB_FMT="hash"
fi

if [[ -x "$ROOT/.venv/bin/python" ]]; then
    PYTHON="$ROOT/.venv/bin/python"
elif [[ -x "$ROOT/.venv/bin/python3" ]]; then
    PYTHON="$ROOT/.venv/bin/python3"
else
    PYTHON="${PYTHON:-python3}"
fi

if ! "$PYTHON" -c "import imgtool, click, cryptography, cbor2, intelhex" 2>/dev/null; then
    echo "Python signing deps missing. Install with:" >&2
    echo "  $PYTHON -m pip install imgtool click cryptography cbor2 intelhex" >&2
    exit 1
fi

# wrapper.py does "import bl2.macro_parser". api_ns ships macro_parser.py
# but not the bl2 package, so build a tiny shim on PYTHONPATH.
SHIM="$(mktemp -d)"
cleanup() { rm -rf "$SHIM"; }
trap cleanup EXIT
mkdir -p "$SHIM/bl2"
touch "$SHIM/bl2/__init__.py"
cp -f "$SCRIPTS/macro_parser.py" "$SHIM/bl2/macro_parser.py"

ARGS=(
    --version "$VERSION"
    --layout "$LAYOUT"
    --key "$KEY"
    --public-key-format "$PUB_FMT"
    --align "$ALIGN"
    --pad
    --pad-header
    -H "$HEADER_SIZE"
    -s "$SEC_CNT"
    -L "$ENC_KEY_LEN"
    -d "(0, ${S_MIN_VER})"
)

if [[ "$UPGRADE" == "OVERWRITE_ONLY" ]]; then
    ARGS+=(--overwrite-only)
fi
if [[ "$CONFIRM" == "ON" ]]; then
    ARGS+=(--confirm)
fi
if [[ "$MEASURED" == "ON" ]]; then
    ARGS+=(--measured-boot-record)
fi
if [[ "$ENC_IMAGES" == "ON" ]]; then
    ENC_KEY="$SPE/image_signing/keys/image_enc_ns_key.pem"
    if [[ ! -f "$ENC_KEY" ]]; then
        echo "MCUBOOT_ENC_IMAGES=ON but encryption key not found: $ENC_KEY" >&2
        exit 1
    fi
    ARGS+=(-E "$ENC_KEY")
fi

ARGS+=("$IN_BIN" "$OUT_BIN")

echo "Signing NS image"
echo "  SPE     $SPE"
echo "  input   $IN_BIN"
echo "  output  $OUT_BIN"
echo "  version $VERSION  header $HEADER_SIZE  align $ALIGN  sec-cnt $SEC_CNT"
echo "  pub-key $PUB_FMT  encrypt $ENC_IMAGES"

# cwd must be image_signing/scripts so wrapper.py prefers the bundled imgtool
cd "$SCRIPTS"
PYTHONPATH="$SHIM${PYTHONPATH:+:$PYTHONPATH}" "$PYTHON" "$WRAPPER" "${ARGS[@]}"

ls -l "$OUT_BIN"
echo "Signed NS image: $OUT_BIN"
