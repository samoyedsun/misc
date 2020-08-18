<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use AlibabaCloud\Client\AlibabaCloud;
use AlibabaCloud\Client\Exception\ClientException;
use AlibabaCloud\Client\Exception\ServerException;

class UsersController extends Controller
{
    public function create()
    {
        AlibabaCloud::accessKeyClient('LTAIvfaR1D3tFVjd', 'YN2AHJgJFzabEGkKeV4o7O73WXB2xM')
                                ->regionId('cn-hongkong')
                                ->asGlobalClient();
        try {
            $result = AlibabaCloud::rpcRequest()
                                    ->product('Ecs')
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
        } catch (ClientException $e) {
            echo $e->getErrorMessage() . PHP_EOL;
        } catch (ServerException $e) {
            echo $e->getErrorMessage() . PHP_EOL;
        }
        
        if (!isset($result))
            return view('users.confirm')->with('result', 'Return failed, try again later or contact the administrator.');
        if (!isset($result->toArray()['InstanceIdSets']))
            return view('users.confirm')->with('result', 'Return failed, try again later or contact the administrator.');
        if (!isset($result->toArray()['InstanceIdSets']['InstanceIdSet']))
            return view('users.confirm')->with('result', 'Return failed, try again later or contact the administrator.');
        if (!isset($result->toArray()['InstanceIdSets']['InstanceIdSet'][0]))
            return view('users.confirm')->with('result', 'Return failed, try again later or contact the administrator.');

        $instanceId = $result->toArray()['InstanceIdSets']['InstanceIdSet'][0];
        return view('users.create')->with('instanceId',$instanceId);
    }

    public function details(Request $request)
    {
        $instanceId = $request->input('instance_id');

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
                                    'InstanceId' => $instanceId,
                                    ],
                                ])
                    ->request();
        } catch (ClientException $e) {
            echo $e->getErrorMessage() . PHP_EOL;
        } catch (ServerException $e) {
            echo $e->getErrorMessage() . PHP_EOL;
        }


        if (!isset($result))
            return view('users.confirm')->with('result', 'Return failed, try again later or contact the administrator.');
        if (!isset($result->toArray()['PublicIpAddress']))
            return view('users.confirm')->with('result', 'Return failed, try again later or contact the administrator.');
        if (!isset($result->toArray()['PublicIpAddress']['IpAddress']))
            return view('users.confirm')->with('result', 'Return failed, try again later or contact the administrator.');
        if (!isset($result->toArray()['PublicIpAddress']['IpAddress'][0]))
            return view('users.confirm')->with('result', 'Return failed, try again later or contact the administrator.');

        $ipAddress = $result->toArray()['PublicIpAddress']['IpAddress'][0];
        $parames = [
            'ipAddress' => $ipAddress,
            'port' => '12000',
            'encryptionMethod' => 'aes-256-cfb',
            'password' => 'helloworld12000'
        ];
        return view('users.details', $parames);
    }

    public function delete()
    {
        return view('users.delete');
    }

    public function confirm(Request $request)
    {
        $instanceId = $request->input('instance_id');
        if (!isset($instanceId))
            return view('users.confirm')->with('result', 'The input cannot be null!');

        if (strlen($instanceId) !== 22)
            return view('users.confirm')->with('result', 'The input format is wrong about the length!');

        if ($instanceId[1] !== '-')
            return view('users.confirm')->with('result', 'The input format is wrong about the content!');

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
                                    'InstanceId' => $instanceId,
                                    ],
                                ])
                    ->request();
        } catch (ClientException $e) {
            echo $e->getErrorMessage() . PHP_EOL;
        } catch (ServerException $e) {
            echo $e->getErrorMessage() . PHP_EOL;
        }

        if (!isset($result))
            return view('users.confirm')->with('result', 'Return failed, try again later or contact the administrator.');

        return view('users.confirm')->with('result', json_encode($result->toArray()));
    }
}
