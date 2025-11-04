#!/bin/bash
set -euo pipefail

# >>> 1. 日志文件路径（只落盘，不回显）
LOG_FILE="/var/log/install-elk.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec > "$LOG_FILE" 2>&1

# >>> 2. 打时间戳
echo "======== $(date '+%F %T') install-elk.sh 开始执行 ========"

echo "==== Step 1: 更新系统包 ===="
apt-get update -y
echo "==== 系统包更新完成 ===="

echo "==== Step 2: 安装依赖 ===="
apt-get install -y openjdk-11-jdk wget curl
echo "==== 依赖安装完成 ===="

echo "==== Step 3: 配置root用户SSH免密登录 ===="
# 启用root SSH登录
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# 重启SSH服务
systemctl restart sshd
echo "==== root用户SSH免密登录配置完成 ===="

echo "==== Step 4: 创建ELK相关用户及免密sudo ===="
# 创建elk用户组
if ! grep -q "^elk:" /etc/group; then
  groupadd elk
  echo "==== elk用户组已创建 ===="
else
  echo "==== elk用户组已存在 ===="
fi

# 创建elk用户
if ! id "elk" &>/dev/null; then
  useradd -m -s /bin/bash -g elk elk
  # 配置免密sudo
  echo "elk ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
  echo "==== elk用户已创建并配置免密sudo ===="
else
  echo "==== elk用户已存在 ===="
fi

# 创建logstash用户
if ! id "logstash" &>/dev/null; then
  useradd -m -s /bin/bash -g elk logstash
  echo "logstash ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
  echo "==== logstash用户已创建并配置免密sudo ===="
else
  echo "==== logstash用户已存在 ===="
fi

# 创建kibana用户
if ! id "kibana" &>/dev/null; then
  useradd -m -s /bin/bash -g elk kibana
  echo "kibana ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
  echo "==== kibana用户已创建并配置免密sudo ===="
else
  echo "==== kibana用户已存在 ===="
fi

echo "==== Step 5: 配置ELK软件源 ===="
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elastic.gpg
echo "deb [signed-by=/usr/share/keyrings/elastic.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-8.x.list
apt-get update -y
echo "==== ELK软件源配置完成 ===="

echo "==== Step 6: 安装并配置Elasticsearch ===="
apt-get install -y elasticsearch=${elk_version}
# 配置单节点+外部访问
sed -i 's/#discovery.type: single-node/discovery.type: single-node/' /etc/elasticsearch/elasticsearch.yml
sed -i 's/#network.host: 192.168.0.1/network.host: 0.0.0.0/' /etc/elasticsearch/elasticsearch.yml
# 设置堆内存（4GB，机器内存的50%）
echo -e "\n-Xms4g\n-Xmx4g" | tee -a /etc/elasticsearch/jvm.options.d/custom.options
# 授权目录权限
chown -R elk:elk /etc/elasticsearch
chown -R elk:elk /var/lib/elasticsearch
chown -R elk:elk /var/log/elasticsearch
# 修改服务运行用户
sed -i 's/User=elasticsearch/User=elk/' /usr/lib/systemd/system/elasticsearch.service
sed -i 's/Group=elasticsearch/Group=elk/' /usr/lib/systemd/system/elasticsearch.service
# 启动服务
systemctl daemon-reload
systemctl enable --now elasticsearch
echo "==== Elasticsearch安装配置完成 ===="

echo "==== Step 7: 安装并配置Kibana ===="
apt-get install -y kibana=${elk_version}
# 配置外部访问
sed -i 's/#server.host: "localhost"/server.host: "0.0.0.0"/' /etc/kibana/kibana.yml
# 授权目录权限
chown -R kibana:elk /etc/kibana
chown -R kibana:elk /var/lib/kibana
chown -R kibana:elk /var/log/kibana
# 修改服务运行用户
sed -i 's/User=kibana/User=kibana/' /usr/lib/systemd/system/kibana.service
sed -i 's/Group=kibana/Group=elk/' /usr/lib/systemd/system/kibana.service
# 启动服务
systemctl daemon-reload
systemctl enable --now kibana
echo "==== Kibana安装配置完成 ===="

echo "==== Step 8: 安装并配置Logstash ===="
apt-get install -y logstash=${elk_version}
# 授权目录权限
chown -R logstash:elk /etc/logstash
chown -R logstash:elk /var/lib/logstash
chown -R logstash:elk /var/log/logstash
# 修改服务运行用户
sed -i 's/User=logstash/User=logstash/' /usr/lib/systemd/system/logstash.service
sed -i 's/Group=logstash/Group=elk/' /usr/lib/systemd/system/logstash.service
# 启动服务
systemctl daemon-reload
systemctl enable --now logstash
echo "==== Logstash安装配置完成 ===="

echo "==== Step 9: 验证服务状态 ===="
echo "==== Elasticsearch状态 ===="
systemctl status elasticsearch --no-pager || true
echo "==== Kibana状态 ===="
systemctl status kibana --no-pager || true
echo "==== Logstash状态 ===="
systemctl status logstash --no-pager || true

echo "==== ELK单节点集群安装完成 ===="
echo "======== $(date '+%F %T') install-elk.sh 执行结束 ========"