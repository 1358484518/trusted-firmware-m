################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (14.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../ns_app/spe/api_ns/platform/ext/common/bl2_hal_multisig.c \
../ns_app/spe/api_ns/platform/ext/common/boot_hal_bl1_1.c \
../ns_app/spe/api_ns/platform/ext/common/boot_hal_bl1_2.c \
../ns_app/spe/api_ns/platform/ext/common/boot_hal_bl2.c \
../ns_app/spe/api_ns/platform/ext/common/exception_info.c \
../ns_app/spe/api_ns/platform/ext/common/faults.c \
../ns_app/spe/api_ns/platform/ext/common/mem_check_v6m_v7m.c \
../ns_app/spe/api_ns/platform/ext/common/mpc_ppc_faults.c \
../ns_app/spe/api_ns/platform/ext/common/provisioning.c \
../ns_app/spe/api_ns/platform/ext/common/syscalls_stub.c \
../ns_app/spe/api_ns/platform/ext/common/test_interrupt.c \
../ns_app/spe/api_ns/platform/ext/common/tfm_assert.c \
../ns_app/spe/api_ns/platform/ext/common/tfm_boot_measurement.c \
../ns_app/spe/api_ns/platform/ext/common/tfm_fatal_error.c \
../ns_app/spe/api_ns/platform/ext/common/tfm_hal_isolation_v8m.c \
../ns_app/spe/api_ns/platform/ext/common/tfm_hal_its.c \
../ns_app/spe/api_ns/platform/ext/common/tfm_hal_nvic.c \
../ns_app/spe/api_ns/platform/ext/common/tfm_hal_platform_v8m.c \
../ns_app/spe/api_ns/platform/ext/common/tfm_hal_ps.c \
../ns_app/spe/api_ns/platform/ext/common/tfm_hal_reset_halt.c \
../ns_app/spe/api_ns/platform/ext/common/tfm_hal_sp_logdev_periph.c \
../ns_app/spe/api_ns/platform/ext/common/tfm_hal_spm_logdev_peripheral.c \
../ns_app/spe/api_ns/platform/ext/common/tfm_interrupts.c \
../ns_app/spe/api_ns/platform/ext/common/tfm_sanitize_handlers.c \
../ns_app/spe/api_ns/platform/ext/common/uart_stdout.c 

OBJS += \
./ns_app/spe/api_ns/platform/ext/common/bl2_hal_multisig.o \
./ns_app/spe/api_ns/platform/ext/common/boot_hal_bl1_1.o \
./ns_app/spe/api_ns/platform/ext/common/boot_hal_bl1_2.o \
./ns_app/spe/api_ns/platform/ext/common/boot_hal_bl2.o \
./ns_app/spe/api_ns/platform/ext/common/exception_info.o \
./ns_app/spe/api_ns/platform/ext/common/faults.o \
./ns_app/spe/api_ns/platform/ext/common/mem_check_v6m_v7m.o \
./ns_app/spe/api_ns/platform/ext/common/mpc_ppc_faults.o \
./ns_app/spe/api_ns/platform/ext/common/provisioning.o \
./ns_app/spe/api_ns/platform/ext/common/syscalls_stub.o \
./ns_app/spe/api_ns/platform/ext/common/test_interrupt.o \
./ns_app/spe/api_ns/platform/ext/common/tfm_assert.o \
./ns_app/spe/api_ns/platform/ext/common/tfm_boot_measurement.o \
./ns_app/spe/api_ns/platform/ext/common/tfm_fatal_error.o \
./ns_app/spe/api_ns/platform/ext/common/tfm_hal_isolation_v8m.o \
./ns_app/spe/api_ns/platform/ext/common/tfm_hal_its.o \
./ns_app/spe/api_ns/platform/ext/common/tfm_hal_nvic.o \
./ns_app/spe/api_ns/platform/ext/common/tfm_hal_platform_v8m.o \
./ns_app/spe/api_ns/platform/ext/common/tfm_hal_ps.o \
./ns_app/spe/api_ns/platform/ext/common/tfm_hal_reset_halt.o \
./ns_app/spe/api_ns/platform/ext/common/tfm_hal_sp_logdev_periph.o \
./ns_app/spe/api_ns/platform/ext/common/tfm_hal_spm_logdev_peripheral.o \
./ns_app/spe/api_ns/platform/ext/common/tfm_interrupts.o \
./ns_app/spe/api_ns/platform/ext/common/tfm_sanitize_handlers.o \
./ns_app/spe/api_ns/platform/ext/common/uart_stdout.o 

C_DEPS += \
./ns_app/spe/api_ns/platform/ext/common/bl2_hal_multisig.d \
./ns_app/spe/api_ns/platform/ext/common/boot_hal_bl1_1.d \
./ns_app/spe/api_ns/platform/ext/common/boot_hal_bl1_2.d \
./ns_app/spe/api_ns/platform/ext/common/boot_hal_bl2.d \
./ns_app/spe/api_ns/platform/ext/common/exception_info.d \
./ns_app/spe/api_ns/platform/ext/common/faults.d \
./ns_app/spe/api_ns/platform/ext/common/mem_check_v6m_v7m.d \
./ns_app/spe/api_ns/platform/ext/common/mpc_ppc_faults.d \
./ns_app/spe/api_ns/platform/ext/common/provisioning.d \
./ns_app/spe/api_ns/platform/ext/common/syscalls_stub.d \
./ns_app/spe/api_ns/platform/ext/common/test_interrupt.d \
./ns_app/spe/api_ns/platform/ext/common/tfm_assert.d \
./ns_app/spe/api_ns/platform/ext/common/tfm_boot_measurement.d \
./ns_app/spe/api_ns/platform/ext/common/tfm_fatal_error.d \
./ns_app/spe/api_ns/platform/ext/common/tfm_hal_isolation_v8m.d \
./ns_app/spe/api_ns/platform/ext/common/tfm_hal_its.d \
./ns_app/spe/api_ns/platform/ext/common/tfm_hal_nvic.d \
./ns_app/spe/api_ns/platform/ext/common/tfm_hal_platform_v8m.d \
./ns_app/spe/api_ns/platform/ext/common/tfm_hal_ps.d \
./ns_app/spe/api_ns/platform/ext/common/tfm_hal_reset_halt.d \
./ns_app/spe/api_ns/platform/ext/common/tfm_hal_sp_logdev_periph.d \
./ns_app/spe/api_ns/platform/ext/common/tfm_hal_spm_logdev_peripheral.d \
./ns_app/spe/api_ns/platform/ext/common/tfm_interrupts.d \
./ns_app/spe/api_ns/platform/ext/common/tfm_sanitize_handlers.d \
./ns_app/spe/api_ns/platform/ext/common/uart_stdout.d 


# Each subdirectory must supply rules for building sources it contributes
ns_app/spe/api_ns/platform/ext/common/%.o ns_app/spe/api_ns/platform/ext/common/%.su ns_app/spe/api_ns/platform/ext/common/%.cyclo: ../ns_app/spe/api_ns/platform/ext/common/%.c ns_app/spe/api_ns/platform/ext/common/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m33 -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32H573xx -DDOMAIN_NS=1 -DCONFIG_TFM_FLOAT_ABI=2 -DCONFIG_TFM_ENABLE_CP10CP11 -DPLATFORM_DEFAULT_CRYPTO_KEYS -DCONFIG_TFM_USE_TRUSTZONE -DTFM_ISOLATION_LEVEL=1 -DTFM_PARTITION_CRYPTO -DTFM_PARTITION_INTERNAL_TRUSTED_STORAGE -DTFM_PARTITION_PROTECTED_STORAGE -DTFM_PARTITION_FIRMWARE_UPDATE -DTFM_PARTITION_INITIAL_ATTESTATION -DTFM_PARTITION_PLATFORM -DTFM_PSA_CRYPTO_CLIENT_ONLY '-DTF_PSA_CRYPTO_CONFIG_FILE="mbedtls/tf_psa_crypto_config.h"' '-DTARGET_CONFIG_HEADER_FILE="config_tfm_target.h"' -DBL2 -DBL2_HEADER_SIZE=0x400 -DBL2_TRAILER_SIZE=0x2000 -DMCUBOOT_IMAGE_NUMBER=2 -DTFM_NS_LOG -DNDEBUG -c -I../spe/api_ns/interface/include -I../spe/api_ns/interface/include/crypto_keys -I../spe/api_ns/platform/include -I../spe/api_ns/platform/boards -I../spe/api_ns/platform/Device/Include -I../spe/api_ns/platform/ext/cmsis/Include -I../spe/api_ns/platform/ext/cmsis/Include/m-profile -I../spe/api_ns/platform/ext/common -I../spe/api_ns/platform/hal/Inc -I"C:/Users/13584/Desktop/tfmproject/tfmcubeideproject/STM32CubeIDE/ns_app" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-ns_app-2f-spe-2f-api_ns-2f-platform-2f-ext-2f-common

clean-ns_app-2f-spe-2f-api_ns-2f-platform-2f-ext-2f-common:
	-$(RM) ./ns_app/spe/api_ns/platform/ext/common/bl2_hal_multisig.cyclo ./ns_app/spe/api_ns/platform/ext/common/bl2_hal_multisig.d ./ns_app/spe/api_ns/platform/ext/common/bl2_hal_multisig.o ./ns_app/spe/api_ns/platform/ext/common/bl2_hal_multisig.su ./ns_app/spe/api_ns/platform/ext/common/boot_hal_bl1_1.cyclo ./ns_app/spe/api_ns/platform/ext/common/boot_hal_bl1_1.d ./ns_app/spe/api_ns/platform/ext/common/boot_hal_bl1_1.o ./ns_app/spe/api_ns/platform/ext/common/boot_hal_bl1_1.su ./ns_app/spe/api_ns/platform/ext/common/boot_hal_bl1_2.cyclo ./ns_app/spe/api_ns/platform/ext/common/boot_hal_bl1_2.d ./ns_app/spe/api_ns/platform/ext/common/boot_hal_bl1_2.o ./ns_app/spe/api_ns/platform/ext/common/boot_hal_bl1_2.su ./ns_app/spe/api_ns/platform/ext/common/boot_hal_bl2.cyclo ./ns_app/spe/api_ns/platform/ext/common/boot_hal_bl2.d ./ns_app/spe/api_ns/platform/ext/common/boot_hal_bl2.o ./ns_app/spe/api_ns/platform/ext/common/boot_hal_bl2.su ./ns_app/spe/api_ns/platform/ext/common/exception_info.cyclo ./ns_app/spe/api_ns/platform/ext/common/exception_info.d ./ns_app/spe/api_ns/platform/ext/common/exception_info.o ./ns_app/spe/api_ns/platform/ext/common/exception_info.su ./ns_app/spe/api_ns/platform/ext/common/faults.cyclo ./ns_app/spe/api_ns/platform/ext/common/faults.d ./ns_app/spe/api_ns/platform/ext/common/faults.o ./ns_app/spe/api_ns/platform/ext/common/faults.su ./ns_app/spe/api_ns/platform/ext/common/mem_check_v6m_v7m.cyclo ./ns_app/spe/api_ns/platform/ext/common/mem_check_v6m_v7m.d ./ns_app/spe/api_ns/platform/ext/common/mem_check_v6m_v7m.o ./ns_app/spe/api_ns/platform/ext/common/mem_check_v6m_v7m.su ./ns_app/spe/api_ns/platform/ext/common/mpc_ppc_faults.cyclo ./ns_app/spe/api_ns/platform/ext/common/mpc_ppc_faults.d ./ns_app/spe/api_ns/platform/ext/common/mpc_ppc_faults.o ./ns_app/spe/api_ns/platform/ext/common/mpc_ppc_faults.su ./ns_app/spe/api_ns/platform/ext/common/provisioning.cyclo ./ns_app/spe/api_ns/platform/ext/common/provisioning.d ./ns_app/spe/api_ns/platform/ext/common/provisioning.o ./ns_app/spe/api_ns/platform/ext/common/provisioning.su ./ns_app/spe/api_ns/platform/ext/common/syscalls_stub.cyclo ./ns_app/spe/api_ns/platform/ext/common/syscalls_stub.d ./ns_app/spe/api_ns/platform/ext/common/syscalls_stub.o ./ns_app/spe/api_ns/platform/ext/common/syscalls_stub.su ./ns_app/spe/api_ns/platform/ext/common/test_interrupt.cyclo ./ns_app/spe/api_ns/platform/ext/common/test_interrupt.d ./ns_app/spe/api_ns/platform/ext/common/test_interrupt.o ./ns_app/spe/api_ns/platform/ext/common/test_interrupt.su ./ns_app/spe/api_ns/platform/ext/common/tfm_assert.cyclo ./ns_app/spe/api_ns/platform/ext/common/tfm_assert.d ./ns_app/spe/api_ns/platform/ext/common/tfm_assert.o ./ns_app/spe/api_ns/platform/ext/common/tfm_assert.su ./ns_app/spe/api_ns/platform/ext/common/tfm_boot_measurement.cyclo ./ns_app/spe/api_ns/platform/ext/common/tfm_boot_measurement.d ./ns_app/spe/api_ns/platform/ext/common/tfm_boot_measurement.o ./ns_app/spe/api_ns/platform/ext/common/tfm_boot_measurement.su ./ns_app/spe/api_ns/platform/ext/common/tfm_fatal_error.cyclo ./ns_app/spe/api_ns/platform/ext/common/tfm_fatal_error.d ./ns_app/spe/api_ns/platform/ext/common/tfm_fatal_error.o ./ns_app/spe/api_ns/platform/ext/common/tfm_fatal_error.su ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_isolation_v8m.cyclo ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_isolation_v8m.d ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_isolation_v8m.o ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_isolation_v8m.su ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_its.cyclo ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_its.d ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_its.o ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_its.su ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_nvic.cyclo ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_nvic.d ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_nvic.o ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_nvic.su ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_platform_v8m.cyclo ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_platform_v8m.d ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_platform_v8m.o ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_platform_v8m.su ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_ps.cyclo ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_ps.d ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_ps.o ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_ps.su ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_reset_halt.cyclo ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_reset_halt.d ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_reset_halt.o ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_reset_halt.su ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_sp_logdev_periph.cyclo ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_sp_logdev_periph.d ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_sp_logdev_periph.o ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_sp_logdev_periph.su ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_spm_logdev_peripheral.cyclo ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_spm_logdev_peripheral.d ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_spm_logdev_peripheral.o ./ns_app/spe/api_ns/platform/ext/common/tfm_hal_spm_logdev_peripheral.su ./ns_app/spe/api_ns/platform/ext/common/tfm_interrupts.cyclo ./ns_app/spe/api_ns/platform/ext/common/tfm_interrupts.d ./ns_app/spe/api_ns/platform/ext/common/tfm_interrupts.o ./ns_app/spe/api_ns/platform/ext/common/tfm_interrupts.su ./ns_app/spe/api_ns/platform/ext/common/tfm_sanitize_handlers.cyclo ./ns_app/spe/api_ns/platform/ext/common/tfm_sanitize_handlers.d ./ns_app/spe/api_ns/platform/ext/common/tfm_sanitize_handlers.o ./ns_app/spe/api_ns/platform/ext/common/tfm_sanitize_handlers.su ./ns_app/spe/api_ns/platform/ext/common/uart_stdout.cyclo ./ns_app/spe/api_ns/platform/ext/common/uart_stdout.d ./ns_app/spe/api_ns/platform/ext/common/uart_stdout.o ./ns_app/spe/api_ns/platform/ext/common/uart_stdout.su

.PHONY: clean-ns_app-2f-spe-2f-api_ns-2f-platform-2f-ext-2f-common

