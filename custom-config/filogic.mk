DTS_DIR := $(DTS_DIR)/mediatek

define Image/Prepare
	# For UBI we want only one extra block
	rm -f $(KDIR)/ubi_mark
	echo -ne '\xde\xad\xc0\xde' > $(KDIR)/ubi_mark
endef

define Build/mt7981-bl2
	cat $(STAGING_DIR_IMAGE)/mt7981-$1-bl2.img >> $@
endef

define Build/mt7981-bl31-uboot
	cat $(STAGING_DIR_IMAGE)/mt7981_$1-u-boot.fip >> $@
endef

define Build/mt7986-bl2
	cat $(STAGING_DIR_IMAGE)/mt7986-$1-bl2.img >> $@
endef

define Build/mt7986-bl31-uboot
	cat $(STAGING_DIR_IMAGE)/mt7986_$1-u-boot.fip >> $@
endef

define Build/mt7988-bl2
	cat $(STAGING_DIR_IMAGE)/mt7988-$1-bl2.img >> $@
endef

define Build/mt7988-bl31-uboot
	cat $(STAGING_DIR_IMAGE)/mt7988_$1-u-boot.fip >> $@
endef

define Build/mt798x-gpt
	cp $@ $@.tmp 2>/dev/null || true
	ptgen -g -o $@.tmp -a 1 -l 1024 \
		$(if $(findstring spim-nand,$1), -p 512k@256k:env -p 1024k@768k:factory -p 2048k@1792k:fip) \
		$(if $(findstring emmc,$1), -p 32M@2M:fip)
	cat $@.tmp >> $@
	rm $@.tmp
endef

define Device/abt_sl3000
  DEVICE_VENDOR := ABT
  DEVICE_MODEL := SL3000
  DEVICE_VARIANT := (eMMC)
  DEVICE_DTS := mt7981b-3000-emmc
  DEVICE_DTS_DIR := ../dts
  SUPPORTED_DEVICES := abt,sl3000
  DEVICE_PACKAGES := kmod-mt7981-firmware mt7981-wo-firmware kmod-usb3 kmod-mt7915e
  KERNEL := kernel-bin | lzma
  KERNEL_INITRAMFS := kernel-bin | lzma | \
        fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  IMAGE_SIZE := 102400k
  IMAGES := sysupgrade.itb
  IMAGE/sysupgrade.itb := append-kernel | append-rootfs | \
        monitor-fip mt7981-emmc-abt_sl3000 | pad-to 128k | append-metadata
  ARTIFACTS := preloader.bin u-boot.fip
  ARTIFACT/preloader.bin := mt7981-bl2 emmc-ddr3
  ARTIFACT/u-boot.fip := mt7981-bl31-uboot abt_sl3000
endef
TARGET_DEVICES += abt_sl3000
