<?php
	require "common.php";
	$sql = 'select port from user';
	$ret = mysqli_query($connect, $sql);
	$arr = array();
	while($row = mysqli_fetch_array($ret)){
		array_push($arr, $row);
	}
	mysqli_close($connect);
	$command = 'sh stopss.sh';
	for ($i = 0; $i < sizeof($arr); $i ++){
		$port = $arr[$i]['port'];
		$command = $command . ' ' . $port;
	}
	echo shell_exec($command);
	return 0;
?>
