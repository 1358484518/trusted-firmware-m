/*
 * SPDX-FileCopyrightText: Copyright The TrustedFirmware-M Contributors
 *
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * 密钥派生流程测试（NS）。串口 115200 按步骤打印。
 * CubeIDE：把本文件编进 ns_app，main 里调 kdf_flow_test_run()。
 *
 * 流程：
 *   HUK(SPE, DHUK 派生，NS 看不到明文)
 *     --HKDF-SHA256 + info-->
 *   AES-256 钥匙(只在 SPE 钥匙槽)
 *     --AES-GCM-->
 *   密文回到 NS
 */

#include "kdf_flow_test.h"

#include <stdio.h>
#include <string.h>

#include "psa/crypto.h"
#include "tfm_builtin_key_ids.h"

#define KDF_INFO      ((const uint8_t *)"kdf-flow-test")
#define KDF_INFO_LEN  (sizeof("kdf-flow-test") - 1U)
#define MSG           "flow-ok"
#define MSG_LEN       (sizeof(MSG) - 1U)

static const uint8_t nonce[12] = {
    0x10, 0x11, 0x12, 0x13, 0x14, 0x15,
    0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B,
};

static void hexline(const char *tag, const uint8_t *p, size_t n)
{
    size_t i;

    printf("    %s", tag);
    for (i = 0; i < n; i++) {
        printf("%02x", p[i]);
    }
    printf("\r\n");
}

static int die(const char *step, psa_status_t st)
{
    printf("[X] %s  status=%d\r\n", step, (int)st);
    return (int)st;
}

int kdf_flow_test_run(void)
{
    psa_status_t st;
    psa_key_derivation_operation_t op = PSA_KEY_DERIVATION_OPERATION_INIT;
    psa_key_attributes_t attr = PSA_KEY_ATTRIBUTES_INIT;
    psa_key_id_t kid = PSA_KEY_ID_NULL;
    uint8_t tmp[16];
    size_t tmp_len = 0;
    uint8_t ct[MSG_LEN + 16];
    uint8_t pt[MSG_LEN];
    size_t ct_len = 0;
    size_t pt_len = 0;

    printf("\r\n======== 密钥派生流程测试 ========\r\n");

    printf("[1] psa_crypto_init()\r\n");
    st = psa_crypto_init();
    if (st != PSA_SUCCESS) {
        return die("init", st);
    }
    printf("    ok\r\n");

    printf("[2] 尝试导出 HUK（应失败，NS 拿不到根钥）\r\n");
    st = psa_export_key(TFM_BUILTIN_KEY_ID_HUK, tmp, sizeof(tmp), &tmp_len);
    printf("    export HUK status=%d  (期望 %d NOT_PERMITTED)\r\n",
           (int)st, (int)PSA_ERROR_NOT_PERMITTED);

    printf("[3] HKDF-SHA256 setup\r\n");
    st = psa_key_derivation_setup(&op, PSA_ALG_HKDF(PSA_ALG_SHA_256));
    if (st != PSA_SUCCESS) {
        return die("setup", st);
    }
    printf("    ok\r\n");

    printf("[4] input_key SECRET = TFM_BUILTIN_KEY_ID_HUK\r\n");
    printf("    SPE 内部：DHUK -> 软件 HUK -> 再按 NS 调用者 HKDF 一次\r\n");
    st = psa_key_derivation_input_key(&op, PSA_KEY_DERIVATION_INPUT_SECRET,
                                      TFM_BUILTIN_KEY_ID_HUK);
    if (st != PSA_SUCCESS) {
        (void)psa_key_derivation_abort(&op);
        return die("input_key", st);
    }
    printf("    ok\r\n");

    printf("[5] input_bytes INFO = \"kdf-flow-test\"  （换 info 会得到另一把钥匙）\r\n");
    st = psa_key_derivation_input_bytes(&op, PSA_KEY_DERIVATION_INPUT_INFO,
                                        KDF_INFO, KDF_INFO_LEN);
    if (st != PSA_SUCCESS) {
        (void)psa_key_derivation_abort(&op);
        return die("input_info", st);
    }
    printf("    ok\r\n");

    printf("[6] output_key -> AES-256-GCM，usage=ENCRYPT|DECRYPT，不要 EXPORT\r\n");
    psa_set_key_usage_flags(&attr, PSA_KEY_USAGE_ENCRYPT | PSA_KEY_USAGE_DECRYPT);
    psa_set_key_algorithm(&attr, PSA_ALG_GCM);
    psa_set_key_type(&attr, PSA_KEY_TYPE_AES);
    psa_set_key_bits(&attr, 256);
    psa_set_key_lifetime(&attr, PSA_KEY_LIFETIME_VOLATILE);
    st = psa_key_derivation_output_key(&attr, &op, &kid);
    (void)psa_key_derivation_abort(&op);
    psa_reset_key_attributes(&attr);
    if (st != PSA_SUCCESS) {
        return die("output_key", st);
    }
    printf("    得到 key_id=0x%08x （只是句柄，明文在 SPE）\r\n", (unsigned int)kid);

    printf("[7] 尝试导出派生钥匙（应失败）\r\n");
    st = psa_export_key(kid, tmp, sizeof(tmp), &tmp_len);
    printf("    export derived status=%d  (期望 %d)\r\n",
           (int)st, (int)PSA_ERROR_NOT_PERMITTED);

    printf("[8] 用派生钥匙 AES-GCM 加密 \"" MSG "\"\r\n");
    st = psa_aead_encrypt(kid, PSA_ALG_GCM, nonce, sizeof(nonce),
                          NULL, 0,
                          (const uint8_t *)MSG, MSG_LEN,
                          ct, sizeof(ct), &ct_len);
    if (st != PSA_SUCCESS) {
        (void)psa_destroy_key(kid);
        return die("encrypt", st);
    }
    hexline("ciphertext+tag = ", ct, ct_len);

    printf("[9] 同一把钥匙解密，应还原明文\r\n");
    st = psa_aead_decrypt(kid, PSA_ALG_GCM, nonce, sizeof(nonce),
                          NULL, 0,
                          ct, ct_len,
                          pt, sizeof(pt), &pt_len);
    (void)psa_destroy_key(kid);
    if (st != PSA_SUCCESS) {
        return die("decrypt", st);
    }
    if ((pt_len != MSG_LEN) || (memcmp(pt, MSG, MSG_LEN) != 0)) {
        printf("[X] 明文不一致\r\n");
        return -1;
    }
    printf("    plaintext = %.*s\r\n", (int)pt_len, pt);

    printf("[10] destroy_key 已调用，流程结束\r\n");
    printf("======== KDF FLOW PASSED ========\r\n");
    printf("同一块板 + 同一 info => 步骤8密文相同\r\n");
    printf("换板或改 info        => 密文不同\r\n");
    return 0;
}
