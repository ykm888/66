#!/bin/bash

UBOOT_BRANCH=$1
[ -z "$UBOOT_BRANCH" ] && UBOOT_BRANCH="sl3000-uboot-base"

# 1. 物理破除内核 1024M 识别限制
sed -i 's/256m/1024m/g' openwrt/target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh

# 2. 修改默认主机名为 SL3000
sed -i 's/OpenWrt/SL3000/g' openwrt/package/base-files/files/bin/config_generate

# 3. 物理构建救砖 U-Boot (锁定你的源)
git clone --depth 1 --single-branch -b $UBOOT_BRANCH https://github.com/ykm888/66.git uboot-src
cd uboot-src

# 调试：查看克隆后的目录结构
echo ">>> 当前 U-Boot 源码目录结构:"
ls -F

# 物理对齐：确保在包含 Kconfig 的正确目录下执行 make
if [ ! -f "Kconfig" ]; then
    echo "⚠️ 警告: 当前目录未发现 Kconfig，尝试搜索..."
    # 有些仓库克隆后可能多套了一层目录
    REAL_DIR=$(find . -maxdepth 2 -name "Kconfig" -exec dirname {} \;)
    if [ -n "$REAL_DIR" ] && [ "$REAL_DIR" != "." ]; then
        cd "$REAL_DIR"
        echo ">>> 已切换到实际源码目录: $PWD"
    fi
fi

make mt7981_emmc_defconfig
make -j$(nproc) || exit 1

if [ -f "u-boot.bin" ]; then
    cp u-boot.bin ../sl3000-uboot.bin
    echo "✅ U-Boot 救砖引导编译成功"
fi
cd ..

echo "✅ 救砖全家桶第 2 版补丁执行完毕！"
