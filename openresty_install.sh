

# 第一个参数为 OpenResty 的版本号
VERSION=1.21.4.2
OPENRESTY_FILE="openresty-${VERSION}.tar.gz"
OPENRESTY_URL="https://openresty.org/download/${OPENRESTY_FILE}"
INSTALL_DIR="/data/openresty"
 
 
# 检查 OpenResty 文件是否存在
if [ ! -f "$OPENRESTY_FILE" ]; then
  echo "正在下载 ${OPENRESTY_URL}..."
  wget "$OPENRESTY_URL"
 
 
  # 检查下载是否成功
  if [ "$?" -ne 0 ]; then
    echo "下载 ${OPENRESTY_URL} 失败"
    exit 1
  fi
fi
 
# 安装依赖
yum install -y gcc make pcre-devel openssl-devel

 
# 解压并编译安装 OpenResty
tar -xzvf "$OPENRESTY_FILE"
cd "openresty-$VERSION"
./configure --prefix="$INSTALL_DIR"
make
make install
 
 
# 检查安装是否成功
if [ "$?" -ne 0 ]; then
  echo "OpenResty $VERSION 安装失败"
  exit 1
fi
 
 
# 添加 OpenResty 到环境变量
echo 'export PATH=$PATH:'"$INSTALL_DIR/bin"'/' >> /etc/profile
source /etc/profile
 
 
# 创建 OpenResty 服务文件
echo "正在创建 OpenResty 服务文件..."
cat <<EOF > /etc/systemd/system/openresty.service
[Unit]
Description=OpenResty HTTP Server
After=network.target
[Service]
Type=forking
PIDFile=/run/openresty.pid
ExecStart=$INSTALL_DIR/nginx/sbin/nginx -c $INSTALL_DIR/nginx/conf/nginx.conf
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF
 
 
# 启动 OpenResty 服务
systemctl daemon-reload
systemctl enable openresty
systemctl start openresty
 
if [ "$?" -ne 0 ]; then
  echo "OpenResty $VERSION 启动失败"
  exit 1
fi
echo "OpenResty $VERSION 启动完成"