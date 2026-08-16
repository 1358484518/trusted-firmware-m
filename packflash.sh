#!/usr/bin/env bash
# 把 STM32H573I-DK 的回归/下载脚本和镜像打成可拷到本机 Ubuntu 的包
#
# 用法:
#   ./packflash.sh              # 在仓库根目录，读取 build_s / build_ns
#   ./packflash.sh /path/to/tfm
#
# SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -n "${1:-}" ]]; then
    TFM_ROOT="$(cd "$1" && pwd)"
elif [[ -f "${SCRIPT_DIR}/CMakeLists.txt" && -d "${SCRIPT_DIR}/secure_fw" ]]; then
    TFM_ROOT="${SCRIPT_DIR}"
elif [[ -f "${SCRIPT_DIR}/trusted-firmware-m/CMakeLists.txt" ]]; then
    TFM_ROOT="${SCRIPT_DIR}/trusted-firmware-m"
else
    echo "错误: 找不到 TF-M 仓库，请传入路径"
    exit 1
fi

BL2="${TFM_ROOT}/build_s/bin/bl2.bin"
SBIN="${TFM_ROOT}/build_s/bin/tfm_s_signed.bin"
NSBIN="${TFM_ROOT}/build_ns/bin/tfm_ns_signed.bin"
S_UNSIGN="${TFM_ROOT}/build_s/bin/tfm_s.bin"
NS_UNSIGN="${TFM_ROOT}/build_ns/bin/tfm_ns.bin"
UPDATE="${TFM_ROOT}/build_s/api_ns/TFM_UPDATE.sh"
REG_SRC="${TFM_ROOT}/build_s/api_ns/regression.sh"

[[ -f "${BL2}" ]] || { echo "错误: 缺少 ${BL2}，请先编译"; exit 1; }
[[ -f "${SBIN}" ]] || { echo "错误: 缺少 ${SBIN}，请先编译"; exit 1; }
[[ -f "${NSBIN}" ]] || { echo "错误: 缺少 ${NSBIN}，请先编译"; exit 1; }

read_addr() {
    local key="$1" default="$2"
    if [[ -f "${UPDATE}" ]]; then
        local v
        v="$(sed -n "s/^${key}=//p" "${UPDATE}" | head -1)"
        if [[ -n "${v}" ]]; then
            echo "${v}"
            return
        fi
    fi
    echo "${default}"
}

BOOT_ADDR="$(read_addr boot 0xc00e000)"
SLOT0="$(read_addr slot0 0xc038000)"
SLOT1="$(read_addr slot1 0xc088000)"

STAMP=""
[[ -f "${TFM_ROOT}/build_s/.buildtfm_type" ]] && STAMP="$(tr ' ' '_' < "${TFM_ROOT}/build_s/.buildtfm_type" | head -c 40)"
KIND="prod"
echo "${STAMP}" | grep -q '^test' && KIND="test"
DATE="$(date +%Y%m%d)"
OUT_NAME="tfm-h573-flash-${KIND}-${DATE}"
OUT_DIR="${TFM_ROOT}/${OUT_NAME}"
rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}/images" "${OUT_DIR}/unsigned"

cp -a "${BL2}" "${OUT_DIR}/images/bl2.bin"
cp -a "${SBIN}" "${OUT_DIR}/images/tfm_s_signed.bin"
cp -a "${NSBIN}" "${OUT_DIR}/images/tfm_ns_signed.bin"
if [[ -f "${S_UNSIGN}" ]]; then
    cp -a "${S_UNSIGN}" "${OUT_DIR}/unsigned/tfm_s.bin"
fi
if [[ -f "${NS_UNSIGN}" ]]; then
    cp -a "${NS_UNSIGN}" "${OUT_DIR}/unsigned/tfm_ns.bin"
fi

# 带上独立签名工具：替换未签名 bin 后可在本机重签
SIGN_SRC="${TFM_ROOT}/sign_kit"
if [[ ! -d "${SIGN_SRC}" && -d "${SCRIPT_DIR}/sign_kit" ]]; then
    SIGN_SRC="${SCRIPT_DIR}/sign_kit"
fi
if [[ -d "${SIGN_SRC}" ]]; then
    mkdir -p "${OUT_DIR}/sign/keys" "${OUT_DIR}/sign/layout" "${OUT_DIR}/sign/scripts" "${OUT_DIR}/sign/bl2" "${OUT_DIR}/unsigned"
    cp -a "${SIGN_SRC}/sign.sh" "${SIGN_SRC}/config" "${SIGN_SRC}/requirements.txt" "${OUT_DIR}/sign/"
    cp -a "${SIGN_SRC}/keys/." "${OUT_DIR}/sign/keys/"
    cp -a "${SIGN_SRC}/layout/." "${OUT_DIR}/sign/layout/"
    cp -a "${SIGN_SRC}/scripts/." "${OUT_DIR}/sign/scripts/"
    cp -a "${SIGN_SRC}/bl2/." "${OUT_DIR}/sign/bl2/"
    chmod +x "${OUT_DIR}/sign/sign.sh"
    find "${OUT_DIR}/sign" -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true
fi

cat > "${OUT_DIR}/images/layout.txt" <<EOF
STM32H573I-DK  烧录地址（安全别名 0x0C......）
BL2             ${BOOT_ADDR}   images/bl2.bin
Secure SPE      ${SLOT0}   images/tfm_s_signed.bin
Non-Secure NS   ${SLOT1}   images/tfm_ns_signed.bin
BOOT_UBE        0xB4  (OEM-iRoT，不要用 0xC3)
UART            ST-Link VCP  115200 8N1
EOF

# 共用：找 Linux 上的 STM32_Programmer_CLI
cat > "${OUT_DIR}/_find_cli.sh" <<'EOF'
find_stm32_cli() {
    if command -v STM32_Programmer_CLI >/dev/null 2>&1; then
        command -v STM32_Programmer_CLI
        return 0
    fi
    local d
    for d in \
        /usr/local/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin \
        "${HOME}/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin" \
        /opt/st/stm32cubeprogrammer/bin \
        /opt/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin
    do
        if [[ -x "${d}/STM32_Programmer_CLI" ]]; then
            echo "${d}/STM32_Programmer_CLI"
            return 0
        fi
    done
    echo "错误: 找不到 STM32_Programmer_CLI" >&2
    echo "请在本机 Ubuntu 安装 STM32CubeProgrammer，并把 bin 目录加入 PATH。" >&2
    return 1
}
EOF

# 回归：写 option bytes（会全片擦除）
{
    echo '#!/usr/bin/env bash'
    echo 'set -euo pipefail'
    echo 'SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"'
    echo 'source "${SCRIPT_DIR}/_find_cli.sh"'
    echo 'CLI="$(find_stm32_cli)"'
    echo 'sn_option=""'
    echo '[[ $# -eq 1 ]] && sn_option="sn=$1"'
    echo 'connect="-c port=SWD ap=1 ${sn_option} mode=UR"'
    echo 'connect_hp="-c port=SWD ap=1 ${sn_option} mode=HotPlug"'
    echo 'echo "=== H573 回归（写 option bytes，会全片擦除）==="'
    echo '"${CLI}" ${connect} -ob PRODUCT_STATE=0xED TZEN=0xB4'
    echo '"${CLI}" ${connect} -ob SECWM1_STRT=127 SECWM1_END=0 WRPSGn1=0xffffffff -e all'
    echo '"${CLI}" ${connect} -ob SECWM2_STRT=127 SECWM2_END=0 WRPSGn2=0xffffffff -e all'
    echo '"${CLI}" ${connect_hp} -ob HDP1_END=0 HDP2_END=0'
    echo '"${CLI}" ${connect_hp} -ob SECBOOTADD=0xC0100 HDP1_STRT=1 HDP1_END=0 HDP2_STRT=1 HDP2_END=0 SWAP_BANK=0 SRAM2_RST=0 SRAM2_ECC=0'
    echo '"${CLI}" ${connect_hp} -ob SECWM2_STRT=0 SECWM2_END=127 SECWM1_STRT=0 SECWM1_END=127'
    echo 'echo "regression Done"'
} > "${OUT_DIR}/regression.sh"

# 下载：只烧三份镜像，不擦整片
{
    echo '#!/usr/bin/env bash'
    echo 'set -euo pipefail'
    echo 'SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"'
    echo 'source "${SCRIPT_DIR}/_find_cli.sh"'
    echo 'CLI="$(find_stm32_cli)"'
    echo 'IMG="${SCRIPT_DIR}/images"'
    echo 'sn_option=""'
    echo '[[ $# -eq 1 ]] && sn_option="sn=$1"'
    echo "BOOT_ADDR=${BOOT_ADDR}"
    echo "SLOT0=${SLOT0}"
    echo "SLOT1=${SLOT1}"
    echo 'connect="-c port=SWD ap=1 ${sn_option} mode=HotPlug"'
    echo 'echo "=== H573 下载 BL2 + SPE + NS ==="'
    echo 'echo "BOOT_UBE=0xB4 (OEM-iRoT)"'
    echo '"${CLI}" ${connect} -ob BOOT_UBE=0xB4'
    echo 'echo "Write Secure  ${SLOT0}"'
    echo '"${CLI}" ${connect} -d "${IMG}/tfm_s_signed.bin" ${SLOT0} -v'
    echo 'echo "Write NS      ${SLOT1}"'
    echo '"${CLI}" ${connect} -d "${IMG}/tfm_ns_signed.bin" ${SLOT1} -v'
    echo 'echo "Write BL2     ${BOOT_ADDR}"'
    echo '"${CLI}" ${connect} -d "${IMG}/bl2.bin" ${BOOT_ADDR} -v'
    echo 'echo "download Done"'
} > "${OUT_DIR}/download.sh"

cat > "${OUT_DIR}/sign.sh" <<'EOF'
#!/usr/bin/env bash
# 把未签名 bin 签成 MCUboot 镜像，并放到 images/ 供 download.sh 使用
#
#   ./sign.sh                         # 签 unsigned/ 里能认出来的文件
#   ./sign.sh unsigned/tfm_ns.bin
#   ./sign.sh ns  /path/to/app.bin
#   ./sign.sh s   /path/to/sapp.bin
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIGN_KIT="${SCRIPT_DIR}/sign"
[[ -x "${SIGN_KIT}/sign.sh" ]] || { echo "错误: 本包没有签名工具（缺少 sign/）"; exit 1; }

ensure_deps() {
    local py=""
    if [[ -x "${SIGN_KIT}/.venv/bin/python" ]]; then
        py="${SIGN_KIT}/.venv/bin/python"
    elif command -v python3 >/dev/null 2>&1; then
        py="python3"
    else
        echo "错误: 需要 python3。Ubuntu: sudo apt install -y python3 python3-pip python3-venv"
        exit 1
    fi
    if ! "${py}" -c "import click, cryptography, cbor2, intelhex" 2>/dev/null; then
        echo ">>> 安装签名依赖（python3 -m pip）"
        if [[ ! -x "${SIGN_KIT}/.venv/bin/python" ]]; then
            python3 -m venv "${SIGN_KIT}/.venv" || {
                echo "错误: 创建 venv 失败。请执行: sudo apt install -y python3-venv python3-pip"
                exit 1
            }
        fi
        py="${SIGN_KIT}/.venv/bin/python"
        "${py}" -m pip install -q --upgrade pip
        "${py}" -m pip install -q -r "${SIGN_KIT}/requirements.txt"
    fi
}

install_signed() {
    local kind="$1" signed="$2"
    mkdir -p "${SCRIPT_DIR}/images"
    if [[ "${kind}" == "ns" ]]; then
        cp -a "${signed}" "${SCRIPT_DIR}/images/tfm_ns_signed.bin"
        echo "已更新 images/tfm_ns_signed.bin  （烧录地址 0x0C088000）"
    else
        cp -a "${signed}" "${SCRIPT_DIR}/images/tfm_s_signed.bin"
        echo "已更新 images/tfm_s_signed.bin   （烧录地址 0x0C038000）"
    fi
}

guess_kind() {
    local base_lc
    base_lc="$(printf '%s' "$(basename "$1")" | tr '[:upper:]' '[:lower:]')"
    if [[ "${base_lc}" == *ns* ]]; then
        echo ns
    elif [[ "${base_lc}" == *sapp* || "${base_lc}" == *tfm_s* || "${base_lc}" == *_s.bin ]]; then
        echo s
    else
        echo ""
    fi
}

sign_one() {
    local kind="$1" infile="$2"
    [[ -f "${infile}" ]] || { echo "错误: 找不到 ${infile}"; exit 1; }
    infile="$(cd "$(dirname "${infile}")" && pwd)/$(basename "${infile}")"
    echo ">>> 签名 ${kind}: ${infile}"
    (cd "${SIGN_KIT}" && ./sign.sh "${kind}" "${infile}")
    local stem signed
    stem="$(basename "${infile}")"
    stem="${stem%.*}"
    signed="${SIGN_KIT}/${stem}_signed.bin"
    [[ -f "${signed}" ]] || { echo "错误: 签名没有产出 ${signed}"; exit 1; }
    install_signed "${kind}" "${signed}"
}

ensure_deps

if [[ $# -eq 0 ]]; then
    found=0
    shopt -s nullglob
    for f in "${SCRIPT_DIR}/unsigned/"*.bin; do
        [[ "$(basename "$f")" == *_signed.bin ]] && continue
        k="$(guess_kind "$f")"
        if [[ -z "${k}" ]]; then
            echo "跳过（看不出 S/NS）: $f   请用 ./sign.sh ns $f  或  ./sign.sh s $f"
            continue
        fi
        sign_one "${k}" "$f"
        found=1
    done
    if [[ "${found}" -eq 0 ]]; then
        echo "用法:"
        echo "  1) 把未签名 bin 放到 unsigned/（文件名带 ns 或 tfm_s / _s.bin）"
        echo "     ./sign.sh"
        echo "  2) ./sign.sh unsigned/tfm_ns.bin"
        echo "  3) ./sign.sh ns  /path/app.bin"
        echo "  4) ./sign.sh s   /path/sapp.bin"
        echo "签完后执行 ./download.sh 烧录。"
        exit 2
    fi
    echo "签名完成，可以 ./download.sh"
    exit 0
fi

if [[ "$1" == "ns" || "$1" == "NS" || "$1" == "s" || "$1" == "S" ]]; then
    [[ $# -ge 2 ]] || { echo "错误: 请给出 bin 路径"; exit 2; }
    k="$1"
    [[ "${k}" == "NS" ]] && k="ns"
    [[ "${k}" == "S" ]] && k="s"
    sign_one "${k}" "$2"
    echo "签名完成，可以 ./download.sh"
    exit 0
fi

infile="$1"
k="$(guess_kind "${infile}")"
[[ -n "${k}" ]] || { echo "无法从文件名判断类型，请用: ./sign.sh ns $1  或  ./sign.sh s $1"; exit 2; }
sign_one "${k}" "${infile}"
echo "签名完成，可以 ./download.sh"
EOF

cat > "${OUT_DIR}/unsigned/README.txt" <<'EOF'
这里是未签名固件。包里已带当前编译出的 tfm_s.bin / tfm_ns.bin。

替换成你自己编的 bin 后，在上一级执行 ./sign.sh，会签好并覆盖 images/。

  tfm_ns.bin / *ns*.bin          →  images/tfm_ns_signed.bin
  tfm_s.bin  / *sapp* / *_s.bin  →  images/tfm_s_signed.bin

BL2（images/bl2.bin）不用签。
EOF

cat > "${OUT_DIR}/flash_all.sh" <<'EOF'
#!/usr/bin/env bash
# 先回归（option bytes + 全片擦除），再下载三份镜像
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/regression.sh" "$@"
"${SCRIPT_DIR}/download.sh" "$@"
echo "全部完成。复位板子，串口 115200 8N1 看启动/测试日志。"
EOF

cat > "${OUT_DIR}/README.txt" <<EOF
STM32H573I-DK  本地 Ubuntu 烧录包（${KIND}）
========================================

本包在服务器上由 packflash.sh 打出，拷到插着板子的 Ubuntu 即可。
不需要 TF-M 源码，不需要交叉编译器。

本机需要
--------
1) STM32CubeProgrammer（命令行 STM32_Programmer_CLI）
   装好后确认:
     which STM32_Programmer_CLI
   或存在:
     /usr/local/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin
2) USB 连 ST-Link，用户在 plugdev / dialout 组
3) 串口: /dev/ttyACM0  115200 8N1

用法
----
  chmod +x *.sh
  ./regression.sh     # 写 option bytes，会全片擦除（首次或 option bytes 乱了才跑）
  ./download.sh       # 烧 BL2 + 安全 + NS，并设 BOOT_UBE=0xB4
  ./flash_all.sh      # 上面两步一起做

替换自己编的未签名程序并重签
----------------------------
本机还需要 python3（Ubuntu: sudo apt install -y python3 python3-pip python3-venv）

  1) 包里 unsigned/ 已有本次编译的未签名 tfm_s.bin、tfm_ns.bin
     换成你自己的 bin 后执行:
  2) ./sign.sh                 # 自动签名并覆盖 images/ 里对应 signed
  3) ./download.sh             # 只烧镜像，不必再跑 regression

也可以指定文件:
  ./sign.sh unsigned/tfm_ns.bin
  ./sign.sh ns  /path/to/app.bin
  ./sign.sh s   /path/to/sapp.bin

BL2 不要用这套签；只换 S/NS。密钥是和当前板上 BL2 配套的 dummy RSA-3072。

多块板子时加序列号:
  ./download.sh 002A001234

地址
----
$(cat "${OUT_DIR}/images/layout.txt")

注意
----
- 不要用 CubeProgrammer 再做 Full chip erase
- H5 必须 AP=1；脚本已写好
- BOOT_UBE 必须 0xB4（OEM-iRoT），不要 0xC3
- 烧完复位，NS 会跑回归测试（正式版也是可跑的 NS 测试程序）
EOF

chmod +x "${OUT_DIR}/regression.sh" "${OUT_DIR}/download.sh" "${OUT_DIR}/flash_all.sh" "${OUT_DIR}/sign.sh"

TAR="${TFM_ROOT}/${OUT_NAME}.tar.gz"
tar -C "${TFM_ROOT}" -czf "${TAR}" "${OUT_NAME}"

echo ""
echo "=== 烧录包已打好 ==="
echo "目录: ${OUT_DIR}"
echo "压缩: ${TAR}"
echo "拷到本机 Ubuntu:  scp ${TAR} user@ubuntu:~/"
echo "本机:  tar -xzf ${OUT_NAME}.tar.gz && cd ${OUT_NAME} && ./flash_all.sh"
