include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=uboot-mediatek
PKG_RELEASE:=1

# --- 核心修改：切换到救砖全家桶黄金分支 ---
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=sl3000-clean-source
PKG_MIRROR_HASH:=skip

PKG_MAINTAINER:=ykm888
PKG_LICENSE:=GPL-2.0

PKG_BUILD_PARALLEL:=1
# 注意：由于你现在的仓库结构是 /u-boot/，我们需要指定这个子目录
UBOOT_SRC_SUBDIR:=u-boot

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_SOURCE_VERSION)

include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/package.mk

define U-Boot/Default
  BUILD_TARGET:=mediatek
  BUILD_SUBTARGET:=filogic
  # 匹配你在 DTS 验证中使用的 config
  UBOOT_CONFIG:=mt7981_nor_emmc_rfb
  UBOOT_IMAGE:=u-boot.bin
endef

define U-Boot/mt7981-sl3000
  NAME:=SL-3000 (512MB-Safe-Recovery)
  BUILD_DEVICES:=ykm888_sl-3000
  # 强制依赖 ATF，确保编译顺序
  DEPENDS:=+arm-trusted-firmware-mediatek
endef

UBOOT_TARGETS:=mt7981-sl3000

define Build/Prepare
	$(call Build/Prepare/Default)
	# --- 物理化路径对齐 ---
	# 因为你的仓库里 u-boot 在子目录，需要将其内容提取到构建根目录
	if [ -d "$(PKG_BUILD_DIR)/$(UBOOT_SRC_SUBDIR)" ]; then \
		echo "Found physical u-boot directory, aligning paths..."; \
		cp -rf $(PKG_BUILD_DIR)/$(UBOOT_SRC_SUBDIR)/* $(PKG_BUILD_DIR)/; \
	fi
	
	# 注入默认 IP 适配 (31.1)
	sed -i 's/192.168.1.1/192.168.31.1/g' $(PKG_BUILD_DIR)/configs/mt7981_nor_emmc_rfb_defconfig || true
	
	# 移除过时的编译警告限制，防止编译中断
	find $(PKG_BUILD_DIR) -type f -exec sed -i 's/-no-warn-rwx-segments//g' {} + || true
	find $(PKG_BUILD_DIR) -type f -exec sed -i 's/-Werror//g' {} + || true
endef

define Package/uboot-mediatek-$(1)/install
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	# 将编译出的物理零件存放到 Staging 目录供镜像打包使用
	[ -f $(PKG_BUILD_DIR)/u-boot.bin ] && { \
		$(CP) $(PKG_BUILD_DIR)/u-boot.bin $(STAGING_DIR_IMAGE)/$(1)-u-boot.bin; \
		$(CP) $(PKG_BUILD_DIR)/u-boot.bin $(STAGING_DIR_IMAGE)/u-boot.bin; \
	}
	# 同时备份一份到 bin 目录方便直接下载
	$(INSTALL_DIR) $(BIN_DIR)/sl3000-recovery
	[ -f $(PKG_BUILD_DIR)/u-boot.bin ] && \
		$(CP) $(PKG_BUILD_DIR)/u-boot.bin $(BIN_DIR)/sl3000-recovery/u-boot.bin
endef

$(eval $(call BuildPackage/U-Boot))
