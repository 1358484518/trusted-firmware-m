/*
 * Bare-metal NS smoke test for STM32H573I-DK + TF-M SPE.
 *
 * Requires the matching flashed tfm_s.bin (s_veneers.o addresses must match).
 * USART1 / ST-Link VCP: 115200 8N1, JP1 not fitted.
 */

#include <stdio.h>
#include <string.h>
#include <stdint.h>

#include "uart_stdout.h"
#include "tfm_ns_interface.h"
#include "os_wrapper/common.h"

#include "psa/crypto.h"
#include "psa/error.h"
#include "psa/internal_trusted_storage.h"
#include "psa/update.h"

static int g_fail;

static void check(const char *what, psa_status_t status)
{
    if (status == PSA_SUCCESS) {
        printf("  [PASS] %s\r\n", what);
    } else {
        printf("  [FAIL] %s status=%d\r\n", what, (int)status);
        g_fail++;
    }
}

static void test_crypto(void)
{
    static const uint8_t msg[] = "abc";
    /* FIPS 180-2 SHA-256("abc") */
    static const uint8_t expect[32] = {
        0xba, 0x78, 0x16, 0xbf, 0x8f, 0x01, 0xcf, 0xea,
        0x41, 0x41, 0x40, 0xde, 0x5d, 0xae, 0x22, 0x23,
        0xb0, 0x03, 0x61, 0xa3, 0x96, 0x17, 0x7a, 0x9c,
        0xb4, 0x10, 0xff, 0x61, 0xf2, 0x00, 0x15, 0xad
    };
    uint8_t hash[32];
    size_t hash_len = 0;
    psa_status_t status;

    printf("PSA Crypto\r\n");
    status = psa_crypto_init();
    check("psa_crypto_init", status);
    if (status != PSA_SUCCESS) {
        return;
    }

    status = psa_hash_compute(PSA_ALG_SHA_256, msg, sizeof(msg) - 1u,
                              hash, sizeof(hash), &hash_len);
    check("psa_hash_compute(SHA-256)", status);
    if (status == PSA_SUCCESS) {
        printf("  hash=");
        for (size_t i = 0; i < hash_len; i++) {
            printf("%02x", hash[i]);
        }
        printf("\r\n");
        if ((hash_len != sizeof(expect)) ||
            (memcmp(hash, expect, sizeof(expect)) != 0)) {
            printf("  [FAIL] SHA-256 known-answer mismatch\r\n");
            g_fail++;
        } else {
            printf("  [PASS] SHA-256 known-answer\r\n");
        }
    }
}

static void test_its(void)
{
    const psa_storage_uid_t uid = 0x0000000000001001ULL;
    static const uint8_t payload[] = "ns-its";
    uint8_t readback[16];
    size_t read_len = 0;
    psa_status_t status;

    printf("PSA ITS\r\n");
    (void)psa_its_remove(uid);

    status = psa_its_set(uid, sizeof(payload), payload, PSA_STORAGE_FLAG_NONE);
    check("psa_its_set", status);

    memset(readback, 0, sizeof(readback));
    status = psa_its_get(uid, 0, sizeof(readback), readback, &read_len);
    check("psa_its_get", status);
    if ((status == PSA_SUCCESS) &&
        ((read_len != sizeof(payload)) ||
         (memcmp(readback, payload, sizeof(payload)) != 0))) {
        printf("  [FAIL] ITS payload mismatch\r\n");
        g_fail++;
    }

    status = psa_its_remove(uid);
    check("psa_its_remove", status);
}

static void test_fwu_query(void)
{
    psa_fwu_component_info_t info;
    psa_status_t status;

    printf("PSA FWU query\r\n");

    memset(&info, 0, sizeof(info));
    status = psa_fwu_query(FWU_COMPONENT_ID_SECURE, &info);
    check("psa_fwu_query(S)", status);
    if (status == PSA_SUCCESS) {
        printf("  S  state=%u max_size=%lu\r\n",
               (unsigned)info.state, (unsigned long)info.max_size);
    }

    memset(&info, 0, sizeof(info));
    status = psa_fwu_query(FWU_COMPONENT_ID_NONSECURE, &info);
    check("psa_fwu_query(NS)", status);
    if (status == PSA_SUCCESS) {
        printf("  NS state=%u max_size=%lu\r\n",
               (unsigned)info.state, (unsigned long)info.max_size);
    }
}

int main(void)
{
    stdio_init();
    setvbuf(stdout, NULL, _IONBF, 0);

    printf("\r\nNS app start\r\n");

    if (tfm_ns_interface_init() != OS_WRAPPER_SUCCESS) {
        printf("tfm_ns_interface_init failed\r\n");
        for (;;) {
        }
    }
    printf("tfm_ns_interface_init ok\r\n");

    test_crypto();
    test_its();
    test_fwu_query();

    if (g_fail == 0) {
        printf("ALL PASSED\r\n");
    } else {
        printf("FAILED count=%d\r\n", g_fail);
    }

    for (;;) {
    }
}
