<?php
    
    include_once("Config/Conexion.php"); 

    $recivslip = $_POST['recivslip'];
    $ponumber = $_POST['ponumber'];

    if(!$recivslip || !$ponumber){
        print_r('Debe definir una Orden y un RecivedSlip para Ejecutar la Consulta.');
        
    }

    echo '<script>
            
                document.getElementById("recivslip").value = '.$recivslip.';
                document.getElementById("ponumber").value = '.$ponumber.';
            
        </script>
        ';

        
    $q_body = " SELECT RollNumber,Code as ContainerCode,PartNumber, [Container unit Cost] as UnitCost
                        ,[On Hand] as Quantity , ([Container unit Cost] * [On Hand]) as TotalCost
                from LCA.[dboReaders].[VW_PurchaseOrdersDetailsVerJC_Ver2] WITH (NOLOCK)
                where ShipNumber = '$recivslip'
                order by PartNumber
              ";

    $query_body = sqlsrv_query($conexion,$q_body,array(), array( "Scrollable" => SQLSRV_CURSOR_KEYSET ));  
    //var_dump($query_body);
    /*
    $po_number = $_POST['ponumber'];

    $dataObject_head = $conexion->prepare("SELECT DISTINCT VendorNumber,OrigVendorName--,PartSummary
                                            ,ReceiveNumber,InvoiceNumber
                                        FROM [Financial].[dboReaders].[VW_Purchase_ReceiveWarehouse]
                                        WHERE ReceiveNumber = 'REC60787'
                                        AND Quantity > 0 ");
    $dataObject_head->execute();
    $query_head = $dataObject_head->fetchAll(PDO::FETCH_ASSOC);
    */
?>
<!doctype html>
<html lang="en">
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>MO Container CSV</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.1/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-4bw+/aepP/YC94hEpVNVgiZdgIC5+VKNBQNGCHeKRQN+PtmoHDEXuppvnDJzQIu9" crossorigin="anonymous">
    <!--<script src='https://kit.fontawesome.com/a076d05399.js' crossorigin='anonymous'></script>-->
    <script src="https://code.jquery.com/jquery-1.12.4.js"></script>
  </head>
  <body>
  <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script >
            function mayuscula(e){
                e.value = e.value.toUpperCase();
            }


            function mostrarInfo(){

                console.table(checkedBox);
                var mientras = JSON.stringify(checkedBox);

                var result = new XMLHttpRequest();

                var url = 'UploadCSVMO.php';

                var recivslip = document.getElementById('recivslip').value;
                var ponumber = document.getElementById('ponumber').value;

                console.log(mientras);

                result.open('POST',url,true);
                result.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

                //wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
                result.responseType = "blob";
                result.onload = function () {
                    if (result.status === 200) {
                        var link = document.createElement("a");
                        var blob = result.response
                            link.href = window.URL.createObjectURL(blob);
                            link.download = "Containers to MO "+ponumber+".csv"; // Cambia esto al nombre que desees para el archivo
                            document.body.appendChild(link);
                            link.click();
                            document.body.removeChild(link);
                    }else{
                        Swal.fire({
                                title: "No se pudo crear el archivo",
                                text: "El PartNumber de los Contenedores no coincide con La MO ingresada o La MO ingresada no posee Barcode, Favor verificar.",
                                icon: "error",
                                showConfirmButton: true,
                                showCancelButton: false,
                            });
                    }
                    
                }
                //wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww

                result.send('cadena='+mientras+'&recivslip='+recivslip+'&ponumber='+ponumber);
                
            }

            function clean(){
                var var1 = document.getElementById('resultado');
                var1.innerHTML = '';
                document.getElementById('recivslip').value = '';
                document.getElementById('ponumber').value = '';

            }
                

    </script>
    <nav class="navbar bg-body-tertiary">
        <div class="container-fluid">
        <!--<h1>Prueba CRUD</h1>-->
        <a class="navbar-brand" href="#"><h2>Creacion de Archivos CSV, relacion MO -> Container.</h2>(MOVenta) - Paso 3  </a>
        </div>
    </nav>    
    <br>

    <!--<form action="UploadCSVMO.php" method="POST" >-->
    <form action="MOVenta.php" method="POST" id="data">
        <div class="container" style="overflow:hidden;">
            
            <div class="item" style="float:left;">    
                <input class="form-control s-m" type="text" maxlength="35" placeholder="Ingrese Recived Slip" aria-label="default input example" name="recivslip" id="recivslip" value="<?php echo isset($_POST['recivslip']) ? htmlspecialchars($_POST['recivslip']) : ''; ?>">
            </div>

            <div class="item" style="float:left;">    
                <input class="form-control s-m" type="text" maxlength="35" placeholder="Ingrese MO destino" aria-label="default input example" name="ponumber" id="ponumber" value="<?php echo isset($_POST['ponumber']) ? htmlspecialchars($_POST['ponumber']) : ''; ?>">
            </div>

            <div class="item" style="float:left;">
                <input type="submit" class="btn btn-danger" value="Consultar">
                <input type="button" class="btn btn-success" onClick="clean()" value="Limpiar" id="btClean">
            </div>

            <div id="detalle">
                
            </div>
            
        </div>
        
            
    <br>
    

    
    <div class="container border" id="resultado">
    
   
                            <br>
                            
                            <table class="table">
                                <thead>
                                    <tr class="table-success">
                                        <th scope="col">No.</th>
                                        <th scope="col">Container Code</th>
                                        <th scope="col">Part Number</th>
                                        <th scope="col">UnitCost</th>
                                        <th scope="col">Quantity</th>
                                        <th scope="col">TotalCost</th>
                                        <th scope="col"  style="text-align:center;">
                                                <a href="#" id="marcarTodo">Marcar</a> |
                                                <a href="#" id="desmarcarTodo">Desmarcar</a> |
                                                <input class="form-check-input" style="form-check-input-width:2em;" type="checkbox" value="1" id="flexCheckCheckedAll" checked>
                                        </th>
                                    </tr>
                                </thead>
                                <tbody>

                                    <?php
                                        $j = 1;
                                        $k = 0;
                                        while ($fila2 = sqlsrv_fetch_array($query_body)){        
                                    ?>
                                        <tr>
                                            <td scope="row"><?= $j ?></td>
                                            <td scope="row"><?= $fila2['ContainerCode'] ?></td>
                                            <td scope="row"><?= $fila2['PartNumber'] ?></td>
                                            <td scope="row"><?= $fila2['UnitCost'] ?></td>
                                            <td scope="row"><?= $fila2['Quantity'] ?></td>
                                            <td scope="row"><?= $fila2['TotalCost'] ?></td>
                                            <td scope="row" style="text-align:center;">
                                                <input class="form-check-input" style="form-check-input-width:2em;" type="checkbox" value="<?= $fila2['ContainerCode'] ?>" id="flexCheckChecked" checked>
                                            </td>
                                        </tr>  

                                    <?php
                                        $j = $j + 1;
                                        $k = $k + 1;

                                        }
                                    ?>  

                                </tbody>
                            </table>

                
            <div class="item" style="float:right;">
                <input type="button" class="btn btn-primary" onClick="mostrarInfo();" value="Enviar Info">
            </div>     
        </form>    
    </div>
    <br>
                    

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.1/dist/js/bootstrap.bundle.min.js" integrity="sha384-HwwvtgBNo3bZJJLYd8oVXjrBZt8cqVSpeBNS5n7C8IVInixGAoxmnlMuBnhbgrkm" crossorigin="anonymous"></script>
    </body>

    <script>
        var checkedBox;            
        /*  funcion que me crea un array en donde estan contenidos los checkboxes marcados  */
        $(document).on('click', 'input:checkbox', getCheckedBox);

            getCheckedBox();

            function getCheckedBox() {
            
            checkedBox = $.map($('input:checkbox:checked'), 
            //checkedBox = $.map($('#flexCheckChecked:checked'), 
                                    function(val, i) {
                                        return val.value;
                                    });
            console.clear();
            console.table(checkedBox);
        }

        /*  Funcion de jQuery que me permite la marcacion y desmarcacion de todos los Checkboxes  */ 
        $("#flexCheckCheckedAll").on("click", function() {  
            $(".form-check-input").prop("checked", this.checked);  
            //$("#flexCheckChecked").prop("checked", this.checked);  
        });


    </script>    

</html>