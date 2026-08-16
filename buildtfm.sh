#!/usr/bin/env bash
# STM32H573I-DK  TF-M 一键编译（硬件浮点）
#
# 用法:
#   ./buildtfm.sh              # 交互选择 测试版 / 正式版
#   ./buildtfm.sh test         # 测试版：TEST_S/NS 回归，INFO 日志
#   ./buildtfm.sh prod         # 正式版：同样编可烧可跑的 NS 测试程序，ERROR 日志
#   ./buildtfm.sh -h
#
# SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

usage() {
    cat <<'EOF'
STM32H573I-DK TF-M 编译脚本（已启用硬件浮点 FPv5-SP-D16）

用法:
  ./buildtfm.sh              交互选择构建类型
  ./buildtfm.sh test         测试版（TEST_S/NS 回归，INFO 日志）
  ./buildtfm.sh prod         正式版（同样出可烧可跑的 NS 测试程序，ERROR 日志）

别名: test|debug|回归    prod|release|formal|正式
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
    echo "请选择构建类型:"
    echo "  1) 测试版  — TEST_S / TEST_NS 全开，INFO 日志，NS 测试可烧可跑"
    echo "  2) 正式版  — 同样编 NS 测试程序（可烧可跑），日志收到 ERROR"
    echo -n "输入 1 或 2: "
    read -r choice
    case "${choice}" in
        1) BUILD_TYPE="test" ;;
        2) BUILD_TYPE="prod" ;;
        *) echo "无效选择"; exit 2 ;;
    esac
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 支持两种目录布局:
#   A) 脚本在仓库外:  WORK/buildtfm.sh  WORK/trusted-firmware-m  WORK/tf-m-tests
#   B) 脚本在仓库内:  TF-M/buildtfm.sh  上一级或旁路有 tf-m-tests
if [[ -f "${SCRIPT_DIR}/trusted-firmware-m/CMakeLists.txt" ]]; then
    WORK_ROOT="${SCRIPT_DIR}"
    TFM_ROOT="${WORK_ROOT}/trusted-firmware-m"
    TFM_TESTS="${WORK_ROOT}/tf-m-tests"
elif [[ -f "${SCRIPT_DIR}/CMakeLists.txt" && -d "${SCRIPT_DIR}/secure_fw" ]]; then
    TFM_ROOT="${SCRIPT_DIR}"
    WORK_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
    if [[ -f "${WORK_ROOT}/tf-m-tests/tests_reg/spe/CMakeLists.txt" ]]; then
        TFM_TESTS="${WORK_ROOT}/tf-m-tests"
    elif [[ -f "${TFM_ROOT}/../tf-m-tests/tests_reg/spe/CMakeLists.txt" ]]; then
        TFM_TESTS="$(cd "${TFM_ROOT}/../tf-m-tests" && pwd)"
    else
        TFM_TESTS="${WORK_ROOT}/tf-m-tests"
    fi
else
    echo "错误: 找不到 TF-M 源码（请把脚本放在仓库根目录或与仓库同级）"
    exit 1
fi

[[ -f "${TFM_ROOT}/CMakeLists.txt" ]] || { echo "错误: 缺少 ${TFM_ROOT}"; exit 1; }
[[ -f "${TFM_TESTS}/tests_reg/spe/CMakeLists.txt" ]] || { echo "错误: 缺少 ${TFM_TESTS}"; exit 1; }

cd "${TFM_ROOT}"

if [[ "${BUILD_TYPE}" == "test" ]]; then
    BUILD_LABEL="测试版"
    TEST_FLAGS=(-DTEST_S=ON -DTEST_NS=ON)
    LOG_FLAGS=(
        -DTFM_BL2_LOG_LEVEL=LOG_LEVEL_INFO
        -DTFM_SPM_LOG_LEVEL=LOG_LEVEL_INFO
        -DTFM_PARTITION_LOG_LEVEL=LOG_LEVEL_INFO
    )
else
    BUILD_LABEL="正式版"
    # 正式版也要出能下载、能跑的 NS 测试程序，只把日志收到 ERROR
    TEST_FLAGS=(-DTEST_S=ON -DTEST_NS=ON)
    LOG_FLAGS=(
        -DTFM_BL2_LOG_LEVEL=LOG_LEVEL_ERROR
        -DTFM_SPM_LOG_LEVEL=LOG_LEVEL_ERROR
        -DTFM_PARTITION_LOG_LEVEL=LOG_LEVEL_ERROR
    )
fi

# Cortex-M33 单精度硬件 FPU；BL2 仍为 soft（TF-M 默认）
FP_FLAGS=(
    -DCONFIG_TFM_ENABLE_FP=ON
    -DCONFIG_TFM_FP_ARCH=fpv5-sp-d16
)

echo ">>> WORK_ROOT: ${WORK_ROOT}"
echo ">>> TFM_ROOT:  ${TFM_ROOT}"
echo ">>> TFM_TESTS: ${TFM_TESTS}"
echo ">>> 构建类型:  ${BUILD_LABEL}  (硬件浮点 ON, fpv5-sp-d16)"

LIB_EXT_S="${TFM_ROOT}/build_s/build-spe/lib/ext"
LIB_EXT_NS="${TFM_ROOT}/build_ns/lib/ext"

# Python：用 python -m pip，避免拷贝来的 venv shebang 失效
VENV_DIR="${WORK_ROOT}/.venv"
if [[ ! -x "${VENV_DIR}/bin/python" ]]; then
    echo ">>> 创建 Python venv: ${VENV_DIR}"
    if ! python3 -m venv "${VENV_DIR}"; then
        echo "错误: 创建 venv 失败。Debian/Ubuntu 请先执行:"
        echo "  apt install -y python3-venv python3-pip"
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

# 测试版 <-> 正式版切换时清掉 SPE 缓存，避免 TEST_* 残留
STAMP="${TFM_ROOT}/build_s/.buildtfm_type"
if [[ -f "${STAMP}" ]] && [[ "$(cat "${STAMP}")" != "${BUILD_TYPE}" ]]; then
    echo ">>> 构建类型已切换，清理 build_s"
    rm -rf "${TFM_ROOT}/build_s"
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
echo "${BUILD_TYPE}" > "${STAMP}"

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
echo "烧录: cd ${TFM_ROOT}/build_s/api_ns && ./regression.sh"
echo "      STM32_Programmer_CLI -c port=SWD mode=HotPlug -ob BOOT_UBE=0xB4"
echo "      ./TFM_UPDATE.sh"
echo "NS 测试程序: ${TFM_ROOT}/build_ns/bin/tfm_ns_signed.bin  地址 0x0C088000"
echo "烧录后会上电自动跑回归测试（串口 115200 看 PASSED/FAILED）。"
