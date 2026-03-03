# GPT 分区物理定义
MTK_GPT_PARTS := preloader:64k:256k;bl31:256k:512k;u-boot:512k:2048k;u-boot-env:2048k:256k;factory:2304k:256k;production:2560k:512k;recovery:3072k:20480k;userdata:23552k:

# 修复后的 GPT 构建宏：先创建基础文件
define Build/mt798x-gpt
	rm -f $@
	touch $@
	$(STAGING_DIR_HOST)/bin/ptgen \
		-g -o $@.gpt \
		-a 1 -l 1024 \
		$(if $(findstring sd,$(1)), -s 512) \
		$(if $(findstring emmc,$(1)), -s 512) \
		$(foreach part,$(MTK_GPT_PARTS), -p '$(part)')
	cat $@.gpt >> $@
endef

define Build/mt7981-bl2
	cat $(STAGING_DIR_HOST)/share/u-boot/mt7981-$(1)-preloader.bin >> $@
endef

define Build/mt7981-bl31-uboot
	cat $(STAGING_DIR_HOST)/share/u-boot/mt7981-$(1)-bl31-uboot.fip >> $@
endef

# 设备定义
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
  
  ARTIFACTS := emmc-gpt.bin emmc-preloader.bin emmc-bl31-uboot.fip
  ARTIFACT/emmc-gpt.bin := mt798x-gpt emmc
  ARTIFACT/emmc-preloader.bin := mt7981-bl2 emmc-ddr3
  ARTIFACT/emmc-bl31-uboot.fip := mt7981-bl31-uboot emmc-ddr3

  IMAGES := sysupgrade.bin factory.img.gz
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  # 物理缝合逻辑：增加底图初始化
  IMAGE/factory.img.gz := mt798x-gpt emmc |\
	pad-to 17k | mt7981-bl2 emmc-ddr3 |\
	pad-to 6656k | mt7981-bl31-uboot emmc-ddr3 |\
	pad-to 64M | append-image squashfs-sysupgrade.itb | gzip
endef
TARGET_DEVICES += sl_3000-emmc
