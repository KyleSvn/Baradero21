# Databricks notebook source
# MAGIC %md
# MAGIC # 1. Verificar las carpetas

# COMMAND ----------

# MAGIC %fs ls /Volumes/workspace/baradero_final/origen_csv/csv/

# COMMAND ----------

# MAGIC %fs ls /Volumes/workspace/baradero_final/origen_csv/txt/

# COMMAND ----------

# MAGIC %fs head /Volumes/workspace/baradero_final/origen_csv/csv/Fact_Ventas.csv

# COMMAND ----------

dfVentas = spark.read.csv("/Volumes/workspace/baradero_final/origen_csv/csv/Fact_Ventas.csv",inferSchema=True,
    header=True,
    sep=","
)

print("Filas de ventas:", dfVentas.count())
display(dfVentas)

# COMMAND ----------

# MAGIC %md
# MAGIC # 2. Cargar los DataFrames

# COMMAND ----------

from pyspark.sql import functions as F

ruta = "/Volumes/workspace/baradero_final/origen_csv"

def leer(carpeta, archivo):
    datos = spark.read.csv(f"{ruta}/{carpeta}/{archivo}", header=True, sep="," ,inferSchema= True )
    return datos.toDF(*[columna.lstrip("\ufeff") for columna in datos.columns])

dfSedes = leer("csv", "Sede.csv")
dfProductos = leer("csv", "Producto.csv")
dfCategorias = leer("csv", "Categoria.csv")
dfEmpleados = leer("csv", "Empleado.csv")
dfTiempo = leer("csv", "Tiempo.csv")

dfPublicidad = leer("txt", "inversion_marketing.txt")
dfSatisfaccion = leer("txt", "satisfaccion_cliente.txt")
dfDelivery = leer("txt", "ventas_apps_delivery.txt")


# COMMAND ----------

fuentes = [
    ("Fact_Ventas.csv", dfVentas, 24671),
    ("Sede.csv", dfSedes, 3),
    ("Producto.csv", dfProductos, 40),
    ("Categoria.csv", dfCategorias, 9),
    ("Empleado.csv", dfEmpleados, 21),
    ("Tiempo.csv", dfTiempo, 912),
    ("inversion_marketing.txt", dfPublicidad, 30),
    ("satisfaccion_cliente.txt", dfSatisfaccion, 22),
    ("ventas_apps_delivery.txt", dfDelivery, 22),
]
conteos = [(archivo, df.count(), esperado) for archivo, df, esperado in fuentes]
display(spark.createDataFrame(conteos, ["archivo", "filas_observadas", "filas_esperadas"]))
assert all(filas == esperado for _, filas, esperado in conteos), "Revisa la versión de los archivos."


# COMMAND ----------

# MAGIC %md
# MAGIC # 3. Renombrar, convertir tipos y explorar

# COMMAND ----------

def tipo(columna, tipo_sql):
    return F.expr(f"try_cast(`{columna}` AS {tipo_sql})")

dfVentasTipadas = (
    dfVentas.withColumnRenamed("Suma de Ingreso_Total", "ingresos")
    .withColumnRenamed("Suma de Costo_Total", "costo_operativo")
    .select(
        F.expr("try_cast(substr(Fecha, 1, 10) AS DATE)").alias("fecha"),
        tipo("ID_Sede", "INT").alias("id_sede"),
        tipo("ID_Producto", "INT").alias("id_producto"),
        tipo("ID_Categoria", "INT").alias("id_categoria"),
        tipo("ID_Empleado", "INT").alias("id_empleado"),
        tipo("Suma de Cantidad", "BIGINT").alias("cantidad"),
        tipo("ingresos", "DECIMAL(18,2)").alias("ingresos"),
        tipo("Suma de Costo_Insumos", "DECIMAL(18,2)").alias("insumos"),
        tipo("costo_operativo", "DECIMAL(18,2)").alias("costo_operativo"),
    )
)

dfVentasTipadas.printSchema()
display(dfVentasTipadas.describe("cantidad", "ingresos", "costo_operativo"))

# COMMAND ----------

display(dfVentasTipadas.agg(
    F.min("fecha").alias("desde"), F.max("fecha").alias("hasta"),
    *[F.count(F.when(F.col(c).isNull(), 1)).alias(f"{c}_nulos") for c in dfVentasTipadas.columns],
))
display(dfVentasTipadas.groupBy(F.year("fecha").alias("año")).agg(
    F.count("*").alias("filas"),
    F.sum("ingresos").alias("ingresos"),
).orderBy("año"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## # 4. Limpiar las ventas y comprobar las relaciones

# COMMAND ----------

sedes = dfSedes.select(tipo("ID_Sede", "INT").alias("id_sede"), F.trim("NombreSede").alias("sede"))
productos = dfProductos.select(
    tipo("ID_Producto", "INT").alias("id_producto"), F.trim("NombreProducto").alias("producto")
)
categorias = dfCategorias.select(
    tipo("ID_Categoria", "INT").alias("id_categoria"), F.trim("NombreCategoria").alias("categoria")
)
empleados = dfEmpleados.select(tipo("ID_Empleado", "INT").alias("id_empleado"))
fechas = dfTiempo.select(
    F.make_date(tipo("Año", "INT"), tipo("Mes", "INT"), tipo("DiaMes", "INT")).alias("fecha")
)

grano = ["fecha", "id_sede", "id_producto", "id_categoria", "id_empleado"]
sin_nulos = dfVentasTipadas.na.drop()
en_rango = sin_nulos.filter("cantidad > 0 AND ingresos >= 0 AND insumos >= 0 AND costo_operativo >= 0")
sin_duplicados = en_rango.dropDuplicates()

con_dimensiones = sin_duplicados
for clave, dim in zip(grano, [fechas, sedes, productos, categorias, empleados]):
    total, distintas = dim.agg(F.count("*"), F.countDistinct(clave)).first()
    assert total == distintas, f"Revisa los nulos y duplicados de {clave} en su dimensión."
    con_dimensiones = con_dimensiones.join(dim.select(clave), clave, "left_semi")

conflictos = con_dimensiones.groupBy(*grano).count().filter("count > 1").count()
assert conflictos == 0, "Hay más de una fila válida con la misma clave de agrupación."

display(spark.createDataFrame([
    ("Entrada", conteos[0][1]),
    ("Después de na.drop", sin_nulos.count()),
    ("Después de revisar rangos", en_rango.count()),
    ("Después de retirar duplicados idénticos", sin_duplicados.count()),
    ("Después de validar las cinco dimensiones", con_dimensiones.count()),
], ["etapa", "filas"]))

ventas_limpias = (
    con_dimensiones.join(sedes, "id_sede")
    .join(productos, "id_producto").join(categorias, "id_categoria")
    .withColumn("utilidad", F.col("ingresos") - F.col("costo_operativo"))
)

# COMMAND ----------

# MAGIC %md
# MAGIC # 5. Preparar las fuentes complementarias

# COMMAND ----------

def fecha_txt(columna):
    return F.expr(f"try_cast(`{columna}` AS DATE)")

comentario = F.trim("Comentario_Cliente")
sin_comentario = comentario.isNull() | (comentario == "")
satisfaccion_limpia = (
    dfSatisfaccion.select(
        fecha_txt("Fecha").alias("fecha"),
        F.trim("Sede").alias("sede"),
        tipo("Puntuacion1-5", "INT").alias("puntuacion"),
        F.when(sin_comentario, F.lit("Sin comentario")).otherwise(comentario).alias("comentario"),
    ).na.drop().filter("puntuacion BETWEEN 1 AND 5")
)

app = F.trim("Aplicativo")
normalizado = F.lower(F.regexp_replace(app, " ", ""))
delivery_limpio = (
    dfDelivery.select(
        fecha_txt("Fecha").alias("fecha"),
        F.trim("Sede_Nombre").alias("sede"),
        app.alias("aplicativo_origen"),
        F.when(normalizado.isin("rapi", "rappi"), F.lit("Rappi"))
        .when(normalizado == "pedidosya", F.lit("PedidosYa"))
        .when(normalizado == "didifood", F.lit("DiDi Food"))
        .otherwise(app).alias("aplicativo"),
        tipo("Monto_Bruto_Vendido", "DECIMAL(18,2)").alias("monto_bruto"),
        tipo("Porcentaje_Comision", "DECIMAL(8,4)").alias("tasa_comision"),
    ).na.drop().filter("monto_bruto >= 0 AND tasa_comision BETWEEN 0 AND 1")
    .withColumn("comision_estimada", F.round(F.col("monto_bruto") * F.col("tasa_comision"), 2))
)

publicidad_limpia = (
    dfPublicidad.select(
        F.expr("try_cast(concat(Periodo, '-01') AS DATE)").alias("mes"),
        F.trim("Sede_Objetivo").alias("sede"),
        F.trim("Plataforma_Ad").alias("plataforma"),
        tipo("Inversion_Soles", "DECIMAL(18,2)").alias("inversion_soles"),
    ).na.drop().filter("inversion_soles >= 0")
)

print("Comentarios vacíos en origen:", dfSatisfaccion.filter(sin_comentario).count())
display(satisfaccion_limpia.groupBy("sede").agg(
    F.count("*").alias("encuestas"), F.round(F.avg("puntuacion"), 2).alias("puntuacion_promedio")
))
display(delivery_limpio.groupBy("aplicativo_origen", "aplicativo").count().orderBy("aplicativo"))
display(publicidad_limpia.groupBy("sede").agg(F.sum("inversion_soles").alias("inversion_total")))

# COMMAND ----------

# MAGIC %md
# MAGIC # 6. Construir indicadores y conciliar con BI

# COMMAND ----------

from decimal import Decimal

kpi_mes = (
    ventas_limpias.withColumn("mes", F.trunc("fecha", "month"))
    .groupBy("mes", "sede", "categoria")
    .agg(
        F.count("*").alias("filas_exportadas"),
        F.sum("cantidad").alias("unidades"),
        F.sum("ingresos").alias("ingresos"),
        F.sum("insumos").alias("insumos"),
        F.sum("costo_operativo").alias("costo_operativo"),
        F.sum("utilidad").alias("utilidad"),
        F.round(F.avg("ingresos"), 2).alias("ingreso_promedio_por_fila"),
    ).withColumn("anio", F.year("mes"))
)

comas_2025 = kpi_mes.filter("anio = 2025 AND sede = 'Baradero 21 - Comas'").agg(
    F.sum("ingresos").alias("ingresos"),
    F.sum("costo_operativo").alias("costo_operativo"),
    F.sum("utilidad").alias("utilidad"),
    F.round(F.try_divide(F.sum("utilidad"), F.sum("ingresos")) * 100, 2).alias("margen_pct"),
)
display(comas_2025)
resultado = comas_2025.first()
esperado = tuple(Decimal(valor) for valor in ("380254.00", "307136.92", "73117.08", "19.23"))
assert tuple(resultado) == esperado, f"Revisa el cuadre de Comas 2025: {resultado}"

# COMMAND ----------

# MAGIC %md
# MAGIC # 7. Persistir en Delta

# COMMAND ----------

esquema = "workspace.baradero_final"
ventas_limpias.write.format("delta").mode("overwrite").saveAsTable(f"{esquema}.bd_ventas_limpias")
kpi_mes.write.format("delta").mode("overwrite").saveAsTable(f"{esquema}.bd_kpi_mes")
publicidad_limpia.write.format("delta").mode("overwrite").saveAsTable(f"{esquema}.bd_publicidad")
satisfaccion_limpia.write.format("delta").mode("overwrite").saveAsTable(f"{esquema}.bd_satisfaccion")
delivery_limpio.write.format("delta").mode("overwrite").saveAsTable(f"{esquema}.bd_delivery")


# COMMAND ----------

# MAGIC %sql
# MAGIC SHOW TABLES IN workspace.baradero_final

# COMMAND ----------

# MAGIC %md
# MAGIC # 8. Consultar y visualizar los resultados
# MAGIC
# MAGIC

# COMMAND ----------

# MAGIC %sql
# MAGIC select sede,
# MAGIC        SUM(ingresos) as ingresos,
# MAGIC        SUM(costo_operativo) as costo_operativo,
# MAGIC        SUM(utilidad) as utilidad,
# MAGIC        ROUND(100 * TRY_DIVIDE(SUM(utilidad), SUM(ingresos)), 2) AS margen_pct
# MAGIC  FROM workspace.baradero_final.bd_kpi_mes
# MAGIC  WHERE anio = 2025
# MAGIC  GROUP BY sede
# MAGIC ORDER BY utilidad DESC

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT
# MAGIC     categoria,
# MAGIC     ROUND(SUM(utilidad), 2) AS utilidad_total
# MAGIC FROM workspace.baradero_final.bd_kpi_mes
# MAGIC WHERE anio = 2025
# MAGIC   AND sede = 'Baradero 21 - Comas'
# MAGIC GROUP BY categoria
# MAGIC ORDER BY utilidad_total DESC;

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT
# MAGIC     mes,
# MAGIC     ROUND(SUM(utilidad), 2) AS utilidad_mensual
# MAGIC FROM workspace.baradero_final.bd_kpi_mes
# MAGIC WHERE anio = 2025
# MAGIC   AND sede = 'Baradero 21 - Comas'
# MAGIC GROUP BY mes
# MAGIC ORDER BY mes;