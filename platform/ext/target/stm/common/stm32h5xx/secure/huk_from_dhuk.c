/*
 * SPDX-FileCopyrightText: Copyright The TrustedFirmware-M Contributors
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Load TF-M's software HUK from STM32H5 SAES DHUK. The hardware unique key
 * cannot be read; this encrypts a domain-separated label so Crypto/PS get a
 * per-chip 256-bit derive key without changing the rest of TF-M.
 */

#include <string.h>
#include "huk_from_dhuk.h"
#include "stm32hal.h"

#define STM32H5_HUK_BYTES 32U
#define STM32H5_DHUK_TIMEOUT_MS 1000U

/* Domain-separated plaintext. Do not use all-zero; keep it stable forever. */
static const uint8_t k_huk_label[STM32H5_HUK_BYTES] __attribute__((aligned(4))) = {
    'T', 'F', '-', 'M', ' ', 'H', '5', ' ',
    'D', 'H', 'U', 'K', ' ', 'H', 'U', 'K',
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
    0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
};

static void wipe_buf(uint8_t *buf, size_t len)
{
    volatile uint8_t *p = buf;

    while (len > 0U) {
        *p++ = 0U;
        len--;
    }
}

enum tfm_plat_err_t stm32h5_huk_from_dhuk(uint8_t *out, size_t out_len,
                                          size_t *out_used)
{
    CRYP_HandleTypeDef hcryp;
    uint8_t label[STM32H5_HUK_BYTES] __attribute__((aligned(4)));
    uint8_t cipher[STM32H5_HUK_BYTES] __attribute__((aligned(4)));
    enum tfm_plat_err_t err = TFM_PLAT_ERR_SYSTEM_ERR;

    if ((out == NULL) || (out_used == NULL) || (out_len < STM32H5_HUK_BYTES)) {
        return TFM_PLAT_ERR_INVALID_INPUT;
    }

    memset(&hcryp, 0, sizeof(hcryp));
    memcpy(label, k_huk_label, sizeof(label));
    memset(cipher, 0, sizeof(cipher));

    /* SAES DHUK is mixed with the selected EPOCH; keep it in the secure world. */
    __HAL_RCC_SBS_CLK_ENABLE();
    HAL_SBS_EPOCHSelection(SBS_EPOCH_SEL_SECURE);

    /* RNG is started in tfm_hal_isolation(); SAES still needs its AHB clock. */
    __HAL_RCC_SAES_CLK_ENABLE();

    hcryp.Instance = SAES;
    hcryp.Init.DataType = CRYP_NO_SWAP;
    hcryp.Init.KeySize = CRYP_KEYSIZE_256B;
    hcryp.Init.pKey = NULL;
    hcryp.Init.pInitVect = NULL;
    hcryp.Init.Algorithm = CRYP_AES_ECB;
    hcryp.Init.Header = NULL;
    hcryp.Init.HeaderSize = 0;
    hcryp.Init.DataWidthUnit = CRYP_DATAWIDTHUNIT_BYTE;
    hcryp.Init.HeaderWidthUnit = CRYP_HEADERWIDTHUNIT_BYTE;
    hcryp.Init.KeyIVConfigSkip = CRYP_KEYIVCONFIG_ALWAYS;
    hcryp.Init.KeyMode = CRYP_KEYMODE_NORMAL;
    hcryp.Init.KeySelect = CRYP_KEYSEL_HW;
    hcryp.Init.KeyProtection = CRYP_KEYPROT_ENABLE;

    if (HAL_CRYP_Init(&hcryp) != HAL_OK) {
        goto out;
    }

    if (HAL_CRYP_Encrypt(&hcryp,
                         (uint32_t *)label,
                         (uint16_t)STM32H5_HUK_BYTES,
                         (uint32_t *)cipher,
                         STM32H5_DHUK_TIMEOUT_MS) != HAL_OK) {
        (void)HAL_CRYP_DeInit(&hcryp);
        goto out;
    }

    (void)HAL_CRYP_DeInit(&hcryp);

    memcpy(out, cipher, STM32H5_HUK_BYTES);
    *out_used = STM32H5_HUK_BYTES;
    err = TFM_PLAT_ERR_SUCCESS;

out:
    wipe_buf(label, sizeof(label));
    wipe_buf(cipher, sizeof(cipher));
    if (err != TFM_PLAT_ERR_SUCCESS) {
        wipe_buf(out, out_len);
        if (out_used != NULL) {
            *out_used = 0;
        }
    }

    return err;
}
