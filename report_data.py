#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import json
import urllib2

def main():
    data = parse()
    report(data)


def parse():
    str = ""
    if len(sys.argv) > 2:
        txt = sys.argv[1]
        server_ip = sys.argv[2]
        data = {}
        arr = txt.strip().split()
        for i in [x * 2 for x in range(len(arr)/2)]:
            data[arr[i]] = arr[i + 1]
        data['vps_ip'] = server_ip
        str = json.dumps(data)
        print("解析结果：{}".format(str))
    return str


def report(data):
    if data :
        headers = {'Content-Type': 'application/json'}
        url='http://192.168.7.160/ipc_moudle/sysUser/login/'
        req = urllib2.Request(url=url, data=data, headers=headers)
        res = urllib2.urlopen(req)
        res = res.read()
        print(res)

if __name__ == "__main__":
    main()








