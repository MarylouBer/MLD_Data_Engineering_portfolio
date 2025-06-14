# Project 2: ETL Pipeline with Apache Airflow

This Python script defines an Apache Airflow DAG called `process_web_log` that runs daily. It implements a simple ETL pipeline with three tasks:

- **Extract**: Reads a web log file and extracts IP addresses.
- **Transform**: Filters out a specific unwanted IP (`198.46.149.143`).
- **Load**: Compresses the cleaned data into a `.tar` archive for storage.

Each step is defined as a Python function and executed in sequence using `PythonOperator` within the Airflow DAG.

