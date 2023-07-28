#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===================================================================#
#   System Required:  CentOS 6 or 7                                 #
#   Description: Install for CentOS 6 or 7 #
#===================================================================#

# Color
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Current folder
cur_dir=$(pwd)
# Make sure only root can run our script
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] This script must be run as root!" && exit 1

download_software(){
    cd /root/
    mkdir data_collect
    cd data_collect
    echo "开始下载程序=========="
    wget --no-check-certificate -O collect_server_data.sh https://lijin110136.github.io/collect_server_data.sh
    wget --no-check-certificate -O data_handler.py https://lijin110136.github.io/data_handler.py
    echo "下载程序完成！！！！！！"
}

# Config shadowsocks
install_task(){

    # 动态删除crontab任务
    sed -i '/collect_server_data/d' /var/spool/cron/root

    # 动态添加crontab任务
    echo "*/1 * * * * cd /root/data_collect;sh collect_server_data.sh>>/tmp/data_collect.log" >> /var/spool/cron/root
    echo "添加crontab任务完成!"
}

run(){
    download_software
    install_task
}

# 执行入口方法
run
