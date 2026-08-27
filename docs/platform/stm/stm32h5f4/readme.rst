STM32H5F4
=========

TF-M platform ``stm/stm32h5f4`` is a BL2-first port from ``stm/stm32h573i_dk``.
There is no official Discovery kit in this tree; UART is USART1 PA9/PA10
until the real board pinout is filled in.

Chip vs H573
^^^^^^^^^^^^

=========== =================== ===================
Item        STM32H573           STM32H5F4
=========== =================== ===================
Manual      RM0481              RM0517
Flash       2 MB (1 MB x 2)     4 MB (2 MB x 2)
Sector      8 KB                8 KB
SRAM        640 KB (3 blocks)   1536 KB (5 blocks)
SRAM1       256 KB @ 0x20000000 256 KB @ 0x20000000
SRAM2       64 KB  @ 0x20040000 128 KB @ 0x20040000
SRAM3       320 KB @ 0x20050000 384 KB @ 0x20060000
SRAM4       --                  384 KB @ 0x200C0000
SRAM5       --                  384 KB @ 0x20120000
Secure alias +0x10000000        same
CPU         M33 + TrustZone     same, 250 MHz
=========== =================== ===================

How to port BL2 (order)
^^^^^^^^^^^^^^^^^^^^^^^

Do **not** start with SPE/NS. BL2 must run, print, and jump to a vector at
``S_CODE_START`` before the rest of TF-M is useful.

1. **CMSIS device**

   Add ``stm32h5f4xx.h`` and compile with ``-DSTM32H5F4xx``
   (``cpuarch.cmake``). HAL in ``stm32h5xx`` already has H5F4 ifdefs.

2. **Flash map** (``include/flash_layout.h``)

   Keep the H573 *offsets* for bring-up so BL2 stays at ``0x0C010000``:

   * ``FLASH_B_SIZE = 0x200000`` (2 MB/bank)
   * ``FLASH_TOTAL_SIZE = 4 MB``
   * scratch / BL2 / OTP / NV / PS / ITS / S+NS slots unchanged
   * extra 2 MB left unused until SPE/NS grow

   Sector size stays 8 KB. WRP group stays 32 KB. Bank page count in
   ``low_level_security.c`` must be **256** (``PAGE_MAX_NUMBER_IN_BANK 0xFF``),
   not 128.

3. **RAM map** (``include/region_defs.h``)

   BL2 data lives in **SRAM2** (secure alias ``0x30040000``). On H5F4 SRAM2
   is 128 KB, so shared measurement data moves to ``0x3005FC00``.
   MPU ``BL2_SRAM_AREA_END`` must cover SRAM5.

4. **Startup**

   H5F4 IRQ 0–130 match H573. IRQs 131–160 are extra (I3C2, JPEG, more
   GPDMA, …). ``startup_stm32h5xx_bl2.c`` includes those vectors.

5. **Clock / UART** (board bring-up)

   Reuse H573 HAL clock in ``boot_hal_bl2.c`` only if HSE frequency matches.
   Edit ``include/board.h`` for the real USART pins.

6. **Option bytes / RSS**

   ``regression.sh``, HDP, WRP, ``BOOT_UBE=0xB4`` (OEM-iRoT) are the same
   *idea* as H573. Confirm RSS/system-flash addresses in RM0517; the H573
   values in ``flash_layout.h`` are a placeholder.

7. **Build BL2**

   Use official Arm GNU Toolchain 13.3.Rel1 (not distro ``gcc-arm-none-eabi``).

   .. code-block:: bash

      export PATH="<arm-gnu-13.3>/bin:$PATH"
      cmake -S <tf-m-tests>/tests_reg/spe -B build_s -GNinja \
            -DCONFIG_TFM_SOURCE_PATH=<tf-m> \
            -DTFM_PLATFORM=stm/stm32h5f4 \
            -DTFM_TOOLCHAIN_FILE=<tf-m>/toolchain_GNUARM.cmake \
            -DTFM_PSA_API=ON -DTFM_ISOLATION_LEVEL=1 \
            -DTEST_S=OFF -DTEST_NS=OFF \
            -DCONFIG_TFM_ENABLE_FP=ON -DCONFIG_TFM_FP_ARCH=fpv5-sp-d16 \
            -DCONFIG_TFM_ENABLE_CP10CP11=ON -DCONFIG_TFM_FLOAT_ABI=hard \
            -DCONFIG_TFM_LAZY_STACKING=ON
      ninja -C build_s install

   Artifact: ``build_s/api_ns/bin/bl2.bin`` (linked at ``0x0C010000``).
   ``TFM_UPDATE.sh`` programs the boot script at ``0x0C00E000``.

8. **On-target BL2 checklist**

   * ST-Link VCP 115200: BL2 banner, then “Jumping to SPE” or a verify
     error if SPE is empty.
   * Option bytes: TZEN, SECWM covering BL2+SPE, SRAM2 ECC on.
   * Do not enable product-state CLOSED until BL2 is stable.

Next (not in this step)
^^^^^^^^^^^^^^^^^^^^^^^

* SPE GTZC/SAU for SRAM3–SRAM5
* Enlarge S/NS slots into the extra 2 MB
* Board-specific clock and UART
* NS image and regression tests

-------------

*Copyright (c) 2026. All rights reserved.*
*SPDX-License-Identifier: BSD-3-Clause*
