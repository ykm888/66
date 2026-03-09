#!/bin/bash
#
# 物理修复：解决递归依赖与路径报错
#

# --- 1. 物理解决递归依赖 (EasyMesh 冲突修复) ---
# 既然手动配置有冲突，我们直接在源码层面修改它的依赖关系
sed -i 's/DEPENDS:=+wpad-mesh-openssl/DEPENDS:=+wpad-openssl/g' package/feeds/luci/luci-app-easymesh/Makefile 2>/dev/null || true

# --- 2. 物理注入 .config 核心选项 ---
# 使用 sed 代替 echo，确保如果存在旧配置会被物理替换，而不是重复追加
sed -i '/CONFIG_PACKAGE_trusted-firmware-a-mt7981-nor-ddr4/d' .config
echo "CONFIG_PACKAGE_trusted-firmware-a-mt7981-nor-ddr4=y" >> .config
echo "CONFIG_PACKAGE_uboot-mediatek_mt7981_sl_3000-nor-emmc=y" >> .config

# --- 3. 物理注入内核配置：确保识别 eMMC 分区 ---
echo "CONFIG_EFI_PARTITION=y" >> target/linux/mediatek/filogic/config-5.15
echo "CONFIG_PARTITION_ADVANCED=y" >> target/linux/mediatek/filogic/config-5.15

# --- 4. 物理对齐内存 1024M ---
sed -i 's/reg = <0 0x40000000 0 0x20000000>/reg = <0 0x40000000 0 0x40000000>/g' target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/mt7981.dtsi

# --- 5. 物理路径修正：删除脚本内的 "cd openwrt" ---
# 注意：Workflow 已经帮你 cd 进去了，这里千万不要再 cd
# 只要执行 make defconfig 即可
make defconfig

echo "diy-part2.sh 物理修复执行完毕！"
