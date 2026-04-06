#!/bin/bash
set -e

# 1. Path Positioning
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$WORKSPACE/main-repo/888"
OPENWRT_DIR="$WORKSPACE/source-repo/immortalwrt"

echo "=== [Part 1] Injecting Hardware 3-Piece Set from 888/ ==="

# 2. Inject DTS and Makefile
mkdir -p "$OPENWRT_DIR/target/linux/mediatek/dts"
mkdir -p "$OPENWRT_DIR/target/linux/mediatek/image"

[ -f "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" ] && \
    cp -v "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" "$OPENWRT_DIR/target/linux/mediatek/dts/"

[ -f "$CONFIG_DIR/mt7981_sl3000.mk" ] && \
    cp -v "$CONFIG_DIR/mt7981_sl3000.mk" "$OPENWRT_DIR/target/linux/mediatek/image/"

# 3. Force Architecture Lock (Anti-x86 Patch)
cd "$OPENWRT_DIR"
rm -f .config
if [ -f "$CONFIG_DIR/sl3000.config" ]; then
    cp -v "$CONFIG_DIR/sl3000.config" .config
    # Destroy x86 default flags
    sed -i 's/CONFIG_TARGET_x86_64=y/# CONFIG_TARGET_x86_64 is not set/' .config
    sed -i 's/CONFIG_TARGET_x86=y/# CONFIG_TARGET_x86 is not set/' .config
    # Append Mediatek Filogic SL3000-specific target
    {
      echo "CONFIG_TARGET_mediatek=y"
      echo "CONFIG_TARGET_mediatek_filogic=y"
      echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-spi-nor=y"
    } >> .config
else
    echo "❌ Error: sl3000.config not found in $CONFIG_DIR"
    exit 1
fi

# 4. Feeds Update
./scripts/feeds update -a
./scripts/feeds install -a

# 5. Final Alignment
make defconfig
echo "✅ [Part 1] Architecture locked to ARM64 (MT7981)"
