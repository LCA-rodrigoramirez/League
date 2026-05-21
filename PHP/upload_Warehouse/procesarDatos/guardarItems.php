<?php

use PhpParser\Node\Stmt\Echo_;
use PhpParser\Node\Stmt\Else_;

include("../config/databaseConexApps.php");
include("../config/databaseConexLCA.php");

$bodega = trim($_GET["item"]);
$PO = trim($_GET["texto"]);
$datosCB = $_GET["datosCB"];
$datosCC = $_GET["datosCC"];

$arrayDatosCC = json_decode($datosCC);      /*Recibe datos en este orden
                                            indice 0 = item
                                            indice 1 = partNumber
                                            indice 2 = numCajasCompletas
                                            indice 3 = unidadesCajasCompletas
                                            indice 4 = pesoCajasCompletas
                                            indice 5 = numeroCajasBalance
                                            indice 6 = bin
                                            indice 7 = totalDeCajas (suma de unidades ingresadas en cajas completas y balance)*/ 

$arrayDatosCB = json_decode($datosCB);      /*Recibe datos en este orden
                                            indice 0 = item
                                            indice 1 = unidadesCajaBlance
                                            indice 2 = pesoCajasBalance*/ 
$countItems = intval($_GET["countItems"]);
$correlativo = 0;
$ip = $_SERVER['REMOTE_ADDR'];
$boom = explode(".",$ip);
$ipTabla = $boom[0].$boom[1].$boom[2].$boom[3];


if($connLCA){

    
        //INSERT EN TABLAS
        $queryCorrelativo = "SELECT MAX(IDCaja) as IDCaja FROM dbo.Table_PODataCSV WHERE PONumber ='".$PO."'";

        $resultCorrelativo = sqlsrv_query($connApps,$queryCorrelativo);

        if (sqlsrv_fetch($resultCorrelativo) === true) {
            $correlativo = intval(sqlsrv_get_field($resultCorrelativo, 0)) + 1; // 0 indica la primera columna

        }

        if($correlativo != NULL) {

            $queryCorrTMP = "SELECT MAX(IDCaja) as IDCaja FROM dbo.Table_UploadItemsPPM WHERE PONumber ='".$PO."'";

            $resultCorrTMP = sqlsrv_query($connApps,$queryCorrTMP);

            if (sqlsrv_fetch($resultCorrTMP) === true) {

                $correlativoUpload = intval(sqlsrv_get_field($resultCorrTMP, 0)) + 1; // 0 indica la primera columna

                if ($correlativo <= $correlativoUpload){
                    $correlativo = $correlativoUpload;
                }

            }
        }

        $datosNoValidos = [];
        
            for ($i = 0; $i < count($arrayDatosCC);$i++){    

                /* COMENTADO DEBIDO A REQUERIMIENTO QUE POLY PM PERMITE RECIBIR MÁS PRENDAS DE LAS ORDENADAS */
                //INSERT EN TABLA DE STATUS
                
                /*$sqlStatusContains = "SELECT * FROM dbo.Table_StatusItems WHERE PONumber ='".$PO."' AND PartNumber = '".$arrayDatosCC[$i][1]."' ";
                $sqlStatus = "";
                $flag = 0;

                $resultStatus = sqlsrv_query($connApps,$sqlStatusContains);

                if(sqlsrv_has_rows($resultStatus)){
                    $sqlStatus .= "UPDATE dbo.Table_StatusItems SET ";

                    while ($row = sqlsrv_fetch_array($resultStatus)){

                        $saldoActual = intval($row["Cantidad_Faltante"]);
                        $saldoNuevo = $saldoActual - intval($arrayDatosCC[$i][7]);
                        $yaRecibido = intval($row["Cantidad_Recibida"]);

                        if($saldoNuevo > 0){

                            $sqlStatus .= "
                             Cantidad_Recibida = ".$yaRecibido + intval($arrayDatosCC[$i][7]).
                            ", Cantidad_Faltante = ".$saldoNuevo.
                            " WHERE PONumber ='".$PO."' AND PartNumber = '".$arrayDatosCC[$i][1]."' ";


                        }elseif($saldoNuevo == 0){

                            $sqlStatus .= "
                            Cantidad_Recibida = ".$yaRecibido + intval($arrayDatosCC[$i][7]).
                           ", Cantidad_Faltante = ".$saldoNuevo.
                           ", Status = '1' WHERE PONumber ='".$PO."' AND PartNumber = '".$arrayDatosCC[$i][1]."' ";

                        
                        }else{
                            $flag++;
                        }
                    }
                    sqlsrv_query($connApps,$sqlStatus);
                }else{
                    $query2 = "SELECT * FROM [dboReaders].[VW_PurchaseOrdersDetails] WHERE PONumber ='".$PO."' AND PartNumber = '".$arrayDatosCC[$i][1]."' ORDER BY Item";
                
                    $result2 = sqlsrv_query($connLCA,$query2);

                    $sqlStatus .= "INSERT INTO Table_StatusItems VALUES ";

                    while ($row = sqlsrv_fetch_array($result2, SQLSRV_FETCH_ASSOC)){

                        $saldo = intval($row["Ordered"]) - intval($arrayDatosCC[$i][7]);
                        if ($saldo == 0){

                            $sqlStatus .= "(
                                '".$row["PONumber"]."',
                                '".$row["PartNumber"]."',
                                '".$row["Item"]."',
                                '".$row["Ordered"]."',
                                '".$arrayDatosCC[$i][7]."',
                                '".$saldo."',
                                '1',
                                '0'
                            );";
                        }else{
                            $sqlStatus .= "(
                                '".$row["PONumber"]."',
                                '".$row["PartNumber"]."',
                                '".$row["Item"]."',
                                '".$row["Ordered"]."',
                                '".$arrayDatosCC[$i][7]."',
                                '".$saldo."',
                                '0',
                                '0'
                            );";
                        }

                    }
                    
                    sqlsrv_query($connApps,$sqlStatus);

                }*/

                /* INSERT EN TABLA AppsLCA.dbo.Table_PODataCSV, DE ESTOS DATOS SE GENERARÁ EL CSV*/
                    //$datosCC = $_GET["datosCC"];
                    //$datosCB = $_GET["datosCB"];

                    //$arrayDatosCC = json_decode($datosCC);
                    //$arrayDatosCB = json_decode($datosCB);
                    $query = "SELECT * FROM [dboReaders].[VW_PurchaseOrdersDetails] WITH(NOLOCK) WHERE PONumber ='".$PO."' AND PartNumber = '".$arrayDatosCC[$i][1]."' ORDER BY Item";
                
                    $result = sqlsrv_query($connLCA,$query);

                    $sqlCC = "INSERT INTO dbo.Table_PODataCSV VALUES ";
                    
                    while ($row = sqlsrv_fetch_array($result, SQLSRV_FETCH_ASSOC)) {
                        
                        if(intval($arrayDatosCC[$i][2]) > 0){
                             for ($j = 0; $j < $arrayDatosCC[$i][2]; $j++){
                            
                                 $BoxNumber = $PO."/".str_pad($correlativo,5,"0",STR_PAD_LEFT);
                            
                                 $sqlCC .= "(
                                 '".$row["PONumber"]."',
                                 '".$row["Item"]."',
                                 '".$row["PartNumber"]."',
                                 '".$BoxNumber."',
                                 '".$correlativo."',
                                 '".$arrayDatosCC[$i][3]."',
                                 '".$bodega."',
                                 '".$row["HTSCode"]."',
                                 '".$arrayDatosCC[$i][4]."',
                                 '".$arrayDatosCC[$i][6]."',
                                 '1',
                                 '".$arrayDatosCC[$i][5]."',
                                 '".$ipTabla."'),";
                                 $correlativo++;
                             }
                         
                             $longitud = strlen($sqlCC);
                             $sqlCC = substr($sqlCC,0,$longitud - 1).";";
                         
                             if(!sqlsrv_query($connApps,$sqlCC)){
                                 //$e = sqlsrv_error();
                                 //echo $e["message"];
                                 die(print_r(sqlsrv_error()));
                             }
                             
                        }
                        
                        if (intval($arrayDatosCC[$i][5]) != 0){
                            
                            $correlativoBalance = 0;
                            $indiceCB = 0.1;
                             for ($j = 0; $j <= count($arrayDatosCB); $j++){

                                 if ($arrayDatosCC[$i][0] == $arrayDatosCB[$j][0]){

                                    if ($correlativo == 1){
                                        $correlativoBalance = $correlativo;
                                        $correlativoBalance += $indiceCB;
                                    }else{
                                        $correlativoBalance = $correlativo - 1;
                                        $correlativoBalance += $indiceCB;
                                    }

                                    $BoxNumber = $PO."/".str_pad($correlativoBalance,7,"0",STR_PAD_LEFT);
                                    $sqlCB = "INSERT INTO Table_PODataCSV VALUES (
                                        '".$row["PONumber"]."',
                                        '".$row["Item"]."',
                                        '".$row["PartNumber"]."',
                                        '".$BoxNumber."',
                                        '".($correlativo - 1)."',
                                        '".$arrayDatosCB[$j][1]."',
                                        '".$bodega."',
                                        '".$row["HTSCode"]."',
                                        '".$arrayDatosCB[$j][2]."',
                                        '".$arrayDatosCC[$i][6]."',
                                        '2',
                                        '".$arrayDatosCC[$i][5]."',
                                        '".$ipTabla."');";

                                        if(!sqlsrv_query($connApps,$sqlCB)){

                                            $e = sqlsrv_error();
                                            echo $e["message"];
                                        };
                                        
                                        $indiceCB += 0.1;
                                 }
                                 
                                 
                             }
                        }
                     }

            }

            


            if (count($datosNoValidos) == 0){
                echo "Datos guardados con éxito";
            }else{
                $datosMostrar = implode(',',$datosNoValidos);
                echo "No puede ingresar más datos para el/los PartNumber: $datosMostrar.\n 
                Asegúrese que la cantidad que está ingresando sea correcta";
            }
}else{
    $e = sqlsrv_error();
    echo $e["message"];
}

?>