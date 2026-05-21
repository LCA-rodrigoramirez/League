//Mostrar tabla, primer botón del inicio de la página
function MostrarTabla(){
    var selectBodega = document.getElementById('bodega');
    var inputPO = document.getElementById('purchaseOrder');
    document.getElementById("showTable").textContent = "Mostrar Tabla";
    //var fecha = document.getElementById('dateIngress');
    
        if (inputPO.value != "" && selectBodega.value != "Seleccione una bodega" /*&& fecha.value != ""*/){

                var imprimirBoton = document.getElementById("enviar");
                var botonGuardar = document.getElementById("save");

                // Crear objeto XMLHttpRequest
                var xhr = new XMLHttpRequest();

                // Configurar la solicitud
                xhr.open("GET", "procesarDatos/datosTabla.php?item=" + selectBodega.value + "&texto=" + inputPO.value, true);

                // Definir qué hacer cuando la solicitud se complete
                xhr.onload = function() {
                  if (xhr.status === 200) {
                    // La solicitud fue exitosa
                    // Mostrar la tabla en el HTML
                    //document.getElementById("tabla").textContent = "Datos recibidos: " + datos[1];
                    document.getElementById("tabla").innerHTML = xhr.responseText;
                    var countDatos = document.getElementById("items").value;
                    botonGuardar.innerHTML = "<button type='button' id='save-"+countDatos+"' onclick='Guardar(this)' class='btn btn-info'>"+
                    "<i class='fa-solid fa-cloud-arrow-up'>&nbsp;&nbsp;&nbsp;1.Guardar Items</i></button>"
                    ;

                    imprimirBoton.innerHTML = "<button type='submit' id='Enviar' name='Enviar' class='btn btn-success'><i class='fa-solid fa-file-csv'>&nbsp;&nbsp;&nbsp;2.CSV Materials</i></button>";
                    imprimirBoton.innerHTML += "<button type='submit' id='EnviarBin' name='EnviarBin' class='btn btn-success'><i class='fa-solid fa-file-csv'>&nbsp;&nbsp;&nbsp;3.Containers to Bin</i></button>";

                  } else {
                    // Hubo un error en la solicitud
                    Swal.fire({
                        title: "Error al intentar obtener la información",
                        text: xhr.responseText+"\n"+xhr.status,
                        icon: "warning",
                        buttons: true,
                    });
                  }
                };
                
                
                // Enviar la solicitud
                xhr.send();
            
        }else{

            Swal.fire({
                title: "Faltan Datos",
                text: "Ingrese una PO para cargar los datos",
                icon: "warning",
                buttons: true,
            });
        }
}

//Filtrar por PartNumber
document.getElementById('inputData').addEventListener('input', function() {
    var ciudadSeleccionada = this.value;
    var filas = document.querySelectorAll('TablaItems tr');
  
    for (var i = 1; i < filas.length; i++) { // Empezamos desde 1 para omitir la fila de encabezado
      var celdaCiudad = filas[i].getElementsByTagName('td')[1]; // La tercera celda contiene la ciudad
      if (ciudadSeleccionada === '' || celdaCiudad.textContent === ciudadSeleccionada) {
        filas[i].style.display = ''; // Mostrar la fila si coincide con la ciudad seleccionada o si no se ha seleccionado ninguna ciudad
      } else {
        filas[i].style.display = 'none'; // Ocultar la fila si no coincide con la ciudad seleccionada
      }
    }
  });

//Botón Agregar Cajas de Balance de la tabla
function AñadirCeldas(elemento){

    var idBoton = elemento.id;

    var identificarItem = idBoton.substring(7);

    var celdaTarget = document.getElementById("col-"+identificarItem);

    var numeroCajasBalance = document.getElementById("numCajaBalance-"+identificarItem).value;

    var correlativoBalance = 1;

    if (numeroCajasBalance === null || numeroCajasBalance === undefined || numeroCajasBalance === ""){

        Swal.fire({
            title: "Faltan Datos",
            text: "Ingrese un numero de cajas de balance",
            icon: "warning",
            buttons: true,
        });
    }else{
        var tablaCajasBalance = "<input type='number'id='numCajaBalance-"+identificarItem+"' value='"+numeroCajasBalance+"' class='form-control' placeholder='Cantidad de cajas'>"+
        "<table class='table table-bordered'>"+
        "<tr><th>Caja Balance</th><th>Unidades por<br>caja de balance</th><th>Peso por<br>caja de balance</th></tr>";

        for(var i = 0; i < numeroCajasBalance;i++){

            tablaCajasBalance += "<tr id='fil-"+identificarItem+"-"+correlativoBalance+"'>"+
            "<td id='col1-"+identificarItem+"-"+correlativoBalance+"'>"+correlativoBalance+"</td>"+
            "<td><input class='form-control' type='number' id='"+identificarItem+"-caja"+correlativoBalance+"' style='width: 70px;'></td>"+
            "<td><input type='number' step='0.01' class='form-control' id='"+identificarItem+"-pesoCaja"+correlativoBalance+"' style='width: 70px;'></td>"+
            "<td align='center'><button type='button' onclick='Eliminar(this)' id='"+correlativoBalance+":buttonD-"+identificarItem+"' class='btn btn-success'><i class='fa-solid fa-trash'></i></button></td></tr>";

            correlativoBalance++;
        }

        tablaCajasBalance += "</table>";

        celdaTarget.innerHTML = tablaCajasBalance

    }
}

//Botón Guardar Items de la tabla
function Guardar(elemento){

    var selectBodega = document.getElementById('bodega');
    var inputPO = document.getElementById('purchaseOrder');
    //var fecha = document.getElementById('dateIngress');

if (selectBodega.value != "Seleccione una bodega"){
    var idBoton = elemento.id;

    var countItems = parseInt(idBoton.substring(5));

    var datosCB = [];

    var datosCC = [];

    var datosCCNoValidos = [];

    var datosCBNoValidos = [];
    var idCaja = 0;

    var idCajaC = 0

    for (var i = 1; i <= countItems; i++){

            var ordered = document.getElementById("ordered-"+i).value;

            var received = document.getElementById("received-"+i).value;

            var numCajasCompletas = document.getElementById("numeroCajasCompletas-"+i).value;

            var unidadesCajasCompletas = document.getElementById("unidadesCajasCompletas-"+i).value;

            var pesoCajasCompletas = document.getElementById("pesoCajasCompletas-"+i).value;

            var numeroCajasBalance = document.getElementById("numCajaBalance-"+i).value;

            var bin = document.getElementById("bin-"+i).value;

            if (bin == ''){
                bin = "CDN";
            }

            var partNumber = document.getElementById("pn-"+i).textContent

            var totalFaltante = ordered - received            

            var totalCB = 0

            var totalCC = numCajasCompletas*unidadesCajasCompletas;

            var isNull = false;

            if (numCajasCompletas != "" && unidadesCajasCompletas != "" && pesoCajasCompletas != "" && bin != ""){

                if (numeroCajasBalance == ''){
                    numeroCajasBalance = 0;
                    
                }

                for (var j = 1; j <= parseInt(numeroCajasBalance); j++){
                
                    let caja = document.getElementById(i+"-caja"+j);
                
                    if (typeof caja === "undefined" || caja === null){
                    
                        isNull = true;

                    }else{
                        isNull = false;
                    }
                }

                console.log(numeroCajasBalance);

                if (isNull == false){

                    for (var j = 1; j <= parseInt(numeroCajasBalance);j++){
                    
                        let caja = document.getElementById(i+"-caja"+j);
                        let pesoCaja = document.getElementById(i+"-pesoCaja"+j);

                        console.log(caja.value);
                        totalCB += parseInt(caja.value);
                    
                        datosCB[idCaja] = [i,caja.value,pesoCaja.value];

                        console.log(datosCB);
                    
                        idCaja++;
                    }
                }else{

                    datosCBNoValidos += [i]+"-"+partNumber+",";
                }

                var totalCajas = totalCC + totalCB;
                
                datosCC[idCajaC] = [i,partNumber,numCajasCompletas,unidadesCajasCompletas,pesoCajasCompletas,numeroCajasBalance,bin,totalCajas];
                idCajaC++;
            }

    }

    var datosCBJSON = JSON.stringify(datosCB);
    var datosCCJSON = JSON.stringify(datosCC);

    if (datosCBNoValidos.length == 0){

        if (datosCCNoValidos.length == 0){

            // Crear objeto XMLHttpRequest
            var xhr = new XMLHttpRequest();
            
            Swal.fire({
                title: "¿Está seguro de guardar?",
                text: "Confirme que los datos de las cajas estén "+
                "correctos y completos, luego confirme que quiere guardarlos",
                icon: "warning",
                showCancelButton: true,
                confirmButtonColor: '#3085d6',
                cancelButtonColor: '#d33',
                cancelButtonText: 'Cancelar',
                confirmButtonText: 'Sí, guardar'
            }).then((result) =>{
                if (result.isConfirmed){
                    for (var i = 0; i < datosCC.length;i++){
                        for (var j = 1; j < datosCC[i][5];j++){
                            document.getElementById(datosCC[i][0]+"-caja"+j).readOnly = true;
                            document.getElementById(datosCC[i][0]+"-pesoCaja"+j).readOnly = true;
                        }
                    }
                    
                    console.log(datosCCJSON);
                    console.log(datosCBJSON);
                    // Configurar la solicitud
                    xhr.open("GET", "procesarDatos/guardarItems.php?item=" + selectBodega.value + "&texto=" + inputPO.value +
                    "&datosCB="+ datosCBJSON +"&datosCC=" + datosCCJSON +"&countItems="+countItems, true);
                
                    xhr.onload = function() {
                    if (xhr.status === 200) {
                    
                        Swal.fire({
                            title: "Información de acción",
                            text: xhr.responseText,
                            icon: "warning",
                            buttons: true,
                        });

                        MostrarTabla();
                    } else {
                        // Hubo un error en la solicitud
                        Swal.fire({
                            title: "Error al intentar guardar",
                            text: xhr.responseText+"\n"+xhr.status,
                            icon: "warning",
                            buttons: true,
                        });
                    }
                    }
                
                    
                    // Enviar la solicitud
                    xhr.send();
                
                }
            });
        }else{
            var datosLimite = JSON.stringify(datosCCNoValidos);
            Swal.fire({
                title: "Límite superado",
                text: "Está ingresando más prendas de las ordenadas en el/los Items: \n"+
                datosLimite,
                icon: "warning",
                buttons: true,
            });
        }
    }else{
        var datosSinCB = JSON.stringify(datosCBNoValidos);
        Swal.fire({
            title: "Faltan Datos",
            text: "Definió un número de cajas de balance, pero no las ha agregado en el/los Items: \n"+datosSinCB,
            icon: "warning",
            buttons: true,
        });
    }
}
    
}

//Al agregar cajas de balance, aparece el botón Eliminar, que tiene un basurero de ícono
function Eliminar(elemento){

    var correlativo = elemento.id.split(":");
    var identificarCorrelativo = correlativo[0];
    var identificarItem = correlativo[1].substring(8);
    var filaEliminar = document.getElementById("fil-"+identificarItem+"-"+identificarCorrelativo);
    
    filaEliminar.remove();
    var numeroCajasBalance = document.getElementById("numCajaBalance-"+identificarItem).value;
    console.log(identificarCorrelativo);
    if (numeroCajasBalance != identificarCorrelativo){
        for(var i = identificarCorrelativo; i < numeroCajasBalance;i++){
            var nuevoCorrelativo = parseInt(identificarCorrelativo) + 1;
            var actualizarCorrelativo = document.getElementById("col1-"+identificarItem+"-"+nuevoCorrelativo);

            actualizarCorrelativo.textContent = identificarCorrelativo;
        }
    }

    numeroCajasBalance -= 1;

    var inforCajaBalance = document.getElementById("numCajaBalance-"+identificarItem);

    inforCajaBalance.setAttribute("value",numeroCajasBalance);;
    
    
}

document.getElementById("form-PO").addEventListener("keypress", function(event) {
    // Si la tecla presionada es Enter (código 13), evita el envío del formulario
    if (event.keyCode === 13) {
      event.preventDefault();
    }
  });

  document.getElementById("purchaseOrder").addEventListener("keypress", function(event) {
    // Si la tecla presionada es Enter (código 13), evita el envío del formulario
    if (event.keyCode === 13) {
      event.preventDefault();
    }
  });

  function doSearch()

  {

      const tableReg = document.getElementById('TableItems');

      const searchText = document.getElementById('inputData').value.toLowerCase();

      let total = 0;



      // Recorremos todas las filas con contenido de la tabla

      for (let i = 1; i < tableReg.rows.length; i++) {

          // Si el td tiene la clase "noSearch" no se busca en su cntenido

          if (tableReg.rows[i].classList.contains("noSearch")) {

              continue;

          }



          let found = false;

          const cellsOfRow = tableReg.rows[i].getElementsByTagName('td');

          // Recorremos todas las celdas

          for (let j = 0; j < cellsOfRow.length && !found; j++) {

              const compareWith = cellsOfRow[j].innerHTML.toLowerCase();

              // Buscamos el texto en el contenido de la celda

              if (searchText.length == 0 || compareWith.indexOf(searchText) > -1) {

                  found = true;

                  total++;

              }

          }

          if (found) {

              tableReg.rows[i].style.display = '';

          } else {

              // si no ha encontrado ninguna coincidencia, esconde la

              // fila de la tabla

              tableReg.rows[i].style.display = 'none';

          }

      }

  }