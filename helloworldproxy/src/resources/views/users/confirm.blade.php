@extends('layouts.default')
@section('title', '删除')

@section('content')
<div class="offset-md-2 col-md-8">
  <div class="card ">
    <div class="card-header">
      <h5>删除</h5>
    </div>
    <div class="card-body">
      <form method="POST">
          <div class="form-group">
            <label for="result">返回信息</label>
            <input type="text" name="result" class="form-control" value="{{ $result }}">
          </div>
      </form>
    </div>
  </div>
</div>
@stop