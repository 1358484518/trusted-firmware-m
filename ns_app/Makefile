# Bare-metal NS image for STM32H573I-DK, linked against TF-M SPE export.
#
# Supported layouts:
#   Makefile, main.c, api_ns/     (siblings)
#   ns_app/{Makefile,main.c}  +  ../build_s/api_ns
#
#   make
#   make SPE=/path/to/api_ns
#   make TOOLCHAIN_DIR=/path/to/arm-gnu-toolchain/bin
#   make clean
#
# CPU/ABI must match SPE: cortex-m33+nodsp+nofp, soft float.
# s_veneers.o is linked as a raw object (absolute NSC addresses).
#
# NS bring-up matches tf-m-tests/app_broker/main_ns.c without RTX.
# Only main.c is local. Other sources are copied from TF-M / tf-m-tests
# or compiled from the SPE api_ns export.

NS_APP      := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ROOT        := $(abspath $(NS_APP)/..)
ifeq ($(wildcard $(NS_APP)/api_ns/interface/lib/s_veneers.o),)
SPE         ?= $(ROOT)/build_s/api_ns
else
SPE         ?= $(NS_APP)/api_ns
endif
OUT         := $(NS_APP)/out
OBJDIR      := $(OUT)/obj

CROSS       ?= arm-none-eabi
TOOLCHAIN_DIR ?=
ifneq ($(TOOLCHAIN_DIR),)
export PATH := $(TOOLCHAIN_DIR):$(PATH)
endif

CC          := $(CROSS)-gcc
OBJCOPY     := $(CROSS)-objcopy
NM          := $(CROSS)-nm

ifeq ($(wildcard $(ROOT)/.venv/bin/python),$(ROOT)/.venv/bin/python)
PYTHON      ?= $(ROOT)/.venv/bin/python
else
PYTHON      ?= python3
endif

CPU         := -mcpu=cortex-m33+nodsp+nofp -mthumb -mfloat-abi=soft

CPPFLAGS    := \
	-DSTM32H573xx \
	-DUSE_HAL_DRIVER \
	-DDOMAIN_NS=1 \
	-DCONFIG_TFM_FLOAT_ABI=0 \
	-DPLATFORM_DEFAULT_CRYPTO_KEYS \
	-DCONFIG_TFM_USE_TRUSTZONE \
	-DTFM_ISOLATION_LEVEL=1 \
	-DTFM_PARTITION_CRYPTO \
	-DTFM_PARTITION_INTERNAL_TRUSTED_STORAGE \
	-DTFM_PARTITION_PROTECTED_STORAGE \
	-DTFM_PARTITION_FIRMWARE_UPDATE \
	-DTFM_PARTITION_INITIAL_ATTESTATION \
	-DTFM_PARTITION_PLATFORM \
	-DTFM_PSA_CRYPTO_CLIENT_ONLY \
	-DTF_PSA_CRYPTO_CONFIG_FILE='"mbedtls/tf_psa_crypto_config.h"' \
	-DTARGET_CONFIG_HEADER_FILE='"config_tfm_target.h"' \
	-DBL2 \
	-DBL2_HEADER_SIZE=0x400 \
	-DBL2_TRAILER_SIZE=0x2000 \
	-DMCUBOOT_IMAGE_NUMBER=2 \
	-I$(SPE)/interface/include \
	-I$(SPE)/interface/include/crypto_keys \
	-I$(SPE)/platform/include \
	-I$(SPE)/platform/boards \
	-I$(SPE)/platform/Device/Include \
	-I$(SPE)/platform/ext/cmsis/Include \
	-I$(SPE)/platform/ext/cmsis/Include/m-profile \
	-I$(SPE)/platform/ext/common \
	-I$(SPE)/platform/hal/Inc

CFLAGS      := $(CPU) -std=gnu11 -g -ffunction-sections -fdata-sections \
	-fno-builtin -funsigned-char -Wall -DNDEBUG $(CPPFLAGS)

LDFLAGS     := $(CPU) -specs=nano.specs -specs=nosys.specs \
	-Wl,--gc-sections -Wl,--print-memory-usage \
	-Wl,-Map=$(OUT)/tfm_ns.map \
	-T $(OUT)/appli_ns.pp.ld

APP_SRCS := \
	$(NS_APP)/main.c \
	$(NS_APP)/syscalls_stub.c \
	$(NS_APP)/platform_init_def.c

SPE_SRCS := \
	$(SPE)/interface/src/os_wrapper/tfm_ns_interface_bare_metal.c \
	$(SPE)/interface/src/tfm_tz_psa_ns_api.c \
	$(SPE)/interface/src/tfm_crypto_api.c \
	$(SPE)/interface/src/tfm_its_api.c \
	$(SPE)/interface/src/tfm_ps_api.c \
	$(SPE)/interface/src/tfm_fwu_api.c \
	$(SPE)/interface/src/tfm_attest_api.c \
	$(SPE)/interface/src/tfm_platform_api.c \
	$(SPE)/platform/Device/Source/startup_stm32h5xx_ns.c \
	$(SPE)/platform/Device/Source/system_stm32h5xx.c \
	$(SPE)/platform/ext/common/uart_stdout.c \
	$(SPE)/platform/hal/CMSIS_Driver/low_level_com.c \
	$(SPE)/platform/hal/Src/stm32h5xx_hal.c \
	$(SPE)/platform/hal/Src/stm32h5xx_hal_cortex.c \
	$(SPE)/platform/hal/Src/stm32h5xx_hal_dma.c \
	$(SPE)/platform/hal/Src/stm32h5xx_hal_dma_ex.c \
	$(SPE)/platform/hal/Src/stm32h5xx_hal_gpio.c \
	$(SPE)/platform/hal/Src/stm32h5xx_hal_pwr.c \
	$(SPE)/platform/hal/Src/stm32h5xx_hal_pwr_ex.c \
	$(SPE)/platform/hal/Src/stm32h5xx_hal_rcc.c \
	$(SPE)/platform/hal/Src/stm32h5xx_hal_rcc_ex.c \
	$(SPE)/platform/hal/Src/stm32h5xx_hal_uart.c \
	$(SPE)/platform/hal/Src/stm32h5xx_hal_uart_ex.c

SRCS        := $(APP_SRCS) $(SPE_SRCS)
OBJS        := $(addprefix $(OBJDIR)/,$(notdir $(SRCS:.c=.o)))
VENEERS     := $(SPE)/interface/lib/s_veneers.o
LDSCRIPT_IN := $(SPE)/platform/linker_scripts/appli_ns.ld
LDSCRIPT    := $(OUT)/appli_ns.pp.ld

.PHONY: all clean

all: $(OUT)/tfm_ns_signed.bin

$(OBJDIR) $(OUT):
	mkdir -p $@

$(LDSCRIPT): $(LDSCRIPT_IN) | $(OUT)
	@echo "PP  $(notdir $<)"
	$(CC) $(CFLAGS) -E -P -xc $< -o $@

define COMPILE_C
$(OBJDIR)/$(notdir $(1:.c=.o)): $(1) | $(OBJDIR)
	@echo "CC  $$(notdir $$<)"
	$(CC) $(CFLAGS) -c $$< -o $$@
endef
$(foreach src,$(SRCS),$(eval $(call COMPILE_C,$(src))))

$(OUT)/tfm_ns.axf: $(OBJS) $(VENEERS) $(LDSCRIPT) | $(OUT)
	@echo "LD  $(notdir $@)"
	$(CC) $(LDFLAGS) -o $@ $(OBJS) $(VENEERS)
	$(NM) $@ | grep ' tfm_psa_call_veneer$$' || true

$(OUT)/tfm_ns.bin: $(OUT)/tfm_ns.axf
	$(OBJCOPY) -O binary $< $@

$(OUT)/tfm_ns.hex: $(OUT)/tfm_ns.axf
	$(OBJCOPY) -O ihex $< $@

# imgtool (wrapper.py) needs: intelhex click cryptography cbor2
# wrapper.py also does "import bl2.macro_parser"; api_ns ships macro_parser.py
# but not the bl2 package. Build a tiny shim on PYTHONPATH.
.PHONY: python-deps
python-deps:
	$(PYTHON) -m pip install intelhex click cryptography cbor2 pyyaml

BL2_PY := $(OUT)/pypath

$(OUT)/tfm_ns_signed.bin: $(OUT)/tfm_ns.bin $(OUT)/tfm_ns.hex
	@echo "SIGN $(notdir $@)"
	@$(PYTHON) -c "import intelhex, click, cryptography, cbor2" || \
		(echo "Missing imgtool Python deps. Run: make python-deps"; \
		 echo "or: $(PYTHON) -m pip install intelhex click cryptography cbor2"; exit 1)
	mkdir -p $(BL2_PY)/bl2
	touch $(BL2_PY)/bl2/__init__.py
	cp -f $(SPE)/image_signing/scripts/macro_parser.py $(BL2_PY)/bl2/macro_parser.py
	cd $(SPE)/image_signing/scripts && PYTHONPATH=$(BL2_PY):$$PYTHONPATH $(PYTHON) wrapper.py \
		--version 0.0.0 \
		--layout $(SPE)/image_signing/layout_files/signing_layout_ns.o \
		--key $(SPE)/image_signing/keys/image_ns_signing_private_key.pem \
		--public-key-format full \
		--align 16 \
		--pad \
		--pad-header \
		-H 0x400 \
		-s 1 \
		-L 128 \
		-d "(0, 0.0.0+0)" \
		--measured-boot-record \
		$(OUT)/tfm_ns.bin \
		$(OUT)/tfm_ns_signed.bin

$(VENEERS):
	$(error SPE export not found: $@  (set SPE=/path/to/build_s/api_ns))

clean:
	rm -rf $(OUT)
