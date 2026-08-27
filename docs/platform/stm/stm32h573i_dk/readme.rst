-------
STM32H5
-------

TF-M is supported on STM32H5 family

https://www.st.com/en/microcontrollers-microprocessors/stm32h5-series.html


Directory content
^^^^^^^^^^^^^^^^^

- stm/common/stm32h5xx/stm32h5xx_hal:
   Content from https://github.com/STMicroelectronics/stm32h5xx_hal_driver

- stm/common/stm32h5xx/Device:
   Content from https://github.com/STMicroelectronics/cmsis_device_h5

- stm/common/stm32h5xx/bl2:
   stm32h5xx bl2 code specific from https://github.com/STMicroelectronics/STM32CubeH5.git (Projects/STM32H573I_DK/Applications/TFM)

- stm/common/stm32h5xx/secure:
   stm32h5xx Secure porting adaptation from https://github.com/STMicroelectronics/STM32CubeH5.git (Projects/STM32H573I_DK/Applications/TFM)

- stm/common/stm32h5xx/boards:
   Adaptation and tools specific to stm32 board using stm32h5xx soc from https://github.com/STMicroelectronics/STM32CubeH5.git (Projects/STM32H573I_DK/Applications/TFM)

- stm/common/stm32h5xx/CMSIS_Driver:
   Flash and uart driver for stm32h5xx platform

- stm/common/stm32h5xx/Native_Driver:
   Random generator and tickless implementation

Specific Software Requirements
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

STM32_Programmer_CLI is required.(see https://www.st.com/en/development-tools/stm32cubeprog.html)

Limitations to Consider When Using the Platform
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
MPU and ICACHE disabled in bl2 boot stage


STM32H573I_DK
^^^^^^^^^^^^^^^

Discovery kit for IoT node with STM32H5 series
https://www.st.com/en/evaluation-tools/stm32h573i-dk.html

Configuration and Build
"""""""""""""""""""""""

GNUARM/ARMCLANG/IARARM compilation is available for this target.
and build the selected configuration as follow.

Hardware FPU is enabled by default (``CONFIG_TFM_ENABLE_FP=ON``,
``-mfloat-abi=hard -mfpu=fpv5-sp-d16``). SPE and NSPE must use the same
FP ABI. Rebuild the SPE after this option changes so NSACR/CP10/CP11 and
FPU context switching stay consistent.

Ubuntu 22.04 GNUARM one-command build (regression tests)
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

Do not use the distro ``gcc-arm-none-eabi`` package. TF-M rejects some
Ubuntu compiler version strings. Install the official Arm GNU Toolchain
13.3.Rel1 and host packages, then build SPE+NS regression tests:

.. code-block:: bash

    ./scripts/setup_ubuntu2204.sh
    export PATH="$HOME/toolchains/arm-gnu-toolchain-13.3.rel1-x86_64-arm-none-eabi/bin:$PATH"
    ./buildtfm.sh test

``./buildtfm.sh test`` sets ``TEST_S=ON`` and ``TEST_NS=ON`` (Isolation
Level 1, PSA API). Artifacts:

- ``build_s/api_ns/bin/bl2.bin``
- ``build_s/api_ns/bin/tfm_s_signed.bin``
- ``build_ns/bin/tfm_ns_signed.bin`` (NS regression image, ``0x0C088000``)

``./buildtfm.sh prod`` keeps NS tests but omits Secure test partitions.

The build configuration for TF-M is provided to the build system using command
line arguments. Required arguments are noted below.

The following instructions build multi-core TF-M with regression test suites
in Isolation Level 1.

In common STM (``platform\ext\target\stm\common\build_stm``)
There are scripts that help users to build the TF-M project on all STM platforms

.. code-block:: bash


    cd <TF-M base folder>
    cd <trusted-firmware-m folder>

    git clone https://git.trustedfirmware.org/TF-M/tf-m-tests.git
    git checkout <recommended tf-m-tests commit> (..\trusted-firmware-m\lib\ext\tf-m-tests\version.txt)

    mkdir build_s && cd build_s

    cmake -S /../tf-m-tests/tests_reg/spe -B . -GNinja -DTFM_PLATFORM=stm/stm32h573i_dk
         -DTFM_TOOLCHAIN_FILE= /../toolchain_ARMCLANG.cmake
         -DCONFIG_TFM_SOURCE_PATH= /../trusted-firmware-m
         -DTFM_PSA_API=ON -DTFM_ISOLATION_LEVEL=1
         -DTEST_S=ON -DTEST_NS=ON

    ninja -C . install -j 8

    cd <trusted-firmware-m folder>
    mkdir build_ns && cd build_ns
    cmake -S /../trusted-firmware-m  /../tf-m-tests/tests_reg -B . -GNinja
         -DCONFIG_SPE_PATH= /../build_s/api_ns -DTFM_TOOLCHAIN_FILE= /../build_s/api_ns/cmake/toolchain_ns_ARMCLANG.cmake

    ninja -C . -j 8

The following instructions build multi-core TF-M with PSA API test suite for
the attestation service in Isolation Level 1 on Linux.

.. code-block:: bash


    cd <TF-M base folder>
    cd <trusted-firmware-m folder>

    git clone https://git.trustedfirmware.org/TF-M/tf-m-tests.git
    git checkout <recommended tf-m-tests commit> (..\trusted-firmware-m\lib\ext\tf-m-tests\version.txt)

    mkdir build_s && cd build_s

    cmake -S /../tf-m-tests/tests_psa_arch/spe -B . -GNinja -DTFM_PLATFORM=stm/stm32h573i_dk
         -DTFM_TOOLCHAIN_FILE= /../toolchain_ARMCLANG.cmake
         -DCONFIG_TFM_SOURCE_PATH= /../trusted-firmware-m
         -DTFM_PSA_API=ON -DTFM_ISOLATION_LEVEL=1
         -DTEST_PSA_API=INITIAL_ATTESTATION

    ninja -C . install -j 8

    cd <trusted-firmware-m folder>
    mkdir build_ns && cd build_ns
    cmake -S /../trusted-firmware-m  /../tf-m-tests/tests_psa_arch -B . -GNinja
         -DCONFIG_SPE_PATH= /../build_s/api_ns -DTFM_TOOLCHAIN_FILE= /../build_s/api_ns/cmake/toolchain_ns_ARMCLANG.cmake

    ninja -C . -j 8


Write software on target
^^^^^^^^^^^^^^^^^^^^^^^^
In build folder:

  - ``postbuild.sh``: Updates regression.sh and TFM_UPDATE.sh scripts according to flash_layout.h
  - ``regression.sh``: Sets platform option bytes config and erase platform
  - ``TFM_UPDATE.sh``: Writes bl2, secure, and non secure image in target


Connect board to USB and Execute the 3 scripts in following order to update platform:
postbuild.sh, regression.sh, TFM_UPDATE.sh

The virtual com port from STLINK is used for TFM log and serial port configuration should be:

  - Baud rate    = 115200
  - Data         = 8 bits
  - Parity       = none
  - Stop         = 1 bit
  - Flow control = none

-------------

*Copyright (c) 2023, STMicroelectronics. All rights reserved.*
*SPDX-License-Identifier: BSD-3-Clause*
