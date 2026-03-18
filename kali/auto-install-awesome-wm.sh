#!/bin/bash
#
# auto-install-awesome.sh
# 在 Kali Linux 中自动安装 AwesomeWM，不影响原有环境
# 使用方法：普通用户运行，需要 sudo 权限

set -e  # 遇到错误立即退出

# 颜色输出函数
info()  { echo -e "\033[32m[信息]\033[0m $1"; }
warn()  { echo -e "\033[33m[警告]\033[0m $1"; }
error() { echo -e "\033[31m[错误]\033[0m $1"; exit 1; }

# 检查 sudo 权限
info "检查 sudo 权限..."
sudo -v || error "当前用户需要拥有 sudo 权限才能继续。"

# 更新包列表并安装 Awesome 及相关组件
info "安装 AwesomeWM 及推荐工具（终端、启动器、壁纸、合成器）..."
sudo apt update
sudo apt install -y awesome           # 窗口管理器
sudo apt install -y xterm             # 默认终端（Awesome 常用）
sudo apt install -y rofi              # 应用程序启动器（可替代 dmenu）
sudo apt install -y feh               # 壁纸设置工具
sudo apt install -y picom             # 合成器（用于透明/阴影效果）
sudo apt install -y lxappearance      # 主题设置工具（可选）

# 创建用户配置目录
AWESOME_CONFIG="$HOME/.config/awesome"
if [ ! -d "$AWESOME_CONFIG" ]; then
    info "创建 Awesome 用户配置目录..."
    mkdir -p "$AWESOME_CONFIG"
fi

# 复制系统默认配置文件到用户目录（如果不存在）
if [ ! -f "$AWESOME_CONFIG/rc.lua" ]; then
    info "复制默认 rc.lua 配置到用户目录..."
    if [ -f /etc/xdg/awesome/rc.lua ]; then
        cp /etc/xdg/awesome/rc.lua "$AWESOME_CONFIG/"
        info "已复制默认配置，你可以编辑 ~/.config/awesome/rc.lua 进行个性化设置。"
    else
        warn "未找到系统默认 rc.lua，跳过配置复制。"
    fi
else
    info "用户配置文件已存在，跳过复制。"
fi

# 为显示管理器（如 LightDM）创建 Awesome 会话文件
XSESSIONS_DIR="/usr/share/xsessions"
DESKTOP_FILE="$XSESSIONS_DIR/awesome.desktop"

info "创建 Awesome 会话文件供显示管理器使用..."
sudo tee "$DESKTOP_FILE" > /dev/null <<EOF
[Desktop Entry]
Encoding=UTF-8
Name=Awesome
Comment=Highly configurable window manager
Exec=awesome
Icon=awesome
Type=XSession
EOF

# 完成提示
info "安装完成！"
echo "=================================================="
echo "已安装组件："
echo "  - AwesomeWM 窗口管理器"
echo "  - xterm 终端"
echo "  - rofi 启动器"
echo "  - feh 壁纸设置"
echo "  - picom 合成器"
echo "  - lxappearance 主题工具"
echo ""
echo "使用方法："
echo "  1. 注销当前会话，在登录界面（如 LightDM）选择 'Awesome' 会话。"
echo "  2. 或通过命令行输入 'startx /usr/bin/awesome' 启动（需确保 ~/.xinitrc 配置正确）。"
echo ""
echo "AwesomeWM 默认快捷键（Mod 键 = Super / Windows 键）："
echo "  Mod + Enter         : 打开终端（xterm）"
echo "  Mod + r             : 运行命令（rofi）"
echo "  Mod + #（1-9）       : 切换到工作区 #"
echo "  Mod + Shift + #     : 将当前窗口移动到工作区 #"
echo "  Mod + j/k           : 聚焦下一个/上一个窗口"
echo "  Mod + Space         : 循环切换布局"
echo "  Mod + Shift + c     : 关闭当前窗口"
echo "  Mod + Shift + q     : 退出 Awesome"
echo "  Mod + Left/Right    : 切换到相邻工作区"
echo "  Mod + Ctrl + r      : 重新加载 Awesome 配置"
echo "更多快捷键请参考官方文档或编辑 ~/.config/awesome/rc.lua"
echo "=================================================="
