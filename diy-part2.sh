#!/bin/bash
# 物理执行：Part 2 救砖全家桶像素级注入

# 1. 物理覆盖核心零件 (针对 24.10 路径)
# 工作流中 888 文件夹在 ../ 目录，源码在当前目录
if [ -d "../888" ]; then
    cp -f ../888/atf-Makefile package/boot/arm-trusted-firmware-mediatek/Makefile
    cp -f ../888/uboot-Makefile package/boot/uboot-mediatek/Makefile
    cp -f ../888/filogic.mk target/linux/mediatek/image/filogic.mk
    echo "物理诊断：888 文件夹补丁已强力注入 Makefile。"
fi

# 2. 修改默认 IP (可选，SL-3000 常用 192.168.1.1)
sed -i 's/192.168.1.1/192.168.1.1/g' package/base-files/files/bin/config_generate

# 3. 强制锁定救砖开关 (防止 defconfig 意外剔除)
echo "CONFIG_PACKAGE_arm-trusted-firmware-mediatek-mt7981-nor-ddr4=y" >> .config
echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl3000_nor=y" >> .config

echo "物理定论：SL-3000 救砖生产线已锁定，准备开始物理编译。"
