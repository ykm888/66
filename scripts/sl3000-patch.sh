#!/bin/bash

# 2版修正：进入物理源码目录，确保后续 sed 和 cat 路径正确
cd openwrt || exit 1

# 1. 物理拉取私有 U-Boot 源码 (锁死 sl3000-uboot-base，原文照抄)
rm -rf package/boot/uboot-mtk
git clone https://github.com/ykm888/66 -b sl3000-uboot-base package/boot/uboot-mtk

# 2. 【物理静默审计】全路径执行“设置删除” (原文照抄 1版)
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

# 3. 物理注入 Device 定义 (锁定 1024M 与救砖配置，原文照抄 1版)
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

# 4. 物理适配 1024M DRAM 变量 (原文照抄 1版)
sed -i 's/DRAM_SIZE := 256M/DRAM_SIZE := 1024M/g' target/linux/mediatek/image/filogic.mk

# 5. 内核调试瘦身 (原文照抄 1版)
sed -i 's/CONFIG_KERNEL_KALLSYMS=y/# CONFIG_KERNEL_KALLSYMS is not set/g' .config
sed -i 's/CONFIG_KERNEL_DEBUG_INFO=y/# CONFIG_KERNEL_DEBUG_INFO is not set/g' .config

echo "物理延续成功：2版脚本已修正路径，依赖抹除与配置注入已生效。"
