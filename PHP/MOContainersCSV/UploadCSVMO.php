<?php

    include_once("Config/Conexion.php");

    $ponumber = $_POST["ponumber"];
    $recivslip = $_POST["recivslip"];
    
    $array_check = $_REQUEST["cadena"];

    
    $array_json = [];
    $container_code = '';

    $rows = strlen($array_check);
    
    $array_json = json_encode($array_check);
    $rows = count($array_json);
    


    $sin_corche_fin = substr($array_check,0,-1);
    $sin_corche_ini = substr($sin_corche_fin,1);
    $container_code1 = str_replace('"',"'",$sin_corche_ini);
    //$container_code = substr($sin_corche_ini,5);
    if($array_json[0] == "1"){
        $container_code = substr($container_code1,4);
    }else{
        $container_code = $container_code1;
    }

    //var_dump($container_code);
    //return 0;

    if(!$ponumber || !$recivslip){
        return $row;
    }
    /* 1.  validamos si la MO ha sido creada, de lo contrario enviara un mensaje indicando que
		es necesario la creacion de la MO, antes de continuar con la creacion de CSV   */    
    /* 2.  Buscamos el valor del campo PurchaseID en la tabla LCA.dbo.PurchaseOrders con el criterio de la
		PONumber, segun la que estamos buscando */

    //wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
    //--procedemos con la evaluacion de la primera consulta  

    $sql0 = " SELECT OrderID,PONumber, OrderNumber,ManufactureID
                FROM LCA.dbo.Orders WITH (NOLOCK)
                WHERE PONumber = '$ponumber'
                    AND ManufactureID IS NOT NULL ";
    

    //$query0 = sqlsrv_query($conexion, $sql0,array(), array( "scrollable" => SQLSRV_CURSOR_KEYSET ));

      

/*

    if(sqlsrv_fetch($query0) === false){
        echo '<script language="javascript">alert(Error);window.location.href="MOVenta.php"</script>';
        die(print_r(sqlsrv_errors(), true));

    }
  */  
    //wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
    
            $rawMaterial = 0;
            //--obtenemos en primer lugar la informacion del barcode (PPMO1) por medio de la MO
            $sql4 = "SELECT
                        Barcode
                        ,STRING_AGG(MOMaterial,',') AS MOMaterial
                    FROM
                    (
                        SELECT distinct concat('PPMO',(Cast ((MO.ManufactureID + 1000000)  as varchar(30)  ))) as Barcode, RA.RawMaterialID as MOMaterial
                        from lca.dbo.ManufactureOrders MO WITH (NOLOCK)
						INNER JOIN lca.dbo.RawAllocations RA WITH (NOLOCK) ON MO.ManufactureID = RA.ManufactureID and MO.StatusID <90
						LEFT JOIN lca.dbo.RawContainers RC WITH (NOLOCK) ON RA.RawMaterialID = RC.RawMaterialID

                        where ManufactureNumber = '$ponumber'
							AND RC.ContainerCode in ($container_code)
                    ) as tb
                    GROUP BY Barcode
                            ";

            $query4 = sqlsrv_query($conexion,$sql4,array(), array( "Scrollable" => SQLSRV_CURSOR_KEYSET )); 


                while($fila4 = sqlsrv_fetch_array($query4,SQLSRV_FETCH_ASSOC)){
                    
                    $ppmo1 = $fila4['Barcode'];
                    $rawMaterial = $fila4["MOMaterial"];
                    
                    
                    //$data[$j][1] = $fila4['Code'];
                    //$data[$j][2] = $fila4['OnHand'];
                }

                

        if(!$ppmo1){

            echo 'El PartNumber de los Contenedores no coincide con La MO ingresada o La MO ingresada no posee Barcode, Favor verificar.';
            $valido = false;
            return http_response_code(404);
        }else{

            $sql5 = "SELECT Code,[On Hand] as OnHand,RawMaterialID 
                        from LCA.[dboReaders].[VW_PurchaseOrdersDetailsVerJC_Ver2] WITH (NOLOCK)
                        where shipnumber ='$recivslip'
                            and Code in ($container_code)
                            and RawMaterialID IN ($rawMaterial) ";

            $query5 = sqlsrv_query($conexion,$sql5,array(), array( "Scrollable" => SQLSRV_CURSOR_KEYSET )); 

            $k = 0;
                while($fila5 = sqlsrv_fetch_array($query5,SQLSRV_FETCH_ASSOC)){
                    //$data[$j][0] = $fila4['Barcode'];
                    $data[$k][1] = $fila5['Code'];
                    $data[$k][2] = $fila5['OnHand'];

                    $k = $k + 1;
                }    




            /*  PROCEDEMOS CON LA CONSTRUCCION DEL CSV GESTIONANDO LA INFORMACION DEL ARRAY    */
            
            $cant_data = count($data);
            //echo $cant_data;
            /*  procedemos con el bucle para la creacion del CSV registro por registro   */

            $carpeta = '/var/www/html/proyect/ArchivosCSVMOC/';
            $csvFileName = "{$ponumber}.csv";
            $rutaCompleta = $carpeta.$csvFileName;
            
            $csvFile = fopen($rutaCompleta, "wb");
            
            $hoy = date("Ymd");

            $hora = date("His");

            if($csvFile){
                
                foreach($data as $i => $valor){    
                   
                    //fputcsv($csvFile,array('MFG',$valor[0],$hoy,$hora,'3','TAKQ',$valor[1],'','1'),",");
                    fputcsv($csvFile,array('MFG',$ppmo1,$hoy,$hora,'3','TAKQ',$data[$i][1],'',$data[$i][2]),",");
                   
                }
            }

            fclose($csvFile);


            if(file_exists($rutaCompleta)){
                        
                header("Content-disposition: attachment; filename={$ponumber}.csv");
                header("Content-type: application/csv");
                readfile("/var/www/html/proyect/ArchivosCSVMOC/{$ponumber}.csv");

                unlink($rutaCompleta);


            }else{
                return "No se logra definir el nombre de la PONumber".$ponumber;
            
            }
        }
        //}

?>
