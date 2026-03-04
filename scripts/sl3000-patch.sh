#!/bin/bash
set -euo pipefail

# 配置构建参数
export BUILD_DIR=$(pwd)
export JOBS=$(nproc)
export TARGET="mediatek/filogic"
export DEVICE="sl3000"

# 清理旧构建文件
make clean

# 生成设备配置
make menuconfig <<EOF
${TARGET}_${DEVICE}_config
exit
EOF

# 开始编译（启用并行构建）
echo "开始构建，使用 $JOBS 线程..."
make -j$JOBS || {
  # 若并行构建失败，单线程重试以定位错误
  echo "并行构建失败，尝试单线程构建..."
  make -j1 V=s
}

# 生成校验文件
cd bin/targets/$TARGET
sha256sum *.bin > sha256sums

# 输出构建信息
echo "构建完成："
ls -lh *.bin
echo "SHA256校验值："
cat sha256sums
