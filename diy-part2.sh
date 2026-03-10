#!/bin/bash

# 1. 物理目录复刻：确保目标架构路径存在
mkdir -p target/linux/mediatek/dts/
mkdir -p target/linux/mediatek/image/
mkdir -p target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/

# 2. 物理注入配置
cp -f $GITHUB_WORKSPACE/custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/dts/
cp -f $GITHUB_WORKSPACE/custom-config/filogic.mk target/linux/mediatek/image/
cp -f $GITHUB_WORKSPACE/custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/

# 3. 救砖零件仓库同步
rm -rf package/boot/uboot-mediatek
git clone https://github.com/ykm888/66 -b sl3000-uboot-base package/boot/uboot-mediatek

# 4. --- 物理报错修复：强行移除冲突补丁 ---
# 既然源码已经是 2026 最新版，旧补丁已经失去物理意义，直接删除防止中断
echo "Cleaning up conflicting ATF patches..."
rm -rf package/boot/arm-trusted-firmware-mediatek/patches
