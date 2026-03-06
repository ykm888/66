#!/bin/bash

# 5版修正：进入物理源码目录
cd openwrt || exit 1

# 1. 物理拉取私有 U-Boot 源码 (原文照抄)
rm -rf package/boot/uboot-mtk
git clone https://github.com/ykm888/66 -b sl3000-uboot-base package/boot/uboot-mtk

# 2. 【物理静默审计】全路径执行依赖项“设置删除” (原文照抄)
find package/ -name "Makefile" | xargs sed -i 's/ +luci-lua-runtime//g' 2>/dev/null || true
find package/ -name "Makefile" | xargs sed -i 's/ +luci-base\/host//g' 2>/dev/null || true
find package/ -name "Makefile" | xargs sed -i 's/ +csstidy\/host//g' 2>/dev/null || true
find package/ -name "Makefile" | xargs sed -i 's/ +luasrcdiet\/host//g' 2>/dev/null || true
find package/ -name "Makefile" | xargs sed -i 's/ +lua-cjson//g' 2>/dev/null || true
find package/ -name "Makefile" | xargs sed -i 's/ +glib2//g' 2>/dev/null || true
find package/ -name "Makefile" | xargs sed -i 's/ +libgpiod//g' 2>/dev/null || true
find package/ -name "Makefile" | xargs sed -i 's/ +libpam//g' 2>/dev/null || true
find package/ -name "Makefile" | xargs sed -i 's/ +pciids//g' 2>/dev/null || true
find package/ -name "Makefile" | xargs sed -i 's/ +pciutils//g' 2>/dev/null || true
find package/ -name "Makefile" | xargs sed -i 's/ +bc//g' 2>/dev/null || true
find package/ -name "Makefile" | xargs sed -i 's/ +jq//g' 2>/dev/null || true
find package/ -name "Makefile" | xargs sed -i 's/ +usbutils//g' 2>/dev/null || true

# 3. 【精准修复：条件注入】 (原文照抄 4版)
if grep -q "Device/sl_3000-emmc" target/linux/mediatek/image/filogic.mk; then
    echo "检测到仓库源已包含 sl_3000-emmc 配置，执行物理对齐。"
    sed -i 's/DEVICE_DRAM_SIZE := .*/DEVICE_DRAM_SIZE := 1024M/g' target/linux/mediatek/image/filogic.mk
else
    cat << 'EOF' >> target/linux/mediatek/image/filogic.mk

define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  DEVICE_DRAM_SIZE := 1024M
  DEVICE_PACKAGES := $(MT7981_USB_PKGS) f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc \
	luci-app-ksmbd luci-i18n-ksmbd-zh-cn ksmbd-utils
  KERNEL_LOADADDR := 0x44000000
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  IMAGES := sysupgrade.bin factory.img.gz
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  ARTIFACTS := emmc-gpt.bin emmc-preloader.bin emmc-bl31-uboot.fip
  ARTIFACT/emmc-gpt.bin := mt798x-gpt emmc
  ARTIFACT/emmc-preloader.bin := mt7981-bl2 emmc-ddr3
  ARTIFACT/emmc-bl31-uboot.fip := mt7981-bl31-uboot emmc-ddr3
  IMAGE/factory.img.gz := mt798x-gpt emmc |\
	pad-to 17k | mt7981-bl2 emmc-ddr3 |\
	pad-to 6656k | mt7981-bl31-uboot emmc-ddr3 |\
	pad-to 64M | append-image squashfs-sysupgrade.itb | gzip
endef
TARGET_DEVICES += sl_3000-emmc
EOF
fi

# 4. 物理适配全局 1024M DRAM 变量 (原文照抄)
sed -i 's/DRAM_SIZE := 256M/DRAM_SIZE := 1024M/g' target/linux/mediatek/image/filogic.mk

# 5. 【内核编译器物理修正】强制 .config 使用正确的工具链路径
sed -i 's/CONFIG_EXTERNAL_TOOLCHAIN=y/# CONFIG_EXTERNAL_TOOLCHAIN is not set/g' .config
sed -i 's/CONFIG_KERNEL_KALLSYMS=y/# CONFIG_KERNEL_KALLSYMS is not set/g' .config
sed -i 's/CONFIG_KERNEL_DEBUG_INFO=y/# CONFIG_KERNEL_DEBUG_INFO is not set/g' .config

echo "物理延续成功：5版脚本已修正内核编译器配置。"
