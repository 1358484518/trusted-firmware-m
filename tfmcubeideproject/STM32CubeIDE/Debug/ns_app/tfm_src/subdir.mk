################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (14.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../ns_app/tfm_src/low_level_com.c \
../ns_app/tfm_src/startup_stm32h5xx_ns.c \
../ns_app/tfm_src/stm32h5xx_hal.c \
../ns_app/tfm_src/stm32h5xx_hal_cortex.c \
../ns_app/tfm_src/stm32h5xx_hal_dma.c \
../ns_app/tfm_src/stm32h5xx_hal_dma_ex.c \
../ns_app/tfm_src/stm32h5xx_hal_gpio.c \
../ns_app/tfm_src/stm32h5xx_hal_pwr.c \
../ns_app/tfm_src/stm32h5xx_hal_pwr_ex.c \
../ns_app/tfm_src/stm32h5xx_hal_rcc.c \
../ns_app/tfm_src/stm32h5xx_hal_rcc_ex.c \
../ns_app/tfm_src/stm32h5xx_hal_uart.c \
../ns_app/tfm_src/stm32h5xx_hal_uart_ex.c \
../ns_app/tfm_src/system_stm32h5xx.c \
../ns_app/tfm_src/tfm_attest_api.c \
../ns_app/tfm_src/tfm_crypto_api.c \
../ns_app/tfm_src/tfm_fwu_api.c \
../ns_app/tfm_src/tfm_its_api.c \
../ns_app/tfm_src/tfm_ns_interface_bare_metal.c \
../ns_app/tfm_src/tfm_platform_api.c \
../ns_app/tfm_src/tfm_ps_api.c \
../ns_app/tfm_src/tfm_tz_psa_ns_api.c \
../ns_app/tfm_src/uart_stdout.c 

OBJS += \
./ns_app/tfm_src/low_level_com.o \
./ns_app/tfm_src/startup_stm32h5xx_ns.o \
./ns_app/tfm_src/stm32h5xx_hal.o \
./ns_app/tfm_src/stm32h5xx_hal_cortex.o \
./ns_app/tfm_src/stm32h5xx_hal_dma.o \
./ns_app/tfm_src/stm32h5xx_hal_dma_ex.o \
./ns_app/tfm_src/stm32h5xx_hal_gpio.o \
./ns_app/tfm_src/stm32h5xx_hal_pwr.o \
./ns_app/tfm_src/stm32h5xx_hal_pwr_ex.o \
./ns_app/tfm_src/stm32h5xx_hal_rcc.o \
./ns_app/tfm_src/stm32h5xx_hal_rcc_ex.o \
./ns_app/tfm_src/stm32h5xx_hal_uart.o \
./ns_app/tfm_src/stm32h5xx_hal_uart_ex.o \
./ns_app/tfm_src/system_stm32h5xx.o \
./ns_app/tfm_src/tfm_attest_api.o \
./ns_app/tfm_src/tfm_crypto_api.o \
./ns_app/tfm_src/tfm_fwu_api.o \
./ns_app/tfm_src/tfm_its_api.o \
./ns_app/tfm_src/tfm_ns_interface_bare_metal.o \
./ns_app/tfm_src/tfm_platform_api.o \
./ns_app/tfm_src/tfm_ps_api.o \
./ns_app/tfm_src/tfm_tz_psa_ns_api.o \
./ns_app/tfm_src/uart_stdout.o 

C_DEPS += \
./ns_app/tfm_src/low_level_com.d \
./ns_app/tfm_src/startup_stm32h5xx_ns.d \
./ns_app/tfm_src/stm32h5xx_hal.d \
./ns_app/tfm_src/stm32h5xx_hal_cortex.d \
./ns_app/tfm_src/stm32h5xx_hal_dma.d \
./ns_app/tfm_src/stm32h5xx_hal_dma_ex.d \
./ns_app/tfm_src/stm32h5xx_hal_gpio.d \
./ns_app/tfm_src/stm32h5xx_hal_pwr.d \
./ns_app/tfm_src/stm32h5xx_hal_pwr_ex.d \
./ns_app/tfm_src/stm32h5xx_hal_rcc.d \
./ns_app/tfm_src/stm32h5xx_hal_rcc_ex.d \
./ns_app/tfm_src/stm32h5xx_hal_uart.d \
./ns_app/tfm_src/stm32h5xx_hal_uart_ex.d \
./ns_app/tfm_src/system_stm32h5xx.d \
./ns_app/tfm_src/tfm_attest_api.d \
./ns_app/tfm_src/tfm_crypto_api.d \
./ns_app/tfm_src/tfm_fwu_api.d \
./ns_app/tfm_src/tfm_its_api.d \
./ns_app/tfm_src/tfm_ns_interface_bare_metal.d \
./ns_app/tfm_src/tfm_platform_api.d \
./ns_app/tfm_src/tfm_ps_api.d \
./ns_app/tfm_src/tfm_tz_psa_ns_api.d \
./ns_app/tfm_src/uart_stdout.d 


# Each subdirectory must supply rules for building sources it contributes
ns_app/tfm_src/%.o ns_app/tfm_src/%.su ns_app/tfm_src/%.cyclo: ../ns_app/tfm_src/%.c ns_app/tfm_src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m33 -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32H573xx -DDOMAIN_NS=1 -DCONFIG_TFM_FLOAT_ABI=2 -DCONFIG_TFM_ENABLE_CP10CP11 -DPLATFORM_DEFAULT_CRYPTO_KEYS -DCONFIG_TFM_USE_TRUSTZONE -DTFM_ISOLATION_LEVEL=1 -DTFM_PARTITION_CRYPTO -DTFM_PARTITION_INTERNAL_TRUSTED_STORAGE -DTFM_PARTITION_PROTECTED_STORAGE -DTFM_PARTITION_FIRMWARE_UPDATE -DTFM_PARTITION_INITIAL_ATTESTATION -DTFM_PARTITION_PLATFORM -DTFM_PSA_CRYPTO_CLIENT_ONLY '-DTF_PSA_CRYPTO_CONFIG_FILE="mbedtls/tf_psa_crypto_config.h"' '-DTARGET_CONFIG_HEADER_FILE="config_tfm_target.h"' -DBL2 -DBL2_HEADER_SIZE=0x400 -DBL2_TRAILER_SIZE=0x2000 -DMCUBOOT_IMAGE_NUMBER=2 -DTFM_NS_LOG -DNDEBUG -c -I../spe/api_ns/interface/include -I../spe/api_ns/interface/include/crypto_keys -I../spe/api_ns/platform/include -I../spe/api_ns/platform/boards -I../spe/api_ns/platform/Device/Include -I../spe/api_ns/platform/ext/cmsis/Include -I../spe/api_ns/platform/ext/cmsis/Include/m-profile -I../spe/api_ns/platform/ext/common -I../spe/api_ns/platform/hal/Inc -I"C:/Users/13584/Desktop/tfmproject/tfmcubeideproject/STM32CubeIDE/ns_app" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-ns_app-2f-tfm_src

clean-ns_app-2f-tfm_src:
	-$(RM) ./ns_app/tfm_src/low_level_com.cyclo ./ns_app/tfm_src/low_level_com.d ./ns_app/tfm_src/low_level_com.o ./ns_app/tfm_src/low_level_com.su ./ns_app/tfm_src/startup_stm32h5xx_ns.cyclo ./ns_app/tfm_src/startup_stm32h5xx_ns.d ./ns_app/tfm_src/startup_stm32h5xx_ns.o ./ns_app/tfm_src/startup_stm32h5xx_ns.su ./ns_app/tfm_src/stm32h5xx_hal.cyclo ./ns_app/tfm_src/stm32h5xx_hal.d ./ns_app/tfm_src/stm32h5xx_hal.o ./ns_app/tfm_src/stm32h5xx_hal.su ./ns_app/tfm_src/stm32h5xx_hal_cortex.cyclo ./ns_app/tfm_src/stm32h5xx_hal_cortex.d ./ns_app/tfm_src/stm32h5xx_hal_cortex.o ./ns_app/tfm_src/stm32h5xx_hal_cortex.su ./ns_app/tfm_src/stm32h5xx_hal_dma.cyclo ./ns_app/tfm_src/stm32h5xx_hal_dma.d ./ns_app/tfm_src/stm32h5xx_hal_dma.o ./ns_app/tfm_src/stm32h5xx_hal_dma.su ./ns_app/tfm_src/stm32h5xx_hal_dma_ex.cyclo ./ns_app/tfm_src/stm32h5xx_hal_dma_ex.d ./ns_app/tfm_src/stm32h5xx_hal_dma_ex.o ./ns_app/tfm_src/stm32h5xx_hal_dma_ex.su ./ns_app/tfm_src/stm32h5xx_hal_gpio.cyclo ./ns_app/tfm_src/stm32h5xx_hal_gpio.d ./ns_app/tfm_src/stm32h5xx_hal_gpio.o ./ns_app/tfm_src/stm32h5xx_hal_gpio.su ./ns_app/tfm_src/stm32h5xx_hal_pwr.cyclo ./ns_app/tfm_src/stm32h5xx_hal_pwr.d ./ns_app/tfm_src/stm32h5xx_hal_pwr.o ./ns_app/tfm_src/stm32h5xx_hal_pwr.su ./ns_app/tfm_src/stm32h5xx_hal_pwr_ex.cyclo ./ns_app/tfm_src/stm32h5xx_hal_pwr_ex.d ./ns_app/tfm_src/stm32h5xx_hal_pwr_ex.o ./ns_app/tfm_src/stm32h5xx_hal_pwr_ex.su ./ns_app/tfm_src/stm32h5xx_hal_rcc.cyclo ./ns_app/tfm_src/stm32h5xx_hal_rcc.d ./ns_app/tfm_src/stm32h5xx_hal_rcc.o ./ns_app/tfm_src/stm32h5xx_hal_rcc.su ./ns_app/tfm_src/stm32h5xx_hal_rcc_ex.cyclo ./ns_app/tfm_src/stm32h5xx_hal_rcc_ex.d ./ns_app/tfm_src/stm32h5xx_hal_rcc_ex.o ./ns_app/tfm_src/stm32h5xx_hal_rcc_ex.su ./ns_app/tfm_src/stm32h5xx_hal_uart.cyclo ./ns_app/tfm_src/stm32h5xx_hal_uart.d ./ns_app/tfm_src/stm32h5xx_hal_uart.o ./ns_app/tfm_src/stm32h5xx_hal_uart.su ./ns_app/tfm_src/stm32h5xx_hal_uart_ex.cyclo ./ns_app/tfm_src/stm32h5xx_hal_uart_ex.d ./ns_app/tfm_src/stm32h5xx_hal_uart_ex.o ./ns_app/tfm_src/stm32h5xx_hal_uart_ex.su ./ns_app/tfm_src/system_stm32h5xx.cyclo ./ns_app/tfm_src/system_stm32h5xx.d ./ns_app/tfm_src/system_stm32h5xx.o ./ns_app/tfm_src/system_stm32h5xx.su ./ns_app/tfm_src/tfm_attest_api.cyclo ./ns_app/tfm_src/tfm_attest_api.d ./ns_app/tfm_src/tfm_attest_api.o ./ns_app/tfm_src/tfm_attest_api.su ./ns_app/tfm_src/tfm_crypto_api.cyclo ./ns_app/tfm_src/tfm_crypto_api.d ./ns_app/tfm_src/tfm_crypto_api.o ./ns_app/tfm_src/tfm_crypto_api.su ./ns_app/tfm_src/tfm_fwu_api.cyclo ./ns_app/tfm_src/tfm_fwu_api.d ./ns_app/tfm_src/tfm_fwu_api.o ./ns_app/tfm_src/tfm_fwu_api.su ./ns_app/tfm_src/tfm_its_api.cyclo ./ns_app/tfm_src/tfm_its_api.d ./ns_app/tfm_src/tfm_its_api.o ./ns_app/tfm_src/tfm_its_api.su ./ns_app/tfm_src/tfm_ns_interface_bare_metal.cyclo ./ns_app/tfm_src/tfm_ns_interface_bare_metal.d ./ns_app/tfm_src/tfm_ns_interface_bare_metal.o ./ns_app/tfm_src/tfm_ns_interface_bare_metal.su ./ns_app/tfm_src/tfm_platform_api.cyclo ./ns_app/tfm_src/tfm_platform_api.d ./ns_app/tfm_src/tfm_platform_api.o ./ns_app/tfm_src/tfm_platform_api.su ./ns_app/tfm_src/tfm_ps_api.cyclo ./ns_app/tfm_src/tfm_ps_api.d ./ns_app/tfm_src/tfm_ps_api.o ./ns_app/tfm_src/tfm_ps_api.su ./ns_app/tfm_src/tfm_tz_psa_ns_api.cyclo ./ns_app/tfm_src/tfm_tz_psa_ns_api.d ./ns_app/tfm_src/tfm_tz_psa_ns_api.o ./ns_app/tfm_src/tfm_tz_psa_ns_api.su ./ns_app/tfm_src/uart_stdout.cyclo ./ns_app/tfm_src/uart_stdout.d ./ns_app/tfm_src/uart_stdout.o ./ns_app/tfm_src/uart_stdout.su

.PHONY: clean-ns_app-2f-tfm_src

