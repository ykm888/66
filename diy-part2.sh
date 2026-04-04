#!/bin/bash
set -e

cd "$GITHUB_WORKSPACE/openwrt" || exit 1

DTS_DIR="target/linux/mediatek/dts"
MK_DIR="target/linux/mediatek/filogic"

echo "============================================="
echo " 写入 SL3000 硬件配置：32MB SPI + 128GB eMMC"
echo "============================================="

#----------------------------------------------------------------------
# 1. 生成 DTS：mt7981b-sl3000-emmc.dts（原生1GB内存，不修改）
#----------------------------------------------------------------------
cat > "$DTS_DIR"/mt7981b-sl3000-emmc.dts <<'EOF'
/dts-v1/;
#include "mt7981b.dtsi"
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>

/ {
	model = "SiLuo SL3000";
	compatible = "siluo,sl3000", "mediatek,mt7981b";

	memory@40000000 {
		device_type = "memory";
		reg = <0 0x40000000 0 0x40000000>;
	};

	chosen {
		bootargs = "console=ttyS0,115200n1 loglevel=8 earlycon=uart8250,mmio32,0x11000000";
	};

	keys {
		compatible = "gpio-keys";
		reset {
			label = "reset";
			gpios = <&pio 1 GPIO_ACTIVE_LOW>;
			linux,code = <KEY_RESTART>;
			debounce-interval = <20>;
		};
	};

	leds {
		compatible = "gpio-leds";
	};
};

&spi0 {
	status = "okay";
	flash@0 {
		compatible = "jedec,spi-nor";
		reg = <0>;
		spi-max-frequency = <52000000>;
		partitions {
			compatible = "fixed-partitions";
			#address-cells = <1>;
			#size-cells = <1>;
			partition@0 { label = "u-boot"; reg = <0x000000 0x140000>; read-only; };
			partition@140000 { label = "factory"; reg = <0x140000 0x040000>; read-only; };
			partition@180000 { label = "firmware"; reg = <0x180000 0x1e80000>; };
		};
	};
};

&mmc0 {
	status = "okay";
	bus-width = <8>;
	max-frequency = <200000000>;
	no-sd;
	no-sdio;
	non-removable;
};

&eth {
	status = "okay";
};
EOF

#----------------------------------------------------------------------
# 2. 生成设备mk：适配 32MB SPI + eMMC，不锁内存
#----------------------------------------------------------------------
cat > "$MK_DIR"/mt7981_sl3000.mk <<'EOF'
define Device/mt7981_sl3000_emmc
  DEVICE_VENDOR := SiLuo
  DEVICE_MODEL := SL3000
  DEVICE_DTS := mt7981b-sl3000-emmc
  SUPPORTED_DEVICES := siluo,sl3000

  # 32MB SPI NOR (25Q256FSSIG)
  KERNEL_SIZE := 4096k
  ROOTFS_SIZE := 26624k
  IMAGE_SIZE := 30720k
  BLOCKSIZE := 64k
  KERNEL_LOADADDR := 0x48000000

  DEVICE_PACKAGES := \
	luci luci-base luci-mod-system luci-theme-bootstrap \
	block-mount e2fsprogs f2fs-tools \
	kmod-fs-ext4 kmod-fs-f2fs \
	kmod-mmc kmod-sdhci-mtk \
	kmod-spi-nor \
	dropbear \
	mtd-utils uboot-envtools

  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += mt7981_sl3000_emmc
EOF

#----------------------------------------------------------------------
# 3. 启用机型、应用配置
#----------------------------------------------------------------------
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981_sl3000_emmc=y" >> .config

make defconfig

echo "✅ diy-part2 执行完成：SL3000 完整配置已写入"
echo "✅ 硬件：MT7981B | 1GB | 32MB SPI | 128GB eMMC"
echo "✅ 无内存强制，使用原生1GB配置"
