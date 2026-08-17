# STM32CubeIDE NS 工程（STM32H573I-DK + TF-M）

工程名：`tfmminiproject`。目录：`tfmcubeideproject/STM32CubeIDE/`。

NS 应用在 `ns_app/`。SPE 导出在 `spe/`（只链接，不要当 NS 源码编译）。

## Mbed TLS 4.1.1（PSA 客户端）

NS 侧跑 TLS 1.2 / TLS 1.3 握手状态机和 X.509 解析。AES / SHA / 随机数等密码学走 **TF-M Crypto 分区**（`psa_*` + `s_veneers.o`），不要在 NS 再编一套软件 AES/SHA。

| 组件 | 作用 |
|---|---|
| `ns_app/mbedtls-4.1.1/library/` | TLS / X.509 |
| `tf-psa-crypto` 的 ASN.1 / PK / PEM / platform | 证书格式，不是第二套 PSA core |
| `spe/api_ns/.../tfm_crypto_api.c` | 真正的 `psa_*` 经 veneer 进 SPE |

配置叠加：

- `ns_crypto_user.h`（`TF_PSA_CRYPTO_USER_CONFIG_FILE`）：打开 `MBEDTLS_PSA_CRYPTO_CLIENT` 和 PK/ASN.1/PEM，**不要**定义 `MBEDTLS_ECP_LIGHT`
- `ns_mbedtls_user.h`（`MBEDTLS_USER_CONFIG_FILE`）
- `MBEDTLS_USER_CONFIG_FILE="ns_mbedtls_user.h"` 里会定义 `MBEDTLS_ALLOW_PRIVATE_ACCESS`（编 TLS 库内部字段用）。**不要**再在 CubeIDE 的 `-D` 里加一遍，否则 `tf_psa_crypto_common.h` 会报 redefined

头文件顺序必须是 **Mbed TLS 4.1.1 在前，`api_ns` 在后**，否则会用到 SPE 旧的 `mbedtls/pk.h`。

### 不要编译

- `tf-psa-crypto/core/psa_crypto*.c`
- `drivers/builtin/src` 里的 `aes.c` / `sha*.c` / `ecp.c` / `gcm.c` / `rsa.c` / `cipher.c` 等（只保留 `psa_util_internal.c`）
- `library/net_sockets.c`、`timing.c`、server / DTLS / x509write

Makefile 和 `.cproject` 的 source exclude 已经按上面裁过。

## 命令行编译（与 CubeIDE 硬浮点一致）

```bash
cd tfmcubeideproject/STM32CubeIDE/ns_app
make -j$(nproc)
```

产物：`ns_app/out/tfm_ns.elf`、`tfm_ns.bin`。仍须用 `sign_kit` 签名后再烧录，**不要**直接烧未签名 ELF。

## CubeIDE

1. 导入本目录工程 `tfmminiproject`
2. Debug / Release 已加 Mbed TLS 头路径、三个宏、以及 mbedtls 源码排除
3. 构建后走原来的 `sign_kit/sign.bat` post-build。若 Windows 上签名一步报 `1KIT:~0,-1"` / `'et' 不是内部或外部命令`，更新 `sign_kit/sign.bat` 后再编（GitHub zip 是 LF 换行，旧写法会被 `cmd` 拆行）。
4. 若 CubeIDE 仍去编译 `mbedtls-4.1.1` 下不该编的 `.c`，对照 `.cproject` 的 `sourceEntries` 排除项，或改用上面的 Makefile

浮点 ABI 必须与 SPE 一致：`fpv5-sp-d16` + hard float（`CONFIG_TFM_FLOAT_ABI=2`）。

## 板上测试

当前 `main.c` 的 `test_tls_config()` 只做 `mbedtls_ssl_config_defaults` + min TLS1.2 / max TLS1.3 + `mbedtls_ssl_setup`，**没有 TCP/BIO，不会真正握手**。

烧录（与 SPE/BL2 配套）：

| 镜像 | 地址 |
|---|---|
| `bl2.bin` | `0x0C00E000` |
| `tfm_s_signed.bin` | `0x0C038000` |
| `tfm_ns_signed.bin` | `0x0C088000` |

ST-Link VCP CN10：115200 8N1，**不要插 JP1**。UBE 保持 OEM-iRoT `0xB4`。

串口应看到 `Mbed TLS 4.1.1 (PSA client)` 以及 `mbedtls_ssl_setup` 的 PASS，然后仍是原来的 PSA ITS / FWU smoke。

## 多任务

本工程仍是 `tfm_ns_interface_bare_metal.c`。上 RTOS 前应改用官方 `tfm_ns_interface_rtos.c`，并实现 4 个 `os_wrapper_mutex_*` / `os_wrapper_is_kernel_started`。不要给 bare-metal 接口打补丁互斥锁。FreeRTOS 请设 `configENABLE_TRUSTZONE = 0`；每个任务独立 `mbedtls_ssl_context`；ISR 里不要调 PSA / Mbed TLS。
