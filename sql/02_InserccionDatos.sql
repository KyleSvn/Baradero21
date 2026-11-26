SET NOCOUNT ON;
USE BDRestaurante;
GO


DELETE FROM Detalle_Boleta;
DELETE FROM Boleta;
DELETE FROM Gasto_Operativo;
DELETE FROM Producto;
DELETE FROM Empleado;
DELETE FROM Categoria;
DELETE FROM Sede;

DBCC CHECKIDENT ('Detalle_Boleta', RESEED, 0);
DBCC CHECKIDENT ('Boleta', RESEED, 0);
DBCC CHECKIDENT ('Gasto_Operativo', RESEED, 0);
GO


SET IDENTITY_INSERT Sede ON;
INSERT INTO Sede (IDSede, NombreSede, Distrito, Direccion) VALUES
(1, 'Baradero 21 - Los Olivos', 'Los Olivos', 'Av. Alfredo Mendiola 1234'),
(2, 'Baradero 21 - Comas', 'Comas', 'Av. Túpac Amaru 5678'),
(3, 'Baradero 21 - Puente Piedra', 'Puente Piedra', 'Av. Panamericana Norte 9101');
SET IDENTITY_INSERT Sede OFF;

SET IDENTITY_INSERT Categoria ON;
INSERT INTO Categoria (IDCategoria, NombreCategoria, Tipo) VALUES
(1, 'Entradas', 'Plato'), (2, 'Platos de Fondo', 'Plato'), (3, 'Platos Criollos', 'Plato'),
(4, 'Mariscos', 'Plato'), (5, 'Postres', 'Postre'), (6, 'Bebidas Frías', 'Bebida'),
(7, 'Bebidas Calientes', 'Bebida'), (8, 'Cócteles', 'Bebida'), (9, 'Menú del Día', 'Plato');
SET IDENTITY_INSERT Categoria OFF;

SET IDENTITY_INSERT Empleado ON;
INSERT INTO Empleado (IDEmpleado, IDSede, Nombres, Apellidos, Cargo, SalarioMensual) VALUES
(1, 1, 'Juan', 'Pérez', 'Mozo', 1000.00), (2, 1, 'María', 'Gómez', 'Mozo', 1000.00),
(3, 1, 'Carlos', 'Ramírez', 'Mozo', 1000.00), (4, 1, 'Ana', 'Torres', 'Cocinero', 1200.00),
(5, 1, 'Luis', 'Fernández', 'Cocinero', 1200.00), (6, 1, 'Rosa', 'Chávez', 'Cocinero', 1200.00),
(7, 1, 'Pedro', 'Salazar', 'Administrador', 1350.00), (8, 2, 'Jorge', 'Mendoza', 'Mozo', 1000.00),
(9, 2, 'Lucía', 'Rojas', 'Mozo', 1000.00), (10, 2, 'Miguel', 'Vargas', 'Mozo', 1000.00),
(11, 2, 'Elena', 'Castro', 'Cocinero', 1200.00), (12, 2, 'Raúl', 'Ortiz', 'Cocinero', 1200.00),
(13, 2, 'Sofía', 'Ríos', 'Cocinero', 1200.00), (14, 2, 'Carmen', 'Luna', 'Administrador', 1350.00),
(15, 3, 'Alberto', 'Quispe', 'Mozo', 1000.00), (16, 3, 'Patricia', 'Flores', 'Mozo', 1000.00),
(17, 3, 'Diego', 'Herrera', 'Mozo', 1000.00), (18, 3, 'Natalia', 'Campos', 'Cocinero', 1200.00),
(19, 3, 'Fernando', 'Paredes', 'Cocinero', 1200.00), (20, 3, 'Verónica', 'Soto', 'Cocinero', 1200.00),
(21, 3, 'Ricardo', 'Ibáñez', 'Administrador', 1350.00);
SET IDENTITY_INSERT Empleado OFF;

SET IDENTITY_INSERT Producto ON;
INSERT INTO Producto (IDProducto, IDCategoria, NombreProducto, PrecioVenta, CostoProduccion) VALUES
(1, 1, 'Ceviche Clásico', 35.00, 14.00), (2, 1, 'Causa Limeña', 25.00, 10.00),
(3, 1, 'Anticuchos', 30.00, 13.00), (4, 1, 'Papa a la Huancaína', 22.00, 8.00),
(5, 1, 'Choritos a la Chalaca', 28.00, 12.00), (6, 2, 'Lomo Saltado', 25.00, 18.00),
(7, 2, 'Ají de Gallina', 25.00, 15.00), (8, 2, 'Pollo a la Brasa 1/4', 28.00, 12.00),
(9, 2, 'Pollo a la Brasa 1/2', 45.00, 22.00), (10, 2, 'Milanesa de Pollo', 18.00, 14.00),
(11, 3, 'Seco de Res', 40.00, 16.00), (12, 3, 'Carapulcra', 34.00, 13.00),
(13, 3, 'Adobo de Chancho', 36.00, 15.00), (14, 3, 'Cau Cau', 30.00, 11.00),
(15, 3, 'Tallarín Saltado', 38.00, 15.00), (16, 4, 'Arroz con Mariscos', 38.00, 20.00),
(17, 4, 'Jalea Mixta', 42.00, 22.00), (18, 4, 'Sudado de Pescado', 35.00, 18.00),
(19, 4, 'Chicharrón de Calamar', 30.00, 17.00), (20, 5, 'Suspiro a la Limeña', 18.00, 6.00),
(21, 5, 'Mazamorra Morada', 15.00, 5.00), (22, 5, 'Arroz con Leche', 15.00, 5.00),
(23, 5, 'Torta de Chocolate', 15.00, 8.00), (24, 5, 'Helado Artesanal', 10.00, 6.00),
(25, 6, 'Chicha Morada Jarra', 18.00, 5.00), (26, 6, 'Limonada Frozen', 16.00, 5.00),
(27, 6, 'Inca Kola 1L', 12.00, 6.00), (28, 6, 'Coca Cola 1L', 12.00, 6.00),
(29, 6, 'Agua San Mateo 600ml', 6.00, 2.00), (30, 7, 'Café Pasado', 8.00, 2.00),
(31, 7, 'Capuchino', 12.00, 4.00), (32, 7, 'Té de Hierbas', 7.00, 2.00),
(33, 7, 'Chocolate Caliente', 10.00, 3.00), (34, 8, 'Pisco Sour', 25.00, 9.00),
(35, 8, 'Chilcano', 22.00, 8.00), (36, 8, 'Mojito', 24.00, 9.00),
(37, 8, 'Cuba Libre', 23.00, 8.00), (38, 9, 'Menú del Día - Entrada + Fondo', 25.00, 10.00),
(39, 9, 'Menú del Día - Fondo + Bebida', 22.00, 9.00), (40, 9, 'Menú Ejecutivo', 30.00, 12.00);
SET IDENTITY_INSERT Producto OFF;
GO


    --GENERACION BOLETAS
WITH Fechas AS (
    SELECT CAST('2024-01-01' AS DATE) AS Fecha
    UNION ALL
    SELECT DATEADD(DAY, 1, Fecha)
    FROM Fechas
    WHERE Fecha < '2026-06-30'
)
INSERT INTO Gasto_Operativo (IDSede, Fecha, Gasto_Insumos, Gasto_Personal, Gasto_Local)
SELECT 
    S.IDSede,
    F.Fecha,

    CAST(120 + (ABS(CHECKSUM(NEWID())) % 60) AS DECIMAL(10,2)) AS Gasto_Insumos,

    CAST(265.00 AS DECIMAL(10,2)) AS Gasto_Personal,

    CAST(CASE S.IDSede WHEN 1 THEN 150.00 WHEN 2 THEN 120.00 ELSE 110.00 END AS DECIMAL(10,2)) AS Gasto_Local
FROM Fechas F
CROSS JOIN Sede S
OPTION (MAXRECURSION 1000);
GO


WITH Fechas AS (
    SELECT CAST('2024-01-01' AS DATE) AS Fecha
    UNION ALL
    SELECT DATEADD(DAY, 1, Fecha)
    FROM Fechas
    WHERE Fecha < '2026-06-30'
),
TurnosDia AS (
    SELECT 1 AS NumBoleta UNION ALL SELECT 2 UNION ALL SELECT 3 
    UNION ALL SELECT 4 UNION ALL SELECT 5
)
INSERT INTO Boleta (IDSede, IDEmpleado, FechaEmision, HoraEmision, TotalVenta)
SELECT 
    S.IDSede,
    
    CASE S.IDSede 
        WHEN 1 THEN 1 + (ABS(CHECKSUM(NEWID())) % 3)
        WHEN 2 THEN 8 + (ABS(CHECKSUM(NEWID())) % 3)
        WHEN 3 THEN 15 + (ABS(CHECKSUM(NEWID())) % 3)
    END AS IDEmpleado,
    F.Fecha,
    DATEADD(MINUTE, ABS(CHECKSUM(NEWID())) % 600, CAST('12:00:00' AS TIME)) AS HoraEmision,
    0.00 AS TotalVenta --
FROM Fechas F
CROSS JOIN Sede S
CROSS JOIN TurnosDia T
WHERE 
    
    (YEAR(F.Fecha) = 2024 AND T.NumBoleta <= 3)
    OR (YEAR(F.Fecha) = 2025 AND T.NumBoleta <= 4)
    OR (YEAR(F.Fecha) = 2026 AND T.NumBoleta <= 5)
OPTION (MAXRECURSION 1000);
GO


;WITH ItemsPorBoleta AS (
    SELECT 1 AS ItemNum UNION ALL SELECT 2 UNION ALL SELECT 3
),
DetalleGenerado AS (
    SELECT 
        B.IDBoleta,
        I.ItemNum,
        
        1 + (ABS(CHECKSUM(NEWID(), B.IDBoleta, I.ItemNum)) % 40) AS IDProducto,
        
        1 + (ABS(CHECKSUM(NEWID(), B.IDBoleta)) % 3) AS Cantidad
    FROM Boleta B
    CROSS JOIN ItemsPorBoleta I
    WHERE I.ItemNum <= 2 OR (B.IDBoleta % 2 = 0) 
)
INSERT INTO Detalle_Boleta (IDBoleta, IDProducto, Cantidad, SubTotal)
SELECT 
    DG.IDBoleta,
    DG.IDProducto,
    DG.Cantidad,
    DG.Cantidad * P.PrecioVenta AS SubTotal
FROM DetalleGenerado DG
INNER JOIN Producto P ON DG.IDProducto = P.IDProducto;
GO


UPDATE B
SET B.TotalVenta = Resumen.SumaSubTotal
FROM Boleta B
INNER JOIN (
    SELECT IDBoleta, SUM(SubTotal) AS SumaSubTotal
    FROM Detalle_Boleta
    GROUP BY IDBoleta
) Resumen ON B.IDBoleta = Resumen.IDBoleta;
GO



--DATA MART
USE DataMartRestaurante;
GO

DELETE FROM Fact_Ventas;
DELETE FROM Dim_Sede;
DELETE FROM Dim_Producto;
DELETE FROM Dim_Categoria;
DELETE FROM Dim_Empleado;
DELETE FROM Dim_Tiempo;

DBCC CHECKIDENT ('Fact_Ventas', RESEED, 0);
DBCC CHECKIDENT ('Dim_Sede', RESEED, 0);
DBCC CHECKIDENT ('Dim_Producto', RESEED, 0);
DBCC CHECKIDENT ('Dim_Categoria', RESEED, 0);
DBCC CHECKIDENT ('Dim_Empleado', RESEED, 0);
GO


INSERT INTO Dim_Sede (PK_Sede, NombreSede, Distrito, Direccion)
SELECT IDSede, NombreSede, Distrito, Direccion FROM BDRestaurante.dbo.Sede;

INSERT INTO Dim_Categoria (PK_Categoria, NombreCategoria, Tipo)
SELECT IDCategoria, NombreCategoria, Tipo FROM BDRestaurante.dbo.Categoria;

INSERT INTO Dim_Producto (PK_Producto, NombreProducto, PrecioVenta, CostoProduccion)
SELECT IDProducto, NombreProducto, PrecioVenta, CostoProduccion FROM BDRestaurante.dbo.Producto;

INSERT INTO Dim_Empleado (PK_Empleado, Nombres, Apellidos, Cargo, SalarioMensual)
SELECT IDEmpleado, Nombres, Apellidos, Cargo, SalarioMensual FROM BDRestaurante.dbo.Empleado;


SET LANGUAGE Spanish;
WITH FechasDim AS (
    SELECT CAST('2024-01-01' AS DATE) AS Fecha
    UNION ALL
    SELECT DATEADD(DAY, 1, Fecha)
    FROM FechasDim
    WHERE Fecha < '2026-06-30'
)
INSERT INTO Dim_Tiempo (Fecha, Anio, Mes, DiaMes, DiaSemana, Trimestre)
SELECT 
    Fecha,
    YEAR(Fecha),
    MONTH(Fecha),
    DAY(Fecha),
    DATENAME(WEEKDAY, Fecha),
    DATEPART(QUARTER, Fecha)
FROM FechasDim
OPTION (MAXRECURSION 1000);
GO

-- carga factVentas
WITH ConteoItemsPorSedeFecha AS (
    SELECT 
        B.IDSede, 
        B.FechaEmision, 
        COUNT(DB.IDDetalle) AS TotalLineasDia
    FROM BDRestaurante.dbo.Boleta B
    INNER JOIN BDRestaurante.dbo.Detalle_Boleta DB ON B.IDBoleta = DB.IDBoleta
    GROUP BY B.IDSede, B.FechaEmision
)
INSERT INTO Fact_Ventas (
    ID_Sede, ID_Producto, ID_Categoria, ID_Empleado, Fecha,
    Cantidad, Ingreso_Total, Costo_Insumos, Gasto_Personal_Asignado, Gasto_Local_Asignado
)
SELECT 
    DS.ID_Sede,
    DP.ID_Producto,
    DC.ID_Categoria,
    DE.ID_Empleado,
    B.FechaEmision AS Fecha,
    DB.Cantidad,
    DB.SubTotal AS Ingreso_Total,
    (DB.Cantidad * P.CostoProduccion) AS Costo_Insumos,
    ISNULL(GOp.Gasto_Personal / NULLIF(C.TotalLineasDia, 0), 0) AS Gasto_Personal_Asignado,
    ISNULL(GOp.Gasto_Local / NULLIF(C.TotalLineasDia, 0), 0) AS Gasto_Local_Asignado
FROM BDRestaurante.dbo.Boleta B
INNER JOIN BDRestaurante.dbo.Detalle_Boleta DB ON B.IDBoleta = DB.IDBoleta
INNER JOIN BDRestaurante.dbo.Producto P ON DB.IDProducto = P.IDProducto
INNER JOIN DataMartRestaurante.dbo.Dim_Sede DS ON B.IDSede = DS.PK_Sede
INNER JOIN DataMartRestaurante.dbo.Dim_Producto DP ON P.IDProducto = DP.PK_Producto
INNER JOIN DataMartRestaurante.dbo.Dim_Categoria DC ON P.IDCategoria = DC.PK_Categoria
INNER JOIN DataMartRestaurante.dbo.Dim_Empleado DE ON B.IDEmpleado = DE.PK_Empleado
LEFT JOIN BDRestaurante.dbo.Gasto_Operativo GOp 
    ON B.IDSede = GOp.IDSede AND B.FechaEmision = GOp.Fecha
LEFT JOIN ConteoItemsPorSedeFecha C 
    ON B.IDSede = C.IDSede AND B.FechaEmision = C.FechaEmision;
GO

--resumen
SELECT 'Dim_Sede' AS Tabla, COUNT(*) AS Total_Registros FROM Dim_Sede
UNION ALL SELECT 'Dim_Categoria', COUNT(*) FROM Dim_Categoria
UNION ALL SELECT 'Dim_Empleado', COUNT(*) FROM Dim_Empleado
UNION ALL SELECT 'Dim_Producto', COUNT(*) FROM Dim_Producto
UNION ALL SELECT 'Dim_Tiempo (2024 - Jun 2026)', COUNT(*) FROM Dim_Tiempo
UNION ALL SELECT 'Fact_Ventas (Hechos)', COUNT(*) FROM Fact_Ventas;



-----actualizacion boletas
USE BDRestaurante;
GO

-- 
UPDATE Detalle_Boleta
SET Cantidad = Cantidad + 2 + (IDDetalle % 2);

-- 2
UPDATE DB
SET DB.SubTotal = DB.Cantidad * P.PrecioVenta
FROM Detalle_Boleta DB
INNER JOIN Producto P ON DB.IDProducto = P.IDProducto;

-- 3
UPDATE B
SET B.TotalVenta = Resumen.SumaSubTotal
FROM Boleta B
INNER JOIN (
    SELECT IDBoleta, SUM(SubTotal) AS SumaSubTotal
    FROM Detalle_Boleta
    GROUP BY IDBoleta
) Resumen ON B.IDBoleta = Resumen.IDBoleta;
GO

-- 4
USE DataMartRestaurante;
GO

UPDATE FV
SET 
    FV.Cantidad = FV.Cantidad + 2 + (FV.ID_Venta % 2),
    FV.Ingreso_Total = (FV.Cantidad + 2 + (FV.ID_Venta % 2)) * DP.PrecioVenta,
    FV.Costo_Insumos = (FV.Cantidad + 2 + (FV.ID_Venta % 2)) * DP.CostoProduccion
FROM Fact_Ventas FV
INNER JOIN Dim_Producto DP ON FV.ID_Producto = DP.ID_Producto;
GO

--resumen financiero
SELECT 
    T.Anio,
    SUM(F.Cantidad) AS Total_Unidades_Vendidas,
    SUM(F.Ingreso_Total) AS Ingreso_Ventas_Soles,
    SUM(F.Costo_Insumos + F.Gasto_Personal_Asignado + F.Gasto_Local_Asignado) AS Costo_Total_Operacion,
    SUM(F.Ingreso_Total) - SUM(F.Costo_Insumos + F.Gasto_Personal_Asignado + F.Gasto_Local_Asignado) AS Utilidad_Neta,
    CAST((SUM(F.Ingreso_Total) - SUM(F.Costo_Insumos + F.Gasto_Personal_Asignado + F.Gasto_Local_Asignado)) * 100.0 / SUM(F.Ingreso_Total) AS DECIMAL(5,2)) AS Margen_Neto_Porcentaje
FROM Fact_Ventas F
INNER JOIN Dim_Tiempo T ON F.Fecha = T.Fecha
GROUP BY T.Anio
ORDER BY T.Anio;
GO
