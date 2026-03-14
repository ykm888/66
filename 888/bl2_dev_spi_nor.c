/*
 * Copyright (c) 2023, MediaTek Inc. All rights reserved.
 * 司络 SL-3000 硬件加固版：锁定 1MB 偏移与 2MB 载入空间
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <stddef.h>
#include <stdint.h>
#include <boot_spi.h>
#include <mtk_spi.h>

/* 物理核心：坐标锁定 1MB。必须与 filogic.mk 中的 seek=1024 严格对齐 */
#define FIP_BASE			0x100000

/* 物理核心：载入空间预留 2MB。防止 U-Boot 镜像体积过大导致读取截断 */
#define FIP_SIZE			0x200000

/* 物理核心：MT7981 默认 MPLL 分频时钟 */
#define MTK_QSPI_SRC_CLK		CB_MPLL_D2

/**
 * mtk_plat_qspi_init: 初始化物理链路
 * 负责打通 CPU 到 SPI-NOR 闪存的引脚通路
 */
int mtk_plat_qspi_init(void)
{
	/* 物理引脚对齐：初始化 SPI 硬件接口引脚复用 */
	mtk_spi_gpio_init(SPIM2);

	/* 物理时钟锁定：选择 208M 高速时钟确保启动效率 */
	mtk_spi_source_clock_select(MTK_QSPI_SRC_CLK);

	return mtk_qspi_init(MTK_QSPI_SRC_CLK);
}

/**
 * mtk_plat_fip_location: 定义地图坐标
 * 告知 BL2 逻辑 U-Boot (FIP) 存放在 Flash 的具体位置
 */
void mtk_plat_fip_location(size_t *fip_off, size_t *fip_size)
{
	*fip_off = FIP_BASE;
	*fip_size = FIP_SIZE;
}
