/*
 * SPDX-FileCopyrightText: Copyright The TrustedFirmware-M Contributors
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * 用法（CubeIDE）：
 *   1. 把 huk_derive_demo.c / huk_derive_demo.h 放进 STM32CubeIDE/ns_app
 *   2. 把本文件里的 huk_derive_demo_run() 接到 ns_app/main.c
 *   3. 不要 SystemClock_Config / HAL_Init / IDE Download
 *   4. 正常签名烧到 0x0C088000，串口 115200 8N1
 *
 * 用法（Makefile NS）：把 huk_derive_demo.c 编进 NS，main 里调用即可。
 */

#ifndef HUK_DERIVE_DEMO_H
#define HUK_DERIVE_DEMO_H

#ifdef __cplusplus
extern "C" {
#endif

/** @return 0 成功，其它为 PSA 错误码（负值） */
int huk_derive_demo_run(void);

#ifdef __cplusplus
}
#endif

#endif /* HUK_DERIVE_DEMO_H */
