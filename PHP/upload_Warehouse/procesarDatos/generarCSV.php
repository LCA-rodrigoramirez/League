<?php
include("../config/databaseConexApps.php");
include("../config/databaseConexLCA.php");

    if (isset($_POST["Enviar"])){

        
        $bodega = trim($_POST["bodega"]);
        $PO = trim($_POST["purchaseOrder"]);
        $ip = $_SERVER['REMOTE_ADDR'];
        $boom = explode(".",$ip);
        $ipTabla = $boom[0].$boom[1].$boom[2].$boom[3];
        date_default_timezone_set('America/El_Salvador');
        // Obtiene la fecha y hora actual con precisión de microsegundos
        $microtime = microtime(true);

        // Formatea la fecha y hora con milisegundos
        $fechaConMilisegundos = date("YmdHis") . sprintf("%03d", ($microtime - floor($microtime)) * 1000);

        $carpeta = "/var/www/html/development/import-export/upload_Warehouse/upload/";
        $correlativo = 1;

        if ($connApps){
            $query = "SELECT * FROM dbo.Table_PODataCSV WHERE PONumber ='".$PO."' AND IDUsuario = '".$ipTabla."' ORDER BY ItemNumber";
            $result = sqlsrv_query($connApps,$query);
            $i = 0;
            $datos = [];
           
            while ($row = sqlsrv_fetch_array($result, SQLSRV_FETCH_ASSOC)){
                
                $boom = explode("-",$row["PartNumber"]);

                $datos[$i] = $row;
                $datos[$i]["Estilo"] = $boom[0];
                $datos[$i]["Color"] = $boom[1];

                $i++;
            }

            $mismoEstilo = "";
            $miusmoColor = "";
            $nombreArchivo = "";
            $arvhivos = [];
            $i = 0;
            $j = 0;

            foreach ($datos as $value) {
                
                if($value["Estilo"] != $mismoEstilo || $value["Color"] != $mismoColor){

                    $j = 0;
                    $csvFileName = "Warehouse info PO ".$PO." Estilo-Color ".$value["Estilo"]."-".$value["Color"].".csv";

                    $encabezado = "PONumber,ItemNumber,PartNumber,BoxNumber,Units,Warehouse,SAC,LBS";
                    $contenido = $value["PONumber"].",".$value["ItemNumber"].",".$value["PartNumber"].",".$value["BoxNumber"].",".$value["Units"].",".$value["Warehouse"].",".
                    $value["SAC"].",".$value["LBS"];

                    if($csvFileName != $nombreArchivo){

                        $archivos[$i]["Nombre"] = $csvFileName;
                        $archivos[$i]["Encabezado"] = $encabezado;
                        $archivos[$i]["Contenido"][$j] = $contenido;

                        $i++;
                        $j++;
                    }

                    $mismoEstilo = $value["Estilo"];
                    $mismoColor = $value["Color"];

                }else{

                    $contenido = $value["PONumber"].",".$value["ItemNumber"].",".$value["PartNumber"].",".$value["BoxNumber"].",".$value["Units"].",".$value["Warehouse"].",".
                    $value["SAC"].",".$value["LBS"];

                    $archivos[$i-1]["Contenido"][$j] .= $contenido;
                    $j++;
                }

            }

            /*if(file_exists($carpeta.$csvFileName)){
                //echo "procedemos a abrir el fichero: ".$ponumber;
               
                header("Content-disposition: attachment; filename={$csvFileName}");
                //header("Content-type: MIME");
                header("Content-type: application/csv");
                readfile("/var/www/html/development/import-export/upload_Warehouse/upload/{$csvFileName}");

                //Consultar si todos los Items de la PONumber están completos

                $query = "SELECT * FROM dbo.Table_PODataCSV WHERE PONumber ='".$PO."' ORDER BY ItemNumber";
                $result = sqlsrv_query($connApps,$query);

                $sqlUploadTable = "INSERT INTO dbo.Table_UploadItemsPPM VALUES ";
                
                while ($row = sqlsrv_fetch_array($result, SQLSRV_FETCH_ASSOC)){

                    $sqlUploadTable .= "(
                        '".$row["PONumber"]."',
                        '".$row["ItemNumber"]."',
                        '".$row["PartNumber"]."',
                        '".$row["BoxNumber"]."',
                        '".$row["IDCaja"]."',
                        '".$row["Units"]."',
                        '".$row["Warehouse"]."',
                        '".$row["SAC"]."',
                        '".$row["LBS"]."',
                        '".$row["Bin"]."',
                        '".$row["Tipo"]."',
                        '".$row["CajasBalance"]."'),";
                }
                $longitud = strlen($sqlUploadTable);
                $sqlUploadTable = substr($sqlUploadTable,0,$longitud - 1).";";

                sqlsrv_query($connApps,$sqlUploadTable);

                $queryTBTMP = "DELETE FROM dbo.Table_PODataCSV WHERE PONumber ='".$PO."' AND IDUsuario = '".$ipTabla."'";

                sqlsrv_query($connApps,$queryTBTMP);

                unlink($carpeta.$csvFileName);

            }else{
                    return "No se logra definir el nombre de la PONumber".$PO;
           
            }*/

            $carpeta = "/var/www/html/development/import-export/upload_Warehouse/upload/";
            $zip = new ZipArchive();
            $zip->open($carpeta."Warehouse info PO ".$PO.$fechaConMilisegundos.".zip", ZipArchive::CREATE);

            foreach ($archivos as $key) {
                $csvFileName = $key["Nombre"];

                $csvFile = fopen($carpeta.$csvFileName,"wb");

                fwrite($csvFile,$key["Encabezado"]."\n");

                foreach ($key["Contenido"] as $value) {
                    
                    fwrite($csvFile,$value."\n");
                }

                fclose($csvFile);

                $zip -> addFile($carpeta.$csvFileName,$csvFileName);

            }

            $zip->close();

            /*$carpeta = "/var/www/html/development/import-export/upload_Warehouse/upload/";

            foreach ($archivos as $value) {
                
                $csvFileName = $value["Nombre"];

                if (file_exists($carpeta.$csvFileName)) {
                    
                    
                    
                }
            }*/

            

            header('Content-Type: application/zip');
            header('Content-Disposition: attachment; filename=Warehouse info PO '.$PO.$fechaConMilisegundos);
            header('Content-Transfer-Encoding: binary');
            header('Expires: 0');
            header('Cache-Control: must-revalidate');
            header('Pragma: public');
            header('Content-Length: ' . filesize('/var/www/html/development/import-export/upload_Warehouse/upload/Warehouse info PO '.$PO.$fechaConMilisegundos.'.zip'));
            //ob_clean();
            readfile('/var/www/html/development/import-export/upload_Warehouse/upload/Warehouse info PO '.$PO.$fechaConMilisegundos.'.zip');

            $query = "SELECT * FROM dbo.Table_PODataCSV WHERE PONumber ='".$PO."' ORDER BY ItemNumber";
            $result = sqlsrv_query($connApps,$query);

                $sqlUploadTable = "INSERT INTO dbo.Table_UploadItemsPPM VALUES ";
                
                while ($row = sqlsrv_fetch_array($result, SQLSRV_FETCH_ASSOC)){

                    $sqlUploadTable .= "(
                        '".$row["PONumber"]."',
                        '".$row["ItemNumber"]."',
                        '".$row["PartNumber"]."',
                        '".$row["BoxNumber"]."',
                        '".$row["IDCaja"]."',
                        '".$row["Units"]."',
                        '".$row["Warehouse"]."',
                        '".$row["SAC"]."',
                        '".$row["LBS"]."',
                        '".$row["Bin"]."',
                        '".$row["Tipo"]."',
                        '".$row["CajasBalance"]."'),";
                }

                $longitud = strlen($sqlUploadTable);
                $sqlUploadTable = substr($sqlUploadTable,0,$longitud - 1).";";

                sqlsrv_query($connApps,$sqlUploadTable);

                $queryTBTMP = "DELETE FROM dbo.Table_PODataCSV WHERE PONumber ='".$PO."' AND IDUsuario = '".$ipTabla."'";

                sqlsrv_query($connApps,$queryTBTMP);
            
            unlink($carpeta.'Warehouse info PO '.$PO.$fechaConMilisegundos.'.zip');

            /*?>
            <pre>
                <?php print_r($archivos); ?>
            </pre>

            <?php*/
        }

    }elseif(isset($_POST["EnviarBin"])){
        $PO = trim($_POST["purchaseOrder"]);
        $ip = $_SERVER['REMOTE_ADDR'];
        $boom = explode(".",$ip);
        $ipTabla = $boom[3];

        $carpeta = "/var/www/html/development/import-export/upload_Warehouse/upload/";
        $correlativo = 1;

        $fechaActual = DateTime::createFromFormat('U.u', microtime(true));
            
        // Imprime la fecha y hora actual con los milisegundos agregados

        $fechaActual->sub(new DateInterval('PT6H'));
        
        $fecha = $fechaActual->format('Ymd');
        $hora = $fechaActual->format('His');

        // Obtiene la fecha y hora actual con precisión de microsegundos
        $microtime = microtime(true);

        // Formatea la fecha y hora con milisegundos
        $fechaConMilisegundos = date("YmdHis") . sprintf("%03d", ($microtime - floor($microtime)) * 1000);
 
        $csvFileName = "Bin info PO ".$PO."-".$fechaConMilisegundos.".csv"; // Hour: UTC-6

        $csvFile = fopen($carpeta. $csvFileName, "wb");

        if ($connApps){
            
            $query = "SELECT ContainerCode,TB.Bin FROM LCA.dbo.RawContainers as RC 
            inner join AppsLCA.dbo.Table_UploadItemsPPM as TB ON TB.BoxNumber = RC.ContainerCode
            WHERE RC.ContainerCode IN
            (SELECT BoxNumber FROM AppsLCA.dbo.Table_UploadItemsPPM WHERE PONumber = '".$PO."')";
            $result = sqlsrv_query($connLCA,$query);
            
            while ($row = sqlsrv_fetch_array($result, SQLSRV_FETCH_ASSOC)){
                
                fwrite($csvFile,"BIN,".$row["Bin"].",".$fecha.",".$hora.",3,BINC,".$row["ContainerCode"]."\n");
            }
            fclose($csvFile);
            
            if(file_exists($carpeta.$csvFileName)){
                //echo "procedemos a abrir el fichero: ".$ponumber;
                
                header("Content-disposition: attachment; filename={$csvFileName}");
                //header("Content-type: MIME");
                header("Content-type: application/csv");
                header('Pragma: public');
                header("Content-Transfer-Encoding: binary");
                readfile("/var/www/html/development/import-export/upload_Warehouse/upload/{$csvFileName}");

                unlink($carpeta.$csvFileName);

                //Consultar si todos los Items de la PONumber están completos

            }else{
                    return "No se logra definir el nombre de la PONumber".$PO;
           
            }
        }
    }
?>