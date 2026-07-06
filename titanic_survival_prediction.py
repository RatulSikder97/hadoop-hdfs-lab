"""
Name  : RATUL SIKDER
Roll  : 2506102
Course: MITE 431 - Big Data Analytics

Part A: Titanic Survival Prediction — PySpark MLlib (Logistic Regression)
Dataset: dataset/Titanic-Dataset.csv (Kaggle)
"""
import os

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, count, when, mean
from pyspark.ml import Pipeline
from pyspark.ml.feature import StringIndexer, OneHotEncoder, VectorAssembler
from pyspark.ml.classification import LogisticRegression
from pyspark.ml.evaluation import (
    MulticlassClassificationEvaluator,
    BinaryClassificationEvaluator,
)

# ---- Task 1: Create a SparkSession and load the dataset ----
spark = (
    SparkSession.builder
    .appName("TitanicSurvivalPrediction")
    .master(os.environ.get("SPARK_MASTER_URL", "local[*]"))
    .getOrCreate()
)
spark.sparkContext.setLogLevel("ERROR")

df = spark.read.csv("dataset/Titanic-Dataset.csv", header=True, inferSchema=True)

# ---- Task 2: Explore the schema and basic statistics ----
df.printSchema()
df.describe("Survived", "Pclass", "Age", "SibSp", "Parch", "Fare").show()

# ---- Task 3: Identify and handle missing values ----
#      Age      -> impute with mean
#      Cabin    -> drop column (too sparse)
#      Embarked -> fill with mode "S"
df.select([count(when(col(c).isNull(), c)).alias(c) for c in df.columns]).show()
mean_age = df.select(mean(col("Age"))).first()[0]
df = df.drop("Cabin").fillna({"Age": mean_age, "Embarked": "S"})

# ---- Task 4: Select input features (identifiers excluded) ----
feature_cols = ["Pclass", "Sex", "Age", "SibSp", "Parch", "Fare", "Embarked"]
label_col = "Survived"
df = df.select(feature_cols + [label_col])

# ---- Task 5: Encode categorical attributes (Sex, Embarked) ----
sex_indexer = StringIndexer(inputCol="Sex", outputCol="SexIndex")
embarked_indexer = StringIndexer(inputCol="Embarked", outputCol="EmbarkedIndex")
encoder = OneHotEncoder(
    inputCols=["SexIndex", "EmbarkedIndex"],
    outputCols=["SexVec", "EmbarkedVec"],
)

# ---- Task 6: Combine all features into a single vector ----
assembler = VectorAssembler(
    inputCols=["Pclass", "SexVec", "Age", "SibSp", "Parch", "Fare", "EmbarkedVec"],
    outputCol="features",
)

# ---- Task 7: Split into training and testing sets (80/20) ----
train_df, test_df = df.randomSplit([0.8, 0.2], seed=42)

# ---- Task 8: Train a Logistic Regression classifier ----
lr = LogisticRegression(featuresCol="features", labelCol=label_col, maxIter=100)
pipeline = Pipeline(stages=[sex_indexer, embarked_indexer, encoder, assembler, lr])
model = pipeline.fit(train_df)

# ---- Task 9: Generate predictions on the test dataset ----
predictions = model.transform(test_df)

# ---- Task 10: Evaluate the model (Accuracy, Precision, Recall, F1, AUC) ----
metrics = {}
for metric in ["accuracy", "weightedPrecision", "weightedRecall", "f1"]:
    metrics[metric] = MulticlassClassificationEvaluator(
        labelCol=label_col, predictionCol="prediction", metricName=metric
    ).evaluate(predictions)
auc = BinaryClassificationEvaluator(
    labelCol=label_col, metricName="areaUnderROC"
).evaluate(predictions)

print(f"Accuracy  : {metrics['accuracy']:.4f}")
print(f"Precision : {metrics['weightedPrecision']:.4f} (weighted)")
print(f"Recall    : {metrics['weightedRecall']:.4f} (weighted)")
print(f"F1-score  : {metrics['f1']:.4f}")
print(f"AUC (ROC) : {auc:.4f}")

# ---- Task 11: Display sample prediction results ----
predictions.select(
    "Pclass", "Sex", "Age", "Fare", "Survived", "prediction", "probability"
).show(15, truncate=False)

spark.stop()
