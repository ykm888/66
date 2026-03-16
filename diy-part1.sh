#!/bin/bash
# =========================================================
# 物理执行：Part 1 源码清理与源注入 (SL-3000 稳定版)
# =========================================================

# 1. 物理注入插件源 (增加去重逻辑，防止 feeds.conf 爆炸)
sed -i '/helloworld/d' feeds.conf.default
echo 'src-git helloworld https://github.com/fw876/helloworld' >> feeds.conf.default

# 2. 深度物理清理
# 强制删除自带的旧版引导零件，为 Part 2 的 ykm888 补丁铺平道路
# 增加 -f 参数防止文件不存在时脚本中断报错
rm -rf package/boot/uboot-mediatek
rm -rf package/boot/arm-trusted-firmware-mediatek

# 3. 物理预警：清理 staging 目录残留 (如果是在本地环境二次编译)
rm -rf staging_dir/target-aarch64_cortex-a53_musl/image/bl2.img
rm -rf staging_dir/target-aarch64_cortex-a53_musl/image/u-boot.bin

echo "物理诊断：Part 1 空间清理与源注入已闭环，物理空间已就绪。"
