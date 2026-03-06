#!/bin/bash
# [2026-03-05] SL-3000 物理修复脚本
# 禁用 EOF，针对已手动清理补丁的仓库进行内核优化

CONFIG_FILE=".config"

echo "⚙️ 执行内核优化..."
# 启用硬件卸载固件
sed -i 's/# CONFIG_PACKAGE_mt7981-wo-firmware is not set/CONFIG_PACKAGE_mt7981-wo-firmware=y/' $CONFIG_FILE
# 关闭内核调试 (强制减脂)
sed -i 's/^CONFIG_KERNEL_DEBUG_INFO=y/# CONFIG_KERNEL_DEBUG_INFO is not set/' $CONFIG_FILE
sed -i 's/^CONFIG_KERNEL_DEBUG_KERNEL=y/# CONFIG_KERNEL_DEBUG_KERNEL is not set/' $CONFIG_FILE

echo "🛡️ 根除 Error 255 (剔除 x86 驱动)..."
for pkg in kmod-e1000 kmod-e1000e kmod-i915 kmod-tg3 kmod-vmxnet3 kmod-bnx2 kmod-8139too; do
    sed -i "/CONFIG_PACKAGE_$pkg=y/d" $CONFIG_FILE
done

# 确保 1024M 物理定义注入 (照抄之前逻辑)
# ... [此处保持之前的 Device/sl_3000-emmc 定义注入逻辑不变] ...

make defconfig
