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
                          ->action('DeleteInstance')
                          ->method('POST')
                          ->options([
                                        'query' => [
                                          'RegionId' => 'cn-hongkong',
                                          'Force' => 'true',
                                          'InstanceId' => 'asdf',
                                        ],
                                    ])
                          ->request();
    print_r($result->toArray());
} catch (ClientException $e) {
    echo $e->getErrorMessage() . PHP_EOL;
} catch (ServerException $e) {
    echo $e->getErrorMessage() . PHP_EOL;
}
