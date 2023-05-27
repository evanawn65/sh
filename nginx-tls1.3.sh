
#!/bin/bash

# 更新系统软件包
sudo apt update

# 检查Python版本
python_version=$(python3 -c "import sys; print('{}.{}'.format(sys.version_info.major, sys.version_info.minor))")
required_python_version="3.7"

if [[ $(printf "%s\n" "$required_python_version" "$python_version" | sort -V | head -n1) != "$required_python_version" ]]; then
    echo "当前Python版本为$python_version，需要更新至$required_python_version或以上版本。"
    echo "正在安装最新版本的Python..."
    sudo apt install python3.9 -y
    echo "Python已成功安装！"
else
    echo "当前Python版本已满足要求。"
fi

# 安装NGINX
sudo apt install nginx -y

# 检查是否已安装Python Certbot工具
if ! command -v certbot &> /dev/null; then
    sudo apt install certbot python3-certbot-nginx -y
fi

# 用户输入域名和邮箱
read -p "请输入域名: " domain_name
read -p "请输入邮箱: " email

# 选择证书申请方式
echo "请选择证书申请方式："
echo "1. 默认向Let's Encrypt等CA申请证书"
echo "2. 使用已有证书（客户提供）"
read -p "请输入选项（1或2）: " cert_option

if [ "$cert_option" == "2" ]; then
    read -p "请输入已有证书的公钥文件路径: " cert_public_key_path
    read -p "请输入已有证书的私钥文件路径: " cert_private_key_path

    if [ ! -f "$cert_public_key_path" ] || [ ! -f "$cert_private_key_path" ]; then
        echo "Error: 无效的证书公钥或私钥文件路径。将使用选项1默认申请证书。"
        cert_option="1"
    else
        sudo cp "$cert_public_key_path" /etc/nginx/ssl/$domain_name.crt
        sudo cp "$cert_private_key_path" /etc/nginx/ssl/$domain_name.key
        echo "使用已有证书完成。"
    fi
fi

if [ "$cert_option" == "1" ]; then
    # 申请证书（使用certbot）
    sudo certbot --nginx --non-interactive --agree-tos --redirect --hsts --staple-ocsp --email $email -d $domain_name
    echo "证书签发机构：Let's Encrypt"
fi

# 获取证书有效期信息并显示
cert_expiry=$(sudo openssl x509 -noout -dates -in /etc/letsencrypt/live/$domain_name/fullchain.pem | grep "notAfter" | cut -d "=" -f 2)
echo "SSL证书已签发，有效期至: $cert_expiry"

# 创建404页面
sudo bash -c 'cat << EOF > /var/www/html/404.html
<!DOCTYPE html>
<html>
<head>
    <title>404 Not Found</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            padding: 40px;
        }
        h1 {
            font-size: 24px;
            margin-bottom: 10px;
        }
        p {
            font-size: 16px;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <h1>404 Not Found</h1>
    <p>Sorry, the page you requested was not found.</p>
</body>
</html>
EOF'

# 修改NGINX配置文件
sudo bash -c 'cat << EOF > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    server_name _;

    ssl_certificate /etc/nginx/ssl/$domain_name.crt;
    ssl_certificate_key /etc/nginx/ssl/$domain_name.key;

    # 只接受TLS 1.3及以上版本的SSL协议
    ssl_protocols TLSv1.3;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    error_page 404 /404.html;
    location = /404.html {
        internal;
    }

    location / {
        try_files \$uri \$uri/ =404;
    }

    location /1080 {
        proxy_pass http://localhost:1080;
        proxy_set_header Host \$host;
    }
}
EOF'

# 修改NGINX全局配置文件
sudo sed -i 's/# server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf

# 创建SSL证书目录
sudo mkdir /etc/nginx/ssl

# 启用并启动NGINX服务
sudo systemctl enable nginx
sudo systemctl restart nginx
