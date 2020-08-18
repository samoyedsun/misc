<?php
	$username = $_POST['username'];
	$password = $_POST['password'];
	$mode = 'aes-256-cfb';
	require "common.php";
	mysqli_autocommit($connect, FALSE);
	$sql = 'select username from user where username = "' . $username . '"';
	$ret = mysqli_query($connect, $sql);
	$arr = array();
	while($row = mysqli_fetch_array($ret)){
		array_push($arr, $row);
	}
	if (sizeof($arr) > 0){
		mysqli_close($connect);
		echo json_encode(array('code'=>201, 'tips'=>'user already exist!'));
		return 0;
	}

	$sql = 'select count(u.uid) from user u';
	$sql = 'select * from user order by uid desc LIMIT 1';
	$ret = mysqli_query($connect, $sql);
	$arr = array();
	while($row = mysqli_fetch_array($ret)){
		array_push($arr, $row);
	}
	$curr_max_port = $arr[0]['port'];
	$port = $curr_max_port + 1;

	$sql = 'insert into user(username, password, port, mode, hiredate)
		value(\'' . $username . '\',\'' . $password . '\',' . $port . ',\'' . $mode . '\',now())';
	$ret = mysqli_query($connect, $sql);
	if (!mysqli_commit($connect)) {
		die("Transaction commit failed: " . mysqli_connect_error());
	}
	mysqli_close($connect);
	
	if ($ret){
		$command = 'sh ./startss.sh ' . $port . ' ' . $password . ' ' . $mode;
		shell_exec($command);
		echo json_encode(array('code'=>200, 'tips'=>'create secceed!'));
	}
	return 0;
?>
