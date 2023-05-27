#!/bin/bash

# 清理iptables规则
iptables -F
iptables -X

# 设置默认策略
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# 允许回环接口的流量
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# 允许已建立的、相关的进出流量
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# 开放80端口
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# 开放443端口
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 开放22端口
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# 查找已有的UDP规则
existing_udp_rules=$(iptables -S INPUT | grep -E '^.* -p udp .*ACCEPT')

# 添加UDP规则，如果不存在相同的规则
iptables -C INPUT -p udp -j ACCEPT 2>/dev/null || iptables -A INPUT -p udp -j ACCEPT

# 删除与已有UDP规则不同的规则
for rule in $existing_udp_rules; do
  iptables -D INPUT $rule
done

# 删除端口全开和端口全关规则
iptables -D INPUT -j ACCEPT
iptables -D INPUT -j DROP

# 剔除重复规则
iptables-save | awk '!x[$0]++' | iptables-restore

# 输出清理结果
echo "iptables规则已清理并更新："
iptables -L

# 保存规则
iptables-save > /etc/iptables/rules.v4

sudo netfilter-persistent save
sudo netfilter-persistent reload