#!/bin/bash
# 物理执行：Part 1 源码清理与源注入

# 1. 添加插件源 (成功案例必备)
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default

# 2. 物理清理：删除源码自带的旧版 uboot 和 atf 定义，确保后续使用 888 补丁
rm -rf package/boot/uboot-mediatek
rm -rf package/boot/arm-trusted-firmware-mediatek

echo "物理诊断：Part 1 清理完成，为救砖零件腾出了物理空间。"
