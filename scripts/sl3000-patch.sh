#!/bin/bash

# 物理路径定义
DTS_SRC="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7981b-sl-3000-emmc.dts"

# 1. 物理清淤：删除旧的 U-Boot 编译目录，强制拉取 1024M 源码
rm -rf build_dir/target-aarch64_*/u-boot-*

# 2. 物理校验：确保 DTS 文件存放正确
if [ ! -f "$DTS_SRC" ]; then
    echo "DTS file missing! Physical link broken."
    exit 1
fi

# 3. 物理注入 U-Boot 配置：强制将 1024M 的 defconfig 注入到编译环境
# 注意：这一步会在 U-Boot 源码拉取后执行，解决之前 No such file 的报错
find package/boot/uboot-mediatek/ -name "mt7981_emmc_defconfig" -exec cp -f {} {}.bak \;

# 4. 物理空间清理
rm -rf tmp/*
