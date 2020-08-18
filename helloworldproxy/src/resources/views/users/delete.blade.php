@extends('layouts.default')
@section('title', '删除')

@section('content')
<div class="offset-md-2 col-md-8">
  <div class="card ">
    <div class="card-header">
      <h5>删除</h5>
    </div>
    <div class="card-body">
      <form method="POST" action="{{ route('confirm') }}">
          <div class="form-group">
            <label for="instance_id">实例ID</label>
            <input type="text" name="instance_id" class="form-control">
          </div>
          <button type="submit" class="btn btn-primary">确定</button>
      </form>
    </div>
  </div>
</div>
@stop