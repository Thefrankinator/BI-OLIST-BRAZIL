# BI Project — Olist (Brazilian E-commerce)

CAP-PREP project: an end-to-end BI pipeline built on the public **Olist** dataset (Brazilian e-commerce, Kaggle).

```
Raw CSV files (Kaggle) → Pentaho Data Integration (ETL) → SQL Server (olist_dw warehouse) → Power BI (reporting)
```

The detailed step-by-step process is documented in [`Plan-Projet.md`](Plan-Projet.md). This document summarizes the outcome: the data model, the design choices, the challenges encountered and the resulting dashboard.

---

## 1. Business objective

Use the real Olist data to answer questions such as:
- What is the total revenue and how does it evolve month by month?
- Which cities / product categories generate the most orders?
- What is the average delivery time?
- Which states (Brazilian regions) contribute the most to revenue?

---

## 2. Data model (star schema)

Created by [`migrations/01_create_database.sql`](migrations/01_create_database.sql) and [`migrations/02_create_tables.sql`](migrations/02_create_tables.sql).

**Fact table** — `fact_order_items` (grain: one row = one item of an order)
- Measures: `total_price`, `total_freight_value`, `total_order_items`, `delays` (gap between actual and estimated delivery date)
- Foreign keys: `product_key`, `customer_key`, `seller_key`, and 3 keys to `dim_date` (purchase date, delivery date, estimated delivery date)

**Dimensions**
| Table | Content |
|---|---|
| `dim_customers` | `customer_id`, `customer_city`, `customer_state` |
| `dim_seller` | `seller_id`, `seller_state` |
| `dim_products` | `product_id`, `product_weight_g` |
| `dim_date` | full date + year / quarter / month / day of week (generated, not provided by Olist) |

---

## 3. ETL (Pentaho Data Integration)

The job [`ETL/ETL_pipeline.kjb`](ETL/ETL_pipeline.kjb) runs the transformations in order (dimensions before facts, to satisfy foreign key constraints):

```
dim_customer → dim_product → dim_date → dim_seller → fact_order_items
```

Data quality handling applied during ETL (see the anomalies identified during exploration in [`dataset/NOTES.md`](dataset/NOTES.md)):
- **Product categories**: Portuguese → English translation via a join with `product_category_name_translation.csv` (handling the UTF-8 BOM at the start of that file); value set to `"unknown"` when the category is missing.
- **Encoding**: text columns stored as `NVARCHAR` in SQL Server to support Brazilian Portuguese accented characters.

---

## 4. Power BI dashboard

File: [`olist_DW_VISUALISATION.pbix`](olist_DW_VISUALISATION.pbix) — connected to `olist_dw` in **Import** mode. Shared filters: **Year** and **Month**.

### Overview
![Overview](images/Vue_generale.png)

Global KPIs (total revenue, number of orders, average delivery time), revenue vs. freight cost breakdown, and total revenue by state.

### Page 1 — Sales & geographic distribution
![Page 1](images/page_1.png)

Top 10 cities by number of orders, monthly evolution of revenue and number of orders.

### Page 2 — Products
![Page 2](images/page_2.png)

Top 10 most ordered product categories, top 10 breakdown by state (state filter, e.g. São Paulo).

---

## 5. Challenges & design choices

- **`customer_id` ≠ `customer_unique_id`**: a single physical customer can have several `customer_id` values (one per order). The DW deliberately keeps `customer_id` as the technical key of the dimension — it is not a truly deduplicated customer dimension.
- **Null delivery dates** in `orders`: expected for undelivered/canceled orders and not artificially "fixed" — hence `date_order_del_cust_id` is nullable in `fact_order_items`.
- **Drift between SQL scripts and the actual database**: the migrations were not always kept up to date after changes made directly in SSMS.

---

## 6. Reproducing the project

1. SQL Server: run [`migrations/01_create_database.sql`](migrations/01_create_database.sql) then [`migrations/02_create_tables.sql`](migrations/02_create_tables.sql) in SSMS.
2. Place the Olist CSV files (Kaggle) in `dataset/` (folder ignored by git, see `.gitignore`).
3. Pentaho: open [`ETL/ETL_pipeline.kjb`](ETL/ETL_pipeline.kjb) in Spoon and run it (SQL Server JDBC driver required in PDI's `lib` folder).
4. Power BI: open [`olist_DW_VISUALISATION.pbix`](olist_DW_VISUALISATION.pbix) and refresh the connection to `olist_dw` if needed.

---

## 7. Repository structure

```
ETL/          Pentaho transformations and job (.ktr / .kjb)
migrations/   SQL scripts creating the olist_dw warehouse
dataset/      Olist source CSVs (not versioned) + exploration notes
images/       Power BI dashboard screenshots
Plan-Projet.md   detailed step-by-step project log
olist_DW_VISUALISATION.pbix   the Power BI report
```
