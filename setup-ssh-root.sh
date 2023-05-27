#!/bin/bash

# 启用SSH密码验证
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

# 允许root登录
sudo sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# 重启SSH服务
sudo service ssh restart

# 设置root密码
echo "设置root密码："
sudo passwd root

echo "SSH密码验证和root登录已启用，并且root密码已设置。"