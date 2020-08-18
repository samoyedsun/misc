<?php

require __DIR__ . '/vendor/autoload.php'; 

use AlibabaCloud\Client\AlibabaCloud;
use AlibabaCloud\Client\Exception\ClientException;
use AlibabaCloud\Client\Exception\ServerException;

// Download：https://github.com/aliyun/openapi-sdk-php-client
// Usage：https://github.com/aliyun/openapi-sdk-php-client/blob/master/README-CN.md

AlibabaCloud::accessKeyClient('LTAIvfaR1D3tFVjd', 'YN2AHJgJFzabEGkKeV4o7O73WXB2xM')
                        ->regionId('cn-hongkong')
                        ->asGlobalClient();

try {
    $result = AlibabaCloud::rpcRequest()
                          ->product('Ecs')
                          // ->scheme('https') // https | http
                          ->version('2014-05-26')
                          ->action('RunInstances')
                          ->method('POST')
                          ->options([
                                        'query' => [
                                          'RegionId' => 'cn-hongkong',
                                          'InternetMaxBandwidthOut' => '100',
                                          'ImageId' => 'ubuntu_18_04_64_20G_alibase_20190223.vhd',
                                          'InstanceType' => 'ecs.t5-lc2m1.nano',
                                          'SecurityGroupId' => 'sg-j6c0lvzs6c7blh3m9xtx',
                                          'InstanceName' => 'hwp',
                                          'Description' => 'helloworldproxy',
                                          'HostName' => 'hwphost',
                                          'KeyPairName' => 'aliyunhongkong',
                                          'SecurityEnhancementStrategy' => 'Deactive',
                                          'VSwitchId' => 'vsw-j6cwlvux4l88a782kq2vq',
                                          'UserData' => 'IyEvYmluL3NoCndnZXQgLU8gL3Jvb3QvYm9vdHN0cmFwLnNoIGh0dHBzOi8vcmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbS9zYW1veWVkc3VuL2Jhc2gvbWFzdGVyL3NyYy9ib290c3RyYXAtYWxpeXVuLWh3cC5zaApzaCAvcm9vdC9ib290c3RyYXAuc2g=',
                                        ],
                                    ])
                          ->request();
    print_r($result->toArray());
    $instanceId = $result->toArray()['InstanceIdSets']['InstanceIdSet'][0];
    var_dump($instanceId);
} catch (ClientException $e) {
    echo $e->getErrorMessage() . PHP_EOL;
} catch (ServerException $e) {
    echo $e->getErrorMessage() . PHP_EOL;
}