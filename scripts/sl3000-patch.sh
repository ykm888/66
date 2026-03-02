#!/bin/bash

# 1. 物理拦截：切除 Kernel 6.6 的 Error 1 (MTK_WIFI_CHIP_OFFLINE 未定义)
# 审计：这是 24.10 分支编译 mt7981 时的必经物理修复
find . -name "mtk_eth_soc.c" -exec sed -i '/MTK_WIFI_CHIP_OFFLINE/,/break;/d' {} + 2>/dev/null || true

# 2. 内核版本物理锁定 6.6
# 审计：确保内核路径引用的一致性
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.6/g' target/linux/mediatek/Makefile

# 3. 【核心修复】物理劫持 U-Boot 源码下载地址
# 审计：强行将 OpenWrt 的 U-Boot 编译包指向你那个同步好的魔改仓库分支
UBOOT_MK="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MK" ]; then
    echo "正在物理重定向 U-Boot 源码至 ykm99999/66 (sl3000-uboot-base)..."
    # 替换源码 URL
    sed -i 's|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm99999/66.git|g' "$UBOOT_MK"
    # 替换分支/版本号
    sed -i 's|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g' "$UBOOT_MK"
    # 物理跳过哈希校验，防止源码变动导致编译中断
    sed -i 's|PKG_MIRROR_HASH:=.*|PKG_MIRROR_HASH:=skip|g' "$UBOOT_MK"
fi

# 4. 物理对齐：指定 1024M 配置文件名
# 审计：确保 image 脚本调用你生成的 mt7981_sl_3000-emmc 硬件定义
MT7981_MK="target/linux/mediatek/image/mt7981.mk"
if [ -f "$MT7981_MK" ]; then
    sed -i 's/UBOOT_CONFIG:=.*/UBOOT_CONFIG:=mt7981_sl_3000-emmc/g' "$MT7981_MK"
fi

# 5. 配置物理覆盖 (8000行固件配置)
# 审计：确保 ykm888 仓库中的 sl3000.config 物理覆盖至框架根目录
[ -f "custom-config/sl3000.config" ] && cp -f custom-config/sl3000.config .config
