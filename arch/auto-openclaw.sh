#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🦞 开始部署 OpenClaw (Arch Linux + Qwen 0.5B)...${NC}"

# 检查是否以 root 运行（针对 Arch 用户常见错误提示）
if [ "$EUID" -eq 0 ]; then 
  echo -e "${RED}请不要直接使用 root 用户运行此脚本，请使用普通用户运行。${NC}"
  exit 1
fi

# 检查 sudo 是否存在
if ! command -v sudo &> /dev/null; then
    echo -e "${RED}错误: 未找到 sudo 命令。${NC}"
    echo -e "${YELLOW}请先切换到 root 用户 (su -) 并安装 sudo (pacman -S sudo)，然后重新运行此脚本。${NC}"
    exit 1
fi

# 1. 系统更新与基础依赖安装
echo -e "${YELLOW}[1/6] 更新系统并安装基础依赖...${NC}"
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm nodejs npm git curl

# 2. 配置 NPM 中国镜像源
echo -e "${YELLOW}[2/6] 配置 NPM 淘宝镜像源...${NC}"
npm config set registry https://registry.npmmirror.com

# 3. 安装 OpenClaw 中国社区版
echo -e "${YELLOW}[3/6] 安装 OpenClaw 中国社区版...${NC}"
sudo npm install -g openclaw-cn@latest

if command -v openclaw &> /dev/null; then
    echo -e "${GREEN}✅ OpenClaw 安装成功！${NC}"
else
    echo -e "${RED}❌ OpenClaw 安装失败。${NC}"
    exit 1
fi

# 4. 安装 Ollama
echo -e "${YELLOW}[4/6] 安装 Ollama...${NC}"
curl -fsSL https://ollama.com/install.sh | sh

# 5. 配置 Ollama 并拉取最小模型 (Qwen 2.5 0.5B)
echo -e "${YELLOW}[5/6] 拉取 Qwen 2.5 最小模型 (0.5B)...${NC}"
# 0.5B 模型非常小，下载速度很快
ollama pull qwen2.5:0.5b

# 确保 Ollama 在后台运行
nohup ollama serve > /dev/null 2>&1 &
echo "Ollama 服务已启动。"

# 6. 初始化 OpenClaw 配置
echo -e "${YELLOW}[6/6] 配置 OpenClaw 连接 Qwen 0.5B...${NC}"

mkdir -p ~/.openclaw

# 写入配置文件
cat > ~/.openclaw/openclaw.json <<EOF
{
  "models": {
    "providers": {
      "ollama": {
        "baseUrl": "http://localhost:11434/v1",
        "apiKey": "ollama",
        "api": "openai-completions",
        "models": [
          {
            "id": "qwen2.5:0.5b",
            "name": "Qwen 2.5 0.5B (Tiny)"
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollama/qwen2.5:0.5b"
      }
    }
  }
}
EOF

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}🎉 安装全部完成！${NC}"
echo -e "${GREEN}当前模型: Qwen 2.5 0.5B (最小/极速)${NC}"
echo -e "${GREEN}=========================================${NC}"
echo -e "启动方式："
echo -e "1. 终端模式: ${GREEN}openclaw tui${NC}"
echo -e "2. 网页模式: ${GREEN}openclaw dashboard${NC}"
