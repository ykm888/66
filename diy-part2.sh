#!/bin/bash
# 物理操作：修改默认配置

# 1. 修改默认后台 IP (建议改成你习惯的，比如 192.168.1.1)
sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate

# 2. 修改主机名为 SL3000 (让设备看起来更专业)
sed -i 's/OpenWrt/SL3000-Router/g' package/base-files/files/bin/config_generate

# 3. 物理修正：某些情况下 eMMC 引导需要调整分区挂载逻辑 (可选，针对 23.05)
# sed -i 's/rootfs_data/userdata/g' target/linux/mediatek/image/filogic.mk

# 4. 修改默认主题为 Argon (如果你的 config 里选了这个主题)
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
