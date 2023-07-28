#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===================================================================#
#   System Required:  CentOS 6 or 7                                 #
#   Description: Install Shadowsocks-libev server for CentOS 6 or 7 #
#   Author: Teddysun <i@teddysun.com>                               #
#   Thanks: @madeye <https://github.com/madeye>                     #
#   Intro:  https://teddysun.com/357.html                           #
#===================================================================#

# Color
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Current folder
cur_dir=$(pwd)
openvpnport=8102
# Make sure only root can run our script
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] This script must be run as root!" && exit 1


get_ip(){
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z "${IP}" ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z "${IP}" ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    [ ! -z "${IP}" ] && echo "${IP}" || echo
}

check_installed(){
    if [ "$(command -v "$1")" ]; then
        return 0
    else
        return 1
    fi
}

print_info(){
    clear
    echo "#############################################################"
    echo "# Install openvpn server for CentOS 7        #"
    echo "#############################################################"
    echo
}

# Get version
getversion(){
    if [[ -s /etc/redhat-release ]]; then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}


# CentOS version
centosversion(){
    if check_sys sysRelease centos; then
        local code=$1
        local version="$(getversion)"
        local main_ver=${version%%.*}
        if [ "$main_ver" == "$code" ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Check system
check_sys(){
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''

    if [[ -f /etc/redhat-release ]]; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /etc/issue; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /etc/issue; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
        release="centos"
        systemPackage="yum"
    elif grep -Eqi "debian|raspbian" /proc/version; then
        release="debian"
        systemPackage="apt"
    elif grep -Eqi "ubuntu" /proc/version; then
        release="ubuntu"
        systemPackage="apt"
    elif grep -Eqi "centos|red hat|redhat" /proc/version; then
        release="centos"
        systemPackage="yum"
    fi

    if [[ "${checkType}" == "sysRelease" ]]; then
        if [ "${value}" == "${release}" ]; then
            return 0
        else
            return 1
        fi
    elif [[ "${checkType}" == "packageManager" ]]; then
        if [ "${value}" == "${systemPackage}" ]; then
            return 0
        else
            return 1
        fi
    fi
}

# Pre-installation settings
pre_install(){
    groupadd nogroup;
    yum install -y -q epel-release vim unzip wget unzip
    echo 'net.ipv4.ip_forward = 1'>> /etc/sysctl.conf
    sysctl -p
}

# Config shadowsocks
config_openvpn(){
    rm -rf /etc/openvpn/
    unzip -o openvpn
    local ip=$(get_ip)
    sed -i "s/104.225.153.30/${ip}/g" openvpn/vpn-server.conf
    sed -i "s/8102/${openvpnport}/g" openvpn/vpn-server.conf

}

# Firewall set
firewall_set(){
    echo -e "[${green}Info${plain}] firewall set start..."
    if centosversion 6; then
        /etc/init.d/iptables status > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            iptables -L -n | grep -i "${openvpnport}" > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport "${openvpnport}" -j ACCEPT
                iptables -I INPUT -m state --state NEW -m udp -p udp --dport "${openvpnport}" -j ACCEPT
                iptables -I FORWARD -j ACCEPT
                /etc/init.d/iptables save
                /etc/init.d/iptables restart
            else
                echo -e "[${green}Info${plain}] port ${openvpnport} has been set up."
            fi
        else
            echo -e "[${yellow}Warning${plain}] iptables looks like shutdown or not installed, please manually set it if necessary."
        fi
    elif centosversion 7; then
        iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
        iptables -I FORWARD -j ACCEPT
        systemctl status firewalld > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            default_zone=$(firewall-cmd --get-default-zone)
            firewall-cmd --permanent --zone="${default_zone}" --add-port="${openvpnport}"/tcp
            firewall-cmd --permanent --zone="${default_zone}" --add-port="${openvpnport}"/udp
            firewall-cmd --reload
        else
            echo -e "[${yellow}Warning${plain}] firewalld looks like not running or not installed, please enable port ${openvpnport} manually if necessary."
        fi
    fi
    echo -e "[${green}Info${plain}] firewall set completed..."
}


download_files(){
    cd /etc
    rm -rf openvpn.zip
    wget https://d21z6ifg4bbv2v.cloudfront.net/files/openvpn.zip
}

install_openvpn(){
    yum install -y -q openvpn
}

run_openvpn(){
    systemctl restart openvpn@vpn-server
    netstat -anp|grep openvpn
}

# Install Shadowsocks-libev
install_openvpn_main(){
    pre_install
    download_files
    config_openvpn
    firewall_set
    install_openvpn
    run_openvpn
}

# Initialization step
action=$1
[ -z "$1" ] && action=install
case "$action" in
    install)
        install_openvpn_main
        ;;
    *)
        echo "Arguments error! [${action}]"
        echo "Usage: $(basename "$0") [install]"
        ;;
esac
