# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

# 物理版本锁定
PKG_VERSION:=2024.10
PKG_HASH:=b28daf4ac17e43156363078bf510297584137f6df50fced9b12df34f61a92fb0
PKG_BUILD_DEPENDS:=!(TARGET_ramips||TARGET_mediatek_mt7623):arm-trusted-firmware-tools/host

UBOOT_USE_INTREE_DTC:=1

include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/host-build.mk

# 默认设备物理模板
define U-Boot/Default
  BUILD_TARGET:=mediatek
  UBOOT_IMAGE:=u-boot-mtk.bin
  HIDDEN:=1
endef

# 物理对齐：SL-3000 1024M EMMC 救砖定义
define U-Boot/mt7981_sl_3000-emmc
  NAME:=SL 3000 (eMMC)
  BUILD_SUBTARGET:=filogic
  BUILD_DEVICES:=sl_3000-emmc
  UBOOT_CONFIG:=mt7981_emmc
  UBOOT_IMAGE:=u-boot.fip
  BL2_BOOTDEV:=emmc
  BL2_SOC:=mt7981
  BL2_DDRTYPE:=ddr3
  # 物理依赖：必须先有 ATF 产出的 bl31.bin
  DEPENDS:=+trusted-firmware-a-mt7981-emmc-ddr3
endef

# 物理清单：仅锁定 SL-3000
UBOOT_TARGETS := \
	mt7981_sl_3000-emmc

UBOOT_CUSTOMIZE_CONFIG := \
	--disable TOOLS_KWBIMAGE \
	--disable TOOLS_LIBCRYPTO \
	--disable TOOLS_MKEFICAPSULE \
	--enable SERIAL_RX_BUFFER \
	--set-val SERIAL_RX_BUFFER_SIZE 256

ifdef CONFIG_TARGET_mediatek
UBOOT_MAKE_FLAGS += $(UBOOT_IMAGE:.fip=.bin)
endif

# 物理合成：从子目录提取产物进行 FIP 合成
define Build/fip-image
	$(STAGING_DIR_HOST)/bin/fiptool create \
		--soc-fw $(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl31.bin \
		--nt-fw $(PKG_BUILD_DIR)/$(BUILD_VARIANT)/u-boot.bin \
		$(PKG_BUILD_DIR)/$(BUILD_VARIANT)/u-boot.fip
endef

define Build/Configure
	$(call Build/Configure/U-Boot)
	# 物理脱敏：移除工具链对 libcrypto 的强制依赖
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

# 物理修复：源头解决目录不存在及路径对齐问题
define Build/InstallDev
	# 1. 强制建立物理隧道：确保 host 共享目录存在
	$(INSTALL_DIR) $(STAGING_DIR_HOST)/share/u-boot
	# 2. 物理提取 BL2 并强制改名交付至 host 共享区 (对齐 filogic.mk 的探测路径)
	$(CP) $(PKG_BUILD_DIR)/$(BUILD_VARIANT)/bl2.bin \
		$(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-bl2.bin
	# 3. 物理提取 FIP 并强制改名交付
	$(CP) $(PKG_BUILD_DIR)/$(BUILD_VARIANT)/u-boot.fip \
		$(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-fip.bin
	# 4. 同时保留镜像区备份
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	$(CP) $(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-bl2.bin $(STAGING_DIR_IMAGE)/
	$(CP) $(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-fip.bin $(STAGING_DIR_IMAGE)/
endef

$(eval $(call BuildPackage/U-Boot))
