#!/bin/bash
PATCH_SRC="${GITHUB_WORKSPACE}/custom-config"

# 1. 内存物理锁定 1024M
MT7981_MK="target/linux/mediatek/image/mt7981.mk"
if [ -f "$MT7981_MK" ]; then
    sed -i 's/DRAM_SIZE_256M=y/DRAM_SIZE_1024M=y/g' "$MT7981_MK"
    sed -i 's/DRAM_SIZE_512M=y/DRAM_SIZE_1024M=y/g' "$MT7981_MK"
fi

# 2. 内核符号物理注入
ETH_SOC_SRC=$(find build_dir/ -name "mtk_eth_soc.c" | grep "linux-mediatek_filogic" | head -n 1)
if [ -n "$ETH_SOC_SRC" ]; then
    sed -i '/#include/a \
#ifndef MTK_FE_START_RESET\
#define MTK_FE_START_RESET 0x10\
#define MTK_FE_RESET_DONE 0x11\
#endif' "$ETH_SOC_SRC"
fi

# 3. 三件套原文移植
# 覆盖 DTS
[ -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" ] && cp -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" target/linux/mediatek/dts/

# 缝合 Makefile (保留你的官方框架结构)
if [ -f "$PATCH_SRC/filogic.mk" ]; then
    cat "$PATCH_SRC/filogic.mk" >> target/linux/mediatek/image/filogic.mk
fi

# 4. 物理修复：U-Boot 路径死锁
# 核心动作：你的 filogic.mk 里引用了 sl_3000-emmc，
# 但 U-Boot 只有 emmc 分支。这里建立物理软链接解决 No such file。
UBOOT_PATH="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_PATH" ]; then
    # 在 U-Boot 的 Makefile 中物理注入你的设备变体，使其指向标准 emmc
    sed -i '/define Device\/mt7981_emmc/,/endef/ { /endef/i \
define Device\/mt7981_sl_3000-emmc\
  NAME:=SL 3000 eMMC\
  DEPENDS:=+kmod-mmc\
endef
    }' "$UBOOT_PATH"
    sed -i 's/UBOOT_TARGETS += mt7981_emmc/UBOOT_TARGETS += mt7981_emmc mt7981_sl_3000-emmc/g' "$UBOOT_PATH"
fi

exit 0
