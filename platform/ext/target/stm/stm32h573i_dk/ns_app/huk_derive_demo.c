/*
 * SPDX-FileCopyrightText: Copyright The TrustedFirmware-M Contributors
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * NS 示例：用内置 HUK 做 HKDF，派生钥匙留在 SPE，再 AES-GCM 加解密。
 *
 * - 不调用 output_bytes，不给派生钥匙加 EXPORT
 * - 导出 HUK / 派生钥匙都应失败
 * - 密文可当“这块板”的指纹：同板每次相同，换板不同
 *   （因为 SPE 已用 SAES DHUK 生成 per-chip HUK）
 */

#include "huk_derive_demo.h"

#include <stdio.h>
#include <string.h>

#include "psa/crypto.h"
#include "tfm_builtin_key_ids.h"

#define DEMO_INFO        ((const uint8_t *)"ns-huk-demo")
#define DEMO_INFO_LEN    (sizeof("ns-huk-demo") - 1U)
#define DEMO_PLAINTEXT   "hello-huk"
#define DEMO_PT_LEN      (sizeof(DEMO_PLAINTEXT) - 1U)
#define DEMO_NONCE_LEN   12U
#define DEMO_KEY_BITS    256U
#define DEMO_CT_MAX      (DEMO_PT_LEN + 16U)

static const uint8_t k_fixed_nonce[DEMO_NONCE_LEN] = {
    0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5,
    0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xAB,
};

static void print_hex(const char *title, const uint8_t *buf, size_t len)
{
    size_t i;

    printf("%s", title);
    for (i = 0; i < len; i++) {
        printf("%02x", buf[i]);
    }
    printf("\r\n");
}

static int fail_at(const char *what, psa_status_t status)
{
    printf("FAIL %s: %d\r\n", what, (int)status);
    return (int)status;
}

int huk_derive_demo_run(void)
{
    psa_status_t status;
    psa_key_id_t app_key = PSA_KEY_ID_NULL;
    psa_key_attributes_t attr = PSA_KEY_ATTRIBUTES_INIT;
    psa_key_derivation_operation_t op = PSA_KEY_DERIVATION_OPERATION_INIT;
    uint8_t dump[16];
    size_t dump_len = 0;
    uint8_t ciphertext[DEMO_CT_MAX];
    uint8_t plaintext[DEMO_PT_LEN];
    size_t ciphertext_len = 0;
    size_t plaintext_len = 0;

    printf("\r\n=== HUK derive demo ===\r\n");

    status = psa_crypto_init();
    if (status != PSA_SUCCESS) {
        return fail_at("psa_crypto_init", status);
    }

    status = psa_export_key(TFM_BUILTIN_KEY_ID_HUK, dump, sizeof(dump), &dump_len);
    printf("export HUK: %d (expect not permitted / %d)\r\n",
           (int)status, (int)PSA_ERROR_NOT_PERMITTED);
    if (status == PSA_SUCCESS) {
        return fail_at("HUK must not be exportable", PSA_ERROR_GENERIC_ERROR);
    }

    status = psa_key_derivation_setup(&op, PSA_ALG_HKDF(PSA_ALG_SHA_256));
    if (status != PSA_SUCCESS) {
        return fail_at("derivation setup", status);
    }

    status = psa_key_derivation_input_key(&op, PSA_KEY_DERIVATION_INPUT_SECRET,
                                          TFM_BUILTIN_KEY_ID_HUK);
    if (status != PSA_SUCCESS) {
        (void)psa_key_derivation_abort(&op);
        return fail_at("input HUK", status);
    }

    status = psa_key_derivation_input_bytes(&op, PSA_KEY_DERIVATION_INPUT_INFO,
                                            DEMO_INFO, DEMO_INFO_LEN);
    if (status != PSA_SUCCESS) {
        (void)psa_key_derivation_abort(&op);
        return fail_at("input info", status);
    }

    /* 派生钥匙只给加解密用，不要 EXPORT */
    psa_set_key_usage_flags(&attr, PSA_KEY_USAGE_ENCRYPT | PSA_KEY_USAGE_DECRYPT);
    psa_set_key_algorithm(&attr, PSA_ALG_GCM);
    psa_set_key_type(&attr, PSA_KEY_TYPE_AES);
    psa_set_key_bits(&attr, DEMO_KEY_BITS);
    psa_set_key_lifetime(&attr, PSA_KEY_LIFETIME_VOLATILE);

    status = psa_key_derivation_output_key(&attr, &op, &app_key);
    (void)psa_key_derivation_abort(&op);
    psa_reset_key_attributes(&attr);
    if (status != PSA_SUCCESS) {
        return fail_at("output_key", status);
    }
    printf("derived AES-256 key id=0x%08x (in SPE, not exported)\r\n",
           (unsigned int)app_key);

    status = psa_export_key(app_key, dump, sizeof(dump), &dump_len);
    printf("export derived key: %d (expect not permitted / %d)\r\n",
           (int)status, (int)PSA_ERROR_NOT_PERMITTED);
    if (status == PSA_SUCCESS) {
        (void)psa_destroy_key(app_key);
        return fail_at("derived key must not be exportable", PSA_ERROR_GENERIC_ERROR);
    }

    status = psa_aead_encrypt(app_key, PSA_ALG_GCM,
                              k_fixed_nonce, sizeof(k_fixed_nonce),
                              NULL, 0,
                              (const uint8_t *)DEMO_PLAINTEXT, DEMO_PT_LEN,
                              ciphertext, sizeof(ciphertext), &ciphertext_len);
    if (status != PSA_SUCCESS) {
        (void)psa_destroy_key(app_key);
        return fail_at("aead encrypt", status);
    }

    print_hex("chip fingerprint (GCM ct): ", ciphertext, ciphertext_len);

    status = psa_aead_decrypt(app_key, PSA_ALG_GCM,
                              k_fixed_nonce, sizeof(k_fixed_nonce),
                              NULL, 0,
                              ciphertext, ciphertext_len,
                              plaintext, sizeof(plaintext), &plaintext_len);
    (void)psa_destroy_key(app_key);
    if (status != PSA_SUCCESS) {
        return fail_at("aead decrypt", status);
    }

    if ((plaintext_len != DEMO_PT_LEN) ||
        (memcmp(plaintext, DEMO_PLAINTEXT, DEMO_PT_LEN) != 0)) {
        printf("FAIL plaintext mismatch\r\n");
        return (int)PSA_ERROR_INVALID_SIGNATURE;
    }

    printf("decrypt ok: %.*s\r\n", (int)plaintext_len, plaintext);
    printf("=== HUK derive demo PASSED ===\r\n");
    printf("Same board + same firmware => same fingerprint.\r\n");
    printf("Another H573-DK => different fingerprint.\r\n");

    return 0;
}
