#!/bin/bash
# 自定义二次配置脚本示例
set -e

echo "=== 执行自定义二次配置 ==="
cd $GITHUB_WORKSPACE/openwrt

# 示例：修改配置文件
if ! grep -q "CONFIG_CUSTOM_OPTION=y" .config; then
    echo "CONFIG_CUSTOM_OPTION=y" >> .config
fi

# 示例：复制额外文件
cp -v $GITHUB_WORKSPACE/custom-files/*.patch package/boot/uboot-mediatek/patches/

# 示例：执行其他操作
make menuconfig <<EOF
save
exit
EOF
