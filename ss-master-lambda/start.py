#!/usr/bin/env python
#coding=utf-8

from sys import argv
import json, time

from aliyunsdkcore.client import AcsClient
from aliyunsdkcore.acs_exception.exceptions import ClientException
from aliyunsdkcore.acs_exception.exceptions import ServerException
from aliyunsdkecs.request.v20140526.RunInstancesRequest import RunInstancesRequest
from aliyunsdkecs.request.v20140526.DeleteInstanceRequest import DeleteInstanceRequest
from aliyunsdkecs.request.v20140526.DescribeInstancesRequest import DescribeInstancesRequest

from config import ACCESS_KEY_ID
from config import ACCESS_SECRET
from config import REGION_ID

client = AcsClient(ACCESS_KEY_ID, ACCESS_SECRET, REGION_ID)

def create(user_data):
    request = RunInstancesRequest()
    request.set_accept_format('json')

    request.set_ImageId("ubuntu_18_04_64_20G_alibase_20190624.vhd")
    request.set_InstanceType("ecs.t5-lc2m1.nano")
    request.set_SecurityGroupId("sg-j6c0z0xdiqgujaby8hu4")
    request.set_VSwitchId("vsw-j6cpqku7fl7zjcej0fj1b")
    request.set_InstanceName("ss-slave")
    request.set_Description("ss-slave")
    request.set_InternetMaxBandwidthOut(100)
    request.set_HostName("ss-slave")
    request.set_UniqueSuffix(True)
    request.set_InternetChargeType("PayByTraffic")
    request.set_UserData(user_data)
    request.set_KeyPairName("ss-slave")
    request.set_Amount(1)

    response = client.do_action_with_exception(request)
    res = json.loads(response)
    return res["InstanceIdSets"]["InstanceIdSet"]

def delete(instance_id):
    request = DeleteInstanceRequest()
    request.set_accept_format("json")

    request.set_InstanceId(instance_id)
    request.set_Force(True)

    response = client.do_action_with_exception(request)
    return json.loads(response)

def describe(instance_id_list):
    request = DescribeInstancesRequest()
    request.set_accept_format("json")

    response = client.do_action_with_exception(request)    
    res = json.loads(response)
    instance = res["Instances"]["Instance"]
    return instance

def launch(user_data):
    instance_id_list = create(user_data)
    print("create instance_id_list:{}".format(str(instance_id_list)))
    wait_time = 300
    expend_time = 0
    for index in range(wait_time):
        time.sleep(1)
        expend_time = expend_time + 1
        print("还需等待:{}s".format(wait_time - expend_time))
    instance = describe(instance_id_list)
    for itc in instance:
        description = itc["Description"]
        if description == "ss-slave":
            instance_id = itc["InstanceId"]
            flag = False
            for itc_id in instance_id_list:
                if itc_id == instance_id:
                    flag = True
            if not flag:
                res = delete(instance_id)
                print("delete instance_id:{}, res:{}".format(instance_id, str(res)))

process = {}

def init():
    process['create'] = create
    process['delete'] = delete
    process['describe'] = describe
    process['launch'] = launch

def main():
    if len(argv) <= 2:
        print("参数太少了!")
        return 1

    command = argv[1]
    commands = process.keys()
    if command not in commands:
        print("命令不存在!")
        return 1

    param = argv[2]
    ret = process[command](param)
    print(ret)
    return 0

if __name__ == '__main__':
    init()
    main() 
