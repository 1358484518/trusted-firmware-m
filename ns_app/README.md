# STM32H573I-DK 独立 NS 应用搭建记录

板子：STM32H573I-DK  
TF-M / tf-m-tests：2.3.0（官方代码已验证通过，不当作问题源）  
工具链：ARM GNU Toolchain 14.3.1（`arm-none-eabi-gcc`）  
主机：Ubuntu 22.04  

目标：不把 tf-m-tests 整包当成 NS 应用来编，自己搭一个 **bare-metal NS 烟雾应用**，用 PSA 调 SPE。除 `main.c` 外，C 源码只从 TF-M、tf-m-tests 拷贝，或直接编译 SPE 导出的 `api_ns`。

---

## 1. 原则

1. **只有 `main.c` 是自己写的应用逻辑。**
2. 其它 C 文件：从 TF-M 或 tf-m-tests **原样拷贝**，或由 Makefile 编译 `api_ns` 里的官方源。
3. **不要**自己写 `system_ns.c`、`uart_ns.c`、自制 `low_level_com.c`。tf-m-tests 里没有这些文件。
4. NS 日志走官方测试同一条路：`LOG_MSG` → `tfm_log_printf` → `stdio_output_string`。  
   **不要用 newlib `printf` / `setvbuf`。** 官方 NS 测试从不这样打日志。
5. 日常只重编、只烧 NS 镜像。不要为了改 NS 去跑 `regression.sh`（会动 option bytes、整片擦除）。

---

## 2. 硬件与烧录地址

| 镜像 | 地址 |
|---|---|
| `bl2.bin` | `0x0C00E000` |
| `tfm_s_signed.bin` | `0x0C038000` |
| `tfm_ns_signed.bin` | `0x0C088000`（别名 `0x08088000`） |

- 串口：ST-Link VCP（CN10），**115200 8N1**
- **JP1 不插**
- UBE 保持 OEM-iRoT **`0xB4`**（CubeProgrammer / 本地 `regression.sh` 里设；不要随便改成 ST-iRoT `0xC3`）
- CPU/ABI 必须与 SPE 一致：

```
-mcpu=cortex-m33+nodsp+nofp -mthumb -mfloat-abi=soft
```

- 链接后 `tfm_psa_call_veneer` 必须是 **`0x0C085FE0`**，且与板子上已烧的 `tfm_s.bin` 一致
- 带 `--pad` 签完的 NS 镜像大小：**589824 字节（0x90000）**
- Dummy RSA-3072 签名会有 `NOT SECURE` 警告，这是预期的

---

## 3. 前提：先让官方 SPE 在板上跑通

独立 NS 依赖已经烧进去的 SPE，以及同一次编译导出的 `api_ns`。

SPE（isolation 1，SPM SFN，`TEST_S=ON` / `TEST_NS=ON`）：

```bash
cmake -S tf-m-tests/tests_reg/spe -B build_s -GNinja \
  -DTFM_PLATFORM=stm/stm32h573i_dk \
  -DTFM_TOOLCHAIN_FILE=<tf-m>/toolchain_GNUARM.cmake \
  -DCONFIG_TFM_SOURCE_PATH=<tf-m> \
  -DTFM_PSA_API=ON \
  -DTFM_ISOLATION_LEVEL=1 \
  -DTEST_S=ON \
  -DTEST_NS=ON

ninja -C build_s install
```

导出目录：`build_s/api_ns`  
把这份 `api_ns` **整目录复制**到独立 NS 工程旁边（见下一节）。板子上的 `tfm_s_signed.bin` 必须和这份 `api_ns` 是同一次 SPE 编出来的。换了 SPE 就要换 `api_ns`，并重烧 S 镜像。

首次把 BL2 + SPE 烧上板后，复位应能看到带颜色的 Secure 测试，最后：

```
*** End of Secure test suites ***
```

这是 SPE（`TEST_S=ON`）打的，不是 `main.c`。

---

## 4. 独立 NS 目录

本地工程（示例路径 `/test/libs`）：

```
/test/libs/
  Makefile
  main.c                 # 唯一自己写的应用
  syscalls_stub.c        # 从 TF-M 拷贝
  platform_init_def.c    # 从 tf-m-tests 拷贝
  tfm_log_raw.c          # 从 tf-m-tests 拷贝
  tfm_log_raw.h
  test_log.h
  api_ns/                # SPE 导出，与板子上的 SPE 配套
  out/                   # make 生成，不必手建
```

不要放：`system_ns.c`、`uart_ns.c`、自制 `low_level_com.c`。

---

## 5. 文件从哪来

| 文件 | 来源 | 说明 |
|---|---|---|
| `main.c` | 本地 | PSA 烟雾：Crypto SHA-256 / ITS / FWU query |
| `Makefile` | 本地 | 只做编译、链接、签名胶水 |
| `platform_init_def.c` | `tf-m-tests/app_broker/platform_init_def.c` | `tfm_ns_platform_init()` → `stdio_init()` |
| `syscalls_stub.c` | TF-M `platform/ext/common/syscalls_stub.c` | GNUARM ≥11.3 缺 syscall 符号；也可拷 tests 的 `app_broker/syscalls_stub.c`（无 `_exit`） |
| `tfm_log_raw.c` | `tf-m-tests/lib/log/tfm_log_raw.c` | `tfm_log_printf` |
| `tfm_log_raw.h` | `tf-m-tests/lib/log/tfm_log_raw.h` | |
| `test_log.h` | `tf-m-tests/lib/log/test_log.h` | `LOG_MSG`；必须定义 `TFM_NS_LOG` 才真正打印 |
| 启动、`system_stm32h5xx.c`、`uart_stdout.c`、`low_level_com.c`、HAL、PSA client | **不拷贝到工程根**，Makefile 直接编 `api_ns` 里的文件 | 与官方 NS `platform_ns` 同一套 |

`api_ns` 里会编到的官方源（由 Makefile `SPE_SRCS` 列出）：

- `interface/src/os_wrapper/tfm_ns_interface_bare_metal.c`（不用 RTX）
- `interface/src/tfm_tz_psa_ns_api.c` 以及 crypto / its / ps / fwu / attest / platform client
- `platform/Device/Source/startup_stm32h5xx_ns.c`
- `platform/Device/Source/system_stm32h5xx.c`
- `platform/ext/common/uart_stdout.c`
- `platform/hal/CMSIS_Driver/low_level_com.c`
- HAL：`stm32h5xx_hal.c`、cortex / dma / gpio / pwr / rcc / uart（含 `_ex`）
- 链接：`interface/lib/s_veneers.o`、`platform/linker_scripts/appli_ns.ld`

拷贝命令示例（按你本机 TF-M / tf-m-tests 路径改）：

```bash
cd /test/libs

cp <tf-m>/platform/ext/common/syscalls_stub.c .
cp <tf-m-tests>/app_broker/platform_init_def.c .
cp <tf-m-tests>/lib/log/tfm_log_raw.c .
cp <tf-m-tests>/lib/log/tfm_log_raw.h .
cp <tf-m-tests>/lib/log/test_log.h .

# api_ns 来自同一次 SPE：build_s/api_ns
# cp -a <spe-build>/api_ns .
```

`Makefile`、`main.c` 用本记录配套的那两份（仓库 `ns_app/`）。

---

## 6. NS 启动顺序（对齐官方，去掉 RTX）

官方 `tf-m-tests/app_broker/main_ns.c` 是：

1. `tfm_ns_platform_init()` → `stdio_init()`
2. `tfm_ns_cp_init()`
3. `osKernelInitialize()` + RTX 线程
4. `LOG_MSG("Non-Secure system starting...\r\n")`

独立应用 **不用 RTX**，改成：

1. `tfm_ns_platform_init()`
2. `tfm_ns_cp_init()`
3. `LOG_MSG("NS-SMOKE")` / `LOG_MSG("Non-Secure system starting...")`
4. `tfm_ns_interface_init()`（bare-metal：`tfm_ns_interface_bare_metal.c`）
5. PSA 烟雾：Crypto、ITS、FWU query
6. 打印 `ALL PASSED` 或失败计数，然后死循环

日志必须：

```
LOG_MSG(...)     →  tfm_log_printf()  →  stdio_output_string()
```

Makefile 必须有：

- `-DTFM_NS_LOG`（没有的话 `LOG_MSG` 是空宏，串口没有 NS 字）
- `-I.`（或 `-I$(NS_APP)`），才能找到 `test_log.h` / `tfm_log_raw.h`
- `APP_SRCS` 包含 `tfm_log_raw.c`

`tfm_log_printf` 只支持有限格式（`%s %d %u %x %X %p %c %%`），没有 `%02x` / `%lu`。十六进制按字节拆成两个 `%x` 打印。

---

## 7. Makefile 必须具备的点

- `api_ns` 与 Makefile 同级时，自动 `SPE=./api_ns`
- `CPPFLAGS` 含 `-DDOMAIN_NS=1 -DSTM32H573xx -DUSE_HAL_DRIVER -DTFM_NS_LOG`
- 平台源来自 `api_ns`，不要改成自制 UART/时钟文件
- 链接 `s_veneers.o`（绝对 NSC 地址）
- 预处理器处理 `appli_ns.ld` → `out/appli_ns.pp.ld`
- 签名用 `api_ns` 自带脚本和 NS 密钥，参数与 `api_ns/cmake/spe_config.cmake` 一致：

```
python3 wrapper.py
  --version 0.0.0
  --layout api_ns/image_signing/layout_files/signing_layout_ns.o
  --key    api_ns/image_signing/keys/image_ns_signing_private_key.pem
  --public-key-format full
  --align 16 --pad --pad-header -H 0x400
  -s 1 -L 128
  -d "(0, 0.0.0+0)"
  --measured-boot-record
  out/tfm_ns.bin out/tfm_ns_signed.bin
```

脚本路径：`api_ns/image_signing/scripts/wrapper.py`  
密钥与 TF-M `bl2/ext/mcuboot/root-RSA-3072_1.pem` 相同。  
`wrapper.py` 需要 `import bl2.macro_parser`：Makefile 会把 `macro_parser.py` 摆到临时 `out/pypath/bl2/`。

Python 包（缺了先装一次）：

```bash
python3 -m pip install intelhex click cryptography cbor2 pyyaml
# 或：make python-deps
```

---

## 8. 编译

```bash
cd /test/libs

# 工具链不在 PATH 时：
# make TOOLCHAIN_DIR=/path/to/arm-gnu-toolchain/bin

make clean
make
```

编译日志里应出现 `CC  tfm_log_raw.c`。

检查：

```bash
# 必须是 0c085fe0，对不上说明 api_ns 和板子上的 SPE 不是一套
arm-none-eabi-nm out/tfm_ns.axf | grep ' tfm_psa_call_veneer$'

ls -l out/tfm_ns_signed.bin
# 必须是 589824 字节
```

---

## 9. 只烧 NS

SPE 已在板上、且与当前 `api_ns` 配套时：

```bash
STM32_Programmer_CLI -c port=SWD mode=UR -d out/tfm_ns_signed.bin 0x0C088000 -v
```

不要动 BL2 / SPE。不要跑 `regression.sh`。

---

## 10. 串口与成功判据

115200 8N1，JP1 不插，烧完复位。

前面是 SPE 的 Secure 测试（绿色 `PASSED`）。之后必须是 **可读** 的 NS 文本：

```
*** End of Secure test suites ***

NS-SMOKE
Non-Secure system starting...
tfm_ns_interface_init ok
PSA Crypto
  [PASS] psa_crypto_init
  [PASS] psa_hash_compute(SHA-256)
  hash=ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
  [PASS] SHA-256 known-answer
PSA ITS
  [PASS] psa_its_set
  [PASS] psa_its_get
  [PASS] psa_its_remove
PSA FWU query
  [PASS] psa_fwu_query(S)
  S  state=5 max_size=327680
  [PASS] psa_fwu_query(NS)
  NS state=5 max_size=589824
ALL PASSED
```

hash 必须是 FIPS 180-2 的 SHA-256(`"abc"`)：`ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad`。

若出现 `NtP`、`b71b80ce...` 这类乱码，不是 hash 对上了，而是波特率/日志路径不对。先确认 `main.c` 用的是 `LOG_MSG`，Makefile 有 `-DTFM_NS_LOG` 且编进了 `tfm_log_raw.c`。

---

## 11. 日常改 NS 的循环

```bash
cd /test/libs
# 改 main.c
make clean && make
STM32_Programmer_CLI -c port=SWD mode=UR -d out/tfm_ns_signed.bin 0x0C088000 -v
```

只有重编 SPE 时才需要更新 `api_ns/`、重烧 `tfm_s_signed.bin`，并确认新的 `tfm_psa_call_veneer` 仍与链接结果一致。

---

## 12. 不要做的事

- 不要为独立 NS 去编整份 tf-m-tests NS（RTX + 全套 NS 用例）当日常应用
- 不要自制 USART/时钟驱动替代 `api_ns` 的 `system_stm32h5xx.c` / `low_level_com.c` / `uart_stdout.c`
- 不要用 `printf` 打 NS 日志
- 不要漏 `-DTFM_NS_LOG`（`LOG_MSG` 会变成空）
- 不要拿另一份 SPE 的 `api_ns` 去链当前板上的 `tfm_s`
- 不要为了刷 NS 去跑 `regression.sh`
- 不要插 JP1
- 不要把 UBE 改成 `0xC3`（BL2 会因 BOOT UBE 不匹配进 `Error_Handler`）
