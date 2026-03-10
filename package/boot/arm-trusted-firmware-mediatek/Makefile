include $(TOPDIR)/rules.mk

PKG_NAME:=trusted-firmware-a-mt7981
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/mtk-openwrt/arm-trusted-firmware.git
PKG_SOURCE_DATE:=2023-07-24
PKG_SOURCE_VERSION:=00ac6db375b76e57e1f5e9e9bffa033e907c3581

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/trusted-firmware-a.mk
include $(INCLUDE_DIR)/package.mk

define Trusted-Firmware-A/Default
  BUILD_TARGET:=mediatek
  BUILD_SUBTARGET:=filogic
  PLAT:=mt7981
  # 物理锁定框架产出
  TFA_IMAGE:=bl2.bin bl31.bin
endef

define Trusted-Firmware-A/mt7981-nor-ddr4
  NAME:=SL-3000 (NOR-DDR4-1024M)
  BOOT_DEVICE:=nor
  DDR_TYPE:=ddr4
endef

TFA_TARGETS:=mt7981-nor-ddr4

TFA_MAKE_FLAGS += DRAM_USE_DDR4=1

# --- 【8版核心物理补丁】：拦截框架安装流 ---
# 我们在框架安装完成后，立即物理拷贝出一份不带前缀的 .img 文件
define Package/trusted-firmware-a-$(1)/install
	$(call Package/trusted-firmware-a-$(1)/install/default,$(1))
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl2.bin $(STAGING_DIR_IMAGE)/bl2.img
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl31.bin $(STAGING_DIR_IMAGE)/bl31.bin
endef

$(eval $(call BuildPackage/Trusted-Firmware-A))
