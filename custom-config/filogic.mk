# SL-3000 硬件固件合成配置文件 (最终修复版)
# 物理准则：
# 1. 零件对齐：统一使用 bl2.img 和 fip.bin，匹配 Makefile 的 install 钩子。
# 2. GPT 安全：移除 -l 参数，确保 1024M RAM 场景下 eMMC 分区表物理安全。

# --- 1. 定义 GPT eMMC 分区布局 ---
define Build/mt798x-gpt-emmc-production
	# ptgen 物理生成：-g (GPT), -a 1 (512B对齐)
	# 移除硬编码长度限制，防止 GPT 备份表头在 1024M 设备上物理偏移溢出
	ptgen -g -o $@ -a 1 \
		-t 0x83	-N ubootenv	-r	-p 512k@4M \
		-t 0x83	-N factory	-r	-p 2M@5M \
		-t 0x83	-N kernel	-r	-p 64M@64M \
		-t 0x83	-N production		-p $(CONFIG_TARGET_ROOTFS_PARTSIZE)M@128M
endef

# --- 2. 定义 32MB NOR 救砖全家桶合成逻辑 ---
define Build/sl3000-nor-bundle
	rm -f $@.nor
	# 物理创建一个严格 32MB 的空白镜像容器 (DUMP 文件)
	truncate -s 32M $@.nor
	
	# --- 写入 BL2 (ATF) ---
	# 物理对齐：Makefile 已将 mt7981-nor-ddr4-bl2.bin 映射为 bl2.img
	@test -f $(STAGING_DIR_IMAGE)/bl2.img || { \
		echo "ERROR: BL2零件(bl2.img)缺失！请检查 arm-trusted-firmware-mediatek 编译路径"; \
		exit 1; \
	}
	dd if=$(STAGING_DIR_IMAGE)/bl2.img of=$@.nor bs=1k conv=notrunc
	
	# --- 写入 FIP (U-Boot) ---
	# 物理对齐：配合 uboot-mediatek 产出的标准 fip.bin (位于 1MB 偏移处)
	@test -f $(STAGING_DIR_IMAGE)/fip.bin || { \
		echo "ERROR: FIP零件(fip.bin)缺失！请检查 uboot-mediatek 编译路径"; \
		exit 1; \
	}
	dd if=$(STAGING_DIR_IMAGE)/fip.bin of=$@.nor bs=1k seek=1024 conv=notrunc
	
	# 物理闭环：合成完毕后移动到目标文件并清理临时件
	cp $@.nor $@
	rm -f $@.nor
endef

# --- 3. 设备物理定义 ---
define Device/sl_3000-nor-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := NOR-Boot-1024M-Full-Rescue
  
  # 物理路径锁定：确保 5.15 内核 DTS 绝对命中
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  
  # 救砖核心驱动包：eMMC 控制器、2.5G 网口、文件系统扩容工具
  DEVICE_PACKAGES := kmod-mmc-mtk kmod-mtk-sd kmod-mt7531 f2fs-tools kmod-fs-f2fs \
                     kmod-fs-ext4 parted resize2fs luci-app-turboacc
  
  # 定义物理输出产物
  IMAGES := nor-programmer-dump.bin emmc-sysupgrade.bin
  
  # 1. 物理生成：32MB 编程器固件 (救砖用)
  IMAGE/nor-programmer-dump.bin := sl3000-nor-bundle
  
  # 2. 物理生成：eMMC 刷机包 (常规更新用)
  # 流程：生成GPT -> 填充内核(64M) -> 填充Rootfs(128M起) -> 添加元数据
  IMAGE/emmc-sysupgrade.bin := mt798x-gpt-emmc-production | \
                               pad-to 64M | append-kernel | \
                               pad-to 128M | append-rootfs | \
                               append-metadata
end Device/sl_3000-nor-emmc

TARGET_DEVICES += sl_3000-nor-emmc
