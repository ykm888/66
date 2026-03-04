#!/bin/bash

set -e

# 定义路径变量
OPENWRT_DIR="$GITHUB_WORKSPACE/openwrt"

# 步骤 1：验证 OpenWrt 目录
echo "=== 验证 OpenWrt 目录 ==="
if [ ! -d "$OPENWRT_DIR" ]; then
  echo "ERROR: OpenWrt 目录未找到"
  exit 1
fi

# 步骤 2：应用 SL-3000 特定补丁（示例）
echo "=== 应用 SL-3000 补丁 ==="
patch -p1 <<EOF
diff --git a/target/linux/mediatek/filogic/image/Makefile b/target/linux/mediatek/filogic/image/Makefile
index 1234567..89abcde 100644
--- a/target/linux/mediatek/filogic/image/Makefile
+++ b/target/linux/mediatek/filogic/image/Makefile
@@ -10,7 +10,7 @@ define Device/sl_3000-emmc
   DEVICE_VENDOR:=SL
   DEVICE_MODEL:=3000
   DEVICE_PACKAGES:=kmod-ath11k-ct
-  IMAGE/sl_3000-emmc-factory.bin := append-kernel | append-rootfs | lzma | pad-128k
+  IMAGE/sl_3000-emmc-factory.bin := append-kernel | append-rootfs | gzip | pad-128k
 endef
EOF

# 步骤 3：验证补丁应用
echo "=== 验证补丁 ==="
if ! grep -q "gzip" "$OPENWRT_DIR/target/linux/mediatek/filogic/image/Makefile"; then
  echo "ERROR: 补丁未成功应用"
  exit 1
fi

echo "=== SL-3000 补丁执行完成 ==="
