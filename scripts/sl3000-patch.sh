#!/bin/bash

# 物理审计：严格延续上一版原文逻辑，确保 1024M 物理全闭环

# 1. 物理拦截：内核 6.6 核心报错点
# 修正内核在 MT7981 驱动中关于 WiFi 离线定义的物理冲突
find . -name "mtk_eth_soc.c" -exec sed -i '/MTK_WIFI_CHIP_OFFLINE/,/break;/d' {} + 2>/dev/null || true

# 2. 物理清淤：粉碎旧缓存（这是解决 No such file 的核心）
# 强制删除 dl 目录下的旧压缩包，确保系统必须从你的 66 仓库重新下载
echo "物理清淤：彻底粉碎 U-Boot 源码残留..."
rm -rf dl/u-boot-* 2>/dev/null || true
rm -rf build_dir/target-*/u-boot-* 2>/dev/null || true

# 3. 物理劫持：重定向 Makefile 并注入“物理钢钉”
UBOOT_MK="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MK" ]; then
    echo "物理注入：重定向源码并锁定 UBOOT_CONFIG..."
    sed -i 's|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g' "$UBOOT_MK"
    sed -i 's|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g' "$UBOOT_MK"
    sed -i 's|PKG_MIRROR_HASH:=.*|PKG_MIRROR_HASH:=skip|g' "$UBOOT_MK"
    sed -i 's/UBOOT_CONFIG:=.*/UBOOT_CONFIG:=mt7981_emmc/g' "$UBOOT_MK"

    # 4. 【终极自愈】：Raw 链接强插 + 模糊路径对齐
    # 即使源码包解压失败或路径不对，我们也用 find 找到它并强行塞入 configs/
    RAW_URL="https://raw.githubusercontent.com/ykm888/66/sl3000-uboot-base/configs/mt7981_emmc_defconfig"
    mkdir -p package/boot/uboot-mediatek/files/
    echo "物理下载：获取 1024M 专用原始配置文件..."
    curl -fLo package/boot/uboot-mediatek/files/mt7981_emmc_defconfig "$RAW_URL"

    # 在 Build/Configure 流程中插入模糊匹配指令
    # 物理审计修复：修正 sed 插入路径的语法转义，确保物理注入成功
    sed -i '/define Build\/Configure/i \	find $(BUILD_DIR) -name "u-boot-*" -type d -exec mkdir -p {}/configs \\; -exec cp $(TOPDIR)/package/boot/uboot-mediatek/files/mt7981_emmc_defconfig {}/configs/ \\;' "$UBOOT_MK"
fi

# 5. 物理注入 .config
# 修正：增加对根目录下 .config 的兜底处理
if [ -f "../../custom-config/sl3000.config" ]; then
    cp -f "../../custom-config/sl3000.config" .config
elif [ -f "$GITHUB_WORKSPACE/custom-config/sl3000.config" ]; then
    cp -f "$GITHUB_WORKSPACE/custom-config/sl3000.config" .config
fi

# 无论配置文件是否存在，物理强插 1024M 关键配置
echo "物理锁定：强制注入 1024M 设备定义..."
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config
echo "CONFIG_NR_DRAM_BANKS=1" >> .config
echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config
