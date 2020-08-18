@extends('layouts.default')
@section('title', '创建')

@section('content')
<div class="offset-md-2 col-md-8">
  <div class="card ">
    <div class="card-header">
      <h5>创建</h5>
    </div>
    <div class="card-body">
      <form method="POST" action="{{ route('details') }}">
          <div class="form-group">
            <label for="instance_id">实例ID</label>
            <input type="text" name="instance_id" class="form-control" value="{{ $instanceId }}">
          </div>
          <button type="submit" class="btn btn-primary">获取详细配置</button>
      </form>
    </div>
  </div>
</div>
@stop