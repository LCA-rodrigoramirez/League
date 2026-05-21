<?php
//CONEXION SQL

$serverName = "192.168.1.53";
        $connectionOptions = array(
            "Database" => "LCA",
            "Uid" => "sa",
            "PWD" => "Belerofonte1975"
        );

        $connLCA = sqlsrv_connect($serverName,$connectionOptions);
?>
