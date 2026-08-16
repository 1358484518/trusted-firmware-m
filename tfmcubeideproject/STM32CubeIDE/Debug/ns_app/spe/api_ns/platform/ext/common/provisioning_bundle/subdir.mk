################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (14.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/bl2_provisioning.c \
../ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/provisioning_code.c \
../ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/runtime_stub_provisioning.c 

OBJS += \
./ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/bl2_provisioning.o \
./ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/provisioning_code.o \
./ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/runtime_stub_provisioning.o 

C_DEPS += \
./ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/bl2_provisioning.d \
./ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/provisioning_code.d \
./ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/runtime_stub_provisioning.d 


# Each subdirectory must supply rules for building sources it contributes
ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/%.o ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/%.su ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/%.cyclo: ../ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/%.c ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m33 -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32H573xx -DDOMAIN_NS=1 -DCONFIG_TFM_FLOAT_ABI=2 -DCONFIG_TFM_ENABLE_CP10CP11 -DPLATFORM_DEFAULT_CRYPTO_KEYS -DCONFIG_TFM_USE_TRUSTZONE -DTFM_ISOLATION_LEVEL=1 -DTFM_PARTITION_CRYPTO -DTFM_PARTITION_INTERNAL_TRUSTED_STORAGE -DTFM_PARTITION_PROTECTED_STORAGE -DTFM_PARTITION_FIRMWARE_UPDATE -DTFM_PARTITION_INITIAL_ATTESTATION -DTFM_PARTITION_PLATFORM -DTFM_PSA_CRYPTO_CLIENT_ONLY '-DTF_PSA_CRYPTO_CONFIG_FILE="mbedtls/tf_psa_crypto_config.h"' '-DTARGET_CONFIG_HEADER_FILE="config_tfm_target.h"' -DBL2 -DBL2_HEADER_SIZE=0x400 -DBL2_TRAILER_SIZE=0x2000 -DMCUBOOT_IMAGE_NUMBER=2 -DTFM_NS_LOG -DNDEBUG -c -I../spe/api_ns/interface/include -I../spe/api_ns/interface/include/crypto_keys -I../spe/api_ns/platform/include -I../spe/api_ns/platform/boards -I../spe/api_ns/platform/Device/Include -I../spe/api_ns/platform/ext/cmsis/Include -I../spe/api_ns/platform/ext/cmsis/Include/m-profile -I../spe/api_ns/platform/ext/common -I../spe/api_ns/platform/hal/Inc -I"C:/Users/13584/Desktop/tfmproject/tfmcubeideproject/STM32CubeIDE/ns_app" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-ns_app-2f-spe-2f-api_ns-2f-platform-2f-ext-2f-common-2f-provisioning_bundle

clean-ns_app-2f-spe-2f-api_ns-2f-platform-2f-ext-2f-common-2f-provisioning_bundle:
	-$(RM) ./ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/bl2_provisioning.cyclo ./ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/bl2_provisioning.d ./ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/bl2_provisioning.o ./ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/bl2_provisioning.su ./ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/provisioning_code.cyclo ./ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/provisioning_code.d ./ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/provisioning_code.o ./ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/provisioning_code.su ./ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/runtime_stub_provisioning.cyclo ./ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/runtime_stub_provisioning.d ./ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/runtime_stub_provisioning.o ./ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/runtime_stub_provisioning.su

.PHONY: clean-ns_app-2f-spe-2f-api_ns-2f-platform-2f-ext-2f-common-2f-provisioning_bundle

