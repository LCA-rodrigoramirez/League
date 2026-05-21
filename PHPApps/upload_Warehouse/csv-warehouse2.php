<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="assets/csv-warehouse.css">
    <link rel="stylesheet" href="assets/fontawesome-free-6.3.0-web/css/all.css">
    <link href="assets/bootstrap.min.css" rel="stylesheet" crossorigin="anonymous">
    <title>Purchase Order Upload</title>
</head>
<script src="assets/sweetalert2.all.min.js"></script>
<script src="assets/csv-warehouse.js"></script>


<body >

    <br><br><br>
    <h1>Purchase Order CSV Data</h1>
    <hr>

    <div id="container" class="border border-info">
        <form id="form-PO" action="procesarDatos/generarCSV.php" method="post">
            <div class="row align-items-left">
                <div class="col-4">
                    <div class="mb-3">
                        <label for="purchaseOrder" class="form-label">Ingrese PO</label>
                        <input type="text" name="purchaseOrder" id="purchaseOrder" class="form-control" placeholder="PONumber" required>
                    </div>
                </div>

                <!--<div class="col-4">
                    <div class="mb-3">
                        <label for="dateIngress" class="form-label">Fecha de Ingreso</label>
                        <input type="date" name="dateIngress" id="dateIngress" class="form-control" placeholder="Fecha de ingreso" required>
                    </div>
                </div>-->
            </div>
            

            <div class="row">
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
                        <button type="button" id="showTable" onclick="MostrarTabla()" class="btn btn-dark">Mostrar Tabla</button>
                    </div>
                    
                </div>
            </div>

            <div class="row">
                
                <div class="col-4" id="save">

                </div>
                <div class="col-8" id="enviar">

                </div>
            </div>
                
            

            <div id="tabla">
        
            </div>
            




            
        </form>
    </div>

  
</body>
</html>