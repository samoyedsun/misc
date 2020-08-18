@extends('layouts.default')
@section('title', '详情')

@section('content')
<div class="offset-md-2 col-md-8">
  <div class="card ">
    <div class="card-header">
      <h5>详情</h5>
    </div>
    <div class="card-body">
      <form method="POST">
          <div class="form-group">
            <label for="ip_address">地址</label>
            <input type="text" name="ip_address" class="form-control" value="{{ $ipAddress }}">
          </div>
          <div class="form-group">
            <label for="port">端口</label>
            <input type="text" name="port" class="form-control" value="{{ $port }}">
          </div>
          <div class="form-group">
            <label for="encryption_method">加密方法</label>
            <input type="text" name="encryption_method" class="form-control" value="{{ $encryptionMethod }}">
          </div>
          <div class="form-group">
            <label for="password">密码</label>
            <input type="text" name="password" class="form-control" value="{{ $password }}">
          </div>
      </form>
    </div>
  </div>
</div>
@stop