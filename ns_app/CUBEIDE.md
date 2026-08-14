# STM32CubeIDE 把点灯工程改成 TF-M NS 应用（配置备忘）

板子：STM32H573（SPE 已在板上，UBE=0xB4）  
CubeIDE：2.2.0（GNU Tools for STM32 14.3）  
工程根：**`~/test/tfmminiproject/STM32CubeIDE/`**（不是上一级 `tfmminiproject/`）  
NS 源码：该目录下的 **`ns_app/`**（从已 `make` 通过的 `~/test/libs` 整份拷入）

本文记录的是「删掉 CubeMX 点灯运行时 + 托管编译 ns_app」这套已经编过、veneer 地址核对过的配置。

---

## 1. 目录（改完后）

```
~/test/tfmminiproject/
└── STM32CubeIDE/                 ← CubeIDE 打开的是这一层
    ├── .project / .cproject
    ├── Debug/                    ← 编译产物 tfmminiproject.elf / .map
    └── ns_app/
        ├── main.c
        ├── syscalls_stub.c
        ├── platform_init_def.c
        ├── tfm_log_raw.c
        ├── tfm_log_raw.h
        ├── test_log.h
        ├── Makefile
        ├── tfm_src/              ← 从 api_ns 抽出、要编的官方 .c
        ├── api_ns/               ← 整份 SPE 导出；不编源码，只用头文件/veneer/签名
        └── out/
            ├── appli_ns.pp.ld    ← make 预处理出的链接脚本
            └── tfm_ns_signed.bin
```

已删除（不要再 Generate Code）：

- 上一级 `Core/`、`Drivers/`
- `STM32CubeIDE/Application/`（含 `syscalls.c`、`sysmem.c`、`startup_stm32h573vitx.s`）
- `STM32CubeIDE/Drivers/`
- `STM32H573VITX_FLASH.ld` / `RAM.ld`
- `tfmminiproject.ioc`（可删）

`tfm_src/` 里应有（从 `api_ns` 拷贝，不要拷整个 `api_ns` 当源码）：

```
tfm_ns_interface_bare_metal.c
tfm_tz_psa_ns_api.c
tfm_crypto_api.c  tfm_its_api.c  tfm_ps_api.c
tfm_fwu_api.c  tfm_attest_api.c  tfm_platform_api.c
startup_stm32h5xx_ns.c
system_stm32h5xx.c
uart_stdout.c
low_level_com.c
stm32h5xx_hal.c  stm32h5xx_hal_cortex.c
stm32h5xx_hal_dma.c  stm32h5xx_hal_dma_ex.c
stm32h5xx_hal_gpio.c
stm32h5xx_hal_pwr.c  stm32h5xx_hal_pwr_ex.c
stm32h5xx_hal_rcc.c  stm32h5xx_hal_rcc_ex.c
stm32h5xx_hal_uart.c  stm32h5xx_hal_uart_ex.c
```

---

## 2. CubeIDE 从哪打开设置

1. Project Explorer 点工程名（`tfmminiproject`），不要点某个 `.c`
2. **Project → Properties**
3. **C/C++ Build → Settings → Tool Settings**
4. 上面 **Configuration** 选 **Debug**（有 Release 则两套都改）

---

## 3. Source Location（编哪些文件）

**C/C++ General → Paths and Symbols → Source Location**（有的版本在 Settings 里）

- 源码目录：`ns_app`
- **Exclusion / Filter 排除：**
  - `api_ns`
  - `out`

这样会自动编：`main.c`、`syscalls_stub.c`、`platform_init_def.c`、`tfm_log_raw.c`、`tfm_src/*.c`。

以后加自己的 `.c`：放在 `ns_app/` 下（不要放进 `api_ns/`），和普通 CubeIDE 一样自动参与编译。

---

## 4. Include

**MCU GCC Compiler → Includes → Include paths**

删掉原来的 `../Core/Inc`、`../Drivers/...`，只留：

```
${ProjDirPath}/ns_app
${ProjDirPath}/ns_app/api_ns/interface/include
${ProjDirPath}/ns_app/api_ns/interface/include/crypto_keys
${ProjDirPath}/ns_app/api_ns/platform/include
${ProjDirPath}/ns_app/api_ns/platform/boards
${ProjDirPath}/ns_app/api_ns/platform/Device/Include
${ProjDirPath}/ns_app/api_ns/platform/ext/cmsis/Include
${ProjDirPath}/ns_app/api_ns/platform/ext/cmsis/Include/m-profile
${ProjDirPath}/ns_app/api_ns/platform/ext/common
${ProjDirPath}/ns_app/api_ns/platform/hal/Inc
```

路径**不要加引号**（CubeIDE 会自己加）。

---

## 5. 预处理器宏

**MCU GCC Compiler → Preprocessor → Defined symbols**

```
STM32H573xx
USE_HAL_DRIVER
DOMAIN_NS=1
CONFIG_TFM_FLOAT_ABI=0
PLATFORM_DEFAULT_CRYPTO_KEYS
CONFIG_TFM_USE_TRUSTZONE
TFM_ISOLATION_LEVEL=1
TFM_PARTITION_CRYPTO
TFM_PARTITION_INTERNAL_TRUSTED_STORAGE
TFM_PARTITION_PROTECTED_STORAGE
TFM_PARTITION_FIRMWARE_UPDATE
TFM_PARTITION_INITIAL_ATTESTATION
TFM_PARTITION_PLATFORM
TFM_PSA_CRYPTO_CLIENT_ONLY
TF_PSA_CRYPTO_CONFIG_FILE="mbedtls/tf_psa_crypto_config.h"
TARGET_CONFIG_HEADER_FILE="config_tfm_target.h"
BL2
BL2_HEADER_SIZE=0x400
BL2_TRAILER_SIZE=0x2000
MCUBOOT_IMAGE_NUMBER=2
TFM_NS_LOG
NDEBUG
```

漏 `TFM_NS_LOG` 则 `LOG_MSG` 是空宏。漏 `DOMAIN_NS=1` 则 UART 会走错驱动。

---

## 6. CPU / FPU

**MCU Settings**（或 MCU/MPU Settings）

- FPU Type：None
- Floating-point ABI：Software implementation
- Instruction set：Thumb

**MCU GCC Compiler → Miscellaneous → Other flags** 再加（链接 Miscellaneous 同样加）：

```
-mcpu=cortex-m33+nodsp+nofp -mthumb -mfloat-abi=soft
```

必须和 SPE 一致：软浮点、无 FPU/DSP。

---

## 7. 链接（最容易配错）

**MCU GCC Linker → General → Linker Script (-T)**

不要引号：

```
${ProjDirPath}/ns_app/out/appli_ns.pp.ld
```

这个文件必须先存在。没有就：

```bash
cd ~/test/tfmminiproject/STM32CubeIDE/ns_app
make
ls -l out/appli_ns.pp.ld
```

**MCU GCC Linker → Libraries → Libraries (-l)**

必须是空的，**不要**把 `s_veneers.o` 加在这里。加在这里会变成：

```text
-l/home/klp/.../s_veneers.o     ← 错误
```

**MCU GCC Linker → Miscellaneous → Additional object files**

只加这一条，不要 `-l`，不要引号：

```
${ProjDirPath}/ns_app/api_ns/interface/lib/s_veneers.o
```

正确链接行应类似：

```text
arm-none-eabi-gcc -o tfmminiproject.elf @objects.list \
  /home/klp/.../s_veneers.o \
  -T".../appli_ns.pp.ld" --specs=nosys.specs --specs=nano.specs ...
```

**不要**在 Other flags 里再写一遍 `-specs=nano.specs -specs=nosys.specs`。CubeIDE 默认已有，写两遍会报：

```text
attempt to rename spec 'link_gcc_c_sequence' to already defined spec 'nosys_link_gcc_c_sequence'
```

链接其它选项保留 CubeIDE 默认即可，另加 `-Wl,--gc-sections` 可以（默认往往已有）。

---

## 8. 编译通过后核对

```bash
grep __Vectors ~/test/tfmminiproject/STM32CubeIDE/Debug/tfmminiproject.map
arm-none-eabi-nm ~/test/tfmminiproject/STM32CubeIDE/Debug/tfmminiproject.elf | grep veneer
```

必须是：

| 符号 | 地址 |
|---|---|
| `__Vectors` | `0x08088400` |
| `tfm_psa_call_veneer` | `0x0c085fe0` |

map 里用 `grep veneer` 可能只看到 `LOAD s_veneers.o`，以 `nm` 为准。

---

## 9. 签名并烧录（不要用 IDE Download）

CubeIDE 的 `.elf` 没有 MCUBoot 头，BL2 不认。

```bash
cd ~/test/tfmminiproject/STM32CubeIDE

arm-none-eabi-objcopy -O binary Debug/tfmminiproject.elf ns_app/out/tfm_ns.bin

cd ns_app
make out/tfm_ns_signed.bin
ls -l out/tfm_ns_signed.bin
# 必须是 589824 字节

STM32_Programmer_CLI -c port=SWD mode=UR \
  -d out/tfm_ns_signed.bin 0x0C088000 -v
```

串口：ST-Link VCP，**115200 8N1**，JP1 不插。  
先出现 Secure 测试 `*** End of Secure test suites ***`，再出现 `NS-SMOKE` / `ALL PASSED`。

不要跑 `regression.sh`，不要动 BL2 / SPE。

---

## 10. 以后加文件

只在 `STM32CubeIDE/ns_app/` 下 New → Source File（例如 `led.c`）。头文件同目录或靠已有 `-I ns_app`。

不要：

- 再点 CubeMX Generate Code
- 把业务代码丢进 `api_ns/` 或 `tfm_src/`
- 用 CubeIDE Run 下载未签名 ELF
- 换 SPE 却不换 `api_ns/`（veneer 地址会对不上）

换 SPE 之后：更新 `ns_app/api_ns`，在 `ns_app` 里重新 `make` 生成 `appli_ns.pp.ld`，再核对 `0x0c085fe0`。

---

## 11. 踩过的坑（速查）

| 现象 | 原因 | 处理 |
|---|---|---|
| `No rule to make target '".../appli_ns.pp.ld"'` | 链接脚本路径带了引号 | 去掉引号 |
| `No rule to make target ... appli_ns.pp.ld` | 文件还不存在 | `cd ns_app && make` |
| `rename spec ... nosys_link_gcc_c_sequence` | `nano.specs`/`nosys.specs` 写了两遍 | Other flags 里删掉 specs |
| `cannot find -l/.../s_veneers.o` | 加到了 Libraries (-l) | 改到 Additional object files |
| 串口 Secure 之后乱码/无 NS 字 | 用了 `printf` 或漏了 `TFM_NS_LOG` | 用 `LOG_MSG`，宏里要有 `TFM_NS_LOG` |
