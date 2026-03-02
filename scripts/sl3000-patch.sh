#!/bin/bash

# 1. 物理拦截：切除 Error 1 (MTK_WIFI_CHIP_OFFLINE 未定义)
# 审计：直接物理修改内核驱动源码，确保构建 6.6 内核时不崩溃
find . -name "mtk_eth_soc.c" -exec sed -i '/MTK_WIFI_CHIP_OFFLINE/,/break;/d' {} + 2>/dev/null || true

# 2. 内核版本物理锁定 6.6
# 审计：防止 24.10 分支 Makefile 变动导致的内核版本偏移
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.6/g' target/linux/mediatek/Makefile

# 3. 物理劫持：U-Boot 1024M 引导链配置注入
# 审计：物理强制注入你魔改仓库中的 1024M 内存定义，这是救砖包成功的关键
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    # 清理旧注入，防止 Makefile 逻辑堆叠导致语法错误
    sed -i '/curl -fsSL.*sl_3000/d' "$UBOOT_MAKEFILE"
    # 物理注入指令：在 Configure 阶段抓取远程 1024M 硬件定义文件
    sed -i '/define Build\/Configure/a \
\tcurl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig -o $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig; \\' "$UBOOT_MAKEFILE"
fi

# 4. 物理清理冲突补丁
rm -f target/linux/mediatek/patches-6.6/999-fix-mtk-eth-soc.patch 2>/dev/null || true

# 5. 配置物理覆盖
# 审计：确保 ykm888 仓库中的 8000 行 sl3000.config 物理生效
if [ -f "custom-config/sl3000.config" ]; then
    cp -f custom-config/sl3000.config .config
fi
