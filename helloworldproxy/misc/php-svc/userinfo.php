<?php
	$username = $_POST['username'];
	$password = $_POST['password'];
	require "common.php";
	$sql = 'select * from user where username = "' . $username . '"';
	$ret = mysqli_query($connect, $sql);
	$arr = array();
	while($row = mysqli_fetch_array($ret)){
		array_push($arr, $row);
	}
	mysqli_close($connect);
	echo json_encode($arr[0]);
	return 0;
?>
