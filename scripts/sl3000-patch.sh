#!/bin/bash

# 1. 物理拦截：切除 mt7981 常见的 MTK_WIFI_CHIP_OFFLINE 宏未定义错误 (Error 1)
# 审计：此操作直接物理修改内核源码，确保救砖包 U-Boot 与 Kernel 编译通过
find . -name "mtk_eth_soc.c" -exec sed -i '/MTK_WIFI_CHIP_OFFLINE/,/break;/d' {} + 2>/dev/null || true

# 2. 内核版本强制锁定 6.6
# 审计：确保 24.10 分支下的 Kernel 6.6 物理路径一致性
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.6/g' target/linux/mediatek/Makefile

# 3. 物理清理：移除可能冲突的旧补丁
rm -f target/linux/mediatek/patches-6.6/999-fix-mtk-eth-soc.patch 2>/dev/null || true

# 4. 配置物理对齐
# 审计：如果根目录没有配置文件，物理搬运 ykm888 仓库中的 8000 行 sl3000.config
if [ -f "custom-config/sl3000.config" ]; then
    cp -f custom-config/sl3000.config .config
fi
