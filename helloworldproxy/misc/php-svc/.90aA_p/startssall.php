<?php
	require "common.php";
	$sql = 'select password, port, mode from user';
	$ret = mysqli_query($connect, $sql);
	$arr = array();
	while($row = mysqli_fetch_array($ret)){
		array_push($arr, $row);
	}
	mysqli_close($connect);
	for ($i = 0; $i < sizeof($arr); $i ++){
		$pwd = $arr[$i]['password'];
		$port = $arr[$i]['port'];
		$mode = $arr[$i]['mode'];
		$command = 'sh ./startss.sh ' . $port . ' ' . $pwd . ' ' . $mode; 	
		shell_exec($command);
	}
	return 0;
?>
