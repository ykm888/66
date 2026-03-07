#!/bin/bash

# 获取从工作流传来的 U-Boot 分支名
UBOOT_BRANCH=$1
[ -z "$UBOOT_BRANCH" ] && UBOOT_BRANCH="sl3000-uboot-base"

echo ">>> 开始执行 12 工序核心补丁 (含 U-Boot 构建) <<<"

# 1. 物理破除内核 1024M 内存识别限制
# 延续之前针对 platform.sh 的 sed 修改逻辑
TARGET_FILE="openwrt/target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh"
if [ -f "$TARGET_FILE" ]; then
    sed -i 's/256m/1024m/g' "$TARGET_FILE"
    echo "✅ 内核 1024M 限制已物理破除"
fi

# 2. 修改默认主机名为 SL3000
sed -i 's/OpenWrt/SL3000/g' openwrt/package/base-files/files/bin/config_generate

# 3. 物理构建救砖 U-Boot (全家桶核心)
echo ">>> 正在从分支 $UBOOT_BRANCH 物理构建 U-Boot <<<"
# 物理拉取 ykm888/66 仓库的指定分支到子目录
git clone --depth 1 --single-branch -b $UBOOT_BRANCH https://github.com/ykm888/66.git uboot-build-dir

cd uboot-build-dir
# 延续你之前的 U-Boot 编译设置（如 mt7981_sl3000_defconfig）
make mt7981_sl3000_defconfig
make -j$(nproc)

# 物理产物整理：将生成的 bin 移动到根目录，方便工作流第 10 步打包
if [ -f "u-boot.bin" ]; then
    cp u-boot.bin ../u-boot.bin
    echo "✅ U-Boot 救砖引导编译成功"
else
    echo "❌ 错误: U-Boot 编译失败，请检查源码逻辑"
    exit 1
fi

cd ..
echo ">>> 全家桶脚本工序全部完成 <<<"
