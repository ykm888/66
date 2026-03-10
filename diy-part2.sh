#!/bin/bash

# 1. 物理复刻：创建目录
mkdir -p target/linux/mediatek/dts/
mkdir -p target/linux/mediatek/image/

# 2. 绝对路径物理复刻配置文件
cp -f $GITHUB_WORKSPACE/custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/dts/
cp -f $GITHUB_WORKSPACE/custom-config/filogic.mk target/linux/mediatek/image/

# 3. 5.15 内核物理路径对齐
mkdir -p target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/
cp -f $GITHUB_WORKSPACE/custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/

# 4. 救砖零件仓库物理替换
rm -rf package/boot/uboot-mediatek
git clone https://github.com/ykm888/66 -b sl3000-uboot-base package/boot/uboot-mediatek

# 5. 【4版新增】物理逻辑修复：将框架产出的标准文件软链接为镜像脚本需要的 .img
# 框架产出：mt7981-nor-ddr4-bl2.bin -> 镜像合成需要：bl2.img
# 我们在 OpenWrt 根目录下通过预处理脚本建立这个“物理桥梁”
mkdir -p staging_dir/target-aarch64_cortex-a53_musl/image/
cd staging_dir/target-aarch64_cortex-a53_musl/image/
ln -sf mt7981-nor-ddr4-bl2.bin bl2.img
ln -sf mt7981-nor-ddr4-bl31.bin bl31.bin
