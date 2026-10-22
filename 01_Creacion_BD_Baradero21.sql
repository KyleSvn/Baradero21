-- ==============================================================================
-- Proyecto: Business Intelligence para Restaurante Baradero 21
-- Objetivo: Creación de BD Transaccional (OLTP) y Data Mart (OLAP)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- FASE 1: CREACIÓN DE BASE DE DATOS TRANSACCIONAL (OLTP) Y STAGING
-- ------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'BDRestaurante')
    CREATE DATABASE BDRestaurante;
GO

USE BDRestaurante
GO

CREATE TABLE Sede (
    IDSede INT IDENTITY(1,1) PRIMARY KEY,
    NombreSede VARCHAR(100) NOT NULL,
    Distrito VARCHAR(100) NOT NULL,
    Direccion VARCHAR(200) NOT NULL
);

CREATE TABLE Categoria (
    IDCategoria INT IDENTITY(1,1) PRIMARY KEY,
    NombreCategoria VARCHAR(100) NOT NULL,
    Tipo VARCHAR(50) NOT NULL
)

CREATE TABLE Empleado (
    IDEmpleado INT IDENTITY(1,1) PRIMARY KEY,
    IDSede INT NOT NULL,
    Nombres VARCHAR(100) NOT NULL,
    Apellidos VARCHAR(100) NOT NULL,
    Cargo VARCHAR(50) NOT NULL,
    SalarioMensual DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (IDSede) REFERENCES Sede(IDSede)
)

CREATE TABLE Producto (
    IDProducto INT IDENTITY(1,1) PRIMARY KEY,
    IDCategoria INT NOT NULL,
    NombreProducto VARCHAR(100) NOT NULL,
    PrecioVenta DECIMAL(10,2) NOT NULL,
    CostoProduccion DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (IDCategoria) REFERENCES Categoria(IDCategoria)
)

CREATE TABLE Boleta (
    IDBoleta INT IDENTITY(1,1) PRIMARY KEY,
    IDSede INT NOT NULL,
    IDEmpleado INT NOT NULL,
    FechaEmision DATE NOT NULL,
    HoraEmision TIME NOT NULL,
    TotalVenta DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (IDSede) REFERENCES Sede(IDSede),
    FOREIGN KEY (IDEmpleado) REFERENCES Empleado(IDEmpleado)
)

CREATE TABLE Detalle_Boleta (
    IDDetalle INT IDENTITY(1,1) PRIMARY KEY,
    IDBoleta INT NOT NULL,
    IDProducto INT NOT NULL,
    Cantidad INT NOT NULL,
    SubTotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (IDBoleta) REFERENCES Boleta(IDBoleta),
    FOREIGN KEY (IDProducto) REFERENCES Producto(IDProducto)
)

CREATE TABLE Gasto_Operativo (
    IDGasto INT IDENTITY(1,1) PRIMARY KEY,
    IDSede INT NOT NULL,
    Fecha DATE NOT NULL,
    Gasto_Insumos DECIMAL(10,2) NOT NULL,
    Gasto_Personal DECIMAL(10,2) NOT NULL,
    Gasto_Local DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (IDSede) REFERENCES Sede(IDSede)
)

-- Tablas temporales (Staging) para carga de archivos planos
CREATE TABLE Stg_Delivery (
    Fecha DATE,
    Sede_Nombre VARCHAR(100),
    Aplicativo VARCHAR(50),
    Monto_Bruto_Vendido DECIMAL(10,2),
    Porcentaje_Comision DECIMAL(5,2)
)

CREATE TABLE Stg_Publicidad (
    Periodo VARCHAR(7),
    Plataforma_Ad VARCHAR(50),
    Inversion_Soles DECIMAL(10,2),
    Sede_Objetivo VARCHAR(100)
)

CREATE TABLE Stg_Satisfaccion (
    Fecha DATE,
    Sede VARCHAR(100),
    Puntuacion INT,
    Comentario VARCHAR(255)
)
GO

-- ------------------------------------------------------------------------------
-- FASE 2: CREACIÓN DEL DATA MART (OLAP - MODELO ESTRELLA)
-- ------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'DataMartRestaurante')
    CREATE DATABASE DataMartRestaurante;
GO

USE DataMartRestaurante
GO

-- 2.1 Tablas de Dimensiones
CREATE TABLE Dim_Sede (
    ID_Sede INT IDENTITY(1,1) PRIMARY KEY,
    PK_Sede INT,
    NombreSede VARCHAR(100),
    Distrito VARCHAR(100),
    Direccion VARCHAR(200)
)

CREATE TABLE Dim_Producto (
    ID_Producto INT IDENTITY(1,1) PRIMARY KEY,
    PK_Producto INT,
    NombreProducto VARCHAR(100),
    PrecioVenta DECIMAL(10,2),
    CostoProduccion DECIMAL(10,2)
)

CREATE TABLE Dim_Categoria (
    ID_Categoria INT IDENTITY(1,1) PRIMARY KEY,
    PK_Categoria INT,
    NombreCategoria VARCHAR(100),
    Tipo VARCHAR(50)
)

CREATE TABLE Dim_Empleado (
    ID_Empleado INT IDENTITY(1,1) PRIMARY KEY,
    PK_Empleado INT,
    Nombres VARCHAR(100),
    Apellidos VARCHAR(100),
    Cargo VARCHAR(50),
    SalarioMensual DECIMAL(10,2)
)

CREATE TABLE Dim_Tiempo (
    Fecha DATE PRIMARY KEY,
    Anio SMALLINT,
    Mes SMALLINT,
    DiaMes SMALLINT,
    DiaSemana VARCHAR(15),
    Trimestre SMALLINT
)
GO

-- 2.2 Tabla de Hechos 
CREATE TABLE Fact_Ventas (
    ID_Venta INT IDENTITY(1,1) PRIMARY KEY,
    -- Claves foráneas a las 5 dimensiones
    ID_Sede INT REFERENCES Dim_Sede(ID_Sede),
    ID_Producto INT REFERENCES Dim_Producto(ID_Producto),
    ID_Categoria INT REFERENCES Dim_Categoria(ID_Categoria),
    ID_Empleado INT REFERENCES Dim_Empleado(ID_Empleado),
    Fecha DATE REFERENCES Dim_Tiempo(Fecha),
    
    -- Medidas Ventas
    Cantidad INT,
    Ingreso_Total DECIMAL(10,2),
    
    -- Medidas de Costos 
    Costo_Insumos DECIMAL(10,2), 
    Gasto_Personal_Asignado DECIMAL(10,2) DEFAULT 0, -- Se llenará en el ETL
    Gasto_Local_Asignado DECIMAL(10,2) DEFAULT 0     -- Se llenará en el ETL
)
GO