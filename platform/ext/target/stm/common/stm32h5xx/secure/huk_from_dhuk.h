/*
 * SPDX-FileCopyrightText: Copyright The TrustedFirmware-M Contributors
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#ifndef STM32H5_HUK_FROM_DHUK_H
#define STM32H5_HUK_FROM_DHUK_H

#include <stddef.h>
#include <stdint.h>
#include "tfm_plat_defs.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Derive a 256-bit software HUK by AES-256-ECB-encrypting a fixed label
 * with the SAES hardware DHUK (CRYP_KEYSEL_HW).
 *
 * DHUK itself never leaves the SAES key registers. The 32-byte result is
 * unique per device and stable across resets.
 */
enum tfm_plat_err_t stm32h5_huk_from_dhuk(uint8_t *out, size_t out_len,
                                          size_t *out_used);

#ifdef __cplusplus
}
#endif

#endif /* STM32H5_HUK_FROM_DHUK_H */
