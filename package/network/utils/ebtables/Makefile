include $(TOPDIR)/rules.mk

PKG_NAME:=ebtables
PKG_SOURCE_DATE:=2018-06-27
PKG_RELEASE:=4

# 【物理路径重对齐】：改用 OpenWrt 官方维护的 tarball 压缩包源，物理避开 Git 链接失效
PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_DATE).tar.gz
PKG_SOURCE_URL:=https://sources.openwrt.org/
PKG_HASH:=1327cdc3402e5e3056819e4e9b6f9d4a5bfd401f2c4f58447afb2c3c73fc8aac

PKG_LICENSE:=GPL-2.0
PKG_CPE_ID:=cpe:/a:netfilter:ebtables

include $(INCLUDE_DIR)/package.mk

define Package/ebtables-legacy
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Firewall
  DEPENDS:=+kmod-ebtables
  TITLE:=Ethernet bridge firewall administration utility (legacy)
  URL:=http://ebtables.sourceforge.net/
  PROVIDES:=ebtables
  # 权重设为 100，物理规避递归冲突
  ALTERNATIVES:=100:/usr/sbin/ebtables:/usr/sbin/ebtables-legacy
endef

define Package/ebtables-legacy-utils
  $(call Package/ebtables-legacy)
  DEPENDS:=ebtables-legacy
  TITLE:=ebtables save/restore utilities (legacy)
  PROVIDES:=ebtables-utils
  ALTERNATIVES:=100:/usr/sbin/ebtables-restore:/usr/sbin/ebtables-legacy-restore
endef

define Package/ebtables-legacy/description
	The ebtables program is a filtering tool for a bridging firewall. 
	Using official OpenWrt source snapshot for physical stability.
endef

MAKE_VARS += EXT_LIBSI="$(LIBGCC_S)"

MAKE_FLAGS += \
	CFLAGS="$(TARGET_CFLAGS) $(FPIC)" \
	LIBDIR="/usr/lib/ebtables"

define Package/ebtables-legacy/install
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/ethertypes $(1)/etc/
	$(INSTALL_DIR) $(1)/usr/lib/ebtables
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib*.so $(1)/usr/lib/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/extensions/*.so $(1)/usr/lib/ebtables/
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ebtables $(1)/usr/sbin/ebtables-legacy
endef

define Package/ebtables-legacy-utils/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ebtables-restore $(1)/usr/sbin/ebtables-legacy-restore
endef

$(eval $(call BuildPackage,ebtables-legacy))
$(eval $(call BuildPackage,ebtables-legacy-utils))
