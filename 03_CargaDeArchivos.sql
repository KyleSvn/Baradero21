USE DataMartRestaurante;
GO

-- Asegurar que las tablas Staging existan en DataMartRestaurante
IF OBJECT_ID('dbo.Stg_Satisfaccion', 'U') IS NULL
    CREATE TABLE Stg_Satisfaccion (Fecha DATE, Sede VARCHAR(100), Puntuacion INT, Comentario VARCHAR(255));

IF OBJECT_ID('dbo.Stg_Publicidad', 'U') IS NULL
    CREATE TABLE Stg_Publicidad (Periodo VARCHAR(7), Plataforma_Ad VARCHAR(50), Inversion_Soles DECIMAL(10,2), Sede_Objetivo VARCHAR(100));

IF OBJECT_ID('dbo.Stg_Delivery', 'U') IS NULL
    CREATE TABLE Stg_Delivery (Fecha DATE, Sede_Nombre VARCHAR(100), Aplicativo VARCHAR(50), Monto_Bruto_Vendido DECIMAL(10,2), Porcentaje_Comision DECIMAL(5,2));
GO

-- Limpiar Staging antes de cargar 
TRUNCATE TABLE Stg_Satisfaccion;
TRUNCATE TABLE Stg_Publicidad;
TRUNCATE TABLE Stg_Delivery;
GO

-- =====================================================
-- PASO 3: CARGA MASIVA DE ARCHIVOS EXTERNOS (STAGING)
-- =====================================================
BULK INSERT Stg_Satisfaccion
FROM 'D:\ETL\Baradero\satisfaccion_cliente.txt'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);

BULK INSERT Stg_Publicidad
FROM 'D:\ETL\Baradero\inversion_marketing.txt'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);

BULK INSERT Stg_Delivery
FROM 'D:\ETL\Baradero\ventas_apps_delivery.txt'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);
GO

-- =====================================================
-- PASO 4: CARGAR FACT_VENTAS (PROCESO DE CARGA)
-- =====================================================
    
IF COL_LENGTH('dbo.Fact_Ventas', 'Costo_Total') IS NULL
    ALTER TABLE dbo.Fact_Ventas ADD Costo_Total DECIMAL(10,2);
GO

TRUNCATE TABLE DataMartRestaurante.dbo.Fact_Ventas;
GO

WITH ConteoItemsPorSedeFecha AS (
    SELECT B.IDSede, B.FechaEmision, COUNT(DB.IDDetalle) AS TotalLineasDia
    FROM BDRestaurante.dbo.Boleta B
    INNER JOIN BDRestaurante.dbo.Detalle_Boleta DB ON B.IDBoleta = DB.IDBoleta
    GROUP BY B.IDSede, B.FechaEmision
)
INSERT INTO DataMartRestaurante.dbo.Fact_Ventas (
    ID_Sede,
    ID_Producto,
    ID_Categoria,
    ID_Empleado,
    Fecha,
    Cantidad,
    Ingreso_Total,
    Costo_Insumos,
    Gasto_Personal_Asignado,
    Gasto_Local_Asignado,
    Costo_Total
)
SELECT 
    DS.ID_Sede,
    DP.ID_Producto,
    DC.ID_Categoria,
    DE.ID_Empleado,
    B.FechaEmision,
    DB.Cantidad,
    DB.SubTotal AS Ingreso_Total,
    (DB.Cantidad * DP.CostoProduccion) AS Costo_Insumos,
    ISNULL(GOp.Gasto_Personal / NULLIF(C.TotalLineasDia, 0), 0) AS Gasto_Personal_Asignado,
    ISNULL(GOp.Gasto_Local / NULLIF(C.TotalLineasDia, 0), 0) AS Gasto_Local_Asignado,
    -- Costo_Total suma Insumos + Personal + Local para cumplir el KPI del profesor
    (DB.Cantidad * DP.CostoProduccion) 
        + ISNULL(GOp.Gasto_Personal / NULLIF(C.TotalLineasDia, 0), 0) 
        + ISNULL(GOp.Gasto_Local / NULLIF(C.TotalLineasDia, 0), 0) AS Costo_Total
FROM BDRestaurante.dbo.Boleta B
INNER JOIN BDRestaurante.dbo.Detalle_Boleta DB 
    ON B.IDBoleta = DB.IDBoleta
INNER JOIN BDRestaurante.dbo.Producto P 
    ON DB.IDProducto = P.IDProducto
INNER JOIN Dim_Sede DS 
    ON B.IDSede = DS.PK_Sede
INNER JOIN Dim_Producto DP 
    ON DB.IDProducto = DP.PK_Producto
INNER JOIN Dim_Categoria DC 
    ON P.IDCategoria = DC.PK_Categoria
INNER JOIN Dim_Empleado DE 
    ON B.IDEmpleado = DE.PK_Empleado
LEFT JOIN BDRestaurante.dbo.Gasto_Operativo GOp 
    ON B.IDSede = GOp.IDSede AND B.FechaEmision = GOp.Fecha
LEFT JOIN ConteoItemsPorSedeFecha C 
    ON B.IDSede = C.IDSede AND B.FechaEmision = C.FechaEmision;
GO

-- Verificación de tablas Staging
SELECT * FROM Stg_Publicidad;
SELECT * FROM Stg_Satisfaccion;
SELECT * FROM Stg_Delivery;
GO

-- CONTEO GENERAL DE REGISTROS  
SELECT 'Dim_Sede' AS Tabla, COUNT(*) AS Registros FROM Dim_Sede
UNION ALL SELECT 'Dim_Producto', COUNT(*) FROM Dim_Producto
UNION ALL SELECT 'Dim_Categoria', COUNT(*) FROM Dim_Categoria
UNION ALL SELECT 'Dim_Empleado', COUNT(*) FROM Dim_Empleado
UNION ALL SELECT 'Dim_Tiempo', COUNT(*) FROM Dim_Tiempo
UNION ALL SELECT 'Fact_Ventas', COUNT(*) FROM Fact_Ventas
UNION ALL SELECT 'Stg_Publicidad', COUNT(*) FROM Stg_Publicidad
UNION ALL SELECT 'Stg_Satisfaccion', COUNT(*) FROM Stg_Satisfaccion
UNION ALL SELECT 'Stg_Delivery', COUNT(*) FROM Stg_Delivery;
GO