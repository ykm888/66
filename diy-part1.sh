#!/bin/bash
# 物理源头修复：在索引生成前切断循环依赖链条
sed -i 's/+wpad-mesh-openssl//g' package/feeds/luci/luci-app-easymesh/Makefile 2>/dev/null || true
sed -i 's/+wpa-supplicant-mesh-openssl//g' package/feeds/luci/luci-app-easymesh/Makefile 2>/dev/null || true

# 注入插件源
# echo 'src-git ...' >> feeds.conf.default
