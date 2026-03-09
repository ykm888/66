# --- 物理修正：强制内核支持 GPT 分区表 (救砖关键) ---
echo "CONFIG_EFI_PARTITION=y" >> target/linux/mediatek/filogic/config-5.15
echo "CONFIG_PARTITION_ADVANCED=y" >> target/linux/mediatek/filogic/config-5.15
echo "CONFIG_MSDOS_PARTITION=y" >> target/linux/mediatek/filogic/config-5.15

# --- 物理修正：确保 eMMC 驱动非模块化 (防止 RootFS 找不到) ---
sed -i 's/CONFIG_MMC_MTK=m/CONFIG_MMC_MTK=y/g' target/linux/mediatek/filogic/config-5.15
