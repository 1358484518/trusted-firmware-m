#-------------------------------------------------------------------------------
# SPDX-FileCopyrightText: Copyright The TrustedFirmware-M Contributors
#
# SPDX-License-Identifier: BSD-3-Clause
#
#-------------------------------------------------------------------------------

# This file is consumed by NS test build to get test configurations
set(TEST_NS_ATTESTATION        ON     CACHE BOOL "Whether to build NS regression Attestation tests")
set(TEST_NS_CRYPTO             ON     CACHE BOOL "Whether to build NS regression Crypto tests")
set(TEST_NS_FLIH_IRQ           OFF    CACHE BOOL "Whether to build NS regression First-Level Interrupt Handling tests")
set(TEST_NS_FPU                OFF    CACHE BOOL "Whether to build NS regression FPU tests")
set(TEST_NS_FWU                ON     CACHE BOOL "Whether to build NS regression FWU tests")
set(TEST_NS_IPC                OFF    CACHE BOOL "Whether to build NS regression IPC tests")
set(TEST_NS_ITS                ON     CACHE BOOL "Whether to build NS regression ITS tests")
set(TEST_NS_MANAGE_NSID        OFF    CACHE BOOL "Whether to build NS regression NSID management tests")
set(TEST_NS_MULTI_CORE         OFF    CACHE BOOL "Whether to build NS regression multi-core tests")
set(TEST_NS_PLATFORM           ON     CACHE BOOL "Whether to build NS regression Platform tests")
set(TEST_NS_PS                 ON     CACHE BOOL "Whether to build NS regression PS tests")
set(TEST_NS_QCBOR              OFF    CACHE BOOL "Whether to build NS regression QCBOR tests")
set(TEST_NS_SFN_BACKEND        ON     CACHE BOOL "Whether to build NS regression SFN backend tests")
set(TEST_NS_SLIH_IRQ           OFF    CACHE BOOL "Whether to build NS regression Second-Level Interrupt Handling tests")
set(TEST_NS_T_COSE             OFF    CACHE BOOL "Whether to build NS regression t_cose tests")
set(TFM_NS_REG_TEST "ON")
set(EXTRA_NS_TEST_SUITE_PATH ""  CACHE PATH "List of extra non-secure test suites directories. An extra test suite folder contains source code, CMakeLists.txt and cmake configuration file")


# Testing related options exported by TF-M

set(ATTEST_KEY_BITS                        256                  CACHE STRING "The size of the initial attestation key in bits")
set(SYMMETRIC_INITIAL_ATTESTATION          OFF    CACHE BOOL   "Use symmetric crypto for initial attestation")

set(TFM_FWU_BOOTLOADER_LIB                 mcuboot           CACHE STRING "Bootloader configure file for Firmware Update partition")

set(PLATFORM_MULTI_CORE_TEST_SUPPORT        CACHE STRING "Whether platform has multi core tests support")
