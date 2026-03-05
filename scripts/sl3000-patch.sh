#!/bin/bash
# SL3000 1024M eMMC 物理修复大师脚本 (Kernel 6.6)

PATCH_DIR="target/linux/mediatek/patches-6.6"

echo "🚀 开始执行物理全流程修复..."

# --- 1. 补丁物理清淤 (只构建路由器相关的补丁) ---
if [ -d "$PATCH_DIR" ]; then
    echo "🧹 正在过滤非 MediaTek 补丁以减少物理冲突..."
    cd "$PATCH_DIR" || exit
    # 物理保留核心补丁：MTK驱动, DSA架构, 网络协议, PCIe总线
    KEEP_KEYWORDS="mtk\|mediatek\|dsa\|net\|phy\|ethtool\|pcie\|7981\|798x"
    ls | grep -v "$KEEP_KEYWORDS" | xargs rm -f
    # 强制物理删除已确认的冲突源 999-1703
    rm -f *1703*v6.9-net-phy*
    cd - > /dev/null
fi

# --- 2. 物理修复 999-2714：API 适配与宏注入 ---
FIX_2714="$PATCH_DIR/999-2714-sl3000-eee-api-fix.patch"
echo "🛠️ 正在物理重建核心补丁: 999-2714"
cat << 'EOF' > "$FIX_2714"
--- a/drivers/net/ethernet/mediatek/mtk_eth_soc.h
+++ b/drivers/net/ethernet/mediatek/mtk_eth_soc.h
@@ -10,6 +10,15 @@
 #ifndef MTK_ETH_SOC_H
 #define MTK_ETH_SOC_H
 
+/* SL3000 Global Source Fix for Kernel 6.6 */
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

# --- 3. 全局静默审计：强制对齐 ethtool_keee 结构体 ---
echo "🔍 正在执行物理 API 对齐审计..."
find "$PATCH_DIR" -type f -exec sed -i 's/struct ethtool_eee/struct ethtool_keee/g' {} +
find "$PATCH_DIR" -type f -exec sed -i 's/\.supported/\.supported_u32/g' {} +

# --- 4. DTS 内存物理校准 (1024M) ---
DTS_FILE=$(find target/linux/mediatek/dts/ -name "*sl-3000-emmc.dts")
if [ -f "$DTS_FILE" ]; then
    echo "🧠 正在物理校准 DTS 内存为 1024M..."
    sed -i 's/reg = <0 0x40000000 0 0x[0-9a-fA-F]*>/reg = <0 0x40000000 0 0x40000000>/g' "$DTS_FILE"
fi

# --- 5. U-Boot Makefile 物理照抄 ---
UB_MK="package/boot/uboot-mediatek/Makefile"
if [ -f "$UB_MK" ]; then
    sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g" "$UB_MK"
    sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UB_MK"
fi

echo "✅ 物理全流程修复完成，环境已就绪。"
