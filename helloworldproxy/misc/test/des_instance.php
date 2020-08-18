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
                          ->action('DescribeInstanceAttribute')
                          ->method('POST')
                          ->options([
                                        'query' => [
                                          'RegionId' => 'cn-hongkong',
                                          'InstanceId' => 'i-j6c8eum1gl346wfk1lax',
                                        ],
                                    ])
                          ->request();
    print_r($result->toArray());
    var_dump($result->toArray()['PublicIpAddress']['IpAddress'][0]);
} catch (ClientException $e) {
    echo $e->getErrorMessage() . PHP_EOL;
} catch (ServerException $e) {
    echo $e->getErrorMessage() . PHP_EOL;
}
