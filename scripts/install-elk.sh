#!/bin/bash

# ==============================
# ELK安装脚本（带日志和进度输出）
# 日志文件：/var/log/elk-install.log
# 运行用户：elk（自定义专用用户）
# ==============================

# 重定向所有输出到日志文件（stdout和stderr）
exec > /var/log/elk-install.log 2>&1

echo "========================================"
echo "开始安装ELK集群（版本：${elk_version}）"
echo "安装时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"

# ------------------------------
# 步骤1：创建elk用户组和用户
# ------------------------------
echo -e "\n[步骤1/6] 创建elk用户组和用户..."
if ! grep -q "^elk:" /etc/group; then
  sudo groupadd elk
  echo "✅ 已创建elk用户组"
else
  echo "ℹ️ elk用户组已存在，跳过创建"
fi

if ! id -u elk >/dev/null 2>&1; then
  # -m：创建家目录，-s：指定shell，-g：关联用户组
  sudo useradd -m -s /bin/bash -g elk elk
  # （可选）设置elk用户密码（如需登录可启用）
  # echo "elk:your-password" | sudo chpasswd
  echo "✅ 已创建elk用户（家目录：/home/elk）"
else
  echo "ℹ️ elk用户已存在，跳过创建"
fi

# ------------------------------
# 步骤2：安装依赖（Java）
# ------------------------------
echo -e "\n[步骤2/6] 安装Java环境..."
sudo apt update -y
sudo apt install -y openjdk-11-jdk

# 验证Java安装
if java -version &>/dev/null; then
  echo "✅ Java安装成功（版本：$(java -version 2>&1 | head -n1 | awk -F '"' '{print $2}')）"
else
  echo "❌ Java安装失败！"
  exit 1
fi

# ------------------------------
# 步骤3：配置ELK软件源
# ------------------------------
echo -e "\n[步骤3/6] 配置ELK软件源..."
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elastic.gpg
echo "deb [signed-by=/usr/share/keyrings/elastic.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
sudo apt update -y

echo "✅ ELK软件源配置完成"

# ------------------------------
# 步骤4：安装并配置Elasticsearch
# ------------------------------
echo -e "\n[步骤4/6] 安装Elasticsearch（版本：${elk_version}）..."
sudo apt install -y elasticsearch=${elk_version}

# 配置Elasticsearch（单节点+允许外部访问）
echo "ℹ️ 配置Elasticsearch..."
sudo sed -i 's/#discovery.type: single-node/discovery.type: single-node/' /etc/elasticsearch/elasticsearch.yml
sudo sed -i 's/#network.host: 192.168.0.1/network.host: 0.0.0.0/' /etc/elasticsearch/elasticsearch.yml

# 修改Elasticsearch目录权限（归elk用户所有）
sudo chown -R elk:elk /etc/elasticsearch
sudo chown -R elk:elk /var/lib/elasticsearch
sudo chown -R elk:elk /var/log/elasticsearch

# 修改systemd服务文件，以elk用户运行
sudo sed -i 's/User=elasticsearch/User=elk/' /usr/lib/systemd/system/elasticsearch.service
sudo sed -i 's/Group=elasticsearch/Group=elk/' /usr/lib/systemd/system/elasticsearch.service

# 启动Elasticsearch并设置开机自启
sudo systemctl daemon-reload
sudo systemctl enable --now elasticsearch

# 验证Elasticsearch状态
if sudo systemctl is-active --quiet elasticsearch; then
  echo "✅ Elasticsearch启动成功（运行用户：elk）"
else
  echo "❌ Elasticsearch启动失败！查看日志：sudo journalctl -u elasticsearch"
fi

# ------------------------------
# 步骤5：安装并配置Kibana
# ------------------------------
echo -e "\n[步骤5/6] 安装Kibana（版本：${elk_version}）..."
sudo apt install -y kibana=${elk_version}

# 配置Kibana允许外部访问
echo "ℹ️ 配置Kibana..."
sudo sed -i 's/#server.host: "localhost"/server.host: "0.0.0.0"/' /etc/kibana/kibana.yml

# 修改Kibana目录权限（归elk用户所有）
sudo chown -R elk:elk /etc/kibana
sudo chown -R elk:elk /var/lib/kibana
sudo chown -R elk:elk /var/log/kibana

# 修改systemd服务文件，以elk用户运行
sudo sed -i 's/User=kibana/User=elk/' /usr/lib/systemd/system/kibana.service
sudo sed -i 's/Group=kibana/Group=elk/' /usr/lib/systemd/system/kibana.service

# 启动Kibana并设置开机自启
sudo systemctl daemon-reload
sudo systemctl enable --now kibana

# 验证Kibana状态
if sudo systemctl is-active --quiet kibana; then
  echo "✅ Kibana启动成功（运行用户：elk）"
else
  echo "❌ Kibana启动失败！查看日志：sudo journalctl -u kibana"
fi

# ------------------------------
# 步骤6：安装并配置Logstash
# ------------------------------
echo -e "\n[步骤6/6] 安装Logstash（版本：${elk_version}）..."
sudo apt install -y logstash=${elk_version}

# 修改Logstash目录权限（归elk用户所有）
sudo chown -R elk:elk /etc/logstash
sudo chown -R elk:elk /var/lib/logstash
sudo chown -R elk:elk /var/log/logstash

# 修改systemd服务文件，以elk用户运行
sudo sed -i 's/User=logstash/User=elk/' /usr/lib/systemd/system/logstash.service
sudo sed -i 's/Group=logstash/Group=elk/' /usr/lib/systemd/system/logstash.service

# 启动Logstash并设置开机自启
sudo systemctl daemon-reload
sudo systemctl enable --now logstash

# 验证Logstash状态
if sudo systemctl is-active --quiet logstash; then
  echo "✅ Logstash启动成功（运行用户：elk）"
else
  echo "❌ Logstash启动失败！查看日志：sudo journalctl -u logstash"
fi

# ------------------------------
# 安装完成总结
# ------------------------------
echo -e "\n========================================"
echo "ELK集群安装完成！"
echo "安装时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo "组件状态："
echo "- Elasticsearch：$(sudo systemctl is-active elasticsearch | awk '{print $1=="active"?"✅ 运行中":"❌ 未运行"}')"
echo "- Kibana：$(sudo systemctl is-active kibana | awk '{print $1=="active"?"✅ 运行中":"❌ 未运行"}')"
echo "- Logstash：$(sudo systemctl is-active logstash | awk '{print $1=="active"?"✅ 运行中":"❌ 未运行"}')"
echo "运行用户：elk（所有组件统一权限）"
echo "安装日志：/var/log/elk-install.log"
echo "========================================"