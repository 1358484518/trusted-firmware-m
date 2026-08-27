#!/usr/bin/env bash
# Ubuntu 22.04 主机：安装 TF-M / STM32H573 GNUARM 编译依赖和官方工具链。
# 不要用 apt 的 gcc-arm-none-eabi：TF-M config/check_config.cmake 会拒绝部分发行版版本。
#
# SPDX-License-Identifier: BSD-3-Clause

set -euo pipefail

TOOLCHAIN_VER="13.3.rel1"
TOOLCHAIN_NAME="arm-gnu-toolchain-${TOOLCHAIN_VER}-x86_64-arm-none-eabi"
TOOLCHAIN_TAR="${TOOLCHAIN_NAME}.tar.xz"
TOOLCHAIN_URL="https://developer.arm.com/-/media/Files/downloads/gnu/${TOOLCHAIN_VER}/binrel/${TOOLCHAIN_TAR}"
PREFIX="${GNUARM_PREFIX:-${HOME}/toolchains}"

echo ">>> 安装 Ubuntu 22.04 编译依赖"
if command -v sudo >/dev/null 2>&1 && [[ "$(id -u)" -ne 0 ]]; then
    SUDO="sudo"
else
    SUDO=""
fi

${SUDO} apt-get update -qq
${SUDO} DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    git curl wget build-essential libssl-dev \
    python3 python3-pip python3-venv python3-dev \
    cmake ninja-build make

echo ">>> cmake $(cmake --version | head -1)"
echo ">>> python3 $(python3 --version)"
echo ">>> ninja $(ninja --version)"

mkdir -p "${PREFIX}"
if [[ ! -x "${PREFIX}/${TOOLCHAIN_NAME}/bin/arm-none-eabi-gcc" ]]; then
    echo ">>> 下载官方 GNU Arm ${TOOLCHAIN_VER} -> ${PREFIX}"
    tmp="$(mktemp -d)"
    curl -L --fail -o "${tmp}/${TOOLCHAIN_TAR}" "${TOOLCHAIN_URL}"
    tar -C "${PREFIX}" -xf "${tmp}/${TOOLCHAIN_TAR}"
    rm -rf "${tmp}"
else
    echo ">>> 已存在 ${PREFIX}/${TOOLCHAIN_NAME}"
fi

GCC="${PREFIX}/${TOOLCHAIN_NAME}/bin/arm-none-eabi-gcc"
[[ -x "${GCC}" ]] || { echo "错误: 未找到 ${GCC}"; exit 1; }
echo ">>> $($GCC --version | head -1)"
echo ""
echo "把下面这行加到 ~/.bashrc，或在编译前 export:"
echo "  export PATH=\"${PREFIX}/${TOOLCHAIN_NAME}/bin:\$PATH\""
echo ""
echo "然后在 TF-M 仓库根目录执行:"
echo "  ./buildtfm.sh test"
