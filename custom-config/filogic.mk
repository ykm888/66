# SL-3000 硬件固件合成配置文件
# 核心修正：
# 1. 移除 ptgen 的 -l 1024 参数，防止 1024M RAM 场景下 GPT 备份表头物理偏移损坏。
# 2. 增强 sl3000-nor-bundle 逻辑，确保 BL2 和 FIP 零件物理存在。

# --- 1. 定义 GPT eMMC 分区布局 ---
define Build/mt798x-gpt-emmc-production
	# 使用 ptgen 生成 GPT 分区表
	# -g: 生成 GPT 格式
	# -a 1: 扇区对齐 (512B/4K 自适应)
	# 物理修正：删除了可能导致分区溢出的硬编码限制
	ptgen -g -o $@ -a 1 \
		-t 0x83	-N ubootenv	-r	-p 512k@4M \
		-t 0x83	-N factory	-r	-p 2M@5M \
		-t 0x83	-N kernel	-r	-p 64M@64M \
		-t 0x83	-N production		-p $(CONFIG_TARGET_ROOTFS_PARTSIZE)M@128M
endef

# --- 2. 定义 32MB NOR 救砖全家桶合成逻辑 ---
define Build/sl3000-nor-bundle
	rm -f $@.nor
	# 物理创建一个严格 32MB 的空白镜像容器
	truncate -s 32M $@.nor
	
	# 写入 BL2 (ATF) - 必须位于 0 地址
	# 物理对齐：Makefile 里的重命名逻辑会将 .bin 映射为 .img
	@test -f $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.img || { echo "ERROR: BL2零件(bl2.img)缺失！"; exit 1; }
	dd if=$(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.img of=$@.nor bs=1k conv=notrunc
	
	# 写入 FIP (U-Boot) - 必须位于 1024k (1MB) 位置
	# 物理对齐：配合 uboot-mediatek Makefile 生成的 .bin
	@test -f $(STAGING_DIR_IMAGE)/mt7981_sl_3000-nor-fip.bin || { echo "ERROR: FIP零件(fip.bin)缺失！"; exit 1; }
	dd if=$(STAGING_DIR_IMAGE)/mt7981_sl_3000-nor-fip.bin of=$@.nor bs=1k seek=1024 conv=notrunc
	
	# 合成完毕后移动到目标文件
	cp $@.nor $@
	rm -f $@.nor
endef

# --- 3. 设备物理定义 ---
define Device/sl_3000-nor-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := NOR-Boot-1024M-Full-Rescue
  
  # 物理引用：必须确保内核源码树中有同名的 .dts 文件
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  
  # 核心驱动包：eMMC、2.5G 网口、文件系统工具
  DEVICE_PACKAGES := kmod-mmc-mtk kmod-mtk-sd kmod-mt7531 f2fs-tools kmod-fs-f2fs \
                     kmod-fs-ext4 parted resize2fs luci-app-turboacc
  
  # 定义输出产物：
  # 1. nor-programmer-dump.bin (32MB 救砖包)
  # 2. emmc-sysupgrade.bin (eMMC 刷机包)
  IMAGES := nor-programmer-dump.bin emmc-sysupgrade.bin
  
  # 调用合成宏
  IMAGE/nor-programmer-dump.bin := sl3000-nor-bundle
  
  # eMMC 布局流水线：GPT -> 填充内核 -> 填充 Rootfs -> 添加元数据
  IMAGE/emmc-sysupgrade.bin := mt798x-gpt-emmc-production | \
                               pad-to 64M | append-kernel | \
                               pad-to 128M | append-rootfs | \
                               append-metadata
endef
TARGET_DEVICES += sl_3000-nor-emmc
