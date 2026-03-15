# SPDX-License-Identifier: BSD-3-Clause
# SL-3000 (MT7981) Physical Hardening Platform Config (Full Version)

MTK_PLAT		:=	plat/mediatek
MTK_PLAT_SOC		:=	$(MTK_PLAT)/$(PLAT)
APSOC_COMMON		:=	$(MTK_PLAT)/apsoc_common

# --- 【物理定标：1MB 偏移与 DDR4 锁定】 ---
MTK_FIP_BASE		:=	0x100000
DRAM_USE_DDR4		:=	1
DRAM_DEBUG_LOG		:=	1
DRAM_SIZE_LIMIT		:=	0
BOARD_BGA		:=	1

# 处理器勘误修复
ERRATA_A53_826319	:=	1
ERRATA_A53_836870	:=	1
ERRATA_A53_855873	:=	1

PROGRAMMABLE_RESET_ADDRESS	:=	1
ENABLE_SVE_FOR_NS		:=	0
MULTI_CONSOLE_API		:=	1
RESET_TO_BL2			:=	1
FIP_ARGS			+=	--align 8

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

include $(MTK_PLAT_SOC)/bl2pl/bl2pl.mk
include $(MTK_PLAT_SOC)/bl2/bl2.mk
include $(MTK_PLAT_SOC)/bl31/bl31.mk
include $(MTK_PLAT_SOC)/drivers/efuse/efuse.mk

# 强制加载救砖驱动源
BL2_SOURCES		+=	$(MTK_PLAT_SOC)/bl2/bl2_dev_spi_nor.c

include $(APSOC_COMMON)/bl2/tbbr_post.mk
include $(APSOC_COMMON)/bl2/ar_post.mk
include $(APSOC_COMMON)/bl2/bl2_image_post.mk

# 编译器宏传递 (物理死锁)
DEFINES += -DMTK_FIP_BASE=$(MTK_FIP_BASE)
DEFINES += -DDRAM_USE_DDR4=$(DRAM_USE_DDR4)

include make_helpers/dep.mk

# 依赖与参数对齐
$(call GEN_DEP_RULES,bl2,bl2_dev_spi_nor emicfg dram_log bl2_boot_ram bl2_boot_nand_nmbm bl2_dev_mmc bl2_plat_init bl2_plat_setup mt7981_gpio dtb)
$(call MAKE_DEP,bl2,bl2_dev_spi_nor,BOOT_DEVICE DRAM_USE_DDR4 MTK_FIP_BASE)
$(call MAKE_DEP,bl2,emicfg,DRAM_USE_DDR4 DRAM_SIZE_LIMIT BOARD_QFN BOARD_BGA)
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
