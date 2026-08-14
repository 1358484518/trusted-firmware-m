# 用 STM32CubeIDE 编 TF-M 独立 NS 应用

CubeMX 生成的「PB7 点灯」工程是**裸机独占整片 Flash**（通常 `0x08000000`），和已经在板上跑的 TF-M 不是同一类工程。不能只把 `main.c` 拷进去就点 Run。

正确做法：把 CubeIDE 工程改成和 `/test/libs` 的 Makefile **同一套 NS 应用**（同一 `api_ns`、同一链接脚本、同一 ABI），LED 只作为 `main.c` 里多出来的 GPIO。编完仍要 **MCUboot 签名**，再烧到 `0x0C088000`。

更省事的做法见文末「方案 A：Makefile 工程」。下面「方案 B」是把现有 CubeMX 工程改造成 NS 工程。

---

## 不能整份保留的 CubeMX 东西

| CubeMX 工程里 | 为什么不行 | 改成 |
|---|---|---|
| `STM32H573XX_FLASH.ld`（Flash 从 `0x08000000` 起） | NS 向量表必须在 **`0x08088400`**（槽位 `0x08088000` + header `0x400`） | `api_ns` 的 `appli_ns.ld` 预处理结果 |
| `startup_stm32h573xx.s` | 不是 TF-M NS 启动 | `api_ns/.../startup_stm32h5xx_ns.c` |
| `Core/Src/system_stm32h5xx.c` | 与 `api_ns` 的 `system_stm32h5xx.c` 重复 | 只用 `api_ns` 那份 |
| `Drivers/STM32H5xx_HAL_Driver` | 与 `api_ns/platform/hal` 重复，会多重定义 | 只用 `api_ns` HAL |
| `syscalls.c` / `sysmem.c` | 和 `syscalls_stub.c`、`uart_stdout.c` 的 `_write` 冲突 | 只用 `syscalls_stub.c` |
| `stm32h5xx_it.c`、`stm32h5xx_hal_msp.c`、`gpio.c`、`usart.c` | 再初始化时钟/USART 会打乱 SPE 之后的 NS 串口 | Exclude from Build |
| CubeMX 默认 FPU hard / `fpv5-sp-d16` | 必须和 SPE 一致：`cortex-m33+nodsp+nofp` + **soft** | MCU Settings 改掉 |
| CubeIDE 一键 Download | 下的是**未签名 ELF**，BL2 不认 | 签名成 `tfm_ns_signed.bin` 再烧 |

改完工程后：**不要再点 CubeMX Generate Code**，否则启动文件和 `.ld` 会被盖回去。`.ioc` 只当引脚备忘录。

SPE 侧已把 `GPIOB_S->SECCFGR = 0`，**PB7 对 NS 可用**，不必改 TF-M 平台代码。

---

## 方案 B：改造现有 CubeMX 点灯工程

假定工程在 `~/STM32CubeIDE/workspace/LedPb7/`，NS 源码在 `/test/libs/`。

### 1. 把 NS 文件放进工程

不要把 `api_ns` 里的文件复制散落到 `Core/`。在工程根目录放：

```
LedPb7/
  Core/                 ← 里面旧文件全部 Exclude，不要删 .ioc
  ns/                   ← 从 /test/libs 拷
    main.c
    syscalls_stub.c
    platform_init_def.c
    tfm_log_raw.c
    tfm_log_raw.h
    test_log.h
    Makefile            ← 可选，给签名脚本用
  api_ns/               ← 整目录拷贝，必须与板子上 SPE 配套
```

CubeIDE：File → Refresh，再把 `ns/`、`api_ns/` 加进工程（已在工程目录里会自动出现）。

### 2. Exclude CubeMX 运行时文件

对每个文件：右键 → **Resource Configurations → Exclude from Build**（Debug 和 Release 都勾）。

至少排除：

- `Core/Src/main.c`（用 `ns/main.c`）
- `Core/Src/system_stm32h5xx.c`
- `Core/Src/syscalls.c`、`Core/Src/sysmem.c`
- `Core/Src/stm32h5xx_it.c`、`stm32h5xx_hal_msp.c`
- `Core/Src/gpio.c`、`usart.c` 以及 CubeMX 生成的其它外设 `.c`
- `Core/Startup/startup_stm32h573xx.s`
- `Drivers/STM32H5xx_HAL_Driver` 整棵
- 工程自带的 `STM32H573XX_FLASH.ld`（改用下面预处理过的脚本）

### 3. 把 Makefile 那批源加进 Build

**Source Location** 增加（或把文件勾进编译）：

`ns/` 下：

- `main.c`
- `syscalls_stub.c`
- `platform_init_def.c`
- `tfm_log_raw.c`

`api_ns/` 下（与 Makefile `SPE_SRCS` 相同）：

- `interface/src/os_wrapper/tfm_ns_interface_bare_metal.c`
- `interface/src/tfm_tz_psa_ns_api.c`
- `interface/src/tfm_crypto_api.c`
- `interface/src/tfm_its_api.c`
- `interface/src/tfm_ps_api.c`
- `interface/src/tfm_fwu_api.c`
- `interface/src/tfm_attest_api.c`
- `interface/src/tfm_platform_api.c`
- `platform/Device/Source/startup_stm32h5xx_ns.c`
- `platform/Device/Source/system_stm32h5xx.c`
- `platform/ext/common/uart_stdout.c`
- `platform/hal/CMSIS_Driver/low_level_com.c`
- `platform/hal/Src/stm32h5xx_hal.c`
- `platform/hal/Src/stm32h5xx_hal_cortex.c`
- `platform/hal/Src/stm32h5xx_hal_dma.c`
- `platform/hal/Src/stm32h5xx_hal_dma_ex.c`
- `platform/hal/Src/stm32h5xx_hal_gpio.c`
- `platform/hal/Src/stm32h5xx_hal_pwr.c`
- `platform/hal/Src/stm32h5xx_hal_pwr_ex.c`
- `platform/hal/Src/stm32h5xx_hal_rcc.c`
- `platform/hal/Src/stm32h5xx_hal_rcc_ex.c`
- `platform/hal/Src/stm32h5xx_hal_uart.c`
- `platform/hal/Src/stm32h5xx_hal_uart_ex.c`

**不要**把整个 `api_ns` 当源码树全编进去（会编到无关文件）。

### 4. 链接 veneer（必须）

Project → Properties → C/C++ Build → Settings → **MCU GCC Linker** → **Miscellaneous** → Other objects：

```
"${ProjDirPath}/api_ns/interface/lib/s_veneers.o"
```

这是绝对地址的 NSC 桩。缺了 PSA 调用会链不上或跳错。

### 5. 头文件路径

**MCU GCC Compiler → Include paths**（和 Makefile 一致）：

```
"${ProjDirPath}/ns"
"${ProjDirPath}/api_ns/interface/include"
"${ProjDirPath}/api_ns/interface/include/crypto_keys"
"${ProjDirPath}/api_ns/platform/include"
"${ProjDirPath}/api_ns/platform/boards"
"${ProjDirPath}/api_ns/platform/Device/Include"
"${ProjDirPath}/api_ns/platform/ext/cmsis/Include"
"${ProjDirPath}/api_ns/platform/ext/cmsis/Include/m-profile"
"${ProjDirPath}/api_ns/platform/ext/common"
"${ProjDirPath}/api_ns/platform/hal/Inc"
```

把 CubeMX 的 `Drivers/CMSIS`、`Drivers/STM32H5xx_HAL_Driver/Inc`、`Core/Inc` **从 Include 里去掉**，避免两套 HAL/CMSIS 混用。

### 6. 预处理器宏

**MCU GCC Compiler → Preprocessor → Defined symbols**：

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

`DOMAIN_NS` 必须是 `1`。漏 `TFM_NS_LOG` 则 `LOG_MSG` 是空宏。

### 7. CPU / ABI（和 SPE 必须一致）

**MCU Settings**（或 Target Processor）：

- MCU: STM32H573xx（DK 那颗）
- Instruction set: Thumb
- **Floating-point ABI: Software implementation**
- **FPU Type: None**（不要 `fpv5-sp-d16`）
- 命令行等价：

```
-mcpu=cortex-m33+nodsp+nofp -mthumb -mfloat-abi=soft
```

Linker 同样加上 `-specs=nano.specs -specs=nosys.specs -Wl,--gc-sections`。

Language：GNU11；建议 `-ffunction-sections -fdata-sections -fno-builtin -funsigned-char`。

### 8. 链接脚本

不要用 CubeMX 的 `.ld`。

在 `/test/libs` 先 `make` 一次，把生成的 `out/appli_ns.pp.ld` 拷到工程，例如 `ns/appli_ns.pp.ld`。

**MCU GCC Linker → General → Linker Script**：

```
"${ProjDirPath}/ns/appli_ns.pp.ld"
```

`api_ns` 没换就不用重新预处理。换了 SPE/`api_ns` 必须重新 `make` 出 `.pp.ld` 再拷进来。

也可做 Pre-build：

```bash
arm-none-eabi-gcc <与工程相同的 -D 和 -I> -E -P -xc \
  "${ProjDirPath}/api_ns/platform/linker_scripts/appli_ns.ld" \
  -o "${ProjDirPath}/ns/appli_ns.pp.ld"
```

编完在 `.map` 里确认：

- `.vectors` / FLASH ORIGIN = **`0x08088400`**
- `tfm_psa_call_veneer` = **`0x0c085fe0`**

### 9. 在 `main.c` 里加 PB7（可选）

不要再调用 CubeMX 的 `MX_GPIO_Init()` / `HAL_Init()` / `SystemClock_Config()`。时钟和串口已由 `tfm_ns_platform_init()` → `stdio_init()` 以及 `api_ns` 的 `SystemInit` 处理。

在 `tfm_ns_platform_init()` 和 `tfm_ns_cp_init()` **之后**加（HAL GPIO 已链进工程）：

```c
    __HAL_RCC_GPIOB_CLK_ENABLE();
    {
        GPIO_InitTypeDef gpio = {0};
        gpio.Pin = GPIO_PIN_7;
        gpio.Mode = GPIO_MODE_OUTPUT_PP;
        gpio.Pull = GPIO_NOPULL;
        gpio.Speed = GPIO_SPEED_FREQ_LOW;
        HAL_GPIO_Init(GPIOB, &gpio);
        HAL_GPIO_WritePin(GPIOB, GPIO_PIN_7, GPIO_PIN_SET);
    }
```

需要 `stm32h5xx_hal.h`。点灯不要改 USART 引脚。

### 10. 编译、签名、烧录（不能用 IDE 默认 Download）

CubeIDE Build 得到 `.elf` / `.bin` 后，**不能**直接 Run 到板子（缺 0x400 MCUBoot 头，BL2 会拒）。

用现有 `/test/libs` 的签名流程最稳：把 CubeIDE 产出的 NS `.bin` 换成 Makefile 同款 `wrapper.py` 参数，或继续在 `/test/libs` 里 `make` 出 `out/tfm_ns_signed.bin`。

若坚持用 CubeIDE 的 `.elf`：

```bash
arm-none-eabi-objcopy -O binary LedPb7.elf tfm_ns.bin

# 然后与 Makefile 相同的 wrapper.py 命令，生成 tfm_ns_signed.bin
# 大小必须是 589824 字节
```

烧录仍是：

```bash
STM32_Programmer_CLI -c port=SWD mode=UR -d tfm_ns_signed.bin 0x0C088000 -v
```

不要用 CubeIDE 把 ELF 下到 `0x08000000`。调试用 **Attach**（板子已由 BL2 跳进 NS 之后），不要用 Download。

---

## 方案 A（推荐）：CubeIDE 只当 Makefile 工程

1. File → New → **Makefile Project with Existing Code**
2. Existing Code Location 填 `/test/libs`
3. Toolchain：ARM Cross GCC（或 GNU Tools for STM32，但命令行仍要 `nodsp+nofp` + soft）
4. 在工程属性里把 `make` 环境的 `PATH` 指到你的 `arm-none-eabi`（或 `make TOOLCHAIN_DIR=...`）
5. Build 就是原来的 `make`，产物仍是 `out/tfm_ns_signed.bin`
6. 烧录命令不变

这样不用在 CubeIDE 里重配几十个 Include/宏，也不和 CubeMX 打架。LED 仍改 `/test/libs/main.c`。

---

## 自检清单

- [ ] 未再 Generate Code
- [ ] 未编 CubeMX 的 startup / system / HAL / syscalls
- [ ] 有 `-DTFM_NS_LOG` 且编了 `tfm_log_raw.c`
- [ ] 链了 `s_veneers.o`
- [ ] `.map` 里 FLASH/`__Vectors` = `0x08088400`
- [ ] `tfm_psa_call_veneer` = `0x0c085fe0`
- [ ] 签完 bin = 589824 字节
- [ ] 只烧 `0x0C088000`，未动 SPE
- [ ] 串口仍是 115200，先 Secure 测试，再 `NS-SMOKE`，PB7 灯亮
