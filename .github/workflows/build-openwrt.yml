name: SL3000 Final Build - 2410 Branch

on:
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - name: 检出脚本仓库 (Main)
        uses: actions/checkout@v4
        with:
          path: main-repo

      - name: 检出底层 2410 分支源 (Source)
        uses: actions/checkout@v4
        with:
          repository: ykm99999/66
          ref: 2410  # 物理锁定 2410 分支
          path: source-repo

      - name: 安装物理编译依赖
        run: |
          sudo apt update
          sudo apt install -y build-essential clang flex bison gawk \
            gettext git libncurses-dev libssl-dev \
            python3-distutils python3-setuptools rsync unzip zlib1g-dev file wget \
            gcc-aarch64-linux-gnu device-tree-compiler

      - name: 执行物理构建脚本
        run: |
          # 物理提权并运行大脑脚本
          chmod +x main-repo/diy-part1.sh
          ./main-repo/diy-part1.sh

      - name: 上传救砖三件套产物
        uses: actions/upload-artifact@v4
        with:
          name: SL3000-2410-Artifacts
          path: main-repo/output/
