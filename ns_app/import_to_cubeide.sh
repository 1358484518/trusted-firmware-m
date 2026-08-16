#!/usr/bin/env bash
# Copy a working NS lib tree (Makefile app + api_ns) into an STM32CubeIDE
# project and remove the CubeMX blink runtime sources.
#
# Does not edit .cproject. After running, still set Include / macros / linker
# once as in ns_app/CUBEIDE.md.
#
# Usage:
#   ./import_to_cubeide.sh --lib ~/test/libs --cube ~/test/tfmminiproject
#   ./import_to_cubeide.sh --lib ~/test/libs --cube ~/test/tfmminiproject/STM32CubeIDE
#   ./import_to_cubeide.sh ~/test/libs ~/test/tfmminiproject
#
# Options:
#   --force     replace existing ns_app, delete old sources without asking
#   --dry-run   print actions only
#   --keep-ioc  do not delete *.ioc

set -euo pipefail

LIB=""
CUBE=""
FORCE=0
DRY=0
KEEP_IOC=0

usage() {
	sed -n '2,16p' "$0" | sed 's/^# \?//'
	exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	-h|--help) usage 0 ;;
	--lib) LIB="${2:?}"; shift 2 ;;
	--cube) CUBE="${2:?}"; shift 2 ;;
	--force) FORCE=1; shift ;;
	--dry-run) DRY=1; shift ;;
	--keep-ioc) KEEP_IOC=1; shift ;;
	--) shift; break ;;
	-*) echo "unknown option: $1" >&2; usage 1 ;;
	*)
		if [[ -z "$LIB" ]]; then
			LIB="$1"
		elif [[ -z "$CUBE" ]]; then
			CUBE="$1"
		else
			echo "extra argument: $1" >&2
			usage 1
		fi
		shift
		;;
	esac
done

if [[ -z "$LIB" || -z "$CUBE" ]]; then
	echo "need --lib <ns-app-dir> and --cube <cubeide-or-mx-dir>" >&2
	usage 1
fi

LIB="$(cd "$LIB" && pwd)"
CUBE="$(cd "$CUBE" && pwd)"

if [[ ! -f "$LIB/main.c" || ! -f "$LIB/Makefile" ]]; then
	echo "not an NS lib dir (need main.c and Makefile): $LIB" >&2
	exit 1
fi
if [[ ! -f "$LIB/api_ns/interface/lib/s_veneers.o" ]]; then
	echo "missing api_ns (need $LIB/api_ns/interface/lib/s_veneers.o)" >&2
	exit 1
fi

# Eclipse project root: this dir or STM32CubeIDE/ under it.
ECLIPSE=""
if [[ -f "$CUBE/.project" ]]; then
	ECLIPSE="$CUBE"
elif [[ -f "$CUBE/STM32CubeIDE/.project" ]]; then
	ECLIPSE="$CUBE/STM32CubeIDE"
else
	echo "no .project in $CUBE or $CUBE/STM32CubeIDE" >&2
	exit 1
fi

# CubeMX Core/Drivers usually sit next to STM32CubeIDE/.
MX_ROOT="$(dirname "$ECLIPSE")"
if [[ ! -d "$MX_ROOT/Core" && -d "$ECLIPSE/Core" ]]; then
	MX_ROOT="$ECLIPSE"
fi

DEST="$ECLIPSE/ns_app"
API="$DEST/api_ns"
TFM_SRC="$DEST/tfm_src"

run() {
	if [[ "$DRY" -eq 1 ]]; then
		printf 'DRY:'
		printf ' %q' "$@"
		printf '\n'
	else
		"$@"
	fi
}

echo "lib:     $LIB"
echo "eclipse: $ECLIPSE"
echo "mx root: $MX_ROOT"
echo "dest:    $DEST"

if [[ -e "$DEST" && "$FORCE" -ne 1 ]]; then
	echo "already exists: $DEST"
	echo "re-run with --force to replace it"
	exit 1
fi

if [[ "$FORCE" -ne 1 && "$DRY" -ne 1 ]]; then
	echo
	echo "Will copy $LIB -> $DEST"
	echo "Will delete CubeMX runtime under $MX_ROOT (Core, Drivers, Application, *.ld)"
	read -r -p "Continue? [y/N] " ans
	case "$ans" in
	y|Y|yes|YES) ;;
	*) echo "aborted"; exit 1 ;;
	esac
fi

if [[ -e "$DEST" ]]; then
	run rm -rf "$DEST"
fi
run mkdir -p "$DEST"
# Copy contents, not the directory node named libs.
run cp -a "$LIB"/. "$DEST"/

# SPE sources CubeIDE should compile (same list as Makefile SPE_SRCS).
SPE_REL=(
	interface/src/os_wrapper/tfm_ns_interface_bare_metal.c
	interface/src/tfm_tz_psa_ns_api.c
	interface/src/tfm_crypto_api.c
	interface/src/tfm_its_api.c
	interface/src/tfm_ps_api.c
	interface/src/tfm_fwu_api.c
	interface/src/tfm_attest_api.c
	interface/src/tfm_platform_api.c
	platform/Device/Source/startup_stm32h5xx_ns.c
	platform/Device/Source/system_stm32h5xx.c
	platform/ext/common/uart_stdout.c
	platform/hal/CMSIS_Driver/low_level_com.c
	platform/hal/Src/stm32h5xx_hal.c
	platform/hal/Src/stm32h5xx_hal_cortex.c
	platform/hal/Src/stm32h5xx_hal_dma.c
	platform/hal/Src/stm32h5xx_hal_dma_ex.c
	platform/hal/Src/stm32h5xx_hal_gpio.c
	platform/hal/Src/stm32h5xx_hal_pwr.c
	platform/hal/Src/stm32h5xx_hal_pwr_ex.c
	platform/hal/Src/stm32h5xx_hal_rcc.c
	platform/hal/Src/stm32h5xx_hal_rcc_ex.c
	platform/hal/Src/stm32h5xx_hal_uart.c
	platform/hal/Src/stm32h5xx_hal_uart_ex.c
)

run mkdir -p "$TFM_SRC"
for rel in "${SPE_REL[@]}"; do
	src="$API/$rel"
	if [[ "$DRY" -eq 1 ]]; then
		echo "DRY: cp $src $TFM_SRC/"
		continue
	fi
	if [[ ! -f "$src" ]]; then
		echo "missing SPE source: $src" >&2
		exit 1
	fi
	cp -a "$src" "$TFM_SRC/"
done

# Remove CubeMX blink runtime. Keep .project / .cproject / ns_app.
[[ -d "$MX_ROOT/Core" ]] && run rm -rf "$MX_ROOT/Core"
[[ -d "$MX_ROOT/Drivers" ]] && run rm -rf "$MX_ROOT/Drivers"
[[ -d "$ECLIPSE/Application" ]] && run rm -rf "$ECLIPSE/Application"
[[ -d "$ECLIPSE/Drivers" ]] && run rm -rf "$ECLIPSE/Drivers"
if [[ "$KEEP_IOC" -eq 0 ]]; then
	shopt -s nullglob
	for ioc in "$MX_ROOT"/*.ioc; do
		run rm -f "$ioc"
	done
	shopt -u nullglob
fi
shopt -s nullglob
for ld in "$ECLIPSE"/*.ld; do
	run rm -f "$ld"
done
shopt -u nullglob

if [[ "$DRY" -eq 1 ]]; then
	echo "dry-run done"
	exit 0
fi

echo
echo "copy done: $DEST"
if [[ ! -f "$DEST/out/appli_ns.pp.ld" ]]; then
	echo "note: $DEST/out/appli_ns.pp.ld missing — run:  make -C $DEST"
fi
if [[ ! -f "$API/interface/lib/s_veneers.o" ]]; then
	echo "note: s_veneers.o missing" >&2
fi

echo
echo "Next in CubeIDE (once per project, see ns_app/CUBEIDE.md):"
echo "  1. Refresh (F5), remove red missing-file refs"
echo "  2. Source Location = ns_app, exclude api_ns and out"
echo "  3. Includes / macros / CPU / linker script / Additional object files"
echo "     linker:  \${ProjDirPath}/ns_app/out/appli_ns.pp.ld"
echo "     object:  \${ProjDirPath}/ns_app/api_ns/interface/lib/s_veneers.o"
echo "     (not Libraries -l; no extra quotes; do not duplicate nano/nosys specs)"
