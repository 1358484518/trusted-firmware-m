/*
 * Overlay on SPE's mbedtls/tf_psa_crypto_config.h (TF_PSA_CRYPTO_USER_CONFIG_FILE).
 *
 * SPE's client-only config keeps PSA_WANT_* in sync with the flashed Crypto
 * partition, but omits TLS/X.509 helper modules. Enable those here without
 * compiling a second PSA crypto core (MBEDTLS_PSA_CRYPTO_C stays off).
 */
#ifndef NS_CRYPTO_USER_H
#define NS_CRYPTO_USER_H

#define MBEDTLS_PSA_CRYPTO_CLIENT
#undef  MBEDTLS_PSA_CRYPTO_C

/* ssl.h sizes ECDHE premaster from this; SPE client config does not set it. */
/* ssl.h needs a premaster buffer size; do not enable ECP_LIGHT (needs DP_*). */
#ifndef MBEDTLS_ECP_MAX_BITS
#define MBEDTLS_ECP_MAX_BITS  521
#endif
#ifndef MBEDTLS_ECP_MAX_BYTES
#define MBEDTLS_ECP_MAX_BYTES ((MBEDTLS_ECP_MAX_BITS + 7) / 8)
#endif

#define MBEDTLS_CIPHER_C
#define MBEDTLS_MD_C
#define MBEDTLS_OID_C
#define MBEDTLS_ASN1_PARSE_C
#define MBEDTLS_ASN1_WRITE_C
#define MBEDTLS_PK_C
#define MBEDTLS_PK_PARSE_C
#define MBEDTLS_PEM_PARSE_C
#define MBEDTLS_BASE64_C
#define MBEDTLS_ERROR_C
#define MBEDTLS_PLATFORM_C

#endif /* NS_CRYPTO_USER_H */
