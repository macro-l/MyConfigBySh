#!/bin/bash
#
# auto-install-suckless.sh
# 在 Kali Linux 中自动编译安装 st + dwm + dmenu，不影响原有环境
# 使用方法：普通用户运行，需要 sudo 权限

set -e  # 遇到错误立即退出

# 颜色输出函数
info()  { echo -e "\033[32m[信息]\033[0m $1"; }
warn()  { echo -e "\033[33m[警告]\033[0m $1"; }
error() { echo -e "\033[31m[错误]\033[0m $1"; exit 1; }

# 检查 sudo 权限
info "检查 sudo 权限..."
sudo -v || error "当前用户需要拥有 sudo 权限才能继续。"

# 检查是否为 Kali Linux（可选）
if ! grep -qi "kali" /etc/os-release 2>/dev/null; then
    warn "当前系统可能不是 Kali Linux，但脚本仍会尝试安装。"
fi

# 更新包列表并安装编译依赖
info "安装编译依赖（build-essential, libx11-dev, libxft-dev, libxinerama-dev, git）..."
sudo apt update
sudo apt install -y build-essential libx11-dev libxft-dev libxinerama-dev git

# 创建工作目录
WORK_DIR=$(mktemp -d)
cd "$WORK_DIR"
info "临时工作目录：$WORK_DIR"

# 克隆 suckless 仓库函数
clone_repo() {
    local repo=$1
    local name=$2
    info "克隆 $name 仓库..."
    if ! git clone --depth 1 "git://git.suckless.org/$repo"; then
        error "克隆 $name 失败，请检查网络连接。"
    fi
}

# 克隆仓库
clone_repo "st"    "st"
clone_repo "dwm"   "dwm"
clone_repo "dmenu" "dmenu"

# 编译安装函数
install_suckless() {
    local dir=$1
    cd "$dir"
    info "编译安装 $dir ..."
    # 如果需要自定义 config.h，可以在此处复制 config.def.h 并修改
    # 此处使用默认配置
    sudo make clean install
    cd ..
}

# 安装 st
install_suckless "st"
# 安装 dmenu
install_suckless "dmenu"
# 安装 dwm
install_suckless "dwm"

# 配置 ~/.xinitrc（用于 startx 启动 dwm）
XINITRC="$HOME/.xinitrc"
if [ -f "$XINITRC" ]; then
    warn "发现已有 $XINITRC，将备份为 $XINITRC.bak"
    cp "$XINITRC" "$XINITRC.bak"
fi

if grep -q "exec dwm" "$XINITRC" 2>/dev/null; then
    info "~/.xinitrc 已包含 dwm 启动命令，无需修改。"
else
    info "配置 ~/.xinitrc 以通过 startx 启动 dwm..."
    {
        echo "#!/bin/sh"
        echo "# 由 auto-install-suckless.sh 自动生成"
        echo "exec dwm"
    } > "$XINITRC"
    chmod +x "$XINITRC"
fi

# 为显示管理器（如 LightDM）创建 Dwm 会话文件
XSESSIONS_DIR="/usr/share/xsessions"
DESKTOP_FILE="$XSESSIONS_DIR/dwm.desktop"

if [ -f "$DESKTOP_FILE" ]; then
    warn "Dwm 会话文件已存在，将覆盖：$DESKTOP_FILE"
fi

info "创建 Dwm 会话文件供显示管理器使用..."
sudo tee "$DESKTOP_FILE" > /dev/null <<EOF
[Desktop Entry]
Encoding=UTF-8
Name=Dwm
Comment=Dynamic window manager
Exec=dwm
Icon=dwm
Type=XSession
EOF

# 清理临时目录
info "清理临时文件..."
cd /
rm -rf "$WORK_DIR"

info "安装完成！"
echo "=================================================="
echo "已安装组件：st, dwm, dmenu (均在 /usr/local/bin)"
echo "使用方法："
echo "  1. 通过 startx 启动：运行 'startx' 即可进入 dwm。"
echo "  2. 通过显示管理器（如 LightDM）：在登录界面选择 'Dwm' 会话。"
echo "  3. 终端模拟器为 st，可在 dwm 中通过 Mod+Shift+Enter 启动。"
echo "注意：Kali 原有桌面环境（如 Xfce）不受影响，仍可从显示管理器选择。"
echo "=================================================="
