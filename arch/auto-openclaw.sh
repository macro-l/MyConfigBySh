#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🦞 开始部署 OpenClaw (Arch Linux 中国源优化版)...${NC}"

# 1. 系统更新与基础依赖安装
echo -e "${YELLOW}[1/6] 更新系统并安装基础依赖 (Node.js, Git)...${NC}"
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm nodejs npm git curl

# 2. 配置 NPM 中国镜像源
echo -e "${YELLOW}[2/6] 配置 NPM 淘宝镜像源...${NC}"
npm config set registry https://registry.npmmirror.com
echo "NPM 源已切换至淘宝镜像。"

# 3. 安装 OpenClaw 中国社区版
echo -e "${YELLOW}[3/6] 安装 OpenClaw 中国社区版 (openclaw-cn)...${NC}"
# 使用 sudo 确保全局安装权限
sudo npm install -g openclaw-cn@latest

# 验证安装
if command -v openclaw &> /dev/null; then
    echo -e "${GREEN}✅ OpenClaw 安装成功！${NC}"
    openclaw --version
else
    echo -e "${RED}❌ OpenClaw 安装失败，请检查 NPM 权限。${NC}"
    exit 1
fi

# 4. 安装 Ollama (本地模型后端)
echo -e "${YELLOW}[4/6] 安装 Ollama 并配置国内镜像...${NC}"
# 设置 Ollama 国内镜像变量 (加速模型下载)
export OLLAMA_ORIGINS=https://ollama.com
# 一键安装 Ollama
curl -fsSL https://ollama.com/install.sh | sh

# 5. 配置 Ollama 服务
echo -e "${YELLOW}[5/6] 拉取推荐模型 (qwen2.5:7b) 并启动服务...${NC}"
# 推荐使用通义千问 qwen2.5 或 gpt-oss，这里以 qwen2.5:7b 为例，国内连接更稳
# 如果需要更小的模型，可以改为 qwen2.5:0.5b
ollama pull qwen2.5:7b

# 确保 Ollama 在后台运行
nohup ollama serve > /dev/null 2>&1 &
echo "Ollama 服务已启动。"

# 6. 初始化 OpenClaw 配置
echo -e "${YELLOW}[6/6] 初始化 OpenClaw 并连接 Ollama...${NC}"

# 创建配置目录
mkdir -p ~/.openclaw

# 生成默认配置文件 (如果不存在)
if [ ! -f ~/.openclaw/openclaw.json ]; then
    # 这里直接写入配置，避免交互式问答，默认连接本地 Ollama
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
            "id": "qwen2.5:7b",
            "name": "Qwen 2.5 7B"
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollama/qwen2.5:7b"
      }
    }
  }
}
EOF
    echo -e "${GREEN}✅ 配置文件已自动生成。${NC}"
else
    echo -e "${YELLOW}⚠️ 配置文件已存在，跳过生成。${NC}"
fi

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}🎉 安装全部完成！${NC}"
echo -e "${GREEN}=========================================${NC}"
echo -e "启动方式："
echo -e "1. 终端模式: ${GREEN}openclaw tui${NC}"
echo -e "2. 网页模式: ${GREEN}openclaw dashboard${NC}"
echo -e "注意: 如果遇到连接问题，请确保 Ollama 正在运行 (ollama serve)"

