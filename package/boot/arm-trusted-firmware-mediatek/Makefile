# --- 【4版】 物理重构 Makefile ---
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
  # 物理修正：只保留框架支持的 .bin，bl2.img 交给 diy-part2.sh 物理软链接
  TFA_IMAGE:=bl2.bin bl31.bin
endef

define Trusted-Firmware-A/mt7981-nor-ddr4
  NAME:=SL-3000 (NOR-DDR4-1024M)
  # 物理对齐：框架会自动解析这些变量并传递给 Make
  BOOT_DEVICE:=nor
  DDR_TYPE:=ddr4
endef

TFA_TARGETS:=mt7981-nor-ddr4

# 物理加固：确保 DDR4 标志位强制进入编译链
TFA_MAKE_FLAGS += \
	DRAM_USE_DDR4=1

# --- 关键：移除所有自定义 define Package/.../install ---
# 理由：框架 $(eval $(call BuildPackage/Trusted-Firmware-A)) 会自动处理
# 它会将产物自动拷贝到 $(STAGING_DIR_IMAGE)/$(BUILD_VARIANT)-bl2.bin

$(eval $(call BuildPackage/Trusted-Firmware-A))
