#!/bin/bash
#
# 物理修复脚本：解决递归依赖、DTS 内存对齐与 eMMC 分区识别
#

# --- 1. 物理解决递归依赖 (强制切断 EasyMesh 冲突环) ---
# 报错显示 luci-app-easymesh 与 wpad 互锁，我们直接物理移除该插件以通过编译
rm -rf package/feeds/luci/luci-app-easymesh
rm -rf package/feeds/custom/luci-app-easymesh

# --- 2. 物理注入 .config 核心救砖选项 ---
# 确保选定针对 1024M DDR4 的 ATF 和 U-Boot
sed -i '/CONFIG_PACKAGE_trusted-firmware-a-mt7981-nor-ddr4/d' .config
echo "CONFIG_PACKAGE_trusted-firmware-a-mt7981-nor-ddr4=y" >> .config
echo "CONFIG_PACKAGE_uboot-mediatek_mt7981_sl_3000-nor-emmc=y" >> .config

# --- 3. 物理修复内核 GPT 分区识别 (针对 eMMC) ---
# 强制开启 EFI 分区支持，否则 root=PARTLABEL=production 无法挂载
echo "CONFIG_EFI_PARTITION=y" >> target/linux/mediatek/filogic/config-5.15
echo "CONFIG_PARTITION_ADVANCED=y" >> target/linux/mediatek/filogic/config-5.15

# --- 4. 物理锁定 1024M RAM 定义 ---
# 修改内核源码中的通用设备树，确保内存不被截断
sed -i 's/reg = <0 0x40000000 0 0x20000000>/reg = <0 0x40000000 0 0x40000000>/g' target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/mt7981.dtsi

# --- 5. 刷新配置 (执行核心) ---
# 注意：脚本由 Workflow 调用，内部严禁再次 cd openwrt
make defconfig

echo "diy-part2.sh 物理修复执行完毕！"
