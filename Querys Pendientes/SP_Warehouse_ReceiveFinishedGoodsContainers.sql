USE [AppsLCA]
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------SP PARA WAREHOUSE DLI, RECEIVE FINISH GOODS CONTAINERS-----------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----Que hace este script
------1) Guarda los elementos digitados por el personal de bodega de forma temporal y de forma definitva en un log cuando crea el archivo (pendiente de desarrollar)
------2) Receibe como parametro un ReceiveSlip en el proceso 1 y en el proceso 2 una MO con los Containers a despachar, además de validar que los containers sean compatibles
-------- con el PartNumber que solicita la MO, que el Style de la MO coincida con el estilo del PartNumber y que el PartNumber de los Matriales sea igual al del Style
-------- si pasa la validación envía proceso a API de PPM para despachar el contenedor y para mover la primera tarea del WorkFlow de la MO
------3) Recibe como parametro las MO y crea las cajas en PPM, luego cada caja creada las mueve al BIN RECEIVED, valida que tenga SKU y mueve la segunda tarea del WorkFlow
------4) Recibe como parametro el BIN de recibimiento para devolver un reporte con las cajas en ese bin y agrupado por PO, CountryOfOrigin y Manufacturer, luego
-------  recibe las cajas con su nuevo bin para moverlas en PPM
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE [dbo].[SP_Warehouse_ReceiveFinishedGoodsContainers]
(
    @Waybill NVARCHAR(200)
)
AS
BEGIN
    SET NOCOUNT ON;
END