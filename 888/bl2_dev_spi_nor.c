#include <assert.h>
#include <common/debug.h>
#include <drivers/io/io_driver.h>
#include <drivers/io/io_fip.h>
#include <drivers/io/io_memmap.h>
#include <drivers/io/io_storage.h>
#include <plat/mediatek/common/mtk_plat_common.h>

/* * 物理执行准则：强制定义 FIP 偏移为 1MB (0x100000)
 * 这是救砖全家桶的核心地图坐标
 */
#ifndef FIP_OFFSET
#define FIP_OFFSET 0x100000
#endif

#ifndef FIP_SIZE
#define FIP_SIZE 0x200000
#endif

static const io_block_spec_t fip_spec = {
	.offset = FIP_OFFSET,
	.length = FIP_SIZE
};

static const io_uuid_spec_t bl31_uuid_spec = {
	.uuid = {0x47, 0xd4, 0x08, 0x6d, 0x4c, 0xfe, 0xe4, 0x11, 0x9b, 0x7b, 0x00, 0x02, 0xa5, 0xd5, 0xc5, 0x1b}
};

static const io_uuid_spec_t uboot_uuid_spec = {
	.uuid = {0x5c, 0x63, 0xf8, 0x5b, 0xef, 0x6d, 0x8a, 0x45, 0xad, 0xbb, 0xa1, 0x8f, 0xcb, 0x55, 0xca, 0x19}
};

/* 硬件初始化逻辑：物理对齐 SPI-NOR 驱动 */
void mtk_io_setup(void)
{
	int io_result;

	NOTICE("SL-3000: Physical Injection - Setting FIP Offset to 0x%lx\n", (unsigned long)FIP_OFFSET);

	io_result = register_io_dev_fip(&fip_dev_con);
	assert(io_result == 0);

	io_result = io_dev_open(fip_dev_con, (uintptr_t)&fip_spec, &fip_dev_handle);
	assert(io_result == 0);

	(void)io_result;
}
