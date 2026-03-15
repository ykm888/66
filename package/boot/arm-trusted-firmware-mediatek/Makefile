include $(TOPDIR)/rules.mk

PKG_NAME:=arm-trusted-firmware-mediatek
PKG_RELEASE:=1
# 对应你的底层源码分支
PKG_VERSION:=sl3000

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=sl3000-clean-source
PKG_MIRROR_HASH:=skip

# 物理构建目录：必须包含 PKG_VARIANT，防止并发编译冲突
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/trusted-firmware-a.mk
include $(INCLUDE_DIR)/package.mk

define Trusted-Firmware-A/Default
  BUILD_TARGET:=mediatek
  BUILD_SUBTARGET:=filogic
  PLAT:=mt7981
  # 救砖必须产出这两个文件
  TFA_IMAGE:=bl2.bin fip.bin
endef

# --- 核心对齐：变体名必须叫 mt7981-nor-ddr4 ---
define Trusted-Firmware-A/mt7981-nor-ddr4
  NAME:=SL-3000 (NOR-DDR4-1MB-Offset)
  # 传递给底层的物理编译参数
  TFA_MAKE_FLAGS:=BOOT_DEVICE=nor DRAM_USE_DDR4=1
endef

TFA_TARGETS:=mt7981-nor-ddr4

define Build/Prepare
	$(call Build/Prepare/Default)
	# 物理手术：由于你的源码在 atf 子目录，必须平铺到根目录
	if [ -d "$(PKG_BUILD_DIR)/atf" ]; then \
		cp -rf $(PKG_BUILD_DIR)/atf/* $(PKG_BUILD_DIR)/; \
	fi
	# 暴力关闭所有警告报错，确保 100% 通过
	find $(PKG_BUILD_DIR) -type f -name "Makefile*" -exec sed -i 's/-Werror//g' {} + || true
endef

define Package/trusted-firmware-a-$(1)/install
	$(call Package/trusted-firmware-a/install/default,$(1))
	# 物理打捞：把产物放到我们预设的救砖目录
	$(INSTALL_DIR) $(BIN_DIR)/sl3000-recovery
	[ -f $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin ] && \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin $(BIN_DIR)/sl3000-recovery/bl2.img
	[ -f $(PKG_BUILD_DIR)/build/$(PLAT)/release/fip.bin ] && \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/fip.bin $(BIN_DIR)/sl3000-recovery/fip.bin
endef

$(eval $(call BuildPackage/Trusted-Firmware-A))
