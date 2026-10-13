"""Builds superstore.db from the CSV using only the Python standard library.

Usage:  python build_database.py
Output: superstore.db  (open it in DB Browser for SQLite and run the files in /sql)
"""
import csv, sqlite3, pathlib

BASE = pathlib.Path(__file__).parent
CSV_FILE = BASE / "data" / "Sample_-_Superstore.csv"
DB_FILE = BASE / "superstore.db"

if DB_FILE.exists():
    DB_FILE.unlink()
con = sqlite3.connect(DB_FILE)

# 1. Staging table: the CSV loaded as-is
con.execute("""
CREATE TABLE stg_superstore (
    row_id INTEGER, order_id TEXT, order_date TEXT, ship_date TEXT, ship_mode TEXT,
    customer_id TEXT, customer_name TEXT, segment TEXT, country TEXT, city TEXT,
    state TEXT, postal_code TEXT, region TEXT, product_id TEXT, category TEXT,
    sub_category TEXT, product_name TEXT, sales REAL, quantity INTEGER,
    discount REAL, profit REAL)""")

with open(CSV_FILE, newline="", encoding="latin-1") as f:
    reader = csv.reader(f)
    next(reader)  # skip header
    con.executemany("INSERT INTO stg_superstore VALUES (" + ",".join("?" * 21) + ")", reader)

# 2. Run the schema script to create the normalized tables
con.executescript((BASE / "sql" / "01_create_tables.sql").read_text())
con.commit()

for t in ("stg_superstore", "customers", "products", "orders", "order_items"):
    print(f"{t:15} {con.execute(f'SELECT COUNT(*) FROM {t}').fetchone()[0]:>6} rows")
con.close()
