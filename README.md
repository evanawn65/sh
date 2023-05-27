[README.md]</br>
1.rules: 清理iptables规则，打开22、80以及443端口</br>
2.nginx-tls1.3: 配合其他后台程序的nginx一键安装脚本，nginx前置分流tls流量，指定流量由其他后台程序监听处理</br>
3.setup-ssh-root: 系统（vps）首次加载后，启用密码验证和root登录</br>
4.pip-install: 检查是否已安装pip,如未安装则自动安装pip。然后使用pip安装名为 "some-package" 的Python包</br>
Tips: 整合1和4可实现pandora、nginx的一键安装
