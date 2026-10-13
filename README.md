# Superstore Sales Analysis (SQL)

SQL project on the Superstore sales dataset. I turned the flat file into a relational database and
answered business questions with 10 queries covering the SQL topics most asked in data analyst interviews.

**Tools:** SQL (SQLite), Python (loading script only)
**Data:** Sample Superstore dataset: 9,994 order lines, 5,009 orders, 793 customers, Jan 2014 to Dec 2017
**Related project:** [Sales Performance Dashboard (Power BI)](https://github.com/Tanvi-rode/sales-performance-dashboard-powerbi), built on the same data. The SQL totals match the dashboard KPIs.

## Database design

| Table | Rows | Key | Holds |
|---|---|---|---|
| `customers` | 793 | `customer_id` | name, segment |
| `products` | 1,862 | `product_id` | name, category, sub-category |
| `orders` | 5,009 | `order_id` | dates, ship mode, customer, city, state, region |
| `order_items` | 9,994 | `row_id` | order, product, sales, quantity, discount, profit |

`order_items` links to `orders` and `products`; `orders` links to `customers`.

## The 10 queries

| # | Business question | SQL concept |
|---|---|---|
| 1 | Overall sales, profit, margin, orders, average order value | Aggregate functions, `COUNT(DISTINCT)` |
| 2 | Sales and margin by category | `JOIN`, `GROUP BY` |
| 3 | Top 10 customers by sales | Multi-table `JOIN`, `ORDER BY`, `LIMIT` |
| 4 | Sub-categories that lose money | `HAVING` |
| 5 | How discount level affects profit | `CASE WHEN` |
| 6 | Duplicate records | `GROUP BY` + `HAVING COUNT(*) > 1` |
| 7 | Customers who spent above the average | Subquery |
| 8 | Yearly sales and year-over-year growth | CTE + `LAG()` |
| 9 | Monthly sales with a running total | `SUM() OVER (ORDER BY ...)` |
| 10 | Top 3 products in each category | `ROW_NUMBER()` + `PARTITION BY` |

## Project files

```
superstore-sql-project/
├── data/Sample_-_Superstore.csv     raw data
├── build_database.py                loads the CSV and creates superstore.db
├── sql/
│   ├── 01_create_tables.sql         schema, keys, indexes, date conversion
│   └── 02_analysis_queries.sql      the 10 queries
└── README.md
```

## How to run it

1. Install Python 3 and [DB Browser for SQLite](https://sqlitebrowser.org/) (both free).
2. Run `python build_database.py`. This creates `superstore.db`.
3. Open `superstore.db` in DB Browser, go to **Execute SQL**, and run the queries in `sql/02_analysis_queries.sql` one at a time.

## Key insights

1. **Discounts are the biggest profit leak.** Items sold with no discount earn a 29.5% margin, while items discounted above 40% lose 77% of their sales value. Any discount above 20% loses money overall.
2. **Furniture grows sales but not profit.** It makes $742K in sales at a 2.5% margin, compared with about 17% for Technology and Office Supplies. Tables and Bookcases both lose money.
3. **Sales grew 29.5% in 2016 and 20.4% in 2017** after a small dip in 2015.
4. **The top customer (Sean Miller, $25K in sales) made a loss** of about $2K, so high sales do not always mean high profit.

## Data quality notes
- One duplicated line item was found (order `US-2014-150119`) and kept as is.
- 32 product IDs have more than one product name in the raw data. The schema keeps one name per ID so product results are not split.

## Author
Tanvi Rode | Data Analyst (Fresher) | Thane, Maharashtra
