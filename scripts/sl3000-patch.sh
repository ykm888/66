#!/bin/bash

# 1. 物理劫持 U-Boot 源码源（延续你之前的设置）
# 确保 PKG_SOURCE_URL 指向你的 sl3000-uboot-base 分支
sed -i 's|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/${{ github.repository_owner }}/你的Uboot仓库名.git|g' package/boot/uboot-mediatek/Makefile
sed -i 's|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g' package/boot/uboot-mediatek/Makefile

# 2. 物理清淤：删除旧缓存，强制应用 1024M 源码
rm -rf dl/u-boot-mediatek-*
rm -rf build_dir/target-aarch64_*/u-boot-*

# 3. 物理注入 DTS 和 配置校验
# 延续之前保存好的物理文件覆盖逻辑
# ...（此处保持你之前脚本中的其他具体 cp 命令不变）

echo "Physical Patch Applied: U-Boot Source Redirected and 1024M Config Secured."
