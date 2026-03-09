#!/bin/bash
# 物理操作：添加第三方插件源

# 1. 添加 helloworld (SSR-plus) - 保持你参考案例的逻辑
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default

# 2. 如果你需要常用的 PassWall (可选，去掉前面的 # 即可生效)
# echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default

# 3. 如果你需要更多的常用插件包 (建议添加，物理补全常用组件)
echo 'src-git packages_custom https://github.com/kenzok8/openwrt-packages' >>feeds.conf.default
