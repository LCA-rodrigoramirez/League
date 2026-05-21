<?php 
include("../config/databaseConexApps.php");
include("../config/databaseConexLCA.php");

    $bodega = trim($_GET["item"]);
    $PO = trim($_GET["texto"]);
    $ip = $_SERVER['REMOTE_ADDR'];
    $boom = explode(".",$ip);
    $ipTabla = $boom[3];

        if ($connLCA){
            $query = "SELECT * FROM [dboReaders].[VW_PurchaseOrdersDetails] WHERE PONumber ='".$PO."' ORDER BY Item";
            $result = sqlsrv_query($connLCA,$query);

            $queryGuardadoUpload = "
            select PONumber,PartNumber
                	,ItemNumber
                	,Tipo
                  ,Units
                  ,CajasBalance
                  ,Bin
                	,case when Tipo = 1 then sum(Tipo)
                	 else sum(Tipo/2) end as num_box

                    ,case when Tipo = 1 then LBS
                	 else sum(LBS) end as peso_box
                from AppsLCA.dbo.Table_UploadItemsPPM
                where Tipo is not null
                group by PONumber,ItemNumber,PartNumber,Tipo,LBS,Units,CajasBalance,Bin
                
				
Union all

select PONumber,PartNumber
                	,ItemNumber
                	,Tipo
                  ,Units
                  ,CajasBalance
                  ,Bin
                	,case when Tipo = 1 then sum(Tipo)
                	 else sum(Tipo/2) end as num_box

                    ,case when Tipo = 1 then LBS
                	 else sum(LBS) end as peso_box
                from AppsLCA.dbo.Table_PODataCSV
                group by PONumber,ItemNumber,PartNumber,Tipo,LBS,Units,CajasBalance,Bin
                order by ItemNumber;";

            /*$queryGuardadoUpload = "
            select PONumber,PartNumber
                	,ItemNumber
                	,Tipo
                  ,Units
                  ,CajasBalance
                  ,Bin
                	,case when Tipo = 1 then sum(Tipo)
                	 else sum(Tipo/2) end as num_box

                    ,case when Tipo = 1 then LBS
                	 else sum(LBS) end as peso_box
                from AppsLCA.dbo.Table_UploadItemsPPM
                where Tipo is not null
                group by PONumber,ItemNumber,PartNumber,Tipo,LBS,Units,CajasBalance,Bin
                order by ItemNumber
                ;";*/

            $resultGuardado = sqlsrv_query($connApps,$queryGuardadoUpload);
              
            /*$queryGuardadoPOData = "
            select PONumber,PartNumber
                  ,ItemNumber
                  ,Tipo
                  ,Units
                  ,CajasBalance
                  ,Bin
                  ,case when Tipo = 1 then sum(Tipo)
                   else sum(Tipo/2) end as num_box
    
                    ,case when Tipo = 1 then LBS
                  else sum(LBS) end as peso_box
                from AppsLCA.dbo.Table_PODataCsv
                where Tipo = 1
                group by PONumber,ItemNumber,PartNumber,Tipo,LBS,Units,CajasBalance,Bin
                order by ItemNumber
                ;";

              $resultPOData = sqlsrv_query($connApps,$queryGuardadoPOData);*/

            /*$queryGuardadoCB = "IF EXISTS (SELECT 1 FROM AppsLCA.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Table_PODataCSV".$ipTabla."')
            BEGIN
            select PONumber,PartNumber
                ,ItemNumber
                ,Tipo
                ,Units
                ,Bin
                ,case when Tipo = 1 then sum(Tipo)
                 else sum(Tipo/2) end as num_box

                  ,case when Tipo = 1 then LBS
                 else sum(LBS) end as peso_box
              from AppsLCA.dbo.Table_PODataCSV".$ipTabla."
              where Tipo = 2
              group by PONumber,ItemNumber,PartNumber,Tipo,LBS,Units,Bin
              order by ItemNumber
              END
              ;";*/

            /*$querySaldoActual = "SELECT PartNumber,Item,[Status],Cantidad_Faltante AS Saldo FROM AppsLCA.dbo.Table_StatusItems WHERE PONumber ='".$PO."' ORDER BY Item";

            $resultSA = sqlsrv_query($connApps,$querySaldoActual);*/
            
            

            

            
            //$resultCB = sqlsrv_query($connApps,$queryGuardadoCB);

            $tabla = "<table class='table table-bordered border-dark table-secondary' id = 'TableItems'>
                    <tr>
                        <th align = 'center'>Item</th>
                        <th align = 'center'>Part Number</th>
                        <th align = 'center'>Vendor</th>
                        <th align = 'center'>Ordered</th>
                        <th align = 'center'>Received in PolyPM</th>
                        <th align = 'center'>SAC</th>
                        <th align = 'center'>Bin</th>
                        <th># Cajas <br>(Cajas Completas)</th>
                        <th>Cantidad Unidades<br>por cajas completas</th>
                        <th>Peso de Cajas<br>(Cajas Completas)</th>
                        <th># Cajas <br>(Cajas Balance)</th>
                        <th>Acciones</th>
                    </tr>";
            
            $filtroPN = '<input type="text" class="form-control" style="width: 300px" onkeyup="doSearch()" list="filtroPorPN" name="inputData" id="inputData" placeholder="Escriba o seleccione un PartNumber">';
            
            $countDatos = 0; //SABER SI ESTÁ ENTRANDO AL WHILE PARA IMPRIMIR LOS DATOS DE LA CONSULTA EN LA TABLA
            
            $cajaBalance = [];
            $cantCB = 1;
            $datos = [];
            /*$statusTB = [];

            while ($row = sqlsrv_fetch_array($resultSA, SQLSRV_FETCH_ASSOC)) {
              
              $statusTB[$countDatos] = $row;
              $countDatos++;
            }

            $countDatos = 0;
            $status = [];*/

            /*$countDatos = 0;

            if (sqlsrv_has_rows($resultCB)){
              while ($item = sqlsrv_fetch_array($resultCB, SQLSRV_FETCH_ASSOC)) {

                $cajaBalance[$countDatos] = $item;
                $countDatos++;
              }
            }*/
            
            $countDatos = 0;
            
            $itemExist = [];

            
            while ($item = sqlsrv_fetch_array($resultGuardado, SQLSRV_FETCH_ASSOC)) {

                $itemExist[$countDatos] = $item;
              $countDatos++;
            }

            $countDatos = 0;
            $flag = 0;
            $countStatus = 0;

            while ($row = sqlsrv_fetch_array($result, SQLSRV_FETCH_ASSOC)) {
              $datos[$countDatos] = $row;
              $countDatos++;
            }

            $countDatos = 0;

            /*foreach($datos as $row){
              $flagPN = 0;
              $PN = '';
              $Item = '';
              $Status = '';
              $CF = '';
              foreach($statusTB as $value){
                if($value["PartNumber"] == $row["PartNumber"]){
                  $flagPN = 1;
                  $PN = $value["PartNumber"];
                  $Item = $value["Item"];
                  $Status = $value["Status"];
                  $CF = $value["Saldo"];
                }

              }
              if($flagPN == 1){
                $status[$countDatos] = [$PN,$Item,$Status,$CF];
              }else{
                $status[$countDatos] = [$row["PartNumber"],$row["Item"],0,0]; 
              }
              $countDatos++;
            }

            $countDatos = 0;*/
            /*$itemExistente = [];
            
            foreach($datos as $row){
              $flagPN = 0;
              $PN = '';
              $item = '';
              $tipo = '';
              $units = 0;
              $CB = 0;
              $bin = '';
              $num_CC = 0;
              $peso_CC = 0;

              foreach($itemExist as $value){
                if($value["PartNumber"] == $row["PartNumber"] && $value["Tipo"] == '1'){

                  $flagPN = 1;
                  $PN = $value["PartNumber"];
                  $item = $value["ItemNumber"];
                  $tipo = $value["Tipo"];
                  $units = intval($value["Units"]);
                  $CB += intval($value["CajasBalance"]);
                  $bin = $value["Bin"];
                  $num_CC += intval($value["num_box"]);
                  $peso_CC = floatval($value["peso_box"]);
                }
              }

              if($flagPN == 1){
                $itemExistente[$countDatos] = [$PN,$item,$tipo,$units,$CB,$bin,$num_CC,$peso_CC];
              }else{
                $itemExistente[$countDatos] = [$row["PartNumber"],$row["Item"],0,0,0,0,0,0];
              }

              $countDatos++;
            }*/

            /*$item2 = [];
            $countDatos = 0;
            foreach($datos as $row){
              $flagPN = 0;
              $PN = '';
              $item = '';
              $tipo = '';
              $units = 0;
              $CB = 0;
              $bin = '';
              $num_CC = 0;
              $peso_CC = 0;

              foreach($itemExist as $value){
                if($value["PartNumber"] == $row["PartNumber"] && $value["Tipo"] == '2'){

                  $flagPN = 1;
                  $PN = $value["PartNumber"];
                  $item = $value["ItemNumber"];
                  $tipo = $value["Tipo"];
                  $units = intval($value["Units"]);
                  $CB += intval($value["CajasBalance"]);
                  $bin = $value["Bin"];
                  $num_CC += intval($value["num_box"]);
                  $peso_CC = floatval($value["peso_box"]);
                }
              }

              if($flagPN == 1){
                $item2[$countDatos] = [$PN,$item,$tipo,$units,$CB,$bin,$num_CC,$peso_CC];
              }else{
                $item2[$countDatos] = [$row["PartNumber"],$row["Item"],0,0,0,0,0,0];
              }

              $countDatos++;
            }*/

            

              $countDatos = 0;
              $countItems = 1;

              foreach ($datos as $row){

                $tabla .= "<tr id='fila-".$countItems."'>
                            <td align = 'center'>".$countItems."</td>
                            <td align = 'center' id= 'pn-".$countItems."'>".$row["PartNumber"]."</td>
                            <td align = 'center'>".$row["Vendor"]."</td>
                            <td align = 'center'><input type='number' value='".$row["Ordered"]."' disabled id='ordered-".$countItems."' class='form-control' style='width: 100px;' placeholder='0'></td>
                            <td align = 'center'><input type='number' value='".$row["Received"]."' disabled id='received-".$countItems."' class='form-control' style='width: 100px;' placeholder='0'></td>
                            <td align = 'center'>".$row["HTSCode"]."</td>
                            <td><input type='text' id='bin-".$countItems."' class='form-control' style='width: 70px;' placeholder=''></td>
                            <td><input type='number' id='numeroCajasCompletas-".$countItems."' class='form-control' style='width: 70px;' placeholder='0' ></td>
                            <td><input type='number' id='unidadesCajasCompletas-".$countItems."' class='form-control' style='width: 70px;' placeholder='0' ></td>
                            <td><input type='number' step='0.01' id='pesoCajasCompletas-".$countItems."' class='form-control' style='width: 70px;' placeholder='' ></td>
                            <td id='col-".$countItems."'><input type='number'id='numCajaBalance-".$countItems."' class='form-control' style='width: 70px;' placeholder='0'></td>
                            <td><button type='button' class='btn btn-primary' onclick='AñadirCeldas(this)' id='button-".$countItems."'>Agregar Cajas<br>de Balance</button>
                              
                          </tr>";
                
                $countDatos++;
                $countItems++;
              }




                if ($countDatos > 0){
                  $countItems -= 1;
                  $tabla .= "</table>
                            <input type='hidden' id='items' value='$countItems'>";
                  $response = $filtroPN.$tabla;
                  echo $response;
                }else{

                    $alerta = "<div class='alert alert-danger' role='alert'>
                    <h3>No se encontraron datos para esta PONumber: ".$PO.", intente ingresar otra</h3>
                            </div>";
                    echo $alerta;
                }
              
                
            //}
            /*elseif (count($datos) == 1)

              $tabla .= "<tr>
                            <td colspan='8'><h3>NO SE ENCONTRARON DATOS DE ESA PONUMBER, INTENTE CON UNA DIFERENTE</h3></td>
                        </tr>";

              echo $tabla;
            }*/
            
            

        }else{
            die(print_r(sqlsrv_errors(),true));
        }

?>
<!-- <script>
function cargarTabla() {
  var itemSeleccionado = document.getElementById("selectItem").value;
  var textoIngresado = document.getElementById("textInput").value;

  // Crear objeto XMLHttpRequest
  var xhr = new XMLHttpRequest();

  // Configurar la solicitud
  xhr.open("GET", "obtener_datos.php?item=" + itemSeleccionado + "&texto=" + textoIngresado, true);

  // Definir qué hacer cuando la solicitud se complete
  xhr.onload = function() {
    if (xhr.status === 200) {
      // La solicitud fue exitosa
      // Obtener los datos de respuesta
      var datos = JSON.parse(xhr.responseText);
      
      // Construir la tabla
      var tabla = "<tr><th>Columna 1</th><th>Columna 2</th></tr>";
      for (var i = 0; i < datos.length; i++) {
        tabla += "<tr><td>" + datos[i].columna1 + "</td><td>" + datos[i].columna2 + "</td></tr>";
      }
      
      // Mostrar la tabla en el HTML
      document.getElementById("tablaDatos").innerHTML = tabla;
    } else {
      // Hubo un error en la solicitud
      console.error("Error al realizar la solicitud: " + xhr.status);
    }
  };

  // Enviar la solicitud
  xhr.send();
}
</script> -->

