#!/bin/bash
set -euo pipefail

# 从环境变量获取配置（与工作流保持一致）
TARGET="${TARGET:-mediatek/filogic}"
DEVICE="${DEVICE:-sl3000}"
BUILD_DIR=$(pwd)
JOBS=$(nproc)

# 清理旧构建文件
make clean

# 生成设备配置（使用工作流传入的TARGET和DEVICE）
make menuconfig <<EOF
${TARGET}_${DEVICE}_config
exit
EOF

# 开始编译（启用并行构建，失败时降级为单线程排查）
echo "开始构建，使用 $JOBS 线程..."
make -j$JOBS || {
  echo "并行构建失败，尝试单线程构建..."
  make -j1 V=s
}

# 生成校验文件
cd bin/targets/"${TARGET}"
sha256sum *.bin > sha256sums

# 输出构建信息
echo "构建完成："
ls -lh *.bin
echo "SHA256校验值："
cat sha256sums
