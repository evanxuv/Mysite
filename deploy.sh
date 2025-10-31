#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Docker Hub用户名
DOCKER_USERNAME="xtavion"
IMAGE_NAME="mysite"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   自动部署脚本 v1.0${NC}"
echo -e "${GREEN}========================================${NC}"

# 获取当前目录
DEPLOY_DIR=$(pwd)
echo -e "部署目录: ${DEPLOY_DIR}"

# 1. 拉取最新代码（配置文件）
if [ -d ".git" ]; then
    echo -e "${YELLOW}拉取最新配置文件...${NC}"
    git pull origin master
else
    echo -e "${YELLOW}提示: 非Git目录，跳过代码拉取${NC}"
fi

# 2. 拉取最新镜像
echo -e "${YELLOW}拉取最新Docker镜像...${NC}"
docker pull ${DOCKER_USERNAME}/${IMAGE_NAME}:latest

if [ $? -ne 0 ]; then
    echo -e "${RED}镜像拉取失败！${NC}"
    exit 1
fi

# 3. 停止旧容器
echo -e "${YELLOW}停止旧容器...${NC}"
docker-compose down

# 4. 启动新容器
echo -e "${YELLOW}启动新容器...${NC}"
export DOCKER_USERNAME=${DOCKER_USERNAME}
docker-compose up -d

# 5. 等待启动
echo -e "${YELLOW}等待服务启动...${NC}"
sleep 15

# 6. 检查服务状态
if docker ps | grep mysite-app | grep -q "Up"; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   部署成功！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "访问地址: http://085214.xyz"
    echo -e "查看日志: docker-compose logs -f app"
    
    # 清理旧镜像
    echo -e "${YELLOW}清理旧镜像...${NC}"
    docker image prune -f
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}   部署失败！${NC}"
    echo -e "${RED}========================================${NC}"
    echo -e "查看日志: docker-compose logs app"
    exit 1
fi

