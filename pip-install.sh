#!/bin/bash

# 检查是否已安装pip
if ! command -v pip &> /dev/null; then
    echo "未找到pip。正在安装pip..."
    sudo apt install python3-pip -y
    echo "pip已成功安装！"
else
    echo "pip已安装。"
fi

# 使用pip安装某个包（示例：some-package）
echo "正在使用pip安装some-package..."
pip install some-package
echo "some-package已成功安装！"
