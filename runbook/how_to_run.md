# ▶ How to Run the Project

This document explains how to execute the analytical SQL queries in this repository.

---

## 1️⃣ Ensure Database Is Set Up

If not already done, execute:

```sql
sql/00_setup/00_create_schema.sql
sql/00_setup/01_constraints_indexes.sql
sql/00_setup/02_seed.sql
```


Run them in this exact order.

---

## 2️⃣ Run Analytical Queries

Navigate to the desired folder and execute SQL files one by one.

Example:
```sql
sql/01_mrr/01_net_mrr_mom.sql
sql/01_mrr/02_top_plan_net_mrr.sql
sql/02_retention/03_cohort_retention.sql
sql/03_activation/04_ttfv.sql
sql/04_churn/05_usage_drop.sql
sql/05_billing_quality/06_expansion_contraction.sql
sql/05_billing_quality/07_duplicate_billing.sql
sql/06_attribution/08_attribution_full_join.sql
sql/07_power_users/09_pareto_80.sql
sql/08_upgrades/10_upgrade_path.sql
```

Each file is independent and can be executed separately.

---

## 3️⃣ Export Results (Optional)

To save results:

1. Execute query in DBeaver  
2. Right-click result grid  
3. Select **Export Data**  
4. Save as CSV  
5. Store in `/results/`

---

## 4️⃣ If You See “relation does not exist”

Run:

```sql
SET search_path TO saas;
```

Or reference tables explicitly:

```sql
SELECT * FROM saas.invoices;
```

## 5️⃣ Notes

* Data is fully synthetic
* Results may vary slightly due to randomness
* Some analytical scenarios may not appear in every run
