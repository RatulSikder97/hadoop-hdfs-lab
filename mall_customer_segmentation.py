"""
Name  : RATUL SIKDER
Roll  : 2506102
Course: MITE 431 - Big Data Analytics

Part B: Mall Customer Segmentation — PySpark MLlib (K-Means, k=5)
Dataset: dataset/Mall_Customers.csv (Kaggle)
"""
import os

from pyspark.sql import SparkSession
from pyspark.ml import Pipeline
from pyspark.ml.feature import VectorAssembler, StandardScaler
from pyspark.ml.clustering import KMeans
from pyspark.ml.evaluation import ClusteringEvaluator

# ---- Task 1: Create a SparkSession and load the dataset ----
spark = (
    SparkSession.builder
    .appName("MallCustomerSegmentation")
    .master(os.environ.get("SPARK_MASTER_URL", "local[*]"))
    .getOrCreate()
)
spark.sparkContext.setLogLevel("ERROR")

df = spark.read.csv("dataset/Mall_Customers.csv", header=True, inferSchema=True)

# Rename the Kaggle headers to simple column names
renames = {
    "Annual Income (k$)": "AnnualIncome",
    "Spending Score (1-100)": "SpendingScore",
    "Genre": "Gender",
}
for old, new in renames.items():
    if old in df.columns:
        df = df.withColumnRenamed(old, new)

# ---- Task 2: Explore the schema and descriptive statistics ----
df.printSchema()
df.describe("Age", "AnnualIncome", "SpendingScore").show()

# ---- Task 3: Select the numerical features for clustering ----
feature_cols = ["Age", "AnnualIncome", "SpendingScore"]

# ---- Task 4: Create the feature vector with VectorAssembler ----
assembler = VectorAssembler(inputCols=feature_cols, outputCol="features_raw")

# ---- Task 5: Standardize the features with StandardScaler ----
scaler = StandardScaler(
    inputCol="features_raw", outputCol="features", withMean=True, withStd=True
)

# ---- Task 6: Apply the K-Means clustering algorithm (k = 5) ----
kmeans = KMeans(featuresCol="features", predictionCol="cluster", k=5, seed=42)
pipeline = Pipeline(stages=[assembler, scaler, kmeans])
model = pipeline.fit(df)
clustered = model.transform(df)

silhouette = ClusteringEvaluator(
    featuresCol="features", predictionCol="cluster"
).evaluate(clustered)
print(f"Silhouette score (k=5): {silhouette:.4f}")

# ---- Task 7: Display the cluster assignment for each customer ----
clustered.select("CustomerID", "Gender", *feature_cols, "cluster").show(
    clustered.count(), truncate=False
)
clustered.groupBy("cluster").count().orderBy("cluster").show()

# ---- Task 8: Print the cluster centers ----
#      Standardized space first, then means in original units
kmeans_model = model.stages[-1]
for i, center in enumerate(kmeans_model.clusterCenters()):
    print(f"Cluster {i}: {[round(float(v), 3) for v in center]}")
clustered.groupBy("cluster").avg(*feature_cols).orderBy("cluster").show()

# ---- Task 9: Interpretation of the clusters (see report discussion) ----
spark.stop()
