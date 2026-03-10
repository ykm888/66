# SL-3000 物理定制版：针对 NOR-BOOT + eMMC-STORAGE + 1024M-RAM
# 修复重点：消除分区表追加冗余、修正标签对齐、强制文件存在性检查

# 基础依赖包定义
SL3000_PKGS := kmod-mmc-mtk kmod-mtk-sd kmod-mt7531 f2fs-tools e2fsprogs kmod-fs-f2fs \
               kmod-fs-ext4 parted resize2fs datconf-lua

# --- 1. 物理合成：32MB NOR 编程器救砖全量包 ---
define Build/sl3000-nor-bundle
	rm -f $@.nor
	# 物理锁定 32MB 空间，确保编程器固件尺寸标准
	truncate -s 32M $@.nor
	
	# 写入 1024M RAM 专用 NOR-BL2 (起始偏移 0)
	@test -f $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.img || { echo "!!! ERROR: BL2 missing in $(STAGING_DIR_IMAGE) !!!"; exit 1; }
	dd if=$(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.img of=$@.nor bs=1k conv=notrunc
	
	# 写入 FIP (U-Boot) (必须在偏移 1024KB 处，与原厂布局一致)
	# 文件名必须与 U-Boot 编译输出 mt7981_sl_3000-nor-fip.bin 严格对齐
	@test -f $(STAGING_DIR_IMAGE)/mt7981_sl_3000-nor-fip.bin || { echo "!!! ERROR: FIP bin missing !!!"; exit 1; }
	dd if=$(STAGING_DIR_IMAGE)/mt7981_sl_3000-nor-fip.bin of=$@.nor bs=1k seek=1024 conv=notrunc
	
	# 将成品拷贝回目标文件
	cp $@.nor $@
	rm -f $@.nor
endef

# --- 2. 物理对齐：eMMC GPT 分区表生成 ---
# 警告：标签名必须与 DTS 中的 root=PARTLABEL=production 保持 100% 一致
define Build/mt798x-gpt-emmc-production
	# 直接生成 GPT 分区表到目标文件，不使用追加模式防止偏移
	ptgen -g -o $@ -a 1 -l 1024 \
		-t 0x83	-N ubootenv	-r	-p 512k@4M \
		-t 0x83	-N factory	-r	-p 2M@5M \
		-t 0x83	-N kernel	-r	-p 64M@64M \
		-t 0x83	-N production		-p $(CONFIG_TARGET_ROOTFS_PARTSIZE)M@128M
endef

# --- 3. 设备物理参数定义 ---
define Device/sl_3000-nor-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := NOR-Boot-1024M-Final
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  DEVICE_PACKAGES := $(SL3000_PKGS)

  # 生成两个物理文件：一个刷 NOR (救砖)，一个刷 eMMC (系统)
  IMAGES := nor-programmer-dump.bin emmc-sysupgrade.bin
  
  # 救砖包构建流
  IMAGE/nor-programmer-dump.bin := sl3000-nor-bundle
  
  # 系统包构建流：分区表 -> 补齐写内核 -> 补齐写 rootfs -> 元数据
  # 注意：pad-to 的物理偏移必须与 ptgen 定义的起始偏移 (@64M, @128M) 严格一致
  IMAGE/emmc-sysupgrade.bin := mt798x-gpt-emmc-production | \
                               pad-to 64M | append-kernel | \
                               pad-to 128M | append-rootfs | \
                               append-metadata
endef
TARGET_DEVICES += sl_3000-nor-emmc
