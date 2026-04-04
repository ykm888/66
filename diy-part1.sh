#!/bin/bash
# 1版原文照抄，修复为远程仓库拉取模式

# 1. 设置远程底层源地址
REMOTE_REPO="https://github.com/ykm99999/66"
REMOTE_BRANCH="sl3000-full-sync"

# 2. 拉取别人的三个底层源到指定目录
echo "=== 正在拉取远程底层源: $REMOTE_BRANCH ==="
mkdir -p source-repo
git clone --depth 1 --branch $REMOTE_BRANCH $REMOTE_REPO source-repo/u-boot
git clone --depth 1 --branch $REMOTE_BRANCH $REMOTE_REPO source-repo/arm-trusted-firmware
git clone --depth 1 --branch $REMOTE_BRANCH $REMOTE_REPO source-repo/mtk_uartboot

# 3. 基础 Feeds 优化
sed -i 's/^src-git telephony/#src-git telephony/g' feeds.conf.default

echo "✅ diy-part1.sh: 远程源拉取与预处理完成"
