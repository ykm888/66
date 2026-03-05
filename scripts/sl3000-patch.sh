#!/bin/bash

# 1. 【物理锁定】：锁定架构与设备，压制 x86 干扰
printf "CONFIG_TARGET_mediatek=y\n" > .config
printf "CONFIG_TARGET_mediatek_filogic=y\n" >> .config
printf "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y\n" >> .config
sed -i 's/CONFIG_TARGET_x86=y/# CONFIG_TARGET_x86 is not set/' .config

# 2. 【物理清淤】：删除导致编译崩溃的冲突源
rm -rf dl/u-boot-* 2>/dev/null || true
rm -f target/linux/mediatek/patches-6.6/999-2714-net-fix-eee-struct-for-mtk-eth-soc-and-net-dsa-due-to-eee-backport.patch

# 3. 【原文照抄】：U-Boot 重定向逻辑（延续成功版本）
UBOOT_MK="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MK" ]; then
    sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g" "$UBOOT_MK"
    sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UBOOT_MK"
    sed -i "s|PKG_MIRROR_HASH:=.*|PKG_MIRROR_HASH:=skip|g" "$UBOOT_MK"
    sed -i "s/UBOOT_TARGETS :=.*/UBOOT_TARGETS := mt7981_sl_3000-emmc/g" "$UBOOT_MK"
    # (此处省略你之前的 Makefile printf 重建逻辑，请保持原文)
fi

# 4. 【物理注入准备】：生成内核手术脚本（解决 undeclared 错误）
# 我们直接在本地生成一个 python 脚本，等 prepare 完后再执行
cat << 'PYTHON_EOF' > kernel_fix.py
import os, sys
def atomic_fix():
    # 动态寻址驱动源码
    h_path = ""
    for root, dirs, files in os.walk('build_dir'):
        if 'mtk_eth_soc.h' in files and 'mediatek' in root:
            h_path = os.path.join(root, 'mtk_eth_soc.h')
            c_path = os.path.join(root, 'mtk_eth_soc.c')
            break
    if not h_path: return
    
    # 注入宏定义
    with open(h_path, 'r') as f: lines = f.readlines()
    with open(h_path, 'w') as f:
        for line in lines:
            f.write(line)
            if '#define MTK_ETH_SOC_H' in line and 'SL3000' not in line:
                f.write("\n#define HIT_BIND_FORCE_TO_CPU 0x0b\n#define MTK_FE_START_RESET 0x01\n#define MTK_FE_RESET_DONE 0x02\n#define MTK_FE_RESET_NAT_DONE 0x03\n#define MTK_WIFI_RESET_DONE 0x04\n#define MTK_WIFI_CHIP_ONLINE 0x05\n#define MTK_WIFI_CHIP_OFFLINE 0x06\n")
    
    # 修复结构体名
    for p in [h_path, c_path]:
        with open(p, 'r') as f: content = f.read()
        with open(p, 'w') as f: f.write(content.replace('ethtool_eee', 'ethtool_keee'))
    print(f"✅ 物理手术完成：{h_path}")

if __name__ == "__main__":
    atomic_fix()
PYTHON_EOF
