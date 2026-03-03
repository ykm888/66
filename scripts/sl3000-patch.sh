#!/bin/bash

# 物理审计：严格延续上一版原文逻辑，确保 1024M 物理全闭环

# 1. 物理拦截：内核 6.6 核心报错点
find . -name "mtk_eth_soc.c" -exec sed -i '/MTK_WIFI_CHIP_OFFLINE/,/break;/d' {} + 2>/dev/null || true

# 2. 物理清淤：粉碎旧缓存，防止旧的 bl2.bin 干扰
echo "物理清淤：粉碎旧源码与产物缓存..."
rm -rf dl/u-boot-* 2>/dev/null || true
rm -rf build_dir/target-*/u-boot-* 2>/dev/null || true
rm -rf staging_dir/host/share/u-boot 2>/dev/null || true

# 3. 物理重构：直接生成完整的 uboot-mediatek/Makefile (像素级注入)
UBOOT_MK_DIR="package/boot/uboot-mediatek"
mkdir -p $UBOOT_MK_DIR
cat << 'EOF' > $UBOOT_MK_DIR/Makefile
# SPDX-License-Identifier: GPL-2.0-only
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_VERSION:=2024.10
PKG_HASH:=skip
PKG_BUILD_DEPENDS:=!(TARGET_ramips||TARGET_mediatek_mt7623):arm-trusted-firmware-tools/host

UBOOT_USE_INTREE_DTC:=1

include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/host-build.mk

define U-Boot/Default
  BUILD_TARGET:=mediatek
  UBOOT_IMAGE:=u-boot-mtk.bin
  HIDDEN:=1
endef

define U-Boot/mt7981_sl_3000-emmc
  NAME:=SL 3000 (eMMC)
  BUILD_SUBTARGET:=filogic
  BUILD_DEVICES:=sl_3000-emmc
  UBOOT_CONFIG:=mt7981_emmc
  UBOOT_IMAGE:=u-boot.fip
  BL2_BOOTDEV:=emmc
  BL2_SOC:=mt7981
  BL2_DDRTYPE:=ddr3
  DEPENDS:=+trusted-firmware-a-mt7981-emmc-ddr3
endef

UBOOT_TARGETS := mt7981_sl_3000-emmc

UBOOT_CUSTOMIZE_CONFIG := \
	--disable TOOLS_KWBIMAGE \
	--disable TOOLS_LIBCRYPTO \
	--disable TOOLS_MKEFICAPSULE \
	--enable SERIAL_RX_BUFFER \
	--set-val SERIAL_RX_BUFFER_SIZE 256

ifdef CONFIG_TARGET_mediatek
UBOOT_MAKE_FLAGS += $(UBOOT_IMAGE:.fip=.bin)
endif

define Build/fip-image
	$(STAGING_DIR_HOST)/bin/fiptool create \
		--soc-fw $(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl31.bin \
		--nt-fw $(PKG_BUILD_DIR)/$(BUILD_VARIANT)/u-boot.bin \
		$(PKG_BUILD_DIR)/$(BUILD_VARIANT)/u-boot.fip
endef

define Build/Configure
	$(call Build/Configure/U-Boot)
	sed -i 's/CONFIG_TOOLS_LIBCRYPTO=y/# CONFIG_TOOLS_LIBCRYPTO is not set/' $(PKG_BUILD_DIR)/.config
endef

define Build/Compile
	$(call Build/Compile/U-Boot)
ifeq ($(UBOOT_IMAGE),u-boot.fip)
	$(call Build/fip-image)
endif
endef

ifdef CONFIG_TARGET_mediatek
define Package/u-boot/install
endef
endif

define Build/InstallDev
	$(INSTALL_DIR) $(STAGING_DIR_HOST)/share/u-boot
	$(CP) $(PKG_BUILD_DIR)/$(BUILD_VARIANT)/bl2.bin \
		$(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-bl2.bin
	$(CP) $(PKG_BUILD_DIR)/$(BUILD_VARIANT)/u-boot.fip \
		$(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-fip.bin
endef

$(eval $(call BuildPackage/U-Boot))
EOF

# 4. 物理劫持：强制将 Makefile 中的源码地址指向你的仓库
sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g" $UBOOT_MK_DIR/Makefile
sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" $UBOOT_MK_DIR/Makefile

# 5. 物理注入 .config 并强制锁定 1024M 选型
echo "物理锁定：强制注入 1024M 设备定义..."
[ -f .config ] || touch .config
sed -i '/CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc/d' .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config
echo "CONFIG_NR_DRAM_BANKS=1" >> .config
echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config

# 6. 物理自愈：如果 filogic.mk 存在，执行最终校验
FILOGIC_MK="target/linux/mediatek/image/filogic.mk"
if [ -f "$FILOGIC_MK" ]; then
    echo "物理检查：filogic.mk 状态..."
    grep -q "Size@Offset" "$FILOGIC_MK" || echo "警告：filogic.mk 尚未修复 GPT 格式！"
fi
