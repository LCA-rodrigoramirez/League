<?php 

    $bodega = $_GET["item"];
    $PO = $_GET["texto"];

    $serverName = "192.168.1.53";
    $connectionOptions = array(
            "Database" => "LCA",
            "Uid" => "sa",
            "PWD" => "Belerofonte197"
    );

    $conn = sqlsrv_connect($serverName,$connectionOptions);

        if ($conn){
            $query = "SELECT * FROM [dboReaders].[VW_PurchaseOrdersDetails] WHERE PONumber ='".$PO."' ORDER BY Item";
            
            $result = sqlsrv_query($conn,$query);

            $tabla = "<table class='table table-bordered border-dark table-secondary'>
                    <tr>
                        <th align = 'center'>Item</th>
                        <th align = 'center'>Part Number</th>
                        <th align = 'center'>Vendor</th>
                        <th align = 'center'>Ordered</th>
                        <th align = 'center'>Received</th>
                        <th align = 'center'>SAC</th>
                        <th># Cajas <br>(Cajas Completas)</th>
                        <th>Cantidad Unidades<br>por cajas completas</th>
                        <th>Peso de Cajas<br>(Cajas Completas)</th>
                        <th># Cajas <br>(Cajas Balance)</th>
                        <th>Cantidad Unidades<br>por cajas de balance</th>
                        <th>Peso de Cajas<br>(Cajas Balance)</th>
                    </tr>";
            
            $countDatos = 0; //SABER SI ESTÁ ENTRANDO AL WHILE PARA IMPRIMIR LOS DATOS DE LA CONSULTA EN LA TABLA

              while ($row = sqlsrv_fetch_array($result, SQLSRV_FETCH_ASSOC)) {
                $countDatos++;
                $datosConsulta[] = $row;
                $tabla .= "<tr>
                            <td align = 'center'><input type='text' class='form-control' disabled name='item[]' value='".$row["Item"]."' style='width: 50px;' ></td>
                            <td align = 'center'><input type='text' class='form-control' disabled name='partNumber[]' value='".$row["PartNumber"]."' style='width: 200px;' ></td>
                            <td align = 'center'>".$row["Vendor"]."</td>
                            <td align = 'center'>".$row["Ordered"]."</td>
                            <td align = 'center'>".$row["Received"]."</td>
                            <td align = 'center'><input type='text' class='form-control' disabled name='SAC[]' value='".$row["HTSCode"]."' style='width: 140px;'></td>
                            <td><input type='number' name='numeroCajasCompletas[]' class='form-control' placeholder='Cantidad de cajas'></td>
                            <td><input type='number' name='unidadesCajasCompletas[]' class='form-control' placeholder='Cantidad de unidades'></td>
                            <td><input type='text' name='pesoCajasCompletas[]' class='form-control' placeholder='Peso de caja'></td>
                            <td><input type='number' name='numeroCajasBalance[]' class='form-control' placeholder='Cantidad de cajas'></td>
                            <td><input type='number' name='unidadesCajasBalance[]' class='form-control' placeholder='Cantidad de unidades'></td>
                            <td><input type='text' name='pesoCajasBalance[]' class='form-control' placeholder='Peso de caja'></td>
                        </tr>";
                }

                if ($countDatos > 0){
                    $tabla .= "</table>";
                    echo $tabla;
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

