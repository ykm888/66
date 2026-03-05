#!/bin/bash

# 1. 【物理锁定】：锁定架构与设备
printf "CONFIG_TARGET_mediatek=y\n" > .config
printf "CONFIG_TARGET_mediatek_filogic=y\n" >> .config
printf "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y\n" >> .config
sed -i 's/CONFIG_TARGET_x86=y/# CONFIG_TARGET_x86 is not set/' .config

# 2. 【物理清淤】：删除冲突源
rm -rf dl/u-boot-* 2>/dev/null || true
rm -f target/linux/mediatek/patches-6.6/999-2714-net-fix-eee-struct-for-mtk-eth-soc-and-net-dsa-due-to-eee-backport.patch

# 3. 【U-Boot 重定向】：原文照抄你的 U-Boot 逻辑
UBOOT_MK="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MK" ]; then
    sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g" "$UBOOT_MK"
    sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UBOOT_MK"
    sed -i "s|PKG_MIRROR_HASH:=.*|PKG_MIRROR_HASH:=skip|g" "$UBOOT_MK"
    sed -i "s/UBOOT_TARGETS :=.*/UBOOT_TARGETS := mt7981_sl_3000-emmc/g" "$UBOOT_MK"
    # 这里保留你之前的 printf 重建 Makefile 逻辑...
fi

# 4. 【生成手术刀】：创建一个独立的 Python 修复脚本
cat << 'EOF' > kernel_fix.py
import os

def atomic_fix():
    target_h = ""
    target_c = ""
    # 动态搜寻内核源码路径
    for root, dirs, files in os.walk('build_dir'):
        if 'mtk_eth_soc.h' in files and 'mediatek' in root:
            target_h = os.path.join(root, 'mtk_eth_soc.h')
            target_c = os.path.join(root, 'mtk_eth_soc.c')
            break
    
    if not target_h:
        print("❌ 未找到内核头文件")
        return

    # 注入缺失的宏定义
    with open(target_h, 'r') as f:
        lines = f.readlines()
    
    with open(target_h, 'w') as f:
        for line in lines:
            f.write(line)
            if '#define MTK_ETH_SOC_H' in line:
                f.write("\n/* SL3000 Atomic Fix */\n")
                f.write("#define HIT_BIND_FORCE_TO_CPU 0x0b\n")
                f.write("#define MTK_FE_START_RESET 0x01\n")
                f.write("#define MTK_FE_RESET_DONE 0x02\n")
                f.write("#define MTK_FE_RESET_NAT_DONE 0x03\n")
                f.write("#define MTK_WIFI_RESET_DONE 0x04\n")
                f.write("#define MTK_WIFI_CHIP_ONLINE 0x05\n")
                f.write("#define MTK_WIFI_CHIP_OFFLINE 0x06\n")

    # 修复 ethtool 结构体兼容性 (6.6 内核 API 变更)
    for p in [target_h, target_c]:
        with open(p, 'r') as f:
            content = f.read()
        with open(p, 'w') as f:
            f.write(content.replace('ethtool_eee', 'ethtool_keee'))
    print(f"✅ 物理手术已完成: {target_h}")

if __name__ == "__main__":
    atomic_fix()
EOF
