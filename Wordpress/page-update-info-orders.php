<?php
get_header();
?>

<script src="http://www.l2brandca.com/wp-content/themes/twentyseventeen/flexmonster/flexmonster.js"></script>
<script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js"></script>
<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/js/bootstrap.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
<link rel="stylesheet" type="text/css" href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css">

<!-- ////////////////////////////////////////////////////////////////////////
    ///////////////////////HTML////////////////////////////////////
    //////////////////////////////////////////////////////////////////////// -->

<?php
require_once("flexmonster/configDataBaseLeague.php");
require_once("flexmonster/Encryp.php");
?>

<BR>

<div class="container">

    <div class="row">
        <div class="col-md-4">
        </div>
        <div class="col-md-4">
            <form method="post" action="<?php echo $_SERVER['PHP_SELF']; ?>">
                <div class="input-group mb-3">
                    <div class="input-group-append">
                        <label class="input-group-text" for="inputGroupSelect02">PWModulo</label>
                    </div>
                    <input type="text" id="PWModulo" name="PWModulo" class="form-control" value="">
                    
                </div>
                <button type="submit" class="btn btn-primary" id="enviarListado" name="enviarListado" value="Submit Form">Ejecutar Procedimiento</button>
            </form>
        </div>
        <div class="col-md-4">
        </div>

    </div>
    <!--fin row-->
</div>
<!--fin container-->

<?php if (isset($_POST['enviarListado'])) { ?>
    <div id="pivot-container">Test FlexMonter</div>
<?php } ?>

<?php
global $Query;
global  $Type;
global $QueryFlexEnc;
if (isset($_POST['enviarListado'])) {



$PWModulo = $_POST["PWModulo"];

    //Asignación de Query a consultar
    // $Query = "SELECT * FROM [dboReaders].[VW_Kardex_PPM_ADUANA] WHERE [IM5] = '".$_POST['TextOrigIM5']."' ORDER BY [OrdenData]";

    // $Query = "SELECT A.* ,CASE WHEN A.[TT_Sum]  = 1 THEN A.[DATOSALDO] ELSE SUM(A.[DATOSALDO]) OVER (PARTITION BY A.[KeyData] ORDER BY A.[OrdenData] ASC) END AS [Saldo] FROM [dboReaders].[VW_Kardex_PPM_ADUANA] AS A WHERE [IM5] = '" . $_POST['TextOrigIM5'] . "' ORDER BY [OrdenData]";
    $Query = "EXEC [dbo].[sp_Upload_InfoOrders_to_PolyPM_withData_2] @PWModulo = '$PWModulo' ";
   
    // $Query = "EXEC lca.[dboReaders].[Check_Sales_Prices] @WayBill = '20220315-NOVA'";
    //echo $Query;

    // SELECT * FROM [dboReaders].[VW_Kardex_PPM_ADUANA] WHERE [IM5] = '".$_POST['TextOrigIM5']."' ORDER BY [OrdenData]";
    //Tipo para diferentes consultas:
    //SQL_APPSLCA   = SQL SERVER BASE DE DATOS APPSLCA
    //SQL_LCA       = SQL SERVER BASE DE DATOS LCA
    //MARIA_WORDPRESS = MARIA DB BASE DE DATOS WORDPRESS
    $Type = 'SQL_APPSLCA';
    //$Type = "SQL_LCA_1_93";
    // $Type = "SQL_APPSLCA_E";
    $QueryFlexEnc = encrypt($Query, $KeyEncrypQuery);               //ENCRIPTADO DE QUERY PARA ENVIO     

} else {
    //echo "Noooooooooooooo";
}
?>



<?php 

if (isset($_POST['enviarListado'])) { ?>
    <script>
        var pivot = new Flexmonster({
            container: "pivot-container", //Div donde se mostrará la pivote
            licenseKey: " <?php echo $LicenceFlexMonter ?> ", //Licencia en linea de FlexMonter (ver archivo configDataBaseLeague.php)
            componentFolder: "http://www.l2brandca.com/wp-content/themes/twentyseventeen/flexmonster/", //Carpeta requerida para FlexMonter
            toolbar: true,
            // reportcomplete: showAlert,
            customizeCell: customizeCellFunction,
            beforetoolbarcreated: customizeToolbar,
            report: {
                dataSource: {
                    type: "csv", //Tipo de dato devuelto del link de filename
                    /* URL to the Data Compressor PHP */
                    "filename": "http://www.l2brandca.com/wp-content/themes/twentyseventeen/flexmonster/DataBase.php?Type=<?php echo $Type ?>&Query=<?php echo $QueryFlexEnc ?>"
                }



                /////////////////////////////////////////////////
                //Agregar luego de hacer pivote
                // #region "Data solo para la pivote"
                ,
                "slice": {
        "rows": [
            {
                "uniqueName": "PWModulo",
                "sort": "unsorted"
            },
            {
                "uniqueName": "PONumber",
                "sort": "unsorted"
            },
            {
                "uniqueName": "Location_Desc",
                "sort": "unsorted"
            },
            {
                "uniqueName": "Code",
                "sort": "unsorted"
            },
            {
                "uniqueName": "LogoStyleName",
                "sort": "unsorted"
            },
            {
                "uniqueName": "ApplicationType",
                "sort": "unsorted"
            },
            {
                "uniqueName": "OrderTypePPM",
                "sort": "unsorted"
            },
            {
                "uniqueName": "OrderTypeTechnique",
                "sort": "unsorted"
            },
            {
                "uniqueName": "Sequence_Qty",
                "sort": "unsorted"
            },
            {
                "uniqueName": "StitchCount",
                "sort": "unsorted"
            },
            {
                "uniqueName": "ThreadID",
                "sort": "unsorted"
            }
        ],
        "measures": [

        ],
        "expands": {
            "expandAll": true
        },
        "drills": {
            "drillAll": true
        },
        "flatOrder": [
        ]
    },
    "options": {
        "grid": {
            "type": "flat",
            "showTotals": "off",
            "showGrandTotals": "off"
        }
    },
    "conditions": [

    ],


            }


        });






        /////FUNCION QUE MODIFICA TOOLBAR
        function customizeToolbar(toolbar) {
            var tabs = toolbar.getTabs(); // get all tabs from the toolbar
            toolbar.getTabs = function() {
                delete tabs[0]; //quitar boton Connect
                delete tabs[1]; //quitar boton Open
                delete tabs[2]; //quitar boton Save JSON
                //delete tabs[3]; //quitar boton EXPORT DATA
                tabs.unshift(
                    {
                        id: "Code-Report1",
                        title: "All Data",
                        handler: varReport1,
                        // icon: "<img width = '48px' height = '48px' src='http://www.l2brandca.com/wp-content/plugins/download-manager/assets/file-type-icons/flatform2.png' class=\"present\" border='0' alt='gift-box'/>" 
                        icon: "<img width = '36px' height = '36px' src='http://www.l2brandca.com/wp-content/plugins/download-manager/assets/file-type-icons/hoja-de-calculo (3).png' class=\"present\" border='0' alt='gift-box'/>"
                    }, 
                    // {
                    //     id: "Code-Report2",
                    //     title: "Pivot",
                    //     handler: varReport2,
                    //     icon: "<img width = '55px' height = '55px' src='http://www.l2brandca.com/wp-content/plugins/download-manager/assets/file-type-icons/cobija-desenvuelta (1).png' class=\"present\" border='0' alt='gift-box'/>"
                    // }

                );
                return tabs;
            }
        }




        //SETEO DE REPORTE 1
        //DATA DE REPORTE ALL DATA
        var varReport1 = function() {
            setReport1()
        };

        function setReport1() {

            pivot.setReport({
                dataSource: {
                    type: "csv", //Tipo de dato devuelto del link de filename
                    /* URL to the Data Compressor PHP */
                    "filename": "http://www.l2brandca.com/wp-content/themes/twentyseventeen/flexmonster/DataBase.php?Type=<?php echo $Type ?>&Query=<?php echo $QueryFlexEnc ?>"
                },
                "slice": {
        "rows": [
            {
                "uniqueName": "PWModulo",
                "sort": "unsorted"
            },
            {
                "uniqueName": "PONumber",
                "sort": "unsorted"
            },
            {
                "uniqueName": "Location_Desc",
                "sort": "unsorted"
            },
            {
                "uniqueName": "Code",
                "sort": "unsorted"
            },
            {
                "uniqueName": "LogoStyleName",
                "sort": "unsorted"
            },
            {
                "uniqueName": "ApplicationType",
                "sort": "unsorted"
            },
            {
                "uniqueName": "OrderTypePPM",
                "sort": "unsorted"
            },
            {
                "uniqueName": "OrderTypeTechnique",
                "sort": "unsorted"
            },
            {
                "uniqueName": "Sequence_Qty",
                "sort": "unsorted"
            },
            {
                "uniqueName": "StitchCount",
                "sort": "unsorted"
            },
            {
                "uniqueName": "ThreadID",
                "sort": "unsorted"
            }
        ],
        "measures": [

        ],
        "expands": {
            "expandAll": true
        },
        "drills": {
            "drillAll": true
        },
        "flatOrder": [
        ]
    },
    "options": {
        "grid": {
            "type": "flat",
            "showTotals": "off",
            "showGrandTotals": "off"
        }
    },
    "conditions": [

    ],

            });
        }



        var highlightRows = {};
        var orderTypeByRow = {};
        var mismatchRows = {};
        function customizeCellFunction(cellBuilder, cellData) {
            if (typeof cellData.rowIndex !== "number" || cellData.rowIndex === 0) return;
            if (!cellData.hierarchy || cellData.type !== "value") return;

            var hierarchyName = cellData.hierarchy.uniqueName;
            if (hierarchyName !== "OrderTypePPM" && hierarchyName !== "OrderTypeTechnique") return;

            var rowKey = cellData.rowIndex;
            var cellText = "";
            if (cellData.member && cellData.member.caption != null) {
                cellText = String(cellData.member.caption);
            } else if (cellData.label != null) {
                cellText = String(cellData.label);
            } else if (cellData.value != null) {
                cellText = String(cellData.value);
            }

            if (!orderTypeByRow[rowKey]) {
                orderTypeByRow[rowKey] = {};
            }

            if (hierarchyName === "OrderTypePPM") {
                orderTypeByRow[rowKey].ppm = cellText;
                if (mismatchRows[rowKey]) {
                    cellBuilder.style['background-color'] = '#ffd9d9';
                    cellBuilder.style['color'] = '#a63a3a';
                }
                return;
            }

            orderTypeByRow[rowKey].tech = cellText;
            var ppmValue = String(orderTypeByRow[rowKey].ppm || "").trim().toUpperCase();
            var techValue = String(orderTypeByRow[rowKey].tech || "").trim().toUpperCase();
            if (ppmValue !== "" && techValue !== "" && ppmValue !== techValue) {
                mismatchRows[rowKey] = true;
                cellBuilder.style['background-color'] = '#ffd9d9';
                cellBuilder.style['color'] = '#a63a3a';
            }
        }


        //Funcion que manda un error cuando no se conecta a la base de datos
        pivot.on('reportcomplete', () => {
            if (pivot.getAllHierarchies().length == 0)
                pivot.alert({
                    title: 'Data error, please contac LCA IT (lca.it@league91.com)',
                    type: 'error'
                })
        });



        //Funcion que muestra mensaje que ya cargo toda la información en la pivote
        function showAlert() {
            flexmonster.alert({
                title: "Pivot Title", //Aqui ponemos el titulo de la pivote para mensaje emergente
                message: "Data Updated", //mensaje abajo del alert
                type: "info",
                blocking: false
            });
        }



        var PDFFlex = function() {
            ExportTo_pdf()
        };
        var ExcelDataFlex = function() {
            ExportTo_excel()
        };
        var CSVDataFlex = function() {
            ExportTo_csv()
        };
        var PrinDataFlex = function() {
            printGrid()
        };
        var ImageDataFlex = function() {
            ExportTo_image()
        };
        var HTMLDataFlex = function() {
            ExportTo_html()
        };

        var ExpandDataFlex = function() {
            expand()
        };
        var CollapseDataFlex = function() {
            collapse()
        };






        ///////////////////////////////////////////
        // #region "FUNCIONES BOTONES"
        ///////////////////////////////////////////

        //Funcion para Boton para PRINTL
        function printGrid() {
            flexmonster.print();
        }

        //Funcion para Boton para exportar a HTML
        function ExportTo_html() {
            var params = {
                filename: 'flexmonster'
            };
            flexmonster.exportTo('html', params);
        }

        //Funcion para Boton para exportar a CSV
        function ExportTo_csv() {
            var params = {
                filename: 'flexmonster'
            };
            flexmonster.exportTo('csv', params,
                function(result) {
                    console.log(result.data)
                }
            );
        }

        //Funcion para Boton para exportar a EXCEL
        function ExportTo_excel() {
            var params = {
                filename: 'flexmonster',
                excelSheetName: 'Report',
                showFilters: true
            };
            flexmonster.exportTo('excel', params);
        }

        //Funcion para Boton para exportar a IMAGE
        function ExportTo_image() {
            var params = {
                filename: 'flexmonster'
            };
            flexmonster.exportTo('image', params);
        }

        //Funcion para Boton para exportar a PDF
        function ExportTo_pdf() {
            var params = {
                filename: 'flexmonster',
                header: "<div>##CURRENT-DATE##</div>",
                footer: "<div>##PAGE-NUMBER##</div>",
                pageOrientation: 'landscape'
            };
            flexmonster.exportTo('pdf', params);
        }
        ///////////////////////////////////////////
        // #endregion



        /////////////////////////
        //Funcion para Expandir toda la pivote
        function expand() {
            pivot.expandAllData();
        }

        //Funcion para Collapsar toda la pivote
        function collapse() {
            pivot.collapseAllData();
        }
        //////////////////////////

        //Funcion para poner pivote Compacta
        function switchToCompact() {
            pivot.setOptions({
                grid: {
                    type: "compact"
                }
            });

            pivot.refresh();
        }

        //Funcion para poner pivote FLAT
        function switchToFlat() {
            pivot.setOptions({
                grid: {
                    type: "flat"
                }
            });

            pivot.refresh();
        }

        //Funcion para poner pivote CLASSIC
        function switchToClassic() {
            pivot.setOptions({
                grid: {
                    type: "classic"
                }
            });

            pivot.refresh();
        }
    </script>
<?php }?>

<?php
get_footer();
?>
