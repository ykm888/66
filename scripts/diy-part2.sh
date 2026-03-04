#!/bin/bash

set -e

# 定义路径变量
OPENWRT_DIR="$GITHUB_WORKSPACE/openwrt"
MAIN_DIR="$GITHUB_WORKSPACE/main"

# 步骤 1：验证目录结构
echo "=== 验证目录结构 ==="
if [ ! -d "$OPENWRT_DIR" ]; then
  echo "ERROR: OpenWrt 目录未找到"
  exit 1
fi

if [ ! -d "$MAIN_DIR" ]; then
  echo "ERROR: Main 分支目录未找到"
  exit 1
fi

# 步骤 2：应用自定义补丁（示例）
echo "=== 应用自定义补丁 ==="
patch -p1 <<EOF
diff --git a/package/boot/uboot-mediatek/Makefile b/package/boot/uboot-mediatek/Makefile
index 1234567..89abcde 100644
--- a/package/boot/uboot-mediatek/Makefile
+++ b/package/boot/uboot-mediatek/Makefile
@@ -10,7 +10,7 @@ PKG_SOURCE:=uboot-custom.tar.zst
 PKG_SOURCE_PROTO:=local
 PKG_SOURCE_SUBDIR:=\$(PKG_NAME)-\$(PKG_VERSION)
 PKG_BUILD_DIR:=\$(BUILD_DIR)/\$(PKG_NAME)-\$(PKG_VERSION)
-
+# 自定义补丁
 include \$(INCLUDE_DIR)/package.mk
EOF

# 步骤 3：验证 U-Boot 配置
echo "=== 验证 U-Boot 配置 ==="
if [ ! -f "$OPENWRT_DIR/configs/mt7981_emmc_defconfig" ]; then
  echo "ERROR: U-Boot 配置文件缺失"
  exit 1
fi

# 步骤 4：验证设备配置
echo "=== 验证设备配置 ==="
if [ ! -f "$OPENWRT_DIR/target/linux/mediatek/filogic/config-6.6" ]; then
  echo "ERROR: 设备配置文件缺失"
  exit 1
fi

# 步骤 5：注入自定义配置（示例）
echo "=== 注入自定义配置 ==="
cat >> "$OPENWRT_DIR/.config" <<EOF
CONFIG_CUSTOM_PACKAGE=y
CONFIG_DEBUG=y
EOF

echo "=== 脚本执行完成 ==="
