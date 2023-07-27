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

print_info(){
    echo "#############################################################"
    echo "# add task "
    echo "#############################################################"
    echo
}

get_ip(){
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z "${IP}" ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z "${IP}" ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    [ ! -z "${IP}" ] && echo "${IP}" || echo
}

# Config shadowsocks
run(){
    print_info
    netinfo=`netstat -an | awk '/^tcp/ {++y[$NF]} END {for(w in y) print w, y[w]}'`
    local ip=$(get_ip)
    python report_data.py "$netinfo" "$ip"
}
# 执行入口方法
run
