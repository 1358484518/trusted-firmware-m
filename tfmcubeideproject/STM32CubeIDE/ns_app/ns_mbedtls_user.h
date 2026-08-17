/*
 * TLS-side overlay (MBEDTLS_USER_CONFIG_FILE).
 * Crypto options belong in ns_crypto_user.h.
 *
 * ssl.h / ssl_ciphersuites.c still need the legacy cipher and ECP size
 * types after the PSA client config has been read.
 */
#ifndef NS_MBEDTLS_USER_H
#define NS_MBEDTLS_USER_H

/*
 * Must be set before any public header includes private_access.h.
 * Do not also pass -DMBEDTLS_ALLOW_PRIVATE_ACCESS: tf_psa_crypto_common.h
 * defines it again and GCC warns "redefined".
 */
#ifndef MBEDTLS_ALLOW_PRIVATE_ACCESS
#define MBEDTLS_ALLOW_PRIVATE_ACCESS
#endif

#include "mbedtls/private/cipher.h"

#endif /* NS_MBEDTLS_USER_H */
