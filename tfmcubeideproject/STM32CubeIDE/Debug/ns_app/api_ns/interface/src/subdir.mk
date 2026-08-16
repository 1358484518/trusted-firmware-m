################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (14.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../ns_app/api_ns/interface/src/tfm_attest_api.c \
../ns_app/api_ns/interface/src/tfm_crypto_api.c \
../ns_app/api_ns/interface/src/tfm_fwu_api.c \
../ns_app/api_ns/interface/src/tfm_its_api.c \
../ns_app/api_ns/interface/src/tfm_platform_api.c \
../ns_app/api_ns/interface/src/tfm_ps_api.c \
../ns_app/api_ns/interface/src/tfm_tz_psa_ns_api.c 

OBJS += \
./ns_app/api_ns/interface/src/tfm_attest_api.o \
./ns_app/api_ns/interface/src/tfm_crypto_api.o \
./ns_app/api_ns/interface/src/tfm_fwu_api.o \
./ns_app/api_ns/interface/src/tfm_its_api.o \
./ns_app/api_ns/interface/src/tfm_platform_api.o \
./ns_app/api_ns/interface/src/tfm_ps_api.o \
./ns_app/api_ns/interface/src/tfm_tz_psa_ns_api.o 

C_DEPS += \
./ns_app/api_ns/interface/src/tfm_attest_api.d \
./ns_app/api_ns/interface/src/tfm_crypto_api.d \
./ns_app/api_ns/interface/src/tfm_fwu_api.d \
./ns_app/api_ns/interface/src/tfm_its_api.d \
./ns_app/api_ns/interface/src/tfm_platform_api.d \
./ns_app/api_ns/interface/src/tfm_ps_api.d \
./ns_app/api_ns/interface/src/tfm_tz_psa_ns_api.d 


# Each subdirectory must supply rules for building sources it contributes
ns_app/api_ns/interface/src/%.o ns_app/api_ns/interface/src/%.su ns_app/api_ns/interface/src/%.cyclo: ../ns_app/api_ns/interface/src/%.c ns_app/api_ns/interface/src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m33 -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32H573xx -DDOMAIN_NS=1 -DCONFIG_TFM_FLOAT_ABI=2 -DCONFIG_TFM_ENABLE_CP10CP11 -DPLATFORM_DEFAULT_CRYPTO_KEYS -DCONFIG_TFM_USE_TRUSTZONE -DTFM_ISOLATION_LEVEL=1 -DTFM_PARTITION_CRYPTO -DTFM_PARTITION_INTERNAL_TRUSTED_STORAGE -DTFM_PARTITION_PROTECTED_STORAGE -DTFM_PARTITION_FIRMWARE_UPDATE -DTFM_PARTITION_INITIAL_ATTESTATION -DTFM_PARTITION_PLATFORM -DTFM_PSA_CRYPTO_CLIENT_ONLY '-DTF_PSA_CRYPTO_CONFIG_FILE="mbedtls/tf_psa_crypto_config.h"' '-DTARGET_CONFIG_HEADER_FILE="config_tfm_target.h"' -DBL2 -DBL2_HEADER_SIZE=0x400 -DBL2_TRAILER_SIZE=0x2000 -DMCUBOOT_IMAGE_NUMBER=2 -DTFM_NS_LOG -DNDEBUG -c -I"C:/Users/13584/Desktop/tfmproject/tfmcubeideproject/STM32CubeIDE/ns_app" -I"C:/Users/13584/Desktop/tfmproject/tfmcubeideproject/STM32CubeIDE/ns_app/api_ns/interface/include" -I"C:/Users/13584/Desktop/tfmproject/tfmcubeideproject/STM32CubeIDE/ns_app/api_ns/interface/include/crypto_keys" -I"C:/Users/13584/Desktop/tfmproject/tfmcubeideproject/STM32CubeIDE/ns_app/api_ns/platform/include" -I"C:/Users/13584/Desktop/tfmproject/tfmcubeideproject/STM32CubeIDE/ns_app/api_ns/platform/boards" -I"C:/Users/13584/Desktop/tfmproject/tfmcubeideproject/STM32CubeIDE/ns_app/api_ns/platform/Device/Include" -I"C:/Users/13584/Desktop/tfmproject/tfmcubeideproject/STM32CubeIDE/ns_app/api_ns/platform/ext/cmsis/Include" -I"C:/Users/13584/Desktop/tfmproject/tfmcubeideproject/STM32CubeIDE/ns_app/api_ns/platform/ext/cmsis/Include/m-profile" -I"C:/Users/13584/Desktop/tfmproject/tfmcubeideproject/STM32CubeIDE/ns_app/api_ns/platform/ext/common" -I"C:/Users/13584/Desktop/tfmproject/tfmcubeideproject/STM32CubeIDE/ns_app/api_ns/platform/hal/Inc" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-ns_app-2f-api_ns-2f-interface-2f-src

clean-ns_app-2f-api_ns-2f-interface-2f-src:
	-$(RM) ./ns_app/api_ns/interface/src/tfm_attest_api.cyclo ./ns_app/api_ns/interface/src/tfm_attest_api.d ./ns_app/api_ns/interface/src/tfm_attest_api.o ./ns_app/api_ns/interface/src/tfm_attest_api.su ./ns_app/api_ns/interface/src/tfm_crypto_api.cyclo ./ns_app/api_ns/interface/src/tfm_crypto_api.d ./ns_app/api_ns/interface/src/tfm_crypto_api.o ./ns_app/api_ns/interface/src/tfm_crypto_api.su ./ns_app/api_ns/interface/src/tfm_fwu_api.cyclo ./ns_app/api_ns/interface/src/tfm_fwu_api.d ./ns_app/api_ns/interface/src/tfm_fwu_api.o ./ns_app/api_ns/interface/src/tfm_fwu_api.su ./ns_app/api_ns/interface/src/tfm_its_api.cyclo ./ns_app/api_ns/interface/src/tfm_its_api.d ./ns_app/api_ns/interface/src/tfm_its_api.o ./ns_app/api_ns/interface/src/tfm_its_api.su ./ns_app/api_ns/interface/src/tfm_platform_api.cyclo ./ns_app/api_ns/interface/src/tfm_platform_api.d ./ns_app/api_ns/interface/src/tfm_platform_api.o ./ns_app/api_ns/interface/src/tfm_platform_api.su ./ns_app/api_ns/interface/src/tfm_ps_api.cyclo ./ns_app/api_ns/interface/src/tfm_ps_api.d ./ns_app/api_ns/interface/src/tfm_ps_api.o ./ns_app/api_ns/interface/src/tfm_ps_api.su ./ns_app/api_ns/interface/src/tfm_tz_psa_ns_api.cyclo ./ns_app/api_ns/interface/src/tfm_tz_psa_ns_api.d ./ns_app/api_ns/interface/src/tfm_tz_psa_ns_api.o ./ns_app/api_ns/interface/src/tfm_tz_psa_ns_api.su

.PHONY: clean-ns_app-2f-api_ns-2f-interface-2f-src

