#
# SL-3000 物理定制版：针对 NOR-BOOT + eMMC-STORAGE + 1024M-RAM
# 修复点：物理路径对齐、产物命名对齐、GPT 偏移锁定
#

# 物理组件包：确保 eMMC 驱动、GPT 分区工具、1024M 内存优化包全部就位
SL3000_PKGS := kmod-mmc-mtk kmod-mtk-sd kmod-mt7531 f2fs-tools e2fsprogs kmod-fs-f2fs \
               kmod-fs-ext4 parted resize2fs datconf-lua

# --- 1. 物理合成：生成 32MB NOR 离线编程器固件 (救砖心脏) ---
define Build/sl3000-nor-bundle
	# 物理初始化：创建一个干净的 32MB 空白文件
	rm -f $@.nor
	truncate -s 32M $@.nor
	# 写入 BL2：物理地址 0x0。必须是针对 1024M DDR4 编译的版本
	[ -f $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.img ] && \
	dd if=$(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.img of=$@.nor bs=1k conv=notrunc
	# 写入 FIP (U-Boot)：物理地址 0x100000 (即 1024KB 偏移)
	# 物理修正：文件名必须匹配你 U-Boot Makefile 中定义的 UBOOT_IMAGE
	[ -f $(STAGING_DIR_IMAGE)/mt7981_sl_3000-nor-u-boot.fip ] && \
	dd if=$(STAGING_DIR_IMAGE)/mt7981_sl_3000-nor-u-boot.fip of=$@.nor bs=1k seek=1024 conv=notrunc
	# 物理导出
	cp $@.nor $@
endef

# --- 2. 物理分区：生成 eMMC GPT 分区表 (生产环境) ---
define Build/mt798x-gpt-emmc-production
	cp $@ $@.tmp 2>/dev/null || true
	# 物理对齐：production 分区锁定在 64MB (131072s) 起始点，防止内核覆盖
	# 参数说明：-l 1024 为对齐颗粒，-p 声明分区大小与偏移
	ptgen -g -o $@.tmp -a 1 -l 1024 \
		-t 0x83	-N ubootenv	-r	-p 512k@4M \
		-t 0x83	-N factory	-r	-p 2M@5M \
		-t 0x2e -N production		-p $(CONFIG_TARGET_ROOTFS_PARTSIZE)M@64M
	cat $@.tmp >> $@
	rm $@.tmp
endef

# --- 3. 设备定义：SL-3000 终极版 ---
define Device/sl_3000-nor-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := NOR-Boot-1024M-Final
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  
  # 物理注入组件
  DEVICE_PACKAGES := $(SL3000_PKGS)

  # 产出定义：nor-programmer-dump 用于编程器，emmc-sysupgrade 用于日常升级
  IMAGES := nor-programmer-dump.bin emmc-sysupgrade.bin
  IMAGE_SIZE := 1024M

  # 物理动作 1：合成离线全量包
  IMAGE/nor-programmer-dump.bin := sl3000-nor-bundle

  # 物理动作 2：合成 eMMC 升级包
  # 逻辑：建立 GPT 分区表 -> 压入内核 -> 填充至 64M -> 压入 RootFS -> 校验
  IMAGE/emmc-sysupgrade.bin := mt798x-gpt-emmc-production | append-kernel | pad-to 64M | \
                               append-rootfs | pad-to $(IMAGE_SIZE) | check-size | append-metadata
endef
TARGET_DEVICES += sl_3000-nor-emmc
