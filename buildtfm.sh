#!/usr/bin/env bash
# STM32H573I-DK  TF-M 一键编译（Ubuntu 22.04 / GNUARM，硬件浮点 + 回归测试）
#
# 用法:
#   ./scripts/setup_ubuntu2204.sh   # 首次：依赖 + Arm GNU 13.3.Rel1
#   ./buildtfm.sh test              # 回归测试版：TEST_S + TEST_NS，INFO 日志
#   ./buildtfm.sh prod              # 正式版：SPE 不带 S 测试分区，NS 测试仍可烧
#   ./buildtfm.sh                   # 交互选择
#   ./buildtfm.sh -h
#
# SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

usage() {
    cat <<'EOF'
STM32H573I-DK TF-M 编译脚本（Ubuntu 22.04 GNUARM，硬件浮点 FPv5-SP-D16）

用法:
  ./scripts/setup_ubuntu2204.sh   安装 cmake/ninja/python3-venv 和官方 GNU Arm 工具链
  ./buildtfm.sh test              回归测试版（TEST_S + TEST_NS，INFO 日志）
  ./buildtfm.sh prod              正式版（TEST_S 关，TEST_NS 开，ERROR 日志）
  ./buildtfm.sh                   交互选择构建类型

别名: test|debug|回归    prod|release|formal|正式

环境变量:
  TFM_TESTS       tf-m-tests 源码路径（默认自动克隆到 ~/tf-m-tests）
  GNUARM_PATH     arm-none-eabi-gcc 所在目录（默认探测 ~/toolchains/.../bin）
EOF
}

BUILD_TYPE=""
case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    test|debug|回归) BUILD_TYPE="test"; shift || true ;;
    prod|release|formal|正式) BUILD_TYPE="prod"; shift || true ;;
    "") ;;
    *)
        echo "未知参数: $1"
        usage
        exit 2
        ;;
esac

if [[ -z "${BUILD_TYPE}" ]]; then
    if [[ ! -t 0 ]]; then
        echo "非交互环境，默认回归测试版（TEST_S + TEST_NS）"
        BUILD_TYPE="test"
    else
        echo "请选择构建类型:"
        echo "  1) 测试版  — TEST_S / TEST_NS 全开，INFO 日志（回归测试）"
        echo "  2) 正式版  — 安全侧不带测试分区，NS 测试程序仍可烧可跑，ERROR 日志"
        echo -n "输入 1 或 2: "
        read -r choice
        case "${choice}" in
            1) BUILD_TYPE="test" ;;
            2) BUILD_TYPE="prod" ;;
            *) echo "无效选择"; exit 2 ;;
        esac
    fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TFM_TESTS_VERSION="TF-Mv2.3.0"
TFM_TESTS_GIT="https://github.com/TrustedFirmware-M/tf-m-tests.git"

# 支持两种目录布局:
#   A) 脚本在仓库外:  WORK/buildtfm.sh  WORK/trusted-firmware-m  WORK/tf-m-tests
#   B) 脚本在仓库内:  TF-M/buildtfm.sh  上一级或旁路有 tf-m-tests
if [[ -f "${SCRIPT_DIR}/trusted-firmware-m/CMakeLists.txt" ]]; then
    WORK_ROOT="${SCRIPT_DIR}"
    TFM_ROOT="${WORK_ROOT}/trusted-firmware-m"
    TFM_TESTS="${TFM_TESTS:-${WORK_ROOT}/tf-m-tests}"
elif [[ -f "${SCRIPT_DIR}/CMakeLists.txt" && -d "${SCRIPT_DIR}/secure_fw" ]]; then
    TFM_ROOT="${SCRIPT_DIR}"
    WORK_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
    if [[ -n "${TFM_TESTS:-}" ]]; then
        :
    elif [[ -f "${WORK_ROOT}/tf-m-tests/tests_reg/spe/CMakeLists.txt" ]]; then
        TFM_TESTS="${WORK_ROOT}/tf-m-tests"
    elif [[ -f "${TFM_ROOT}/../tf-m-tests/tests_reg/spe/CMakeLists.txt" ]]; then
        TFM_TESTS="$(cd "${TFM_ROOT}/../tf-m-tests" && pwd)"
    else
        TFM_TESTS="${HOME}/tf-m-tests"
    fi
else
    echo "错误: 找不到 TF-M 源码（请把脚本放在仓库根目录或与仓库同级）"
    exit 1
fi

[[ -f "${TFM_ROOT}/CMakeLists.txt" ]] || { echo "错误: 缺少 ${TFM_ROOT}"; exit 1; }

# 缺 tf-m-tests 时按 version.txt 推荐标签自动克隆
if [[ ! -f "${TFM_TESTS}/tests_reg/spe/CMakeLists.txt" ]]; then
    PINNED="${TFM_TESTS_VERSION}"
    if [[ -f "${TFM_ROOT}/lib/ext/tf-m-tests/version.txt" ]]; then
        PINNED="$(sed -n 's/^version=//p' "${TFM_ROOT}/lib/ext/tf-m-tests/version.txt" | head -1)"
        PINNED="${PINNED:-${TFM_TESTS_VERSION}}"
    fi
    echo ">>> 克隆 tf-m-tests ${PINNED} -> ${TFM_TESTS}"
    git clone --depth 1 --branch "${PINNED}" "${TFM_TESTS_GIT}" "${TFM_TESTS}"
fi
[[ -f "${TFM_TESTS}/tests_reg/spe/CMakeLists.txt" ]] || { echo "错误: 缺少 ${TFM_TESTS}"; exit 1; }

# 官方 GNU Arm 工具链（Ubuntu 自带 gcc-arm-none-eabi 会被 TF-M 拒绝）
if [[ -n "${GNUARM_PATH:-}" ]]; then
    export PATH="${GNUARM_PATH}:${PATH}"
else
    for d in \
        "${HOME}/toolchains/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/bin" \
        "${HOME}/toolchains/arm-gnu-toolchain-13.3.Rel1-x86_64-arm-none-eabi/bin" \
        /opt/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/bin
    do
        if [[ -x "${d}/arm-none-eabi-gcc" ]]; then
            export PATH="${d}:${PATH}"
            break
        fi
    done
fi

if ! command -v arm-none-eabi-gcc >/dev/null 2>&1; then
    echo "错误: 找不到 arm-none-eabi-gcc"
    echo "请先执行: ./scripts/setup_ubuntu2204.sh"
    echo "或把官方 GNU Arm 工具链 bin 目录加入 PATH / GNUARM_PATH"
    exit 1
fi
if ! command -v ninja >/dev/null 2>&1; then
    echo "错误: 找不到 ninja。Ubuntu 22.04: sudo apt install -y ninja-build"
    echo "或执行: ./scripts/setup_ubuntu2204.sh"
    exit 1
fi
if ! command -v cmake >/dev/null 2>&1; then
    echo "错误: 找不到 cmake（需要 >= 3.21）"
    echo "或执行: ./scripts/setup_ubuntu2204.sh"
    exit 1
fi

echo ">>> arm-none-eabi-gcc: $(command -v arm-none-eabi-gcc)"
arm-none-eabi-gcc --version | head -1
echo ">>> cmake: $(cmake --version | head -1)"
echo ">>> ninja: $(ninja --version)"

cd "${TFM_ROOT}"

if [[ "${BUILD_TYPE}" == "test" ]]; then
    BUILD_LABEL="回归测试版"
    TEST_FLAGS=(-DTEST_S=ON -DTEST_NS=ON)
    LOG_FLAGS=(
        -DTFM_BL2_LOG_LEVEL=LOG_LEVEL_INFO
        -DTFM_SPM_LOG_LEVEL=LOG_LEVEL_INFO
        -DTFM_PARTITION_LOG_LEVEL=LOG_LEVEL_INFO
    )
else
    BUILD_LABEL="正式版"
    # 正式 SPE 不编安全侧测试分区；NS 仍是可烧、可跑的回归测试程序
    TEST_FLAGS=(-DTEST_S=OFF -DTEST_NS=ON)
    LOG_FLAGS=(
        -DTFM_BL2_LOG_LEVEL=LOG_LEVEL_ERROR
        -DTFM_SPM_LOG_LEVEL=LOG_LEVEL_ERROR
        -DTFM_PARTITION_LOG_LEVEL=LOG_LEVEL_ERROR
    )
fi

# Cortex-M33 单精度硬件 FPU；BL2 仍为 soft（TF-M 默认）
# 平台 cpuarch/config 已默认打开 FPU，这里再显式传入，避免旧缓存/导出不一致
FP_FLAGS=(
    -DCONFIG_TFM_ENABLE_FP=ON
    -DCONFIG_TFM_FP_ARCH=fpv5-sp-d16
    -DCONFIG_TFM_ENABLE_CP10CP11=ON
    -DCONFIG_TFM_FLOAT_ABI=hard
    -DCONFIG_TFM_LAZY_STACKING=ON
)

echo ">>> WORK_ROOT: ${WORK_ROOT}"
echo ">>> TFM_ROOT:  ${TFM_ROOT}"
echo ">>> TFM_TESTS: ${TFM_TESTS}"
echo ">>> 构建类型:  ${BUILD_LABEL}  (硬件浮点 ON, fpv5-sp-d16, TEST_S/NS=${TEST_FLAGS[*]})"

LIB_EXT_S="${TFM_ROOT}/build_s/build-spe/lib/ext"
LIB_EXT_NS="${TFM_ROOT}/build_ns/lib/ext"

# 测试版 <-> 正式版或 TEST_* 变化时清掉 SPE 缓存（须在离线检查之前）
STAMP="${TFM_ROOT}/build_s/.buildtfm_type"
STAMP_VAL="${BUILD_TYPE} ${TEST_FLAGS[*]} ${LOG_FLAGS[*]}"
if [[ -f "${STAMP}" ]] && [[ "$(cat "${STAMP}")" != "${STAMP_VAL}" ]]; then
    echo ">>> 构建配置已切换，清理 build_s"
    rm -rf "${TFM_ROOT}/build_s"
fi

# Python：用 python -m pip，避免拷贝来的 venv shebang 失效
# 脚本在仓库内时 WORK_ROOT 可能是 /，venv 放到 TF-M 根目录
VENV_DIR="${TFM_ROOT}/.venv"
if [[ ! -w "$(dirname "${VENV_DIR}")" ]]; then
    VENV_DIR="${HOME}/.tfm-venv"
fi
if [[ ! -x "${VENV_DIR}/bin/python" ]]; then
    echo ">>> 创建 Python venv: ${VENV_DIR}"
    if ! python3 -m venv "${VENV_DIR}"; then
        echo "错误: 创建 venv 失败。Debian/Ubuntu 请先执行:"
        echo "  sudo apt install -y python3-venv python3-pip"
        echo "或: ./scripts/setup_ubuntu2204.sh"
        exit 1
    fi
fi
# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"
export PATH="${VENV_DIR}/bin:${PATH}"
PYTHON="${VENV_DIR}/bin/python"
"${PYTHON}" -m pip install -q --upgrade pip setuptools wheel || true
if ! command -v hex_generation >/dev/null 2>&1; then
    "${PYTHON}" -m pip install -q -e "${TFM_ROOT}"
fi
command -v hex_generation >/dev/null || { echo "错误: hex_generation 未安装"; exit 1; }

# 有 lib/ext 就离线，没有就自动在线下载
OFFLINE=1
for lib in qcbor mcuboot cmsis t_cose tf-psa-crypto tf-m-extras; do
    [[ -d "${LIB_EXT_S}/${lib}-src" ]] || OFFLINE=0
done
[[ -f "${LIB_EXT_S}/qcbor-src/src/qcbor_encode.c" ]] || OFFLINE=0

if [[ "${OFFLINE}" -eq 1 ]]; then
    echo ">>> 离线模式"
    FETCH_OFF=(-DFETCHCONTENT_FULLY_DISCONNECTED=ON)
else
    echo ">>> 在线模式（首次会下载依赖，较慢）"
    FETCH_OFF=()
fi

# 关掉 tf-m-tests 版本检查（只打一次补丁）
CV="${TFM_TESTS}/cmake/check_version.cmake"
if [[ -f "${CV}" ]] && ! grep -q 'buildtfm: skip version check' "${CV}"; then
    sed -i '8i\return() # buildtfm: skip version check' "${CV}"
fi

echo ">>> build_s (${BUILD_LABEL})"
cmake -S "${TFM_TESTS}/tests_reg/spe" -B build_s -GNinja \
    -DCONFIG_TFM_SOURCE_PATH="${TFM_ROOT}" \
    -DTFM_PLATFORM=stm/stm32h573i_dk \
    -DTFM_TOOLCHAIN_FILE="${TFM_ROOT}/toolchain_GNUARM.cmake" \
    -DTFM_PSA_API=ON \
    -DTFM_ISOLATION_LEVEL=1 \
    "${TEST_FLAGS[@]}" \
    "${FP_FLAGS[@]}" \
    "${LOG_FLAGS[@]}" \
    "${FETCH_OFF[@]}"

ninja -C build_s install -j"$(nproc)"
mkdir -p "$(dirname "${STAMP}")"
echo "${STAMP_VAL}" > "${STAMP}"

SPE_CONFIG="${TFM_ROOT}/build_s/api_ns/cmake/spe_config.cmake"
[[ -f "${SPE_CONFIG}" ]] && \
    sed -i 's/^set(CHECK_TFM_TESTS_VERSION.*$/set(CHECK_TFM_TESTS_VERSION OFF)/' "${SPE_CONFIG}"

echo ">>> build_ns (回归测试程序，可烧录可跑)"
rm -rf build_ns
mkdir -p "${LIB_EXT_NS}"
for lib in qcbor t_cose; do
    [[ -d "${LIB_EXT_S}/${lib}-src" ]] && cp -a "${LIB_EXT_S}/${lib}-src" "${LIB_EXT_NS}/"
done

cmake -S "${TFM_TESTS}/tests_reg" -B build_ns -GNinja \
    -DCONFIG_SPE_PATH="${TFM_ROOT}/build_s/api_ns" \
    -DTFM_TOOLCHAIN_FILE="${TFM_ROOT}/build_s/api_ns/cmake/toolchain_ns_GNUARM.cmake" \
    "${FP_FLAGS[@]}" \
    "${FETCH_OFF[@]}"

ninja -C build_ns -j"$(nproc)"

echo ">>> postbuild"
cd build_s/api_ns
chmod +x postbuild.sh regression.sh TFM_UPDATE.sh preprocess.sh 2>/dev/null || true
./postbuild.sh "$(command -v arm-none-eabi-gcc)"

echo ""
grep -E '^boot=|^slot0=|^slot1=' TFM_UPDATE.sh || true
echo ""
echo "=== 编译完成（${BUILD_LABEL}，硬件浮点 ON）==="
echo "镜像:"
echo "  BL2:     ${TFM_ROOT}/build_s/api_ns/bin/bl2.bin"
echo "  SPE:     ${TFM_ROOT}/build_s/api_ns/bin/tfm_s_signed.bin"
echo "  NS 测试: ${TFM_ROOT}/build_ns/bin/tfm_ns_signed.bin  地址 0x0C088000"
echo "烧录: cd ${TFM_ROOT}/build_s/api_ns && ./regression.sh"
echo "      STM32_Programmer_CLI -c port=SWD mode=HotPlug -ob BOOT_UBE=0xB4"
echo "      ./TFM_UPDATE.sh"
echo "烧录后会上电自动跑回归测试（串口 115200 看 PASSED/FAILED）。"

if [[ -x "${TFM_ROOT}/packflash.sh" ]]; then
    echo ""
    "${TFM_ROOT}/packflash.sh" "${TFM_ROOT}"
fi
