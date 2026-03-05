#!/bin/bash

# --- 1. 物理锁定：设备与架构 ---
echo "CONFIG_TARGET_mediatek=y" > .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config

# --- 2. 物理修复：坏补丁 999-2714 源头重写 ---
PATCH_FILE="target/linux/mediatek/patches-6.6/999-2714-net-fix-eee-struct-for-mtk-eth-soc-and-net-dsa-due-to-eee-backport.patch"
echo "🛠️ 正在物理重建坏补丁: $PATCH_FILE"
rm -f "$PATCH_FILE"
cat << 'EOF' > "$PATCH_FILE"
--- a/drivers/net/ethernet/mediatek/mtk_eth_soc.h
+++ b/drivers/net/ethernet/mediatek/mtk_eth_soc.h
@@ -10,6 +10,15 @@
 #ifndef MTK_ETH_SOC_H
 #define MTK_ETH_SOC_H
 
+/* SL3000 Kernel 6.6 Symbols Fix */
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
@@ -5367,7 +5367,7 @@
-static int mtk_get_eee(struct net_device *dev, struct ethtool_eee *eee)
+static int mtk_get_eee(struct net_device *dev, struct ethtool_keee *eee)
 {
--- a/net/dsa/user.c
+++ b/net/dsa/user.c
@@ -1238,7 +1238,7 @@
-static int dsa_user_set_eee(struct net_device *dev, struct ethtool_eee *e)
+static int dsa_user_set_eee(struct net_device *dev, struct ethtool_keee *e)
EOF

# --- 3. DTS 物理校准：强制 1024M 内存 ---
DTS_FILE=$(find target/linux/mediatek/dts/ -name "*sl-3000-emmc.dts")
if [ -f "$DTS_FILE" ]; then
    echo "🧠 正在校准 DTS 内存为 1024M..."
    sed -i 's/reg = <0 0x40000000 0 0x20000000>/reg = <0 0x40000000 0 0x40000000>/g' "$DTS_FILE"
    sed -i 's/reg = <0 0x40000000 0 0x10000000>/reg = <0 0x40000000 0 0x40000000>/g' "$DTS_FILE"
fi

# --- 4. U-Boot 原文照抄：1024M 源码重定向 ---
UBOOT_MK="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MK" ]; then
    sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g" "$UBOOT_MK"
    sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UBOOT_MK"
    sed -i "s|PKG_MIRROR_HASH:=.*|PKG_MIRROR_HASH:=skip|g" "$UBOOT_MK"
fi

# --- 5. 静默审计：全局 API 对齐 ---
find target/linux/mediatek/patches-6.6/ -type f -exec sed -i 's/ethtool_eee/ethtool_keee/g' {} +

echo "✅ SL3000 物理环境准备完成。"
