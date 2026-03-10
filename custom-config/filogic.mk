# SL-3000 物理定制版：修复 ptgen 磁盘长度限制及标签对齐

SL3000_PKGS := kmod-mmc-mtk kmod-mtk-sd kmod-mt7531 f2fs-tools e2fsprogs kmod-fs-f2fs \
               kmod-fs-ext4 parted resize2fs datconf-lua

# --- 1. 合成 32MB NOR 救砖包 ---
define Build/sl3000-nor-bundle
	rm -f $@.nor
	truncate -s 32M $@.nor
	@test -f $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.img || { echo "BL2 missing"; exit 1; }
	dd if=$(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.img of=$@.nor bs=1k conv=notrunc
	@test -f $(STAGING_DIR_IMAGE)/mt7981_sl_3000-nor-fip.bin || { echo "FIP missing"; exit 1; }
	dd if=$(STAGING_DIR_IMAGE)/mt7981_sl_3000-nor-fip.bin of=$@.nor bs=1k seek=1024 conv=notrunc
	cp $@.nor $@
	rm -f $@.nor
endef

# --- 2. 生成 eMMC GPT 分区表 ---
define Build/mt798x-gpt-emmc-production
	# 物理修正：删除 -l 1024 以免 GPT 备份表头越界。删除 -a 1 强制对齐以提高兼容性。
	# 标签名统一为 production 对应 DTS
	ptgen -g -o $@ \
		-t 0x83	-N ubootenv	-r	-p 512k@4M \
		-t 0x83	-N factory	-r	-p 2M@5M \
		-t 0x83	-N kernel	-r	-p 64M@64M \
		-t 0x83	-N production		-p $(CONFIG_TARGET_ROOTFS_PARTSIZE)M@128M
endef

# --- 3. 设备定义 ---
define Device/sl_3000-nor-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := NOR-Boot-1024M-Final
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  DEVICE_PACKAGES := $(SL3000_PKGS)

  IMAGES := nor-programmer-dump.bin emmc-sysupgrade.bin
  # 物理修正：不要在 Device 定义里强制 IMAGE_SIZE，由各镜像流水线控制
  
  IMAGE/nor-programmer-dump.bin := sl3000-nor-bundle
  IMAGE/emmc-sysupgrade.bin := mt798x-gpt-emmc-production | \
                               pad-to 64M | append-kernel | \
                               pad-to 128M | append-rootfs | \
                               append-metadata
endef
TARGET_DEVICES += sl_3000-nor-emmc
