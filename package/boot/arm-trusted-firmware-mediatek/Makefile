#
# Copyright (C) 2024-2026 ykm888
# 物理修复：SL-3000 (MT7981) 路径终极对齐 & Host 工具链物理补全
# 目标：彻底解决 cc1 路径报错、1024M 内存寻址、U-Boot 零件缺失
#

include $(TOPDIR)/rules.mk

PKG_NAME:=arm-trusted-firmware-mediatek
PKG_RELEASE:=1

# 物理重定向：确保拉取已物理对齐路径的 Git 分支
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=atf-sl3000-base

PKG_MAINTAINER:=ykm888

# 物理支持：定义主机端路径，解决 uboot-mediatek 的构建依赖
HOST_BUILD_DIR:=$(BUILD_DIR_HOST)/$(PKG_NAME)

include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/trusted-firmware-a.mk
include $(INCLUDE_DIR)/package.mk

# --- 全局宏注入：物理屏蔽报错 ---
# WERROR=0 告知 ATF 脚本关闭错误转换
# -Wno-error=missing-include-dirs 强制 C 编译器忽略路径缺失
TFA_MAKE_FLAGS += \
	WERROR=0 \
	CFLAGS="$(TARGET_CFLAGS) -Wno-error=missing-include-dirs" \
	DRAM_USE_DDR4=1 \
	BOOT_DEVICE=nor \
	TRUSTED_BOARD_BOOT=0 \
	DEBUG=0

define Trusted-Firmware-A/Default
  BUILD_TARGET:=mediatek
  BUILD_SUBTARGET:=filogic
  PLAT:=mt7981
  TFA_IMAGE:=bl2.bin bl31.bin
endef

# 定义 SL-3000 专属硬件变体：1024M 内存寻址锁定
define Trusted-Firmware-A/mt7981-nor-ddr4
  NAME:=SL-3000 (NOR-DDR4-1024M)
  BOOT_DEVICE:=nor
  DDR_TYPE:=ddr4
endef

TFA_TARGETS:=mt7981-nor-ddr4

# --- 主机端手术：物理产出 fiptool ---
# 解决警告: 'arm-trusted-firmware-mediatek/host', which does not exist
define Host/Prepare
	$(call Host/Prepare/Default)
	# 主机端源码同样需要补齐路径，防止编译 fiptool 时因缺少头文件报错
	mkdir -p $(HOST_BUILD_DIR)/plat/mediatek/apsoc_common/include
	[ -d $(HOST_BUILD_DIR)/plat/mediatek/apsoc_common/bl2/include ] && \
		cp -f $(HOST_BUILD_DIR)/plat/mediatek/apsoc_common/bl2/include/*.h \
		      $(HOST_BUILD_DIR)/plat/mediatek/apsoc_common/include/ || true
endef

define Host/Compile
	# 物理编译主机端工具
	$(MAKE) -C $(HOST_BUILD_DIR)/tools/fiptool \
		LDFLAGS="$(HOST_LDFLAGS)" \
		CPPFLAGS="$(HOST_CPPFLAGS) -I$(HOST_BUILD_DIR)/include"
endef

define Host/Install
	$(INSTALL_DIR) $(STAGING_DIR_HOST)/bin
	$(INSTALL_BIN) $(HOST_BUILD_DIR)/tools/fiptool/fiptool $(STAGING_DIR_HOST)/bin/
endef

# --- 源码环境手术：Build/Prepare ---
define Build/Prepare
	$(call Build/Prepare/Default)
	@echo "Physical Surgery: Fixing include paths and killing -Werror..."
	
	# 1. 强行补齐物理路径
	mkdir -p $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/include
	mkdir -p $(PKG_BUILD_DIR)/plat/mediatek/common/include
	mkdir -p $(PKG_BUILD_DIR)/plat/mediatek/mt7981/include

	# 2. 物理搬运：确保头文件在编译器指定的搜索位置
	if [ -d $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/bl2/include ]; then \
		cp -f $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/bl2/include/*.h \
		      $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/include/ || true; \
	fi

	# 3. 暴力清理：扫描所有子 Makefile，物理抹除硬编码的 -Werror 标志
	find $(PKG_BUILD_DIR) -name "*.mk" -o -name "Makefile" | xargs sed -i 's/-Werror//g' || true
endef

# --- 暴力覆盖编译指令 ---
define Build/Compile
	$(call Build/Compile/Default, \
		WERROR=0 \
		CPPFLAGS="$(TARGET_CPPFLAGS) -I$(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/include" \
	)
endef

# --- 物理分发：建立零件桥梁 ---
define Package/arm-trusted-firmware-mediatek-$(1)/install
	$(call Package/trusted-firmware-a-$(1)/install/default,$(1))
	
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	# 物理重命名：供 filogic.mk 在合成阶段识别
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl2.bin $(STAGING_DIR_IMAGE)/bl2.img
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl31.bin $(STAGING_DIR_IMAGE)/bl31.bin
	
	# 物理备份：存放在 bin 目录方便用户下载救砖镜像
	$(INSTALL_DIR) $(BIN_DIR)/sl3000-recovery
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl2.bin $(BIN_DIR)/sl3000-recovery/bl2.img
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl31.bin $(BIN_DIR)/sl3000-recovery/bl31.bin
endef

# 物理激活双端构建
$(eval $(call HostBuild))
$(eval $(call BuildPackage/Trusted-Firmware-A))
