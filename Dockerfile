# Spark 4.1.2 image (matches the pyspark version in the local .venv)
# extended with numpy, which pyspark.ml needs on the driver.
FROM apache/spark:4.1.2

USER root
RUN pip3 install --no-cache-dir numpy

# Run as the default non-root spark user; the project is mounted at /opt/app
USER spark
WORKDIR /opt/app
