#!/bin/bash
# 物理溯源诊断脚本 - 针对扁平化仓库结构优化

MODE=$1
cd openwrt

if [ "$MODE" == "inject" ]; then
    echo "--- 执行物理穿透注入 (目标：扁平化结构) ---"
    
    # 1. 溯源定位 ATF 核心
    # 逻辑：查找包含 platform.mk 的目录作为 ATF 根路径
    REAL_ATF=$(find build_dir/target-aarch64* -name "platform.mk" | sed 's/\/plat\/mediatek\/mt7981\/platform.mk//' | head -n 1)
    
    if [ -n "$REAL_ATF" ]; then
        echo "命中 ATF 物理根目录: $REAL_ATF"
        # 强制修正：1MB 偏移逻辑 + DDR4 硬件支持
        sed -i 's/MTK_FIP_BASE.*=.*/MTK_FIP_BASE = 0x100000/g' "$REAL_ATF/plat/mediatek/mt7981/platform.mk"
        echo "DRAM_USE_DDR4 := 1" >> "$REAL_ATF/plat/mediatek/mt7981/platform.mk"
        
        # 物理强灌零件 (c/h)
        cp -v ../main-repo/888/bl2_dev_spi_nor.c "$REAL_ATF/plat/mediatek/mt7981/bl2/"
        cp -v ../main-repo/888/platform_def.h "$REAL_ATF/plat/mediatek/mt7981/include/"
        
        # 针对扁平仓库可能存在的路径变体进行二次覆盖
        [ -d "$REAL_ATF/include/plat/mediatek/mt7981" ] && cp -v ../main-repo/888/platform_def.h "$REAL_ATF/include/plat/mediatek/mt7981/"
        
        touch "$REAL_ATF/.prepared"*
        echo "ATF 零件注入成功"
    else
        echo "物理报错：无法定位 ATF 源码核心，请检查 prepare 步骤日志"
        exit 1
    fi

    # 2. 溯源定位 U-Boot 核心
    # 逻辑：根据 configs 目录位置反推 U-Boot 根路径
    REAL_UBOOT=$(find build_dir/target-aarch64* -name "configs" -type d | grep "u-boot" | head -n 1 | sed 's/\/configs//')
    
    if [ -n "$REAL_UBOOT" ]; then
        echo "命中 U-Boot 物理根目录: $REAL_UBOOT"
        # 注入 U-Boot 分区配置及设备树
        cp -v ../main-repo/888/mt7981_sl3000_defconfig "$REAL_UBOOT/configs/"
        if [ -f "../main-repo/888/mt7981-sl3000.dts" ]; then
            mkdir -p "$REAL_UBOOT/arch/arm/dts/"
            cp -v ../main-repo/888/mt7981-sl3000.dts "$REAL_UBOOT/arch/arm/dts/"
            echo "U-Boot DTS 零件注入成功"
        fi
        touch "$REAL_UBOOT/.prepared"*
    fi
else
    echo "--- 执行物理清创 ---"
    rm -rf package/boot/arm-trusted-firmware-mediatek/patches
    rm -rf package/boot/uboot-mediatek/patches
fi
