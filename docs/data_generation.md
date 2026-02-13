# 🧪 Synthetic Data Generation

This project uses **synthetic data** generated in PostgreSQL to simulate a realistic SaaS business:  
accounts → users → subscriptions → invoices → refunds, plus product usage events and acquisition attribution.  

The dataset is intentionally designed for **SQL analytics practice** (CTEs, joins, window functions, cohort logic, billing edge cases).

### Why synthetic?

The data is synthetic to:
- avoid privacy and compliance issues
- keep the project fully reproducible
- make it possible to simulate SaaS analytics scenarios end-to-end


### Database design note (OLTP vs star schema)

The schema is a **normalized OLTP-style relational model**, similar to how a SaaS product would store operational data.  
It is **not** a star schema.  

Analytical outputs (MRR, retention, churn signals) are intentionally derived from transactional tables using JOINs and window functions.  

### Where the generator code lives

Synthetic data is generated via SQL scripts (PostgreSQL):

- `sql/00_setup/00_create_schema.sql` — schema + tables + PK/FK + constraints
- `sql/00_setup/01_constraints_indexes.sql` — performance indexes
- `sql/00_setup/02_seed.sql` — synthetic data inserts

### Reproducibility

Run scripts in order:
1) `sql/00_setup/00_create_schema.sql`  
2) `sql/00_setup/01_constraints_indexes.sql`  
3) `sql/00_setup/02_seed.sql`

Optional: to make randomness reproducible within a session, add at the top of `02_seed.sql`:  
```sql  
SELECT setseed(0.42);
