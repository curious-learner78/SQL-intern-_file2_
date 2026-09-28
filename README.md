# Advanced SQL Query Development for Sustainability Data

## 📌 Project Overview
This repository contains the Week 2 submission for the **Virtual Sustainability SQL Development Internship**. It demonstrates advanced SQL techniques for querying, aggregating, and extracting operational insights from environmental and energy datasets.

---

## 🛠️ Key SQL Queries Included

1. **Energy Trend & Rolling Averages:** Employs window functions (`LAG()`, `AVG() OVER()`) to measure Month-over-Month consumption shifts and 3-month rolling averages.
2. **Scope 1 vs Scope 2 Carbon Intensity:** Computes direct vs. indirect emissions per facility and evaluates carbon density per square meter ($\text{tCO}_2\text{e}/\text{m}^2$).
3. **Waste Diversion Rate Benchmarking:** Evaluates recycling efficiency percentages and applies `DENSE_RANK()` across regional operations.
4. **Energy Anomaly Outlier Detection:** Isolates consumption events exceeding 1.5 standard deviations above baseline averages.
5. **Unified Enterprise ESG Executive Summary:** Merges energy, emission, and waste records across multi-table CTEs into a consolidated reporting matrix.

---

## ⚡ Optimization & Indexing Strategies
* **Composite Indexing:** B-Tree indexes on `(facility_id, reading_date)` to optimize temporal range filtering.
* **Table Partitioning:** Range partitioning on high-volume transactional logs by calendar month.
* **Materialized Views:** Pre-aggregated views to accelerate executive reporting queries.
