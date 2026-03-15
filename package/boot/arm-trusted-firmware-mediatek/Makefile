#
# Copyright (C) 2024-2026 ykm888
# 针对 SL-3000 (MT7981) 适配 1MB 偏移黄金救砖分支
#

include $(TOPDIR)/rules.mk

PKG_NAME:=arm-trusted-firmware-mediatek
PKG_RELEASE:=1
PKG_VERSION:=sl3000

# --- 核心：物理指向你的黄金分支 ---
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=sl3000-clean-source
PKG_MIRROR_HASH:=skip

PKG_MAINTAINER:=ykm888

# 物理仓库内的源码目录名
ATF_SRC_SUBDIR:=atf

# 物理构建目录定义：适配变体构建，防止路径死锁
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/trusted-firmware-a.mk
include $(INCLUDE_DIR)/package.mk

# --- 1. 零件工艺默认参数 ---
define Trusted-Firmware-A/Default
  BUILD_TARGET:=mediatek
  BUILD_SUBTARGET:=filogic
  PLAT:=mt7981
  # 必须产出 bl2.bin 和 fip.bin
  TFA_IMAGE:=bl2.bin fip.bin
endef

# --- 2. 物理变体修复：严格对齐 CONFIG_PACKAGE_...-mt7981-nor-ddr4 ---
define Trusted-Firmware-A/mt7981-nor-ddr4
  NAME:=SL-3000 (Hardened NOR-DDR4)
  # 传递给编译器的救砖核心参数
  TFA_MAKE_FLAGS:=BOOT_DEVICE=nor DRAM_USE_DDR4=1
endef

# 宣告变体目标
TFA_TARGETS:=mt7981-nor-ddr4

# --- 3. 物理编译选项 ---
TFA_MAKE_FLAGS += \
	BOOT_DEVICE=nor \
	TRUSTED_BOARD_BOOT=0 \
	WERROR=0 \
	DEBUG=0

# --- 4. 物理工地准备 ---
define Build/Prepare
	$(call Build/Prepare/Default)
	@echo "Physical Surgery: Aligning ATF source from subfolder..."
	# 如果源码在 atf 文件夹里，将其提升至根目录，否则模板会找不到 Makefile
	if [ -d "$(PKG_BUILD_DIR)/$(ATF_SRC_SUBDIR)" ]; then \
		cp -rf $(PKG_BUILD_DIR)/$(ATF_SRC_SUBDIR)/* $(PKG_BUILD_DIR)/; \
	fi
	
	# 暴力消除 GCC 警告导致的 Error 2
	find $(PKG_BUILD_DIR) -type f -name "Makefile*" -exec sed -i 's/-Werror//g' {} + || true
	find $(PKG_BUILD_DIR) -type f -name "*.mk" -exec sed -i 's/-Werror//g' {} + || true
endef

# --- 5. 零件分发逻辑：产出救砖专用镜像 ---
define Package/trusted-firmware-a-$(1)/install
	# 执行模板默认安装逻辑
	$(call Package/trusted-firmware-a/install/default,$(1))
	
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	# 物理重命名并提取到 Image 目录
	if [ -f $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin ]; then \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin $(STAGING_DIR_IMAGE)/bl2.img; \
	fi
	
	# 物理备份：同步到 Bin 目录，方便 Action 打包上传
	$(INSTALL_DIR) $(BIN_DIR)/sl3000-recovery
	[ -f $(STAGING_DIR_IMAGE)/bl2.img ] && \
		$(CP) $(STAGING_DIR_IMAGE)/bl2.img $(BIN_DIR)/sl3000-recovery/bl2.img; \
	[ -f $(PKG_BUILD_DIR)/build/$(PLAT)/release/fip.bin ] && \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/fip.bin $(BIN_DIR)/sl3000-recovery/fip.bin
endef

$(eval $(call BuildPackage/Trusted-Firmware-A))
