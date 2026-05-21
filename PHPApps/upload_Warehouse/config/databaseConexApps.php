<?php
//CONEXION SQL

$serverName = "192.168.1.53";
        $connectionOptions = array(
            "Database" => "AppsLCA",
            "Uid" => "sa",
            "PWD" => "Belerofonte1975"
        );

        $connApps = sqlsrv_connect($serverName,$connectionOptions);
?>
