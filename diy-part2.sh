#!/bin/bash

# 1. 确保在 openwrt 源码根目录操作
[ -d "openwrt" ] && cd openwrt

# 2. 物理创建必要的目录（防止部分源码包未完全展开）
mkdir -p target/linux/mediatek/dts/
mkdir -p target/linux/mediatek/image/

# 3. 物理植入核心文件 (路径前加 ../ 是因为现在在 openwrt 子目录里)
# 确保你的仓库根目录有名为 custom-config 的文件夹
cp -f ../custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/dts/
cp -f ../custom-config/filogic.mk target/linux/mediatek/image/

# 4. 注入精简版 Config 定义并强制展开
cat ../custom-config/sl3000.config > .config

# 5. 核心：执行 defconfig，将几十行精简配置物理转化为 8000 行完整配置
make defconfig
