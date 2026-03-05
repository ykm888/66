#!/bin/bash
# SL3000 1024M eMMC 物理修复脚本

PATCH_DIR="target/linux/mediatek/patches-6.6"

echo "🧹 1. 物理清淤：移除不兼容的 6.9 Backport 补丁及无关驱动..."
if [ -d "$PATCH_DIR" ]; then
    cd "$PATCH_DIR"
    # 物理保留核心补丁：MTK, DSA, PHY, Net, PCIe
    KEEP_KEYWORDS="mtk\|mediatek\|dsa\|net\|phy\|ethtool\|pcie\|7981\|798x"
    ls | grep -v "$KEEP_KEYWORDS" | xargs rm -f
    # 强制切除 1703 冲突源
    rm -f *1703*v6.9-net-phy*
    cd - > /dev/null
fi

echo "🛠️ 2. 物理重构核心补丁 999-2714 (API & Macros)..."
cat << 'EOF' > "$PATCH_DIR/999-2714-sl3000-eee-api-fix.patch"
--- a/drivers/net/ethernet/mediatek/mtk_eth_soc.h
+++ b/drivers/net/ethernet/mediatek/mtk_eth_soc.h
@@ -10,6 +10,15 @@
 #ifndef MTK_ETH_SOC_H
 #define MTK_ETH_SOC_H
 
+/* SL3000 Global Symbols Fix for Kernel 6.6 */
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

echo "🔍 3. 物理 API 强制对齐 (ethtool_keee)..."
find "$PATCH_DIR" -type f -exec sed -i 's/struct ethtool_eee/struct ethtool_keee/g' {} +
find "$PATCH_DIR" -type f -exec sed -i 's/\.supported/\.supported_u32/g' {} +

echo "🧠 4. DTS 1024M 内存物理校准..."
DTS_FILE=$(find target/linux/mediatek/dts/ -name "*sl-3000-emmc.dts")
if [ -f "$DTS_FILE" ]; then
    sed -i 's/reg = <0 0x40000000 0 0x[0-9a-fA-F]*>/reg = <0 0x40000000 0 0x40000000>/g' "$DTS_FILE"
fi

echo "📦 5. U-Boot 1024M 源码重定向..."
sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g" package/boot/uboot-mediatek/Makefile
sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" package/boot/uboot-mediatek/Makefile
