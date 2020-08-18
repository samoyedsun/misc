<?php
	$username = $_POST['username'];
	$password = $_POST['password'];
	require "common.php";
	$sql = 'select password from user where username = "' . $username . '"';
	$ret = mysqli_query($connect, $sql);
	$arr = array();
	while($row = mysqli_fetch_array($ret)){
		array_push($arr, $row);
	}
	mysqli_close($connect);
	if (sizeof($arr) == 0){
		echo json_encode(array('code'=>202, 'tips'=>'user not exist!'));
		return 0;
	}
	if ($arr[0]['password'] === $password){
		echo json_encode(array('code'=>200, 'tips'=>'login secceed!'));
		return 0;
	}
	echo json_encode(array('code'=>203, 'tips'=>'password error!'));
	return 0;
?>
