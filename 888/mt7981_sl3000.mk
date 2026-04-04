define Device/mt7981_sl3000_emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := SL3000
  DEVICE_VARIANT := eMMC
  DEVICE_DTS := mt7981b-sl3000-emmc
  SUPPORTED_DEVICES := sl,sl3000

  # 🔥 救砖全家桶（核心全部在这里）
  DEVICE_PACKAGES := \
	luci luci-base luci-mod-system luci-theme-bootstrap \
	fail2ban \
	block-mount blockd e2fsprogs f2fs-tools parted losetup kmod-fs-ext4 kmod-fs-f2fs \
	dropbear openssh-sftp-server \
	usbutils lsblk blkid mount-utils swap-utils \
	kmod-usb-storage kmod-usb-storage-uas kmod-usb3 \
	htop iftop iperf3 net-tools tcpdump wget-nossl \
	adminip ip-full ip-bridge kmod-bridge \
	uboot-envtools uboot-envtools-mtk

  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += mt7981_sl3000_emmc
