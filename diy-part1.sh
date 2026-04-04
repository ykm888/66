#!/bin/bash
# 2版：修复远程仓库拉取逻辑，确保物理路径闭环
# 原则：延续1版逻辑，只修复克隆冲突错误，不画蛇添足。

# 1. 设置远程底层源地址 (SL3000 专用同步分支)
REMOTE_REPO="https://github.com/ykm99999/66"
REMOTE_BRANCH="sl3000-full-sync"

echo "=== 开始物理执行：远程底层源拉取 ==="

# 2. 清理并创建临时空间 (避免 Git 非空目录克隆失败)
rm -rf source-temp
mkdir -p source-temp

# 3. 像素级精准拉取
# 注意：我们将整个分支拉取下来，然后提取其中的子组件，这样效率更高且不会产生路径冲突
git clone --depth 1 --branch $REMOTE_BRANCH $REMOTE_REPO source-temp

# 4. 搬运底层组件到 OpenWrt 编译目录
# 确保与你之前修改的路径 (arm-trusted-firmware, u-boot) 严格一致
echo "正在搬运底层组件..."
[ -d "source-temp/u-boot" ] && cp -r source-temp/u-boot ./u-boot
[ -d "source-temp/arm-trusted-firmware" ] && cp -r source-temp/arm-trusted-firmware ./arm-trusted-firmware
[ -d "source-temp/mtk_uartboot" ] && cp -r source-temp/mtk_uartboot ./mtk_uartboot

# 5. 基础 Feeds 优化
sed -i 's/^src-git telephony/#src-git telephony/g' feeds.conf.default

# 6. 清理临时目录
rm -rf source-temp

echo "✅ diy-part1.sh: 远程源拉取与物理路径闭环完成"
