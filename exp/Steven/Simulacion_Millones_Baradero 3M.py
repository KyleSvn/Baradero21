# Databricks notebook source
# /// script
# [tool.databricks.environment]
# environment_version = "6"
# ///
# MAGIC %md
# MAGIC # Simulación de rentabilidad por sede de Baradero 21

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Definir los escenarios y el número de filas
# MAGIC A usa los importes de referencia con variaciones aleatorias moderadas. B aplica un aumento de 3 % en los ingresos por las mismas unidades y un aumento del costo de insumos distinto en cada sede. Los gastos restantes se mantienen iguales entre A y B. Estos porcentajes son parte del experimento.

# COMMAND ----------

from datetime import datetime
from time import perf_counter
from zoneinfo import ZoneInfo

from pyspark.sql import Window
from pyspark.sql import functions as F

N = 3_000_000
SEMILLA = 42
ESQUEMA = "workspace.baradero_final"
fuente = f"{ESQUEMA}.bd_ventas_limpias"
tabla_ventas = f"{ESQUEMA}.exp_steven_sim_ventas"
tabla_resumen = f"{ESQUEMA}.exp_steven_sim_resumen"

print(f"Filas objetivo: {N:,} | Semilla: {SEMILLA} | Spark: {spark.version}")
print(datetime.now(ZoneInfo("America/Lima")).isoformat(timespec="seconds"))

supuestos = spark.createDataFrame([
    (0, "Los Olivos", 8),
    (1, "Comas", 12),
    (2, "Puente Piedra", 16),
], ["id_sede", "sede", "aumento_insumos_pct"])
display(supuestos)

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Preparar el perfil base
# MAGIC La referencia de 2025 proviene de filas agrupadas por fecha, sede, producto, categoría y empleado. Cada fila sintética representa un grupo simulado de ventas. La selección aleatoria preserva aproximadamente la mezcla de las sedes, los meses y los productos del archivo de referencia.

# COMMAND ----------

campos_base = [
    "fecha", "id_sede", "id_producto", "id_categoria", "id_empleado",
    "categoria", "cantidad", "ingresos", "insumos", "costo_operativo",
]
base = spark.table(fuente).filter(
    "fecha >= DATE '2025-01-01' AND fecha < DATE '2026-01-01'"
).select(*campos_base)

claves = ["fecha", "id_sede", "id_producto", "id_categoria", "id_empleado"]
assert base.groupBy(*claves).count().filter("count > 1").limit(1).count() == 0
calidad = base.agg(
    F.count("*").alias("filas"),
    F.count(F.when(
        F.col("cantidad").isNull() | F.col("ingresos").isNull() |
        F.col("insumos").isNull() | F.col("costo_operativo").isNull() |
        (F.col("cantidad") <= 0) | (F.col("ingresos") <= 0) |
        (F.col("insumos") < 0) | (F.col("costo_operativo") < F.col("insumos")) |
        ~F.col("id_sede").isin(0, 1, 2),
        1,
    )).alias("invalidas"),
).first()
assert calidad.filas > 0 and calidad.invalidas == 0, calidad

print(f"Filas de referencia de 2025: {calidad.filas:,} | Filas inválidas: {calidad.invalidas}")
display(base.groupBy("id_sede").agg(
    F.count("*").alias("filas_base"),
    F.sum("ingresos").alias("ingresos_referencia"),
    F.sum("costo_operativo").alias("costos_referencia"),
).orderBy("id_sede"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Generar y guardar las ventas sintéticas
# MAGIC Para cada identificador sintético se obtienen números seudoaleatorios a partir de la semilla. Se usan para elegir un perfil de venta, variar el ingreso entre −10 % y +10 %, y variar los costos base entre −8 % y +8 %. El escenario B se calcula sobre esa misma fila. 

# COMMAND ----------

def entero_aleatorio(etiqueta, opciones):
    numero = F.xxhash64(F.col("id_sintetico"), F.lit(SEMILLA), F.lit(etiqueta))
    return F.pmod(numero, F.lit(opciones))

def importe(columna):
    return F.round(columna, 2).cast("decimal(18,2)")

def mil_a_factor(columna):
    return columna.cast("decimal(7,0)") / F.lit(1000)

perfiles = base.withColumn(
    "id_perfil", F.row_number().over(Window.orderBy(*claves))
)

ids = spark.range(N).withColumnRenamed("id", "id_sintetico").withColumn(
    "id_perfil", (entero_aleatorio("perfil", calidad.filas) + 1).cast("int")
)

inicio = perf_counter()
a_y_b = (
    ids.join(F.broadcast(perfiles), "id_perfil")
    .join(F.broadcast(supuestos), "id_sede")
    .withColumn("factor_ingreso", mil_a_factor(F.lit(900) + entero_aleatorio("ingreso", 201)))
    .withColumn("factor_costos", mil_a_factor(F.lit(920) + entero_aleatorio("costo", 161)))
    .withColumn("ingresos_a", importe(F.col("ingresos") * F.col("factor_ingreso")))
    .withColumn("insumos_a", importe(F.col("insumos") * F.col("factor_costos")))
    .withColumn("otros_costos", importe((F.col("costo_operativo") - F.col("insumos")) * F.col("factor_costos")))
    .withColumn("ingresos_b", importe(F.col("ingresos_a") * F.lit("1.03").cast("decimal(4,2)")))
    .withColumn("insumos_b", importe(F.col("insumos_a") * (1 + F.col("aumento_insumos_pct").cast("decimal(5,2)") / 100)))
    .withColumn("costo_a", F.col("insumos_a") + F.col("otros_costos"))
    .withColumn("costo_b", F.col("insumos_b") + F.col("otros_costos"))
    .select(
        "id_sintetico", "fecha", "sede", "categoria", "id_producto", "cantidad",
        "ingresos_a", "ingresos_b", "insumos_a", "insumos_b", "otros_costos", "costo_a", "costo_b",
    )
)
a_y_b.write.format("delta").mode("overwrite").saveAsTable(tabla_ventas)
segundos = perf_counter() - inicio

guardadas = spark.table(tabla_ventas)
n = guardadas.count()
assert n == N, (n, N)
print(f"Filas guardadas: {n:,} | Generación y escritura Delta: {segundos:.3f} s")
display(guardadas.groupBy("sede").agg(
    F.count("*").alias("filas_sinteticas"), F.sum("cantidad").alias("unidades")
).orderBy("sede"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. Calcular los KPI y el cambio por sede
# MAGIC La simulación A y B se compara sobre el mismo número de filas y unidades. La utilidad se calcula restando el costo de los ingresos. El cambio de margen se presenta en puntos porcentuales.

# COMMAND ----------

def resumen_financiero(datos, etiqueta, ingreso, costo):
    return (
        datos.groupBy("sede").agg(
            F.count("*").alias("filas"),
            F.sum("cantidad").alias("unidades"),
            F.sum(ingreso).alias("ingresos"),
            F.sum(costo).alias("costo_operativo"),
        )
        .withColumn("escenario", F.lit(etiqueta))
        .withColumn("utilidad", F.col("ingresos") - F.col("costo_operativo"))
        .withColumn("margen_pct", F.round(100 * F.try_divide("utilidad", "ingresos"), 2))
        .withColumn("ingreso_por_fila", F.round(F.try_divide("ingresos", "filas"), 2))
        .withColumn("costo_por_fila", F.round(F.try_divide("costo_operativo", "filas"), 2))
    )

a = resumen_financiero(guardadas, "A · Simulado base", "ingresos_a", "costo_a")
b = resumen_financiero(guardadas, "B · Ingresos e insumos ajustados", "ingresos_b", "costo_b")
hist = resumen_financiero(
    base.join(supuestos.select("id_sede", "sede"), "id_sede"),
    "Referencia BI 2025", "ingresos", "costo_operativo",
)
resumen = a.unionByName(b).unionByName(hist)
resumen.write.format("delta").mode("overwrite").saveAsTable(tabla_resumen)
display(spark.table(tabla_resumen).orderBy("sede", "escenario"))

cambios = a.alias("a").join(b.alias("b"), "sede").selectExpr(
    "sede", "a.filas AS filas_por_escenario",
    "b.ingresos - a.ingresos AS cambio_ingresos",
    "b.costo_operativo - a.costo_operativo AS cambio_costos",
    "b.utilidad - a.utilidad AS cambio_utilidad",
    "round(b.margen_pct - a.margen_pct, 2) AS cambio_margen_pp",
)
display(cambios.orderBy("sede"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 5. Visualizar los escenarios

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT sede, escenario, filas, ingresos, costo_operativo, utilidad, margen_pct
# MAGIC FROM workspace.baradero_final.exp_steven_sim_resumen
# MAGIC WHERE escenario <> 'Referencia BI 2025'
# MAGIC ORDER BY sede, escenario