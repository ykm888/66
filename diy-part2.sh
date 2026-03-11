#!/bin/bash

# 1. 物理目录复刻：确保目标架构路径存在
mkdir -p target/linux/mediatek/dts/
mkdir -p target/linux/mediatek/image/
mkdir -p target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/

# 2. 物理注入配置
cp -f $GITHUB_WORKSPACE/custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/dts/
cp -f $GITHUB_WORKSPACE/custom-config/filogic.mk target/linux/mediatek/image/
cp -f $GITHUB_WORKSPACE/custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/

# 3. 救砖零件 U-Boot 同步 (锁定你的 sl3000-uboot-base 分支)
rm -rf package/boot/uboot-mediatek
git clone https://github.com/ykm888/66 -b sl3000-uboot-base package/boot/uboot-mediatek

# 4. --- ATF 源码物理加固 ---
# 既然你已经在 atf-sl3000-base 分支改好了源码，这里必须做两件事：
# 1) 强行移除官方补丁文件夹，防止 Hunk FAILED
# 2) 确保拉取的是你精修后的仓库版本（如果 Makefile 里没写死，这里可以补刀）

echo "Applying physical fixes for ATF..."
rm -rf package/boot/arm-trusted-firmware-mediatek/patches

# [可选] 强制清理编译缓存，确保 DDR4 1024M 的修改能物理生效
rm -rf build_dir/target-aarch64_cortex-a53_musl/arm-trusted-firmware-mediatek-*
