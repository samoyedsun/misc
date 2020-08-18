# -*- coding: utf-8 -*-
import logging, json, time
from sys import argv

from aliyunsdkcore.client import AcsClient
from aliyunsdkcore.acs_exception.exceptions import ClientException
from aliyunsdkcore.acs_exception.exceptions import ServerException
from aliyunsdkecs.request.v20140526.RunInstancesRequest import RunInstancesRequest
from aliyunsdkecs.request.v20140526.DeleteInstanceRequest import DeleteInstanceRequest
from aliyunsdkecs.request.v20140526.DescribeInstancesRequest import DescribeInstancesRequest

ACCESS_KEY_ID = "*************"
ACCESS_SECRET = "**************************"
REGION_ID = "cn-hongkong"

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

def handler(event, context):
  logger = logging.getLogger()
  
  user_data = "IyEvYmluL2Jhc2gKIyDnjq/looM6IGFsaXl1biBlY3MKIyDns7vnu586IHVidW50dSAxOC4wNAojZWNobyAic2xlZXAgMzAwIGJlZ2luLiIKI3NsZWVwIDMwMAojZWNobyAic2xlZXAgMzAwIGVuZC4iCiMg5pu05pawYXB06L2v5Lu25YyF57Si5byVCmFwdCB1cGRhdGUgLXkKIyDmm7TmlrBhcHTova/ku7bljIUKYXB0IGxpc3QgLS11cGdyYWRhYmxlCiMg5a6J6KOFZG9ja2Vy5pyN5YqhCmFwdCBpbnN0YWxsIGRvY2tlci5pbyAteQojIOWQr+WKqGRvY2tlcuacjeWKoQpzeXN0ZW1jdGwgc3RhcnQgZG9ja2VyCiMg6K6+572u5byA5py66Ieq5ZCv5YqoCnN5c3RlbWN0bCBlbmFibGUgZG9ja2VyCiMg5ZCv5Yqo5Luj55CG5a655ZmoCmRvY2tlciBydW4gLWl0IC1kIC1wIDEzMDAzOjEzMDAzIC0tbmFtZSBzc3Byb3h5IHNhbW95ZWRzdW4vc3Nwcm94eQ=="
  launch(user_data)

  return "success!"