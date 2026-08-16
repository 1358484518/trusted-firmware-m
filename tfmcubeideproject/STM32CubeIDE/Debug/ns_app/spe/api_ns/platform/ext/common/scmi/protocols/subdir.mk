################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (14.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../ns_app/spe/api_ns/platform/ext/common/scmi/protocols/scmi_power_domain.c \
../ns_app/spe/api_ns/platform/ext/common/scmi/protocols/scmi_system_power.c 

OBJS += \
./ns_app/spe/api_ns/platform/ext/common/scmi/protocols/scmi_power_domain.o \
./ns_app/spe/api_ns/platform/ext/common/scmi/protocols/scmi_system_power.o 

C_DEPS += \
./ns_app/spe/api_ns/platform/ext/common/scmi/protocols/scmi_power_domain.d \
./ns_app/spe/api_ns/platform/ext/common/scmi/protocols/scmi_system_power.d 


# Each subdirectory must supply rules for building sources it contributes
ns_app/spe/api_ns/platform/ext/common/scmi/protocols/%.o ns_app/spe/api_ns/platform/ext/common/scmi/protocols/%.su ns_app/spe/api_ns/platform/ext/common/scmi/protocols/%.cyclo: ../ns_app/spe/api_ns/platform/ext/common/scmi/protocols/%.c ns_app/spe/api_ns/platform/ext/common/scmi/protocols/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m33 -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32H573xx -DDOMAIN_NS=1 -DCONFIG_TFM_FLOAT_ABI=2 -DCONFIG_TFM_ENABLE_CP10CP11 -DPLATFORM_DEFAULT_CRYPTO_KEYS -DCONFIG_TFM_USE_TRUSTZONE -DTFM_ISOLATION_LEVEL=1 -DTFM_PARTITION_CRYPTO -DTFM_PARTITION_INTERNAL_TRUSTED_STORAGE -DTFM_PARTITION_PROTECTED_STORAGE -DTFM_PARTITION_FIRMWARE_UPDATE -DTFM_PARTITION_INITIAL_ATTESTATION -DTFM_PARTITION_PLATFORM -DTFM_PSA_CRYPTO_CLIENT_ONLY '-DTF_PSA_CRYPTO_CONFIG_FILE="mbedtls/tf_psa_crypto_config.h"' '-DTARGET_CONFIG_HEADER_FILE="config_tfm_target.h"' -DBL2 -DBL2_HEADER_SIZE=0x400 -DBL2_TRAILER_SIZE=0x2000 -DMCUBOOT_IMAGE_NUMBER=2 -DTFM_NS_LOG -DNDEBUG -c -I../spe/api_ns/interface/include -I../spe/api_ns/interface/include/crypto_keys -I../spe/api_ns/platform/include -I../spe/api_ns/platform/boards -I../spe/api_ns/platform/Device/Include -I../spe/api_ns/platform/ext/cmsis/Include -I../spe/api_ns/platform/ext/cmsis/Include/m-profile -I../spe/api_ns/platform/ext/common -I../spe/api_ns/platform/hal/Inc -I"C:/Users/13584/Desktop/tfmproject/tfmcubeideproject/STM32CubeIDE/ns_app" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-ns_app-2f-spe-2f-api_ns-2f-platform-2f-ext-2f-common-2f-scmi-2f-protocols

clean-ns_app-2f-spe-2f-api_ns-2f-platform-2f-ext-2f-common-2f-scmi-2f-protocols:
	-$(RM) ./ns_app/spe/api_ns/platform/ext/common/scmi/protocols/scmi_power_domain.cyclo ./ns_app/spe/api_ns/platform/ext/common/scmi/protocols/scmi_power_domain.d ./ns_app/spe/api_ns/platform/ext/common/scmi/protocols/scmi_power_domain.o ./ns_app/spe/api_ns/platform/ext/common/scmi/protocols/scmi_power_domain.su ./ns_app/spe/api_ns/platform/ext/common/scmi/protocols/scmi_system_power.cyclo ./ns_app/spe/api_ns/platform/ext/common/scmi/protocols/scmi_system_power.d ./ns_app/spe/api_ns/platform/ext/common/scmi/protocols/scmi_system_power.o ./ns_app/spe/api_ns/platform/ext/common/scmi/protocols/scmi_system_power.su

.PHONY: clean-ns_app-2f-spe-2f-api_ns-2f-platform-2f-ext-2f-common-2f-scmi-2f-protocols

