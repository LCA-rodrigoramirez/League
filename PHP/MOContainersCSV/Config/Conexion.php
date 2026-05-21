<?PHP
        
        $serverName     = "192.168.1.53"; 
        $connectionInfo = array( "Database"=>"LCA", "UID"=>"sa", "PWD"=>"Belerofonte1975");

        $conexion = sqlsrv_connect( $serverName, $connectionInfo);
        
        /*
        if( $conn ) {
            echo "Conexión establecida.<br />";
        }else{
            */
        
        if(!$conexion){    
            echo "Error: could not establish database connection.<br />";
            die( print_r( sqlsrv_errors(), true));
        }  
        

        /*
        $host = "172.16.2.238";  // servidor de POLYPM
        //$host = "127.0.0.1";    // servidor local
        $user = "root";
        $pass = '$c427m00';
        $db   = "wordpress";

        $conexion = mysqli_connect($host,$user,$pass,$db);
        if(!$conexion){
            die("No se pudo conectar a la base de datos");
        }
        */
?>