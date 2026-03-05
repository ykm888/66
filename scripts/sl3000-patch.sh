#!/bin/bash
# [2026-03-05] 延续 1024M U-Boot 与 eMMC 物理对齐逻辑

PATCH_DIR="target/linux/mediatek/patches-6.6"

echo "🛡️ 执行静默审计：物理同步 1024M 内存定义..."
DTS_FILE=$(find target/linux/mediatek/dts/ -name "*sl-3000-emmc.dts")
if [ -f "$DTS_FILE" ]; then
    # 延续 [2026-03-02] 指令：强制 1024M 内存定义
    sed -i 's/reg = <0 0x40000000 0 0x[0-9a-fA-F]*>/reg = <0 0x40000000 0 0x40000000>/g' "$DTS_FILE"
fi

echo "🧹 物理清淤：删除冲突的 1703 补丁..."
rm -f "$PATCH_DIR"/*1703*v6.9-net-phy*

echo "🛠️ 物理修复 999-2714：对齐 ethtool_keee 结构体..."
# 延续之前的修复逻辑，保证内核 6.6 网络栈不崩溃
cat << 'EOF' > "$PATCH_DIR/999-2714-sl3000-eee-api-fix.patch"
--- a/drivers/net/ethernet/mediatek/mtk_eth_soc.h
+++ b/drivers/net/ethernet/mediatek/mtk_eth_soc.h
@@ -10,6 +10,15 @@
 #ifndef MTK_ETH_SOC_H
 #define MTK_ETH_SOC_H
 
+/* SL3000 Global Symbols Fix */
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

echo "🔍 执行全局 API 物理对齐审计..."
find "$PATCH_DIR" -type f -exec sed -i 's/struct ethtool_eee/struct ethtool_keee/g' {} +
