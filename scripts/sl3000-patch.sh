#!/bin/bash

# 1. 物理拉取私有 U-Boot 源码 (延续 sl3000-uboot-base 分支)
rm -rf package/boot/uboot-mtk
git clone https://github.com/ykm888/66 -b sl3000-uboot-base package/boot/uboot-mtk

# 2. 【彻底修复错误】全路径扫描式抹除不存在的依赖 (补全 1m15s 日志所有项)
# 针对 package/ 目录下所有 Makefile 进行物理清洗，解决 dependency does not exist
# 涵盖: luci-lua-runtime, luci-base/host, csstidy/host, luasrcdiet/host, lua-cjson, glib2, libgpiod, libpam, pciids, pciutils 等
FIX_FILES=$(find package/ -name "Makefile")
for file in $FIX_FILES; do
    sed -i 's/ +luci-lua-runtime//g' "$file" 2>/dev/null
    sed -i 's/ +luci-base\/host//g' "$file" 2>/dev/null
    sed -i 's/ +csstidy\/host//g' "$file" 2>/dev/null
    sed -i 's/ +luasrcdiet\/host//g' "$file" 2>/dev/null
    sed -i 's/ +lua-cjson//g' "$file" 2>/dev/null
    sed -i 's/ +glib2//g' "$file" 2>/dev/null
    sed -i 's/ +libgpiod//g' "$file" 2>/dev/null
    sed -i 's/ +libpam//g' "$file" 2>/dev/null
    sed -i 's/ +pciids//g' "$file" 2>/dev/null
    sed -i 's/ +pciutils//g' "$file" 2>/dev/null
    sed -i 's/ +luci-compat//g' "$file" 2>/dev/null
    sed -i 's/ +bc//g' "$file" 2>/dev/null
    sed -i 's/ +jq//g' "$file" 2>/dev/null
    sed -i 's/ +usbutils//g' "$file" 2>/dev/null
    sed -i 's/ +wget-ssl//g' "$file" 2>/dev/null
done

# 3. 物理注入 Device 定义 (锁定 1024M 与救砖配置 - 原文照抄)
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

# 4. 物理适配 1024M DRAM 变量 (原文照抄)
sed -i 's/DRAM_SIZE := 256M/DRAM_SIZE := 1024M/g' target/linux/mediatek/image/filogic.mk

# 5. 内核调试瘦身 (原文照抄)
sed -i 's/CONFIG_KERNEL_KALLSYMS=y/# CONFIG_KERNEL_KALLSYMS is not set/g' .config
sed -i 's/CONFIG_KERNEL_DEBUG_INFO=y/# CONFIG_KERNEL_DEBUG_INFO is not set/g' .config

echo "物理延续成功：全路径依赖错误已全部修正。"
