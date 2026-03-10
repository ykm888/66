# SL-3000 硬件固件合成配置文件
# 核心修正：移除 -l 1024 参数，防止 GPT 备份表头因物理扇区偏移导致损坏

# --- 1. 定义 GPT eMMC 分区布局 ---
define Build/mt798x-gpt-emmc-production
	# 使用 ptgen 生成 GPT 分区表
	# -g: 生成 GPT 格式
	# -a 1: 扇区对齐
	# 物理修正：删除了 -l 1024，允许 GPT 根据最后一个分区自动定位备份表头位置
	ptgen -g -o $@ -a 1 \
		-t 0x83	-N ubootenv	-r	-p 512k@4M \
		-t 0x83	-N factory	-r	-p 2M@5M \
		-t 0x83	-N kernel	-r	-p 64M@64M \
		-t 0x83	-N production		-p $(CONFIG_TARGET_ROOTFS_PARTSIZE)M@128M
endef

# --- 2. 定义 32MB NOR 救砖全家桶合成逻辑 ---
define Build/sl3000-nor-bundle
	rm -f $@.nor
	# 物理创建一个 32MB 的空白镜像容器
	truncate -s 32M $@.nor
	
	# 写入 BL2 (Boot Loader Stage 2) - 位于 0 偏移位置
	# 必须确保 staging_dir 中存在该文件，否则报错中断
	@test -f $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.img || { echo "ERROR: BL2零件缺失，请检查ATF编译配置"; exit 1; }
	dd if=$(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.img of=$@.nor bs=1k conv=notrunc
	
	# 写入 FIP (Flash Image Package, 含U-Boot) - 位于 1MB (1024k) 位置
	@test -f $(STAGING_DIR_IMAGE)/mt7981_sl_3000-nor-fip.bin || { echo "ERROR: FIP零件缺失，请检查U-Boot编译配置"; exit 1; }
	dd if=$(STAGING_DIR_IMAGE)/mt7981_sl_3000-nor-fip.bin of=$@.nor bs=1k seek=1024 conv=notrunc
	
	# 将合成好的全量包重命名为目标产物
	cp $@.nor $@
	rm -f $@.nor
endef

# --- 3. 设备物理定义 ---
define Device/sl_3000-nor-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := NOR-Boot-1024M-Full-Rescue
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  
  # 必须包含的驱动包
  DEVICE_PACKAGES := kmod-mmc-mtk kmod-mtk-sd kmod-mt7531 f2fs-tools kmod-fs-f2fs \
                     kmod-fs-ext4 parted resize2fs
  
  # 生成两种镜像：1. 编程器全量救砖包 2. eMMC 系统升级包
  IMAGES := nor-programmer-dump.bin emmc-sysupgrade.bin
  
  # 合成救砖包
  IMAGE/nor-programmer-dump.bin := sl3000-nor-bundle
  
  # 合成 eMMC 升级包 (GPT + Kernel + Rootfs)
  # 布局：128M 偏移量之前为引导区，128M 开始写入 Rootfs
  IMAGE/emmc-sysupgrade.bin := mt798x-gpt-emmc-production | \
                               pad-to 64M | append-kernel | \
                               pad-to 128M | append-rootfs | \
                               append-metadata
endef
TARGET_DEVICES += sl_3000-nor-emmc
