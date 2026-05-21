<?php 

include("config/databaseConexApps.php");
include("config/databaseConexLCA.php");

$bodega = $_GET["item"];
$PO = $_GET["texto"];
$cajasCompletas = $_GET["cajasCompletas"];
$pesoCajasCompletas = $_GET["pesoCajasCompletas"];
$unidadesCajasCompletas = $_GET["unidadesCajasCompletas"];
$numCajasBalance = $_GET["numCajasBalance"];
$partNumber = $_GET["partNumber"];
$datosCB = $_GET["datosCB"];

$arrayDatosCB = json_decode($datosCB);

$ip = $_SERVER['REMOTE_ADDR'];
$boom = explode(".",$ip);
$ipTabla = $boom[3];


if ($connApps){

    //CREACIÓN DE TABLAS TEMPORALES

    $sql = "CREATE TABLE
    TableTMP_PODataCSV".$ipTabla." (
    PONumber VARCHAR(50),
    ItemNumber INT,
    PartNumber VARCHAR(50),
    BoxNumber VARCHAR(100),
    Units INT,
    Warehouse VARCHAR(50),
    SAC VARCHAR(50),
    LBS VARCHAR(50)
    CONSTRAINT UQ_ponumber_partnumber_boxnumber".$ipTabla." UNIQUE (PONumber, PartNumber,BoxNumber)
    );";

    if(!sqlsrv_query($connApps,$sql)){
        $e = sqlsrv_error();
        echo $e["message"];
    }
}else{
    $e = sqlsrv_error();
    echo $e["message"];
}


if($connLCA){

    //INSERT EN TABLAS
    $query = "SELECT * FROM [dboReaders].[VW_PurchaseOrdersDetails] WHERE PONumber ='".$PO."' AND PartNumber = '".$partNumber."' ORDER BY Item";
            $result = sqlsrv_query($connLCA,$query);

            if(!$result){
                $e = sqlsrv_error();
                echo $e["message"];
            }
            $correlativo = 1;
           
            $sqlCC = "INSERT INTO TableTMP_PODataCSV".$ipTabla." VALUES ";
           while ($row = sqlsrv_fetch_array($result, SQLSRV_FETCH_ASSOC)) {

                    for ($j = 0; $j < $cajasCompletas; $j++){

                        $BoxNumber = $PO.$row["PartNumber"]."-".str_pad("0",4,STR_PAD_LEFT).$correlativo;

                        $sqlCC .= "(
                        '".$row["PONumber"]."',
                        '".$row["Item"]."',
                        '".$row["PartNumber"]."',
                        '".$BoxNumber."',
                        '".$unidadesCajasCompletas."',
                        '".$bodega."',
                        '".$row["HTSCode"]."',
                        '".$pesoCajasCompletas."'),";
                        $correlativo++;
                    }

                    $longitud = strlen($sqlCC);
                    $sqlCC = substr($sqlCC,0,$longitud - 1).";";

                    if(!sqlsrv_query($connApps,$sqlCC)){
                        $e = sqlsrv_error();
                        echo $e["message"];
                    }
    
                    for ($j = 0; $j < $numCajasBalance; $j++){
                        $BoxNumber = $PO.$row["PartNumber"]."-".str_pad("0",4,STR_PAD_LEFT).$correlativo;
                        
                        $sqlCB = "INSERT INTO TableTMP_PODataCSV".$ipTabla." VALUES (
                            '".$row["PONumber"]."',
                            '".$row["Item"]."',
                            '".$row["PartNumber"]."',
                            '".$BoxNumber."',
                            '".$arrayDatosCB[$j][1]."',
                            '".$bodega."',
                            '".$row["HTSCode"]."',
                            '".$arrayDatosCB[$j][2]."');";

                        if(!sqlsrv_query($connApps,$sqlCB)){
                            $e = sqlsrv_error();
                            echo $e["message"];
                        };
                        $correlativo++;
                    }
            }
}else{
    $e = sqlsrv_error();
    echo $e["message"];
}

?>