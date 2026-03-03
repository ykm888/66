#!/bin/bash

# 物理审计：严格延续上一版原文逻辑，确保 1024M 物理全闭环

# 1. 物理拦截：内核 6.6 核心报错点
find . -name "mtk_eth_soc.c" -exec sed -i '/MTK_WIFI_CHIP_OFFLINE/,/break;/d' {} + 2>/dev/null || true

# 2. 物理清淤：粉碎旧缓存，防止旧产物干扰
echo "物理清淤：粉碎旧源码与产物缓存..."
rm -rf dl/u-boot-* 2>/dev/null || true
rm -rf build_dir/target-*/u-boot-* 2>/dev/null || true
rm -rf staging_dir/host/share/u-boot 2>/dev/null || true

# 3. 物理劫持：修正 Makefile 基础定义
UBOOT_MK="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MK" ]; then
    echo "物理注入：重定向源码并锁定 UBOOT_TARGETS..."
    # 修正仓库地址与分支
    sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g" "$UBOOT_MK"
    sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UBOOT_MK"
    sed -i "s|PKG_MIRROR_HASH:=.*|PKG_MIRROR_HASH:=skip|g" "$UBOOT_MK"
    
    # 确保 UBOOT_TARGETS 包含我们的设备
    sed -i "s/UBOOT_TARGETS :=.*/UBOOT_TARGETS := mt7981_sl_3000-emmc/g" "$UBOOT_MK"

    # 4. 【核心修复】：物理路径对齐（不使用 EOF，直接 sed 替换）
    # 修复 Build/fip-image 里的子目录路径
    sed -i '/--nt-fw/c \		--nt-fw $(PKG_BUILD_DIR)/$(BUILD_VARIANT)/u-boot.bin \\' "$UBOOT_MK"
    sed -i '/fiptool create/a \		$(PKG_BUILD_DIR)/$(BUILD_VARIANT)/u-boot.fip' "$UBOOT_MK"

    # 5. 【物理隧道】：重写 Build/InstallDev 段落
    # 找到 Build/InstallDev 的起始行，强行插入物理搬运逻辑
    # 我们直接定位到 $(INSTALL_DIR) $(STAGING_DIR_IMAGE) 这一行后面添加
    sed -i '/define Build\/InstallDev/,/endef/d' "$UBOOT_MK"
    # 在 eval 之前重新插入完整的 InstallDev 逻辑
    sed -i '/\$(eval \$(call BuildPackage\/U-Boot))/i \
define Build/InstallDev \
	$(INSTALL_DIR) $(STAGING_DIR_HOST)/share/u-boot \
	$(CP) $(PKG_BUILD_DIR)/$(BUILD_VARIANT)/bl2.bin $(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-bl2.bin \
	$(CP) $(PKG_BUILD_DIR)/$(BUILD_VARIANT)/u-boot.fip $(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-fip.bin \
endef\
' "$UBOOT_MK"
fi

# 6. 物理注入 .config 并强制锁定 1024M 选型
echo "物理锁定：强制注入 1024M 设备定义..."
[ -f .config ] || touch .config
# 先清理旧定义防止冲突
sed -i '/CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc/d' .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config
echo "CONFIG_NR_DRAM_BANKS=1" >> .config
echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config

# 7. 物理校验：filogic.mk GPT 格式强制对齐（如果脚本没改，这里强行改）
FILOGIC_MK="target/linux/mediatek/image/filogic.mk"
if [ -f "$FILOGIC_MK" ]; then
    echo "物理检查：强制修正 GPT 分区表格式..."
    # 强行将旧的格式替换为 Size@Offset 格式
    sed -i 's/preloader:64k:256k/256k@64k:preloader/g' "$FILOGIC_MK"
    sed -i 's/bl31:256k:512k/512k@256k:bl31/g' "$FILOGIC_MK"
    sed -i 's/u-boot:512k:2048k/2048k@512k:u-boot/g' "$FILOGIC_MK"
fi
