# Baradero 21

Proyecto académico de inteligencia de negocios y Big Data para analizar los ingresos, costos y utilidad de las sedes de Baradero 21 con datos simulados.

| Carpeta | Contenido |
| --- | --- |
| [`sql/`](sql/) | Scripts de SQL Server para crear y cargar `BDRestaurante` y `DataMartRestaurante`. |
| [`powerbi/`](powerbi/) | [Informe financiero de Power BI](powerbi/baradero21%20final.pbix). |
| [`databricks/`](databricks/) | [Notebook de la solución Big Data](databricks/01_Baradero_Solucion_Big_Data.py) y [PDF del dashboard](databricks/Baradero_Solucion_Big_Data%202026-11-26%2015_24.pdf). |
| [`datos/`](datos/) | Archivos TXT de publicidad, satisfacción y ventas por aplicativos de delivery. |

## Reproducir la solución BI

1. Ejecuta [`01_Creacion_BD_Baradero21.sql`](sql/01_Creacion_BD_Baradero21.sql) y [`02_InserccionDatos.sql`](sql/02_InserccionDatos.sql) en SQL Server Management Studio.
2. Copia los tres TXT de [`datos/`](datos/) a una ruta accesible para SQL Server. [`03_CargaDeArchivos.sql`](sql/03_CargaDeArchivos.sql) apunta a `D:\ETL\Baradero\`. Ajusta sus tres rutas `BULK INSERT` si usas otra carpeta. Ejecuta ese script y luego [`04_ProcesoETL.sql`](sql/04_ProcesoETL.sql).
3. Abre el PBIX en Power BI Desktop y, para actualizarlo, configura la conexión a tu instancia de SQL Server y a `DataMartRestaurante`.

## Reproducir la solución Big Data

1. Prepara las carpetas `csv/` y `txt/` en el volumen `workspace.baradero_final.origen_csv`.
2. Carga en `csv/` las exportaciones `Fact_Ventas.csv`, `Sede.csv`, `Producto.csv`, `Categoria.csv`, `Empleado.csv` y `Tiempo.csv`. Esas exportaciones se preparan a partir del BI. Carga los tres archivos de [`datos/`](datos/) en `txt/`.
3. Importa y ejecuta el notebook en Databricks. El PDF permite revisar el dashboard de la entrega.

