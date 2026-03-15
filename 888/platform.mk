# ... (保留你之前的代码)

# --- 【物理加固：逻辑注册与 DDR4 参数对齐】 ---
$(call GEN_DEP_RULES,bl2,bl2_dev_spi_nor emicfg dram_log bl2_boot_ram bl2_boot_nand_nmbm bl2_dev_mmc bl2_plat_init bl2_plat_setup mt7981_gpio dtb)

# 物理像素级传递 DDR4 宏定义到编译器
$(call MAKE_DEP,bl2,bl2_dev_spi_nor,BOOT_DEVICE DRAM_USE_DDR4 MTK_FIP_BASE) # 👈 物理修正：增加 MTK_FIP_BASE 传递
$(call MAKE_DEP,bl2,emicfg,DRAM_USE_DDR4 DRAM_SIZE_LIMIT BOARD_QFN BOARD_BGA)
$(call MAKE_DEP,bl2,dram_log,DRAM_DEBUG_LOG)
$(call MAKE_DEP,bl2,bl2_plat_init,BL2_COMPRESS)
$(call MAKE_DEP,bl2,bl2_plat_setup,BOOT_DEVICE TRUSTED_BOARD_BOOT DUAL_FIP)
$(call MAKE_DEP,bl2,bl2_dev_mmc,BOOT_DEVICE)
$(call MAKE_DEP,bl2,bl2_boot_ram,RAM_BOOT_DEBUGGER_HOOK RAM_BOOT_UART_DL)
$(call MAKE_DEP,bl2,bl2_boot_nand_nmbm,NMBM_MAX_RATIO NMBM_MAX_RESERVED_BLOCKS NMBM_DEFAULT_LOG_LEVEL)
$(call MAKE_DEP,bl2,mt7981_gpio,ENABLE_JTAG)
$(call MAKE_DEP,bl2,dtb,BOOT_DEVICE)

# --- 【物理加固：1MB 偏移终极死锁】 ---
# 这一行决定了 BL2 编译出的 bin 文件内部寻址指针
MTK_FIP_BASE := 0x100000
DEFINES      += -DMTK_FIP_BASE=$(MTK_FIP_BASE)

$(call GEN_DEP_RULES,bl31,bl31_plat_setup)
$(call MAKE_DEP,bl31,bl31_plat_setup,ANTI_ROLLBACK TRUSTED_BOARD_BOOT)
