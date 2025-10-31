# Docker部署指南

## 📋 目录
1. [环境准备](#1-环境准备)
2. [本地测试部署](#2-本地测试部署)
3. [服务器部署](#3-服务器部署)
4. [常用命令](#4-常用命令)
5. [生产环境优化](#5-生产环境优化)
6. [故障排查](#6-故障排查)
7. [后续迭代更新](#7-后续迭代更新)

---

## 1. 环境准备

### 1.1 安装Docker和Docker Compose

#### Windows系统
1. 下载安装 **Docker Desktop for Windows**
   - 官网：https://www.docker.com/products/docker-desktop
   - 安装后重启电脑
   - 验证安装：
   ```bash
   docker --version
   docker-compose --version
   ```

#### Linux服务器 (Ubuntu/Debian)
```bash
# 卸载旧版本
sudo apt-get remove docker docker-engine docker.io containerd runc

# 安装依赖
sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 添加Docker官方GPG密钥
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 添加Docker仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装Docker Engine
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 启动Docker
sudo systemctl start docker
sudo systemctl enable docker

# 验证安装
sudo docker --version
sudo docker compose version

# 添加当前用户到docker组（避免每次sudo）
sudo usermod -aG docker $USER
newgrp docker
```

#### Linux服务器 (CentOS/RHEL)
```bash
# 卸载旧版本
sudo yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

# 安装依赖
sudo yum install -y yum-utils

# 添加Docker仓库
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 安装Docker
sudo yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 启动Docker
sudo systemctl start docker
sudo systemctl enable docker

# 验证安装
docker --version
docker compose version
```

### 1.2 配置Docker镜像加速（中国大陆用户推荐）

#### Ubuntu/Debian
```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker
```

---

## 2. 本地测试部署

### 2.1 准备项目文件

确保项目根目录有以下文件：
```
my-site/
├── Dockerfile              # ✓ 已创建
├── docker-compose.yml      # ✓ 已创建
├── .dockerignore          # ✓ 已创建
├── nginx.conf             # ✓ 已创建
├── init.sql               # ✓ 已创建
├── pom.xml
└── src/
```

### 2.2 修改配置文件

#### 更新 `src/main/resources/application-prod.yml`:
```yaml
server:
  port: 8080

spring:
  datasource:
    # 使用docker-compose中的mysql服务名
    url: jdbc:mysql://mysql:3306/my_site?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai
    username: mysite
    password: mysite123456
    driver-class-name: com.mysql.cj.jdbc.Driver
    
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: false
    
# 日志配置
logging:
  level:
    root: INFO
    com.site: DEBUG
  file:
    path: /app/logs
    name: /app/logs/app.log
```

### 2.3 本地启动测试

```bash
# 进入项目目录
cd D:\IdeaProject\my-site

# 构建并启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 或者只查看应用日志
docker-compose logs -f app
```

### 2.4 访问应用

- **应用地址**：http://localhost:8080
- **Nginx代理地址**：http://localhost:80
- **MySQL端口**：localhost:3306

### 2.5 停止服务

```bash
# 停止所有服务
docker-compose down

# 停止并删除数据卷（慎用！会删除数据库数据）
docker-compose down -v
```

---

## 3. 服务器部署

### 3.1 准备服务器

#### 3.1.1 上传项目到服务器

**方案A：使用Git（推荐）**
```bash
# 在服务器上
cd /home
git clone https://github.com/你的用户名/my-site.git
cd my-site
```

**方案B：使用scp上传**
```bash
# 在本地电脑上（Windows PowerShell）
scp -r D:\IdeaProject\my-site root@你的服务器IP:/home/

# 在服务器上
cd /home/my-site
```

#### 3.1.2 修改配置

编辑 `docker-compose.yml`，根据需要修改：
- 数据库密码
- 端口映射
- 域名配置

编辑 `nginx.conf`，修改 `server_name`：
```nginx
server {
    listen 80;
    server_name 你的域名.com;  # 修改这里
    ...
}
```

### 3.2 启动服务

```bash
# 进入项目目录
cd /home/my-site

# 首次启动（构建镜像）
docker-compose up -d --build

# 查看启动日志
docker-compose logs -f

# 检查服务状态
docker-compose ps
```

### 3.3 配置防火墙

```bash
# Ubuntu (UFW)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# CentOS (firewalld)
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
```

### 3.4 配置域名（可选）

#### 3.4.1 DNS解析
在域名管理后台添加A记录：
```
类型: A
主机记录: @ 或 www
记录值: 你的服务器IP
```

#### 3.4.2 配置SSL证书（HTTPS）

创建 `docker-compose-ssl.yml`:
```yaml
version: '3.8'

services:
  # ... 其他服务保持不变 ...

  nginx:
    image: nginx:alpine
    container_name: mysite-nginx
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx-ssl.conf:/etc/nginx/conf.d/default.conf:ro
      - ./ssl:/etc/nginx/ssl:ro  # SSL证书目录
      - nginx-logs:/var/log/nginx
    depends_on:
      - app
    networks:
      - mysite-network
```

创建 `nginx-ssl.conf`:
```nginx
# HTTP -> HTTPS重定向
server {
    listen 80;
    server_name 你的域名.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS
server {
    listen 443 ssl http2;
    server_name 你的域名.com;

    # SSL证书
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    
    # SSL配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # 其他配置同nginx.conf
    client_max_body_size 50M;
    
    location / {
        proxy_pass http://app:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

使用Let's Encrypt获取免费SSL证书：
```bash
# 安装certbot
sudo apt install certbot -y

# 获取证书
sudo certbot certonly --standalone -d 你的域名.com

# 证书会保存在 /etc/letsencrypt/live/你的域名.com/
# 复制到项目目录
mkdir -p ssl
sudo cp /etc/letsencrypt/live/你的域名.com/fullchain.pem ssl/
sudo cp /etc/letsencrypt/live/你的域名.com/privkey.pem ssl/

# 重启nginx
docker-compose restart nginx
```

---

## 4. 常用命令

### 4.1 Docker Compose命令

```bash
# 启动服务（后台运行）
docker-compose up -d

# 启动服务（前台运行，可看日志）
docker-compose up

# 停止服务
docker-compose stop

# 停止并删除容器
docker-compose down

# 重启服务
docker-compose restart

# 重启特定服务
docker-compose restart app

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs
docker-compose logs -f          # 实时查看
docker-compose logs -f app      # 只看app服务
docker-compose logs --tail=100  # 查看最后100行

# 重新构建镜像
docker-compose build
docker-compose build --no-cache  # 不使用缓存

# 重新构建并启动
docker-compose up -d --build
```

### 4.2 Docker命令

```bash
# 查看容器
docker ps                    # 运行中的容器
docker ps -a                 # 所有容器

# 查看镜像
docker images

# 进入容器
docker exec -it mysite-app sh
docker exec -it mysite-mysql bash

# 查看容器日志
docker logs mysite-app
docker logs -f mysite-app    # 实时查看

# 停止容器
docker stop mysite-app

# 删除容器
docker rm mysite-app

# 删除镜像
docker rmi 镜像ID

# 查看容器资源使用
docker stats

# 清理无用数据
docker system prune -a       # 清理所有未使用的容器、镜像、网络
docker volume prune          # 清理未使用的数据卷
```

### 4.3 数据库操作

```bash
# 进入MySQL容器
docker exec -it mysite-mysql mysql -u mysite -p

# 备份数据库
docker exec mysite-mysql mysqldump -u mysite -pmysite123456 my_site > backup.sql

# 恢复数据库
docker exec -i mysite-mysql mysql -u mysite -pmysite123456 my_site < backup.sql

# 从容器外部连接MySQL
mysql -h 服务器IP -P 3306 -u mysite -p
```

---

## 5. 生产环境优化

### 5.1 使用生产环境配置

创建 `docker-compose.prod.yml`:
```yaml
version: '3.8'

services:
  mysql:
    image: mysql:5.7
    container_name: mysite-mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}  # 使用环境变量
      MYSQL_DATABASE: my_site
      MYSQL_USER: mysite
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      TZ: Asia/Shanghai
    ports:
      - "127.0.0.1:3306:3306"  # 只监听本地，更安全
    volumes:
      - mysql-data:/var/lib/mysql
      - ./mysql-conf:/etc/mysql/conf.d:ro  # 自定义MySQL配置
    command: 
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_unicode_ci
      - --default-time-zone=+08:00
      - --max_connections=500  # 增加连接数
      - --innodb_buffer_pool_size=512M  # 优化内存
    networks:
      - mysite-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: mysite-app
    restart: always
    ports:
      - "127.0.0.1:8080:8080"  # 只监听本地
    environment:
      SPRING_PROFILES_ACTIVE: prod
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/my_site?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai
      SPRING_DATASOURCE_USERNAME: mysite
      SPRING_DATASOURCE_PASSWORD: ${MYSQL_PASSWORD}
      JAVA_OPTS: "-Xms1g -Xmx2g -XX:+UseG1GC"  # 生产环境JVM参数
      TZ: Asia/Shanghai
    volumes:
      - app-logs:/app/logs
    depends_on:
      mysql:
        condition: service_healthy
    networks:
      - mysite-network
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G

  nginx:
    image: nginx:alpine
    container_name: mysite-nginx
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx-ssl.conf:/etc/nginx/conf.d/default.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
      - nginx-logs:/var/log/nginx
    depends_on:
      - app
    networks:
      - mysite-network
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M

volumes:
  mysql-data:
    driver: local
  app-logs:
    driver: local
  nginx-logs:
    driver: local

networks:
  mysite-network:
    driver: bridge
```

创建 `.env` 文件（不要提交到Git）:
```bash
MYSQL_ROOT_PASSWORD=强密码123456
MYSQL_PASSWORD=强密码654321
```

使用生产配置启动：
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### 5.2 自动备份脚本

创建 `backup.sh`:
```bash
#!/bin/bash

BACKUP_DIR=/home/my-site/backups
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份数据库
echo "开始备份数据库..."
docker exec mysite-mysql mysqldump -u mysite -pmysite123456 --all-databases > $BACKUP_DIR/db_$DATE.sql

# 压缩备份
gzip $BACKUP_DIR/db_$DATE.sql

# 备份应用日志
echo "备份应用日志..."
tar -czf $BACKUP_DIR/logs_$DATE.tar.gz -C /var/lib/docker/volumes/my-site_app-logs/_data .

# 删除30天前的备份
find $BACKUP_DIR -name "*.sql.gz" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "备份完成！"
```

设置定时任务：
```bash
chmod +x backup.sh

# 添加到crontab
crontab -e
# 每天凌晨3点执行备份
0 3 * * * /home/my-site/backup.sh >> /home/my-site/backup.log 2>&1
```

### 5.3 监控和日志

#### 安装Portainer（Docker可视化管理）
```bash
docker volume create portainer_data

docker run -d \
  -p 9000:9000 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
```

访问：http://服务器IP:9000

#### 日志管理
```bash
# 限制Docker日志大小（在/etc/docker/daemon.json中）
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}

# 重启Docker
sudo systemctl restart docker
```

---

## 6. 故障排查

### 6.1 常见问题

#### 问题1：容器启动失败
```bash
# 查看容器日志
docker-compose logs app

# 查看容器详细信息
docker inspect mysite-app

# 进入容器排查
docker exec -it mysite-app sh
```

#### 问题2：无法连接数据库
```bash
# 检查MySQL容器是否运行
docker ps | grep mysql

# 查看MySQL日志
docker logs mysite-mysql

# 测试数据库连接
docker exec -it mysite-mysql mysql -u mysite -p

# 检查网络连接
docker network inspect my-site_mysite-network
```

#### 问题3：端口被占用
```bash
# 查看端口占用
netstat -tlnp | grep 8080
lsof -i :8080

# 修改docker-compose.yml中的端口映射
ports:
  - "8081:8080"  # 改为8081
```

#### 问题4：磁盘空间不足
```bash
# 查看磁盘使用
df -h

# 清理Docker数据
docker system prune -a
docker volume prune

# 查看Docker占用空间
docker system df
```

### 6.2 调试技巧

```bash
# 查看容器资源使用
docker stats

# 查看容器进程
docker top mysite-app

# 导出容器文件系统
docker export mysite-app > app.tar

# 查看容器启动命令
docker inspect mysite-app | grep Cmd

# 实时查看日志并过滤
docker logs -f mysite-app | grep ERROR
```

---

## 7. 后续迭代更新

### 7.1 代码更新流程

```bash
# 方式1：在服务器上拉取代码
cd /home/my-site
git pull origin master
docker-compose down
docker-compose up -d --build

# 方式2：本地构建镜像推送
# 本地构建
docker build -t 你的用户名/mysite:latest .
docker push 你的用户名/mysite:latest

# 服务器上拉取
docker pull 你的用户名/mysite:latest
docker-compose up -d
```

### 7.2 零停机更新

创建 `update.sh`:
```bash
#!/bin/bash

echo "开始更新..."

# 拉取最新代码
git pull origin master

# 构建新镜像
docker-compose build app

# 创建新容器（不停止旧容器）
docker-compose up -d --no-deps --build app

# 等待新容器启动
sleep 10

# 检查新容器健康状态
if docker ps | grep mysite-app | grep "Up"; then
    echo "新容器启动成功，清理旧容器"
    docker-compose down --remove-orphans
    docker-compose up -d
    echo "更新完成！"
else
    echo "新容器启动失败，回滚"
    docker-compose down
    exit 1
fi
```

### 7.3 回滚操作

```bash
# 查看镜像历史
docker images

# 使用旧镜像启动
docker-compose down
docker tag 旧镜像ID my-site:latest
docker-compose up -d

# 或者回滚代码
git log
git reset --hard 提交ID
docker-compose up -d --build
```

---

## 8. 快速参考

### 8.1 一键部署脚本

创建 `deploy.sh`:
```bash
#!/bin/bash

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}===== 开始部署 =====${NC}"

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker未安装，请先安装Docker${NC}"
    exit 1
fi

# 停止旧容器
echo "停止旧容器..."
docker-compose down

# 拉取最新代码（如果使用Git）
if [ -d ".git" ]; then
    echo "拉取最新代码..."
    git pull origin master
fi

# 构建并启动
echo "构建并启动容器..."
docker-compose up -d --build

# 等待启动
echo "等待服务启动..."
sleep 15

# 检查状态
echo "检查服务状态..."
docker-compose ps

# 查看日志
echo -e "${GREEN}部署完成！查看日志：${NC}"
echo "docker-compose logs -f"

echo -e "${GREEN}===== 部署成功 =====${NC}"
```

```bash
chmod +x deploy.sh
./deploy.sh
```

### 8.2 常用命令速查

```bash
# 快速启动
docker-compose up -d

# 快速重启
docker-compose restart

# 查看日志
docker-compose logs -f app

# 进入容器
docker exec -it mysite-app sh

# 清理重建
docker-compose down -v && docker-compose up -d --build

# 备份数据库
docker exec mysite-mysql mysqldump -u mysite -p my_site > backup.sql

# 恢复数据库
docker exec -i mysite-mysql mysql -u mysite -p my_site < backup.sql
```

---

## 🎉 完成！

现在您的项目已经可以通过Docker部署了！

**优势**：
- ✅ 环境一致性（开发、测试、生产环境完全一致）
- ✅ 快速部署（一键启动所有服务）
- ✅ 易于扩展（可以轻松添加Redis、Elasticsearch等服务）
- ✅ 资源隔离（各服务独立运行，互不影响）
- ✅ 易于迁移（可以快速在任何支持Docker的服务器上部署）

**下一步**：
1. 提交Dockerfile和docker-compose.yml到Git
2. 在服务器上安装Docker
3. 克隆代码并运行 `docker-compose up -d`
4. 访问您的网站！

如有问题，请查看日志：`docker-compose logs -f`

