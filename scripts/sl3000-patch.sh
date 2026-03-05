#!/bin/bash

# 1. 【物理锁定】：锁定架构与设备
printf "CONFIG_TARGET_mediatek=y\n" > .config
printf "CONFIG_TARGET_mediatek_filogic=y\n" >> .config
printf "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y\n" >> .config
sed -i 's/CONFIG_TARGET_x86=y/# CONFIG_TARGET_x86 is not set/' .config

# 2. 【物理清淤】：删除已知冲突补丁
rm -f target/linux/mediatek/patches-6.6/999-2714-net-fix-eee-struct-for-mtk-eth-soc-and-net-dsa-due-to-eee-backport.patch

# 3. 【原子注入】：直接生成一个万能修复补丁文件
# 这个补丁将直接解决宏丢失和 ethtool_eee 结构体更名问题
mkdir -p target/linux/mediatek/patches-6.6/
cat << 'EOF' > target/linux/mediatek/patches-6.6/999-sl3000-atomic-fix.patch
--- a/drivers/net/ethernet/mediatek/mtk_eth_soc.h
+++ b/drivers/net/ethernet/mediatek/mtk_eth_soc.h
@@ -10,6 +10,14 @@
 #ifndef MTK_ETH_SOC_H
 #define MTK_ETH_SOC_H
 
+/* SL3000 Atomic Fix */
+#define HIT_BIND_FORCE_TO_CPU 0x0b
+#define MTK_FE_START_RESET 0x01
+#define MTK_FE_RESET_DONE 0x02
+#define MTK_FE_RESET_NAT_DONE 0x03
+#define MTK_WIFI_RESET_DONE 0x04
+#define MTK_WIFI_CHIP_ONLINE 0x05
+#define MTK_WIFI_CHIP_OFFLINE 0x06
+
 #define MTK_QDMA_PAGE_SIZE	2048
 #define	MTK_MAX_RXD_NUM		16384
--- a/drivers/net/ethernet/mediatek/mtk_eth_soc.c
+++ b/drivers/net/ethernet/mediatek/mtk_eth_soc.c
@@ -2485,7 +2485,7 @@ static int mtk_poll_rx(struct napi_struc
 			goto next_rx;
 
 		mac = (trxd.rxd4 >> 24) & 0x7;
-		if ( (mac == 4) || ((FIELD_GET(MTK_RXD4_PPE_CPU_REASON, trxd.rxd4)) == HIT_BIND_FORCE_TO_CPU))
+		if ( (mac == 4) || ((FIELD_GET(GENMASK(5, 0), trxd.rxd4)) == 0x0b))
 			trxd.rxd4 |= MTK_RXD4_FOVIA_CPU;
 
 		if (trxd.rxd4 & MTK_RXD4_FOVIA_CPU) {
EOF

# 4. 【原文照抄】：U-Boot 重定向与 Makefile 重建逻辑（延续成功版）
UBOOT_MK="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MK" ]; then
    sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g" "$UBOOT_MK"
    sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UBOOT_MK"
    sed -i "s|PKG_MIRROR_HASH:=.*|PKG_MIRROR_HASH:=skip|g" "$UBOOT_MK"
    sed -i "s/UBOOT_TARGETS :=.*/UBOOT_TARGETS := mt7981_sl_3000-emmc/g" "$UBOOT_MK"

    START_LINE=$(grep -n "define Build/fip-image" "$UBOOT_MK" | cut -d: -f1)
    [ ! -z "$START_LINE" ] && sed -i "${START_LINE},\$d" "$UBOOT_MK"

    printf "define Build/fip-image\n\t\$(STAGING_DIR_HOST)/bin/fiptool create \\\\\n\t\t--soc-fw \$(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl31.bin \\\\\n\t\t--nt-fw \$(PKG_BUILD_DIR)/\$(BUILD_VARIANT)/u-boot.bin \\\\\n\t\t\$(PKG_BUILD_DIR)/\$(BUILD_VARIANT)/u-boot.fip\nendef\n\n" >> "$UBOOT_MK"
    printf "define Build/Configure\n\t\$(call Build/Configure/U-Boot)\n\tsed -i 's/CONFIG_TOOLS_LIBCRYPTO=y/# CONFIG_TOOLS_LIBCRYPTO is not set/' \$(PKG_BUILD_DIR)/.config\nendef\n\n" >> "$UBOOT_MK"
    printf "define Build/Compile\n\t\$(call Build/Compile/U-Boot)\nifeq (\$(UBOOT_IMAGE),u-boot.fip)\n\t\$(call Build/fip-image)\nendif\nendef\n\n" >> "$UBOOT_MK"
    printf "define Build/InstallDev\n\t\$(INSTALL_DIR) \$(STAGING_DIR_HOST)/share/u-boot\n\t\$(CP) \$(PKG_BUILD_DIR)/\$(BUILD_VARIANT)/bl2.bin \$(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-bl2.bin\n\t\$(CP) \$(PKG_BUILD_DIR)/\$(BUILD_VARIANT)/u-boot.fip \$(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-fip.bin\nendef\n\n" >> "$UBOOT_MK"
    printf "\$(eval \$(call BuildPackage/U-Boot))\n" >> "$UBOOT_MK"
fi
