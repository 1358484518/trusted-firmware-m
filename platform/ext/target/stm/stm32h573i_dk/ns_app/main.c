/*
 * SPDX-FileCopyrightText: Copyright The TrustedFirmware-M Contributors
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * CubeIDE：用这份替换 ns_app/main.c（或只把 huk_derive_demo_run() 放进你现有 main）。
 * 不要调用 SystemClock_Config / HAL_Init，不要用 IDE Download。
 * 签名后烧 NS 槽 0x0C088000，AP=1 HotPlug。UART ST-Link VCP 115200 8N1。
 */

#include "huk_derive_demo.h"

int main(void)
{
    (void)huk_derive_demo_run();

    for (;;) {
    }
}
