-- =====================================================
-- PROCESO ETL - FASE DE TRANSFORMACIÓN
-- =====================================================
USE DataMartRestaurante;
GO

-- 1. Transformación de Delivery (Homologación de nombres y cálculo de comisión y venta neta)
SELECT 
    D.Fecha,
    S.ID_Sede,
    S.NombreSede,
    CASE 
        WHEN D.Aplicativo = 'Rapi' THEN 'Rappi'
        WHEN D.Aplicativo IN ('Pedidos Ya', 'Pedidos') THEN 'PedidosYa'
        ELSE D.Aplicativo
    END AS Aplicativo,
    D.Monto_Bruto_Vendido,
    D.Porcentaje_Comision,
    CAST((D.Monto_Bruto_Vendido * D.Porcentaje_Comision) AS DECIMAL(10,2)) AS Monto_Comision,
    CAST((D.Monto_Bruto_Vendido - (D.Monto_Bruto_Vendido * D.Porcentaje_Comision)) AS DECIMAL(10,2)) AS Venta_Neta
FROM Stg_Delivery D
INNER JOIN Dim_Sede S 
    ON D.Sede_Nombre = S.Distrito;
GO

-- 2. Transformación de Publicidad (Cruce con clave subrogada ID_Sede)
SELECT 
    P.Periodo,
    P.Plataforma_Ad,
    P.Inversion_Soles,
    S.ID_Sede,
    S.NombreSede
FROM Stg_Publicidad P
INNER JOIN Dim_Sede S 
    ON P.Sede_Objetivo = S.Distrito;
GO

-- 3. Transformación de Satisfacción (Cruce con ID_Sede y limpieza de comentarios vacíos)
SELECT 
    ST.Fecha,
    S.ID_Sede,
    S.NombreSede,
    ST.Puntuacion,
    ISNULL(NULLIF(ST.Comentario, ''), 'Sin comentario registrado') AS Comentario
FROM Stg_Satisfaccion ST
INNER JOIN Dim_Sede S 
    ON ST.Sede = S.Distrito;
GO

-- 4. Transformación de Ventas OLTP (Cálculo de Ingreso_Total, Costo_Total y Utilidad Bruta)
SELECT 
    B.IDBoleta,
    B.FechaEmision,
    B.IDSede,
    B.IDEmpleado,
    D.IDProducto,
    D.Cantidad,
    D.SubTotal AS Ingreso_Total,
    (D.Cantidad * P.CostoProduccion) AS Costo_Total,
    (D.SubTotal - (D.Cantidad * P.CostoProduccion)) AS Utilidad
FROM BDRestaurante.dbo.Boleta B
INNER JOIN BDRestaurante.dbo.Detalle_Boleta D 
    ON B.IDBoleta = D.IDBoleta
INNER JOIN BDRestaurante.dbo.Producto P 
    ON D.IDProducto = P.IDProducto;
GO