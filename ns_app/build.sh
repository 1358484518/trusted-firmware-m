#!/usr/bin/env bash
# Compile/link a bare-metal NS image against SPE export (build_s/api_ns).
# CPU/ABI must match SPE: cortex-m33+nodsp+nofp, soft float.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SPE="${SPE:-$ROOT/build_s/api_ns}"
OUT="${OUT:-$ROOT/ns_app/out}"
CROSS="${CROSS:-arm-none-eabi}"
if ! command -v "${CROSS}-gcc" >/dev/null 2>&1; then
    export PATH="/home/ubuntu/tfm/arm-gnu-toolchain-14.3.rel1-x86_64-arm-none-eabi/bin:${PATH}"
fi
CC="${CROSS}-gcc"
OBJCOPY="${CROSS}-objcopy"

if [[ ! -f "$SPE/interface/lib/s_veneers.o" ]]; then
    echo "SPE export not found: $SPE/interface/lib/s_veneers.o" >&2
    exit 1
fi

mkdir -p "$OUT/obj"

CPU="-mcpu=cortex-m33+nodsp+nofp -mthumb -mfloat-abi=soft"
CFLAGS=(
    $CPU
    -std=gnu11 -g
    -ffunction-sections -fdata-sections
    -fno-builtin -funsigned-char
    -Wall
    -DNDEBUG
    -DSTM32H573xx
    -DUSE_HAL_DRIVER
    -DDOMAIN_NS=1
    -DCONFIG_TFM_FLOAT_ABI=0
    -DPLATFORM_DEFAULT_CRYPTO_KEYS
    -DCONFIG_TFM_USE_TRUSTZONE
    -DTFM_ISOLATION_LEVEL=1
    -DTFM_PARTITION_CRYPTO
    -DTFM_PARTITION_INTERNAL_TRUSTED_STORAGE
    -DTFM_PARTITION_PROTECTED_STORAGE
    -DTFM_PARTITION_FIRMWARE_UPDATE
    -DTFM_PARTITION_INITIAL_ATTESTATION
    -DTFM_PARTITION_PLATFORM
    -DTFM_PSA_CRYPTO_CLIENT_ONLY
    -DTF_PSA_CRYPTO_CONFIG_FILE='"mbedtls/tf_psa_crypto_config.h"'
    -DTARGET_CONFIG_HEADER_FILE='"config_tfm_target.h"'
    -DBL2
    -DBL2_HEADER_SIZE=0x400
    -DBL2_TRAILER_SIZE=0x2000
    -DMCUBOOT_IMAGE_NUMBER=2
    -I"$SPE/interface/include"
    -I"$SPE/interface/include/crypto_keys"
    -I"$SPE/platform/include"
    -I"$SPE/platform/boards"
    -I"$SPE/platform/Device/Include"
    -I"$SPE/platform/ext/cmsis/Include"
    -I"$SPE/platform/ext/cmsis/Include/m-profile"
    -I"$SPE/platform/ext/common"
    -I"$SPE/platform/hal/Inc"
)

compile() {
    local src="$1"
    local obj="$OUT/obj/$(basename "${src%.*}").o"
    echo "CC  $(basename "$src")" >&2
    "$CC" "${CFLAGS[@]}" -c "$src" -o "$obj"
    printf '%s\n' "$obj"
}

# 1) Preprocess NS linker script (appli_ns.ld includes region_defs.h)
echo "PP  appli_ns.ld"
"$CC" "${CFLAGS[@]}" -E -P -xc \
    "$SPE/platform/linker_scripts/appli_ns.ld" \
    -o "$OUT/appli_ns.pp.ld"

objs=()
add_obj() {
    objs+=("$(compile "$1")")
}

# 2) App + TF-M NS PSA client + veneer dispatcher
add_obj "$ROOT/ns_app/main.c"
add_obj "$SPE/interface/src/os_wrapper/tfm_ns_interface_bare_metal.c"
add_obj "$SPE/interface/src/tfm_tz_psa_ns_api.c"
add_obj "$SPE/interface/src/tfm_crypto_api.c"
add_obj "$SPE/interface/src/tfm_its_api.c"
add_obj "$SPE/interface/src/tfm_ps_api.c"
add_obj "$SPE/interface/src/tfm_fwu_api.c"
add_obj "$SPE/interface/src/tfm_attest_api.c"
add_obj "$SPE/interface/src/tfm_platform_api.c"

# 3) Startup + UART/HAL (same set as platform_ns)
add_obj "$SPE/platform/Device/Source/startup_stm32h5xx_ns.c"
add_obj "$SPE/platform/Device/Source/system_stm32h5xx.c"
add_obj "$SPE/platform/ext/common/uart_stdout.c"
add_obj "$SPE/platform/hal/CMSIS_Driver/low_level_com.c"
add_obj "$SPE/platform/hal/Src/stm32h5xx_hal.c"
add_obj "$SPE/platform/hal/Src/stm32h5xx_hal_cortex.c"
add_obj "$SPE/platform/hal/Src/stm32h5xx_hal_dma.c"
add_obj "$SPE/platform/hal/Src/stm32h5xx_hal_dma_ex.c"
add_obj "$SPE/platform/hal/Src/stm32h5xx_hal_gpio.c"
add_obj "$SPE/platform/hal/Src/stm32h5xx_hal_pwr.c"
add_obj "$SPE/platform/hal/Src/stm32h5xx_hal_pwr_ex.c"
add_obj "$SPE/platform/hal/Src/stm32h5xx_hal_rcc.c"
add_obj "$SPE/platform/hal/Src/stm32h5xx_hal_rcc_ex.c"
add_obj "$SPE/platform/hal/Src/stm32h5xx_hal_uart.c"
add_obj "$SPE/platform/hal/Src/stm32h5xx_hal_uart_ex.c"
add_obj "$ROOT/platform/ext/common/syscalls_stub.c"

# 4) Link: s_veneers.o is a raw object (absolute NSC addresses), not an archive
echo "LD  tfm_ns.axf"
"$CC" $CPU \
    -specs=nano.specs -specs=nosys.specs \
    -Wl,--gc-sections \
    -Wl,--print-memory-usage \
    -Wl,-Map="$OUT/tfm_ns.map" \
    -T "$OUT/appli_ns.pp.ld" \
    -o "$OUT/tfm_ns.axf" \
    "${objs[@]}" \
    "$SPE/interface/lib/s_veneers.o"

"$OBJCOPY" -O binary "$OUT/tfm_ns.axf" "$OUT/tfm_ns.bin"
"$OBJCOPY" -O ihex   "$OUT/tfm_ns.axf" "$OUT/tfm_ns.hex"

# 5) Sign with the same dummy NS key the SPE was built with
SIGN_SCRIPTS="$SPE/image_signing/scripts"
if [[ -x "$ROOT/.venv/bin/python" ]]; then
    PYTHON="$ROOT/.venv/bin/python"
else
    PYTHON="${PYTHON:-python3}"
fi

echo "SIGN tfm_ns_signed.bin"
( cd "$SIGN_SCRIPTS" && "$PYTHON" wrapper.py \
    --version 0.0.0 \
    --layout "$SPE/image_signing/layout_files/signing_layout_ns.o" \
    --key "$SPE/image_signing/keys/image_ns_signing_private_key.pem" \
    --public-key-format full \
    --align 16 \
    --pad \
    --pad-header \
    -H 0x400 \
    -s 1 \
    -L 128 \
    -d "(0, 0.0.0+0)" \
    --measured-boot-record \
    "$OUT/tfm_ns.bin" \
    "$OUT/tfm_ns_signed.bin" )

echo
echo "Linked:"
echo "  $OUT/tfm_ns.axf"
echo "  $OUT/tfm_ns.bin"
echo "  $OUT/tfm_ns.hex"
echo "  $OUT/tfm_ns_signed.bin"
echo
echo "Veneers resolved from $SPE/interface/lib/s_veneers.o"
"${CROSS}-nm" "$OUT/tfm_ns.axf" | grep ' tfm_psa_call_veneer$' || true
