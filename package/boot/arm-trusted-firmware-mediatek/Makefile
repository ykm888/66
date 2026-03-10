#
# Copyright (C) 2024-2026 ykm888
# 物理修复：SL-3000 (MT7981) 救砖零件物理对齐
# 源码分支：mtksoc-20260123
#

include $(TOPDIR)/rules.mk

# 物理归位：必须与目录名保持一致，确保 OpenWrt 编译索引命中
PKG_NAME:=arm-trusted-firmware-mediatek
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/mtk-openwrt/arm-trusted-firmware.git
# 物理升级：使用 2026 最新稳定 SOC 分支
PKG_SOURCE_BRANCH:=mtksoc-20260123
PKG_SOURCE_VERSION:=$(PKG_SOURCE_BRANCH)

PKG_MAINTAINER:=ykm888

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/trusted-firmware-a.mk
include $(INCLUDE_DIR)/package.mk

define Trusted-Firmware-A/Default
  BUILD_TARGET:=mediatek
  BUILD_SUBTARGET:=filogic
  PLAT:=mt7981
  # 框架标准产出 bin 文件
  TFA_IMAGE:=bl2.bin bl31.bin
endef

# 定义 SL-3000 专属硬件变体
define Trusted-Firmware-A/mt7981-nor-ddr4
  NAME:=SL-3000 (NOR-DDR4-1024M)
  BOOT_DEVICE:=nor
  DDR_TYPE:=ddr4
endef

TFA_TARGETS:=mt7981-nor-ddr4

# 物理加固：锁定 DDR4 初始化参数，确保 1024M 内存物理可用
TFA_MAKE_FLAGS += DRAM_USE_DDR4=1

# --- 核心物理修复：建立 bl2.img 桥梁 ---
# 解释：OpenWrt 框架默认生成 $(变体名)-bl2.bin
# 但镜像合成脚本 (filogic.mk) 在物理寻找不带前缀的 bl2.img
# 此函数拦截安装工序，在 $(STAGING_DIR_IMAGE) 建立物理副本
define Package/arm-trusted-firmware-mediatek-$(1)/install
	$(call Package/trusted-firmware-a-$(1)/install/default,$(1))
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl2.bin $(STAGING_DIR_IMAGE)/bl2.img
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl31.bin $(STAGING_DIR_IMAGE)/bl31.bin
endef

$(eval $(call BuildPackage/Trusted-Firmware-A))
