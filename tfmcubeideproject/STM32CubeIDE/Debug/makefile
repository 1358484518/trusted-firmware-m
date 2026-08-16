################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (14.3.rel1)
################################################################################

-include ../makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include ns_app/tfm_src/subdir.mk
-include ns_app/spe/out/obj/subdir.mk
-include ns_app/spe/api_ns/platform/hal/Src/subdir.mk
-include ns_app/spe/api_ns/platform/hal/CMSIS_Driver/subdir.mk
-include ns_app/spe/api_ns/platform/ext/common/template/subdir.mk
-include ns_app/spe/api_ns/platform/ext/common/scmi/protocols/subdir.mk
-include ns_app/spe/api_ns/platform/ext/common/scmi/subdir.mk
-include ns_app/spe/api_ns/platform/ext/common/provisioning_bundle/subdir.mk
-include ns_app/spe/api_ns/platform/ext/common/subdir.mk
-include ns_app/spe/api_ns/platform/Device/Source/subdir.mk
-include ns_app/spe/api_ns/interface/src/os_wrapper/subdir.mk
-include ns_app/spe/api_ns/interface/src/subdir.mk
-include ns_app/spe/api_ns/interface/lib/subdir.mk
-include ns_app/spe/api_ns/image_signing/layout_files/subdir.mk
-include ns_app/spe/api_ns/bin/subdir.mk
-include ns_app/spe/api_ns/subdir.mk
-include ns_app/subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(S_DEPS)),)
-include $(S_DEPS)
endif
ifneq ($(strip $(S_UPPER_DEPS)),)
-include $(S_UPPER_DEPS)
endif
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
endif

-include ../makefile.defs

OPTIONAL_TOOL_DEPS := \
$(wildcard ../makefile.defs) \
$(wildcard ../makefile.init) \
$(wildcard ../makefile.targets) \


BUILD_ARTIFACT_NAME := tfmminiproject
BUILD_ARTIFACT_EXTENSION := elf
BUILD_ARTIFACT_PREFIX :=
BUILD_ARTIFACT := $(BUILD_ARTIFACT_PREFIX)$(BUILD_ARTIFACT_NAME)$(if $(BUILD_ARTIFACT_EXTENSION),.$(BUILD_ARTIFACT_EXTENSION),)

# Add inputs and outputs from these tool invocations to the build variables 
EXECUTABLES += \
tfmminiproject.elf \

MAP_FILES += \
tfmminiproject.map \

SIZE_OUTPUT += \
default.size.stdout \

OBJDUMP_LIST += \
tfmminiproject.list \

OBJCOPY_BIN += \
tfmminiproject.bin \


# All Target
all: main-build

# Main-build Target
main-build: tfmminiproject.elf secondary-outputs

# Tool invocations
tfmminiproject.elf tfmminiproject.map: $(OBJS) $(USER_OBJS) ../ns_app/out/appli_ns.pp.ld makefile objects.list $(OPTIONAL_TOOL_DEPS)
	arm-none-eabi-gcc -o "tfmminiproject.elf" @"objects.list" $(USER_OBJS) $(LIBS) -mcpu=cortex-m33 -T"../ns_app/out/appli_ns.pp.ld" --specs=nosys.specs -Wl,-Map="tfmminiproject.map" -Wl,--gc-sections -static --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -Wl,--start-group -lc -lm -Wl,--end-group
	@echo 'Finished building target: $@'
	@echo ' '

default.size.stdout: $(EXECUTABLES) makefile objects.list $(OPTIONAL_TOOL_DEPS)
	arm-none-eabi-size  $(EXECUTABLES)
	@echo 'Finished building: $@'
	@echo ' '

tfmminiproject.list: $(EXECUTABLES) makefile objects.list $(OPTIONAL_TOOL_DEPS)
	arm-none-eabi-objdump -h -S $(EXECUTABLES) > "tfmminiproject.list"
	@echo 'Finished building: $@'
	@echo ' '

tfmminiproject.bin: $(EXECUTABLES) makefile objects.list $(OPTIONAL_TOOL_DEPS)
	arm-none-eabi-objcopy  -O binary $(EXECUTABLES) "tfmminiproject.bin"
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) default.size.stdout tfmminiproject.bin tfmminiproject.elf tfmminiproject.list tfmminiproject.map
	-@echo ' '

secondary-outputs: $(SIZE_OUTPUT) $(OBJDUMP_LIST) $(OBJCOPY_BIN)

fail-specified-linker-script-missing:
	@echo 'Error: Cannot find the specified linker script. Check the linker settings in the build configuration.'
	@exit 2

warn-no-linker-script-specified:
	@echo 'Warning: No linker script specified. Check the linker settings in the build configuration.'

.PHONY: all clean dependents main-build fail-specified-linker-script-missing warn-no-linker-script-specified

-include ../makefile.targets
