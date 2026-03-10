define Build/sl3000-nor-bundle
	rm -f $@.nor
	# 物理创建 32MB 空白容器
	truncate -s 32M $@.nor
	# 这里的路径对齐很关键，$(STAGING_DIR_IMAGE) 通常指向 staging_dir/target.../image
	@test -f $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.img || { echo "BL2 Missing!"; exit 1; }
	dd if=$(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.img of=$@.nor bs=1k conv=notrunc
	@test -f $(STAGING_DIR_IMAGE)/mt7981_sl_3000-nor-fip.bin || { echo "FIP Missing!"; exit 1; }
	dd if=$(STAGING_DIR_IMAGE)/mt7981_sl_3000-nor-fip.bin of=$@.nor bs=1k seek=1024 conv=notrunc
	cp $@.nor $@
	rm -f $@.nor
endef

define Device/sl_3000-nor-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := NOR-Boot-1024M-Full
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_PACKAGES := kmod-mmc-mtk kmod-mtk-sd kmod-mt7531 f2fs-tools kmod-fs-f2fs
  IMAGES := nor-programmer-dump.bin emmc-sysupgrade.bin
  IMAGE/nor-programmer-dump.bin := sl3000-nor-bundle
  IMAGE/emmc-sysupgrade.bin := mt798x-gpt-emmc-production | pad-to 64M | append-kernel | pad-to 128M | append-rootfs | append-metadata
endef
TARGET_DEVICES += sl_3000-nor-emmc
