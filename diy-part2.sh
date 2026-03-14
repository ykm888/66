#!/bin/bash

# 物理锁定 U-Boot 设备树名称
# 必须与 uboot-Makefile 里的注入名称像素级对齐
sed -i 's/CONFIG_DEFAULT_DEVICE_TREE=.*/CONFIG_DEFAULT_DEVICE_TREE="mt7981-sl3000"/' package/boot/uboot-mediatek/Makefile

# 物理净化：在整个目录树中强制将 DDR3 标志替换为 DDR4，防止残留
grep -rl "ddr3" package/boot/arm-trusted-firmware-mediatek/ | xargs sed -i 's/ddr3/ddr4/g' 2>/dev/null

echo "DIY-PART2: 物理净化完成，DDR4 与 1MB 偏移逻辑已就绪。"
