#!/bin/bash

# 1. 物理拦截：切除 Error 1 (MTK_WIFI_CHIP_OFFLINE 未定义)
# 审计：这是 6.6 内核在编译 mt7981 时由于宏未定义导致中断的物理病灶
find . -name "mtk_eth_soc.c" -exec sed -i '/MTK_WIFI_CHIP_OFFLINE/,/break;/d' {} + 2>/dev/null || true

# 2. 内核版本物理锁定 6.6
# 审计：确保 24.10 分支下的路径引用不会因 Makefile 变动而偏移
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.6/g' target/linux/mediatek/Makefile

# 3. 物理劫持：U-Boot 1024M 引导链配置注入 (核心修复)
# 审计：强制将魔改仓库中的 1024M 内存定义文件物理注入 U-Boot 编译流水线
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    # 先清理旧的注入，防止 Makefile 逻辑堆叠导致编译崩溃
    sed -i '/curl -fsSL.*sl_3000/d' "$UBOOT_MAKEFILE"
    # 物理注入指令：在 Configure 阶段抓取远程 1024M 硬件定义
    sed -i '/define Build\/Configure/a \
\tcurl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig -o $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig; \\' "$UBOOT_MAKEFILE"
fi

# 4. 物理清理：移除 6.6 内核补丁目录中可能存在的冲突残余
rm -f target/linux/mediatek/patches-6.6/999-fix-mtk-eth-soc.patch 2>/dev/null || true

# 5. 配置物理搬运
# 审计：确保 ykm888 仓库中的 8000 行 sl3000.config 物理覆盖至根目录
if [ -f "custom-config/sl3000.config" ]; then
    cp -f custom-config/sl3000.config .config
fi
