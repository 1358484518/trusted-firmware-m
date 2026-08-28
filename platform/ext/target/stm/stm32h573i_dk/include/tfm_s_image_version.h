/*
 * SPE image version shown by NS psa_fwu_query(FWU_COMPONENT_ID_SECURE).
 * CMake signing and sign_kit/sign.sh both read TFM_S_IMAGE_VERSION_STR.
 * Edit this file, then rebuild SPE (or re-sign with sign.sh).
 */
#ifndef TFM_S_IMAGE_VERSION_H
#define TFM_S_IMAGE_VERSION_H

#define TFM_S_IMAGE_VERSION_MAJOR  2
#define TFM_S_IMAGE_VERSION_MINOR  3
#define TFM_S_IMAGE_VERSION_PATCH  0
#define TFM_S_IMAGE_VERSION_STR    "2.3.0"

#endif /* TFM_S_IMAGE_VERSION_H */
