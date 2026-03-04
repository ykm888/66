#!/bin/bash
# 自定义二次配置脚本示例（禁用EOF）
set -e

echo "=== 执行自定义二次配置 ==="
cd $GITHUB_WORKSPACE  # 保持与仓库结构一致

# 示例：修改配置文件
if [ -f .config ]; then
    if ! grep -q "CONFIG_CUSTOM_OPTION=y" .config; then
        echo "CONFIG_CUSTOM_OPTION=y" >> .config
    fi
else
    echo "警告：未找到 .config 文件，跳过配置修改"
fi

# 示例：复制额外文件（保持原有逻辑）
if [ -d "$GITHUB_WORKSPACE/custom-files" ] && [ "$(ls -A $GITHUB_WORKSPACE/custom-files)" ]; then
    cp -v $GITHUB_WORKSPACE/custom-files/*.patch package/boot/uboot-mediatek/patches/
else
    echo "警告：未找到 custom-files 目录或文件，跳过补丁复制"
fi

# 示例：执行其他操作（禁用EOF，改用输入重定向）
if [ -f Makefile ]; then
    # 生成临时输入文件
    echo -e "save\nexit" > /tmp/menuconfig_input
    # 执行 menuconfig 并传递输入
    make menuconfig < /tmp/menuconfig_input
    # 清理临时文件
    rm /tmp/menuconfig_input
else
    echo "警告：未找到 Makefile，跳过 menuconfig"
fi
