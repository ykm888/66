#!/bin/bash

# 1. 物理植入自定义设备定义
cp -f custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/dts/
cp -f custom-config/filogic.mk target/linux/mediatek/image/

# 2. 注入核心 Config 定义
cat custom-config/sl3000.config > .config

# 3. 强制推导依赖关系（这一步会将精简版展开为完整版）
make defconfig
