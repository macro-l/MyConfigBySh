#!/bin/bash
# Kali Linux 中文输入法安装脚本 (Fcitx + 谷歌拼音)
# 使用方法: chmod +x install_fcitx_googlepinyin.sh && ./install_fcitx_googlepinyin.sh

set -e  # 遇到错误立即退出

# 检查是否为root用户，如果不是则使用sudo
if [ "$EUID" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

echo "===== 开始安装 Fcitx + 谷歌拼音输入法 ====="

# 1. 更新软件包列表
echo ">>> 更新软件源..."
$SUDO apt update

# 2. 安装必要的软件包
echo ">>> 安装 fcitx, 谷歌拼音 和 配置工具..."
$SUDO apt install -y fcitx fcitx-googlepinyin fcitx-config-gtk

# 3. 配置环境变量 (写入 ~/.bashrc)
BASHRC="$HOME/.xprofile"
echo ">>> 配置环境变量到 $BASHRC"

# 定义需要添加的变量行
LINE1="export GTK_IM_MODULE=fcitx"
LINE2="export QT_IM_MODULE=fcitx"
LINE3="export XMODIFIERS=@im=fcitx"

# 检查是否已存在，避免重复添加
for line in "$LINE1" "$LINE2" "$LINE3"; do
    if ! grep -qF "$line" "$BASHRC"; then
        echo "$line" >> "$BASHRC"
        echo "已添加: $line"
    else
        echo "已存在: $line"
    fi
done

# 4. 提示用户后续操作
echo ""
echo "===== 安装完成 ====="
echo "请执行以下操作以启用输入法："
echo "1. 重启系统 或 执行 'source ~/.bashrc' 使环境变量生效"
echo "2. 如果 fcitx 未自动启动，可以运行 'fcitx-autostart' 启动"
echo "3. 右键点击右上角键盘图标 → Configure → 点击 + 号"
echo "   取消勾选 'Only Show Current Language'，添加 Google Pinyin"
echo "4. 使用 Ctrl + 空格 切换输入法"
echo ""
echo "如果遇到问题，可以运行 'fcitx-diagnose' 查看诊断信息。"
