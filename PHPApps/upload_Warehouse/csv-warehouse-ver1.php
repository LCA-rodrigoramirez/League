<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="csv-warehouse.css">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-rbsA2VBKQhggwzxH7pPCaAqO46MgnOM80zW1RWuH61DGLwZJEdK2Kadq2F9CUG65" crossorigin="anonymous">
    <title>Purchase Order Upload</title>
</head>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<script>
 

    function MostrarTabla(){
    var selectBodega = document.getElementById('bodega');
    var inputPO = document.getElementById('purchaseOrder');
    
        if (inputPO.value != "" && selectBodega.value != "Seleccione una bodega"){

                var bodega = document.getElementById("bodega").value;
                var purchaseOrder = document.getElementById("purchaseOrder").value;

                // Crear objeto XMLHttpRequest
                var xhr = new XMLHttpRequest();

                // Configurar la solicitud
                xhr.open("GET", "procesarDatos/datos.php?item=" + selectBodega.value + "&texto=" + inputPO.value, true);

                // Definir qué hacer cuando la solicitud se complete
                xhr.onload = function() {
                  if (xhr.status === 200) {
                    // La solicitud fue exitosa
                    // Mostrar la tabla en el HTML
                    /*var datos = JSON.parse(xhr.responseText);
                    var array = "";
                    var tabla = datos[1];

                    for (var i = 0; i < datos[0].length; i++) {
                        array+=datos[0][i];
                    }*/

                    //document.getElementById("tabla").textContent = "Datos recibidos: " + datos[1];
                    document.getElementById("tabla").innerHTML = xhr.responseText;
                    console.log("hola");
                  } else {
                    // Hubo un error en la solicitud
                    console.error("Error al realizar la solicitud: " + xhr.status);
                  }
                };
            
                // Enviar la solicitud
                xhr.send();
            
        }else{

            Swal.fire({
                title: "Faltan Datos",
                text: "Ingrese una PO y Seleccione una Bodega para cargar los datos",
                icon: "warning",
                buttons: true,
            });
        }
    }
</script>



<body>

    <br><br><br>
    <h1>Purchase Order CSV Data</h1>
    <hr>

    <div class="border border-info">
        <form action="" method="post">
            <div class="row align-items-left">
                <div class="col-4">
                    <div class="mb-3">
                        <label for="purchaseOrder" class="form-label">Ingrese PO</label>
                        <input type="text" name="purchaseOrder" id="purchaseOrder" class="form-control" placeholder="PONumber" required>
                    </div>
                </div>
            </div>

            <div class="row align-items-left">
                <div class="col-4">
                    <div class="mb-3">
                        <label for="bodega" class="form-label">Seleccione Bodega</label>
                        <select name="bodega" id="bodega" class="form-select" required>
                            <option value="Seleccione una bodega" selected>Seleccione una bodega</option>
                            <option value="Warehouse">Warehouse</option>
                            <option value="Headwear Embroidery">Headwear Embroidery</option>
                            <option value="Greige Items">Greige Items</option>
                            <option value="Apparel Embroidery">Apparel Embroidery</option>
                        </select>
                    </div>
                </div>

                <div class="col-4">
                    <div class="mb-3">
                        <button type="button" onclick="MostrarTabla()" class="btn btn-dark">Mostrar Tabla</button>
                    </div>
                </div>
            </div>

            <div id="tabla">
        
            </div>
            
            <input type="submit" name="Enviar" value="Crear CSV" class="btn btn-success">
        </form>
    </div>

    <?php
    if (isset($_POST["Enviar"])){

        $bodega = $_POST["bodega"];
        $PO = $_POST["purchaseOrder"];
        $numeroCajasCompletas = $_POST["numeroCajasCompletas"];
        $unidadesCajasCompletas = $_POST["unidadesCajasCompletas"];
        $pesoCajasCompletas = $_POST["pesoCajasCompletas"];
        $numeroCajasBalance = $_POST["numeroCajasBalance"];
        $unidadesCajasBalance = $_POST["unidadesCajasBalance"];
        $pesoCajasBalance = $_POST["pesoCajasBalance"];
        $carpeta = "/var/www/html/development/import-export/upload_Warehouse/upload/";
        $correlativo = 1;
        
        
        $csvFileName = "Warehouse info PO ".$PO.".csv"; // Hour: UTC-6
        $csvFile = fopen($carpeta. $csvFileName, "wb");
        fputcsv($csvFile, array('PONumber','ItemNumber', 'PartNumber','BoxNumber','Units','Warehouse','SAC','LBS'), ",");
        

        $serverName = "192.168.1.53";
        $connectionOptions = array(
            "Database" => "LCA",
            "Uid" => "sa",
            "PWD" => "Belerofonte1975"
        );

        $conn = sqlsrv_connect($serverName,$connectionOptions);

        if ($conn){
            $query = "SELECT * FROM [dboReaders].[VW_PurchaseOrdersDetails] WHERE PONumber ='".$PO."' ORDER BY Item";
            $result = sqlsrv_query($conn,$query);
            $i = 0;
           

           while ($row = sqlsrv_fetch_array($result, SQLSRV_FETCH_ASSOC)) {
                if(intval($numeroCajasCompletas[$i]) > 0 && intval($numeroCajasBalance[$i] > 0)){

                    
                    for ($j = 0; $j < $numeroCajasCompletas[$i]; $j++){

                        $BoxNumber = $PO.$row["PartNumber"]."-".str_pad("0",4,STR_PAD_LEFT).$correlativo;
                        fwrite($csvFile,$PO.",".$row["Item"].",".$row["PartNumber"].",".$BoxNumber.",".$unidadesCajasCompletas[$i].",".$bodega.",".$row["HTSCode"].",".$pesoCajasCompletas[$i]."\n");
                        $correlativo++;
                    }
    
                    for ($j = 0; $j < $numeroCajasBalance[$i]; $j++){
                        $BoxNumber = $PO.$row["PartNumber"]."-".str_pad("0",4,STR_PAD_LEFT).$correlativo;
                        fwrite($csvFile,$PO.",".$row["Item"].",".$row["PartNumber"].",".$BoxNumber.",".$unidadesCajasBalance[$i].",".$bodega.",".$row["HTSCode"].",".$pesoCajasBalance[$i]."\n");
                        $correlativo++;
                    }
                }elseif(intval($numeroCajasCompletas[$i]) > 0 && intval($numeroCajasBalance[$i]) == 0){
                    for ($j = 0; $j < $numeroCajasCompletas[$i]; $j++){
                        $BoxNumber = $PO.$row["PartNumber"]."-".str_pad("0",4,STR_PAD_LEFT).$correlativo;
                        fwrite($csvFile,$PO.",".$row["Item"].",".$row["PartNumber"].",".$BoxNumber.",".$unidadesCajasCompletas[$i].",".$bodega.",".$row["HTSCode"].",".$pesoCajasCompletas[$i]."\n");
                        $correlativo++;
                    }
                }

                $i++;
            }
        }

        fclose($csvFile);
    }
?>

  
</body>
</html>