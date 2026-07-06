# Lab 4 - Machine Learning with PySpark MLlib

**Name:** RATUL SIKDER
**Roll:** 2506102
**Course:** MITE 431 - Big Data Analytics

This lab covers two machine learning tasks using PySpark MLlib on a Spark standalone cluster running in Docker.

| Part | Task | Algorithm | Dataset |
|------|------|-----------|---------|
| A | Supervised: predict passenger survival | Logistic Regression | Titanic (Kaggle) |
| B | Unsupervised: customer segmentation | K-Means (k=5) | Mall Customers (Kaggle) |

## Project Structure

```
.
├── titanic_survival_prediction.py      # Part A source code
├── titanic_survival_prediction.ipynb   # Part A notebook (with outputs)
├── mall_customer_segmentation.py       # Part B source code
├── mall_customer_segmentation.ipynb    # Part B notebook (with outputs)
├── dataset/                            # both CSV files
├── docker-compose.yml                  # Spark cluster (master, worker, client, jupyter)
├── Dockerfile                          # Spark 4.1.2 + numpy
└── Dockerfile.jupyter                  # same image + JupyterLab
```

## How to Run

Start the cluster:

```bash
docker compose up -d --build
```

This starts four containers:

| Container | Purpose | URL |
|-----------|---------|-----|
| spark-master | cluster manager | http://localhost:8080 |
| spark-worker | executor (4 cores, 4 GB) | http://localhost:8081 |
| spark-client | for spark-submit | - |
| spark-jupyter | JupyterLab | http://localhost:8888 |

Run the scripts on the cluster:

```bash
docker compose exec spark-client /opt/spark/bin/spark-submit titanic_survival_prediction.py
docker compose exec spark-client /opt/spark/bin/spark-submit mall_customer_segmentation.py
```

Or open http://localhost:8888 and run the notebooks. The code reads `SPARK_MASTER_URL` from the environment, so the same scripts also run locally without Docker (`pip install pyspark numpy`, then `python titanic_survival_prediction.py`).

Stop the cluster:

```bash
docker compose down
```

## Results

**Part A - Titanic (Logistic Regression):** missing Age values were imputed with the mean, the Cabin column was dropped and Embarked was filled with the mode. Sex and Embarked were encoded with StringIndexer and OneHotEncoder, and the model was trained on an 80/20 split.

| Metric | Value |
|--------|-------|
| Accuracy | 0.8276 |
| Precision (weighted) | 0.8261 |
| Recall (weighted) | 0.8276 |
| F1-score | 0.8265 |
| AUC (ROC) | 0.8941 |

**Part B - Mall Customers (K-Means, k=5):** features were standardized with StandardScaler before clustering. Silhouette score: 0.5834.

| Cluster | Avg Age | Avg Income (k$) | Avg Spending | Customer Group |
|---------|---------|-----------------|--------------|----------------|
| 0 | 32.9 | 86.1 | 81.5 | Target customers |
| 1 | 55.5 | 47.9 | 41.9 | Older regular customers |
| 2 | 44.4 | 89.8 | 18.5 | Rich but low spenders |
| 3 | 27.1 | 52.0 | 41.0 | Young regular customers |
| 4 | 25.5 | 26.3 | 78.6 | Young impulsive buyers |

Detailed discussion of both tasks is available in the notebooks.
