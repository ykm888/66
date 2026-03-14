#
# Copyright (c) 2023, MediaTek Inc. All rights reserved.
# Copyright (c) 2026, ykm888 (Physical Hardening for SL-3000)
#
# SPDX-License-Identifier: BSD-3-Clause
#

MTK_PLAT		:=	plat/mediatek
MTK_PLAT_SOC		:=	$(MTK_PLAT)/$(PLAT)
APSOC_COMMON		:=	$(MTK_PLAT)/apsoc_common

# Enable workarounds for selected Cortex-A53 erratas.
ERRATA_A53_826319	:=	1
ERRATA_A53_836870	:=	1
ERRATA_A53_855873	:=	1

# Indicate the reset vector address can be programmed
PROGRAMMABLE_RESET_ADDRESS	:=	1

# Do not enable SVE
ENABLE_SVE_FOR_NS	:=	0
MULTI_CONSOLE_API	:=	1

RESET_TO_BL2		:=	1

# FIP alignment (Ensures FIP structure integrity)
FIP_ARGS		+=	--align 8

# --- 物理包含路径 ---
PLAT_INCLUDES		:=	-I$(APSOC_COMMON)				\
				-I$(APSOC_COMMON)/drivers/uart			\
				-I$(APSOC_COMMON)/drivers/trng/v2		\
				-I$(APSOC_COMMON)/drivers/wdt			\
				-Iinclude/plat/arm/common			\
				-Iinclude/plat/arm/common/aarch64		\
				-I$(MTK_PLAT_SOC)/drivers/spmc			\
				-I$(MTK_PLAT_SOC)/drivers/timer			\
				-I$(MTK_PLAT_SOC)/drivers/pll			\
				-I$(MTK_PLAT_SOC)/drivers/devapc		\
				-I$(MTK_PLAT_SOC)/include			\
				-I$(MTK_PLAT_SOC)/drivers/dram

# --- 核心组件包含 ---
include $(MTK_PLAT_SOC)/bl2pl/bl2pl.mk
include $(MTK_PLAT_SOC)/bl2/bl2.mk
include $(MTK_PLAT_SOC)/bl31/bl31.mk
include $(MTK_PLAT_SOC)/drivers/efuse/efuse.mk

# --- 【物理加固点 1】：强制追加 SPI-NOR 驱动到 BL2 源码列表 ---
# 这一步确保即使 bl2.mk 逻辑失效，驱动也会被编译进去
BL2_SOURCES		+=	$(MTK_PLAT_SOC)/bl2/bl2_dev_spi_nor.c

include $(APSOC_COMMON)/bl2/tbbr_post.mk
include $(APSOC_COMMON)/bl2/ar_post.mk
include $(APSOC_COMMON)/bl2/bl2_image_post.mk

# OP-TEE & Memory Security
OPTEE_TZRAM_SIZE := 0x10000
ifneq ($(BL32),)
    ifeq ($(TRUSTED_BOARD_BOOT),1)
        DEFINES += -DNEED_BL32
        OPTEE_TZRAM_SIZE := 0x500000
    endif
endif
DEFINES += -DOPTEE_TZRAM_SIZE=$(OPTEE_TZRAM_SIZE)

# Make sure make command parameter reflects on .o files immediately
include make_helpers/dep.mk

# --- 【物理加固点 2】：逻辑注册与依赖锁定 ---
# 将 bl2_dev_spi_nor 加入 GEN_DEP_RULES，确保生成对应的 .o 目标文件
$(call GEN_DEP_RULES,bl2,bl2_dev_spi_nor emicfg dram_log bl2_boot_ram bl2_boot_nand_nmbm bl2_dev_mmc bl2_plat_init bl2_plat_setup mt7981_gpio dtb)

# 物理链接：将驱动与 BOOT_DEVICE 参数锁定，确保在 NOR 启动时激活 1MB 偏移逻辑
$(call MAKE_DEP,bl2,bl2_dev_spi_nor,BOOT_DEVICE)

$(call MAKE_DEP,bl2,emicfg,DRAM_USE_DDR4 DRAM_SIZE_LIMIT DDR3_FREQ_2133 DDR3_FREQ_1866 BOARD_QFN BOARD_BGA)
$(call MAKE_DEP,bl2,dram_log,DRAM_DEBUG_LOG)
$(call MAKE_DEP,bl2,bl2_plat_init,BL2_COMPRESS)
$(call MAKE_DEP,bl2,bl2_plat_setup,BOOT_DEVICE TRUSTED_BOARD_BOOT DUAL_FIP)
$(call MAKE_DEP,bl2,bl2_dev_mmc,BOOT_DEVICE)
$(call MAKE_DEP,bl2,bl2_boot_ram,RAM_BOOT_DEBUGGER_HOOK RAM_BOOT_UART_DL)
$(call MAKE_DEP,bl2,bl2_boot_nand_nmbm,NMBM_MAX_RATIO NMBM_MAX_RESERVED_BLOCKS NMBM_DEFAULT_LOG_LEVEL)
$(call MAKE_DEP,bl2,mt7981_gpio,ENABLE_JTAG)
$(call MAKE_DEP,bl2,dtb,BOOT_DEVICE)

$(call GEN_DEP_RULES,bl31,bl31_plat_setup)
$(call MAKE_DEP,bl31,bl31_plat_setup,ANTI_ROLLBACK TRUSTED_BOARD_BOOT)
