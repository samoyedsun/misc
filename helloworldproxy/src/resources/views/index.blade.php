@extends('layouts.default')

@section('content')
  <div class="jumbotron">
    <!--
    <p>
      <div class="container">
        <div class="row">
          <div class="col-sm">
            <a class="btn btn-lg btn-success" href="{{ route('_create_') }}" role="button">创建</a>
          </div>
          <div class="col-sm">
            <a class="btn btn-lg btn-success" href="{{ route('_delete_') }}" role="button">删除</a>
          </div>
        </div>
      </div>
    </p>
    <p>
      <b>用户必读:</b>
    </p>
    <p>
      扫描赞赏码付费,同时在留言处备注自己的邮件地址; 付费后管理员会为你开启ss服务,并将配置信息发给你.
    </p>
    <p>
      计费方式是每天10元租凭费用, 不限流量, 不限带宽, 限制一人使用.
    </p>
    <p>
      赞赏费用完后会账号会自动生效. 期间有任何问题请加入qq群:675413320, 联系管理员.
    </p>
    --> 
    <p>
      |
      <a href="{{URL::asset('/tools/Shadowsocks-4.1.4.zip')}}">win版客户端</a>
      |
      <a href="{{URL::asset('/tools/shadowsocks-arm64-v8a-4.7.2.apk')}}">安卓版客户端</a>
      |
      <a href="{{URL::asset('/tools/ShadowsocksX-NG.app.1.8.2.zip')}}">mac版客户端</a>
      |
      <a href="#">ios的话去应用商店下载Potatso Lite</a>
      |
    </p>
  </div>
@stop
