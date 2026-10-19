# E-Commerce Analytics: Olist Dataset

End-to-end analysis of **99K orders and R$ 16.01M in revenue** from the Brazilian E-Commerce Public Dataset (Olist). The project covers the full analyst workflow: raw CSVs, a cleaned MySQL database, 30+ business queries, a 4-page Power BI dashboard and a written project report.

**Headline findings:** only **3%** of customers buy again, **7.87%** of orders arrive late (worst in AL, MA, PI and CE), and **42%** of customers are in São Paulo state.

## 📊 Power BI Dashboard

[![Executive Overview](powerbi_dashboard/page1_executive.png)](powerbi_dashboard/page1_executive.png)

A 4-page interactive dashboard built on the cleaned database:

- **Executive Overview**: KPIs, monthly order trend, top categories by revenue
- **Customer Analytics**: geographic distribution, repeat vs one-time customers
- **Operations Analytics**: delivery performance, late orders by state, top sellers
- **Management Insights**: key findings and 5 prioritised recommendations

📂 [Dashboard documentation](powerbi_dashboard/README.md) · 📄 [Full project report (PDF)](Documentation/Project_Report.pdf)

---

## 📋 Business Problem

Analyse an e-commerce marketplace to find its revenue drivers, customer behaviour, delivery performance and seller quality, so that management can make data-driven decisions.

## 🎯 Objectives

- Build a relational database from 9 raw CSV files
- Clean and validate 1.5M+ rows in SQL
- Answer 30+ business questions with SQL queries
- Present the results in a 4-page Power BI dashboard for managers

## 🛠️ Tools Used

- **MySQL**: database design, data cleaning and all analysis queries
- **Power BI**: interactive dashboard
- **Power Query**: data transformation
- **DAX**: calculated measures

## 🗄️ Dataset and Schema

**Source:** [Brazilian E-Commerce Public Dataset by Olist (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

9 tables, about 1.5M rows in total:

`customers` · `orders` · `order_items` · `order_payments` · `order_reviews` · `products` · `sellers` · `geolocation` · `product_category_translation`

## 🧹 Data Cleaning and Challenges Solved

All cleaning was done in SQL (see `analysis_queries.sql`):

| Problem | What I did |
| --- | --- |
| **Composite key** in `order_reviews` | Defined the primary key as `(review_id, order_id)` so the table loads correctly |
| **Duplicate rows in `geolocation`** (about 280K) | Checked total vs distinct rows, rebuilt the table with `SELECT DISTINCT`, then verified the new row count |
| **Missing product weight and dimensions** (2 products) | Calculated medians with `ROW_NUMBER()` and filled them in (weight 700 g, length 25 cm, height 13 cm, width 20 cm) |
| **Missing product categories** | Replaced with `uncategorized` |
| **Spelling errors in column names** | Renamed `product_name_lenght` and `product_description_lenght` to `length` |
| **Broken relationships** | Checked for orphan orders, items and sellers, then added 6 foreign keys |
| **Fan-out when joining orders to payments** | Wrote queries at the correct grain so revenue is not double counted |

## 🔍 Key SQL Techniques Used

- Joins (INNER, LEFT) across 4+ tables
- Window functions (RANK, LAG, ROW_NUMBER)
- Common Table Expressions (CTEs)
- Conditional aggregation (CASE WHEN + SUM)
- Subqueries and correlated subqueries
- Date functions and month-over-month analysis

## 📊 Key Business Insights

- **Revenue:** R$ 16.01M across 99K orders, average order value R$ 160.99, average review score 4.09
- **Top categories:** Health & Beauty (R$ 1.25M) and Watches & Gifts (R$ 1.2M)
- **Geography:** São Paulo state holds **42%** of customers
- **Retention:** only **3%** of customers are repeat buyers
- **Delivery:** **97%** of orders are delivered, but **7.87%** arrive late, and AL, MA, PI and CE run at about twice the national late rate

## 💡 Recommendations

1. **Improve retention:** launch a loyalty programme and post-purchase campaigns. Proposed target: repeat rate from 3% to 8% in 12 months.
2. **Expand beyond São Paulo:** increase marketing in RJ, MG and RS, where customer density is high but still under-penetrated.
3. **Fix late deliveries:** partner with regional logistics providers in AL, MA, PI and CE. Proposed target: late rate from 7.87% to below 5%.
4. **Double down on winners:** prioritise Health & Beauty and Watches & Gifts in ad spend and stock.
5. **Investigate low-rated sellers:** identify sellers averaging below 3 stars and enforce quality standards.

*Targets are proposed goals based on the findings, not forecasts.*

## 📁 Repository Structure

```
ecommerce-analytics-olist/
├── analysis_queries.sql     # Schema, data cleaning and 30+ analysis queries
├── powerbi_dashboard/       # Dashboard screenshots and documentation
├── Documentation/           # Project report (PDF)
└── README.md
```

## 🚀 How to Run

1. Download the CSV files from the Kaggle link above.
2. Open `analysis_queries.sql` in MySQL Workbench and run the schema section to create the `ecommerce_olist` database and tables.
3. Load the 9 CSV files into the matching tables.
4. Run the cleaning section, then the analysis queries.

> The Power BI source file (`.pbix`) is available on request because it exceeds GitHub's file size limit.

## 👤 Author

**Yusuf Baig**, Data Analyst | Open to roles in Dubai, UAE

- LinkedIn: [yusuf-baig-783906210](https://www.linkedin.com/in/yusuf-baig-783906210/)
- GitHub: [@Yusufbaig2001](https://github.com/Yusufbaig2001)
