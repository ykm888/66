#!/bin/bash
# =========================================================
# SL-3000 救砖全链路物理修复 (禁用 EOF 稳定版)
# =========================================================

# --- 1. 修复底层架构 (target/linux/mediatek/Makefile) ---
printf "include \$(TOPDIR)/rules.mk\n" > target/linux/mediatek/Makefile
printf "ARCH:=aarch64\n" >> target/linux/mediatek/Makefile
printf "BOARD:=mediatek\n" >> target/linux/mediatek/Makefile
printf "BOARDNAME:=MediaTek Filogic (SL-3000)\n" >> target/linux/mediatek/Makefile
printf "SUBTARGETS:=filogic\n" >> target/linux/mediatek/Makefile
printf "FEATURES:=dt-overlay emmc fpu gpio nand pci pcie rootfs-part separate_ramdisk squashfs usb\n" >> target/linux/mediatek/Makefile
printf "KERNEL_PATCHVER:=5.15\n" >> target/linux/mediatek/Makefile
printf "include \$(INCLUDE_DIR)/target.mk\n" >> target/linux/mediatek/Makefile
printf "DEFAULT_PACKAGES += kmod-leds-gpio kmod-gpio-button-hotplug autocore-arm\n" >> target/linux/mediatek/Makefile
printf "\$(eval \$(call BuildTarget))\n" >> target/linux/mediatek/Makefile

# --- 2. 物理配置锁定 (写入 .config) ---
printf "CONFIG_TARGET_mediatek=y\n" >> .config
printf "CONFIG_TARGET_mediatek_filogic=y\n" >> .config
printf "CONFIG_TARGET_mediatek_filogic_DEVICE_mediatek_mt7981-rfb-flash=y\n" >> .config
printf "CONFIG_PACKAGE_arm-trusted-firmware-mediatek-mt7981-nor-ddr4=y\n" >> .config
printf "CONFIG_PACKAGE_uboot-mediatek-mt7981-nor-ddr4=y\n" >> .config

# --- 3. 物理清理：防止旧索引干扰 ---
rm -rf package/boot/arm-trusted-firmware-mediatek
rm -rf package/boot/uboot-mediatek
