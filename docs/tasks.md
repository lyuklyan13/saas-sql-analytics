
# ✅ SQL Practice Tasks (SaaS Analytics)

This document contains the **problem statements** for the SQL analytics tasks solved in this repository.
Each task links to its corresponding SQL solution and (when available) a sample output.

> Database: PostgreSQL  
> Schema: `saas` (synthetic OLTP-style SaaS dataset)

---

## 📌 Task Index

### 01) MRR
- **01. Net MRR by month + MoM% (refund-aware)** → [sql/01_mrr/01_net_mrr_mom.sql](../sql/01_mrr/01_net_mrr_mom.sql)  
  Sample: [results/01_net_mrr_sample.csv](../results/01_net_mrr_sample.csv)

- **02. Top plan by Net MRR each month (tie-break by accounts)** → [sql/01_mrr/02_top_plan_net_mrr.sql](../sql/01_mrr/02_top_plan_net_mrr.sql)

### 02) Retention
- **03. Cohort retention (logo retention) by month_number** → [sql/02_retention/03_cohort_retention.sql](../sql/02_retention/03_cohort_retention.sql)  
  Sample: [results/03_retention_sample.csv](../results/03_retention_sample.csv)

### 03) Activation
- **04. Time-to-First-Value (TTFV) + median by acquisition source** → [sql/03_activation/04_ttfv.sql](../sql/03_activation/04_ttfv.sql)

### 04) Churn
- **05. Usage drop ≥40% before cancel (weekly early warning)** → [sql/04_churn/05_usage_drop.sql](../sql/04_churn/05_usage_drop.sql)

### 05) Billing quality
- **06. Expansion vs Contraction between invoices (delta classification)** → [sql/05_billing_quality/06_expansion_contraction.sql](../sql/05_billing_quality/06_expansion_contraction.sql)

- **07. Duplicate billing: 2+ paid invoices in same month** → [sql/05_billing_quality/07_duplicate_billing.sql](../sql/05_billing_quality/07_duplicate_billing.sql)

### 06) Attribution
- **08. Attribution sanity check (FULL JOIN between sources)** → [sql/06_attribution/08_attribution_full_join.sql](../sql/06_attribution/08_attribution_full_join.sql)

### 07) Power users
- **09. Pareto 80/20: minimal users generating ≥80% usage per account (last 30d)** → [sql/07_power_users/09_pareto_80.sql](../sql/07_power_users/09_pareto_80.sql)

### 08) Upgrades
- **10. Plan upgrade path + most common transitions** → [sql/08_upgrades/10_upgrade_path.sql](../sql/08_upgrades/10_upgrade_path.sql)

---

# 🧩 Problem Statements

### 01. Net MRR by month + MoM% (refund-aware)

**Goal:** For each `invoice_month`, calculate:
- `gross_mrr` = sum of `invoices.amount` for **paid invoices only** (`paid_at IS NOT NULL`)
- `refunds` = sum of `refund_amount` grouped by **refund month** (`refunded_at` month, not invoice_month)
- `net_mrr` = `gross_mrr - refunds`
- `mom_change_pct` = percentage change of `net_mrr` vs previous month

**Notes:**
- Refund month may differ from invoice month.
- Use `LAG(net_mrr)` for MoM.

**Solution:** [sql/01_mrr/01_net_mrr_mom.sql](../sql/01_mrr/01_net_mrr_mom.sql)

---

### 02. Top plan by Net MRR each month (tie-break)

**Goal:** For each month, find the **plan leader** by `net_mrr`.

**Tie-break rule:** if multiple plans have the same `net_mrr`, select the plan with:
1) higher `net_mrr`
2) higher number of **unique accounts** (`accounts_cnt`)

**Expected approach:**
- aggregate by `(month, plan_id)`
- compute `net_mrr`
- rank within month using `DENSE_RANK()`:
  `ORDER BY net_mrr DESC, accounts_cnt DESC`

**Solution:** [sql/01_mrr/02_top_plan_net_mrr.sql](../sql/01_mrr/02_top_plan_net_mrr.sql)

---

### 03. Cohort retention (logo retention)

**Cohort definition:** `cohort_month = date_trunc('month', accounts.created_at)`  
**Active in month:** account has **at least one paid invoice** in that month.

**Return columns:**
- `cohort_month`
- `month_number` (0, 1, 2, …)
- `retained_accounts`
- `cohort_size`
- `retention_rate = retained_accounts / cohort_size`

**Notes:**
- This is **logo retention** based on paid activity.
- Cohort month is based on account signup date.

**Solution:** [sql/02_retention/03_cohort_retention.sql](../sql/02_retention/03_cohort_retention.sql)

---

### 04. Time-to-First-Value (TTFV) + median by source

For each `account_id`:
- `signup_date = accounts.created_at`
- `first_value_date` = first product event where `event_type = 'export'`  
  (events are linked via `users → account`)
- `days_to_value = first_value_date - signup_date`

Then compute **median** `days_to_value` grouped by `acquisition.source`.

**Notes:**
- If supported, use `PERCENTILE_CONT(0.5)` for median.
- Otherwise approximate p50 with window ranking.

**Solution:** [sql/03_activation/04_ttfv.sql](../sql/03_activation/04_ttfv.sql)

---

### 05. Churn early warning: weekly usage drop ≥40% before cancel

For accounts with canceled subscriptions:
1) aggregate weekly usage: `COUNT(product_events)` per `(account_id, week)`
2) compute previous week usage using `LAG(usage)`
3) detect drop when usage decreases by **≥40%** compared to previous week

**Output:**
- `account_id`
- `week`
- `usage`
- `prev_usage`
- `drop_pct`

**Solution:** [sql/04_churn/05_usage_drop.sql](../sql/04_churn/05_usage_drop.sql)

---

### 06. Expansion vs contraction (invoice-to-invoice delta)

For each `subscription_id` and `invoice_month` (paid invoices):
- `paid_amount`
- `delta` vs previous invoice (same subscription)
- classify change using:
  - `first_payment`
  - `expansion` (amount increased)
  - `contraction` (amount decreased)
  - `flat` (no change)

**Expected approach:**  
`LAG(paid_amount) OVER (PARTITION BY subscription_id ORDER BY invoice_month)`

**Solution:** [sql/05_billing_quality/06_expansion_contraction.sql](../sql/05_billing_quality/06_expansion_contraction.sql)

---

### 07. Duplicate billing detection

Detect subscriptions that have **2+ paid invoices** in the same `invoice_month`.

**Return:**
- `subscription_id`
- `invoice_month`
- `invoice_id`
- `paid_at`
- `amount`
- `rank` within `(subscription_id, invoice_month)`

**Expected approach:**
- `COUNT(*) OVER (PARTITION BY subscription_id, invoice_month)`
- `ROW_NUMBER()` for ranking

**Solution:** [sql/05_billing_quality/07_duplicate_billing.sql](../sql/05_billing_quality/07_duplicate_billing.sql)

---

### 08. Attribution sanity check (FULL JOIN)

Compare two sources of acquisition attribution:
- `acquisition(account_id, source, ...)`
- `crm_acquisition(account_id, source)` (hypothetical)

Identify:
- accounts that exist only in one source
- accounts where `source` differs

**Expected approach:** `FULL JOIN + CASE` categorization + filter.

**Solution:** [sql/06_attribution/08_attribution_full_join.sql](../sql/06_attribution/08_attribution_full_join.sql)

---

### 09. Pareto 80/20: power users per account

For each account:
1) compute `usage` per user for last **30 days**
2) order users by `usage DESC`
3) compute cumulative usage share
4) identify minimal set of users producing **≥80%** of total account usage

**Expected approach:**
- window cumulative sum / total sum per account

**Solution:** [sql/07_power_users/09_pareto_80.sql](../sql/07_power_users/09_pareto_80.sql)

---

### 10. Plan upgrade path + most common transitions

For each account, build a plan timeline through subscriptions:
- previous plan (`LAG(plan_id)`)
- next plan (`LEAD(plan_id)`)
- transition date (subscription `started_at`)

Then aggregate and count most common transitions (e.g., `basic → pro`, `pro → enterprise`).

**Notes:**
- only count transitions where `plan_id` actually changed.

**Solution:** [sql/08_upgrades/10_upgrade_path.sql](../sql/08_upgrades/10_upgrade_path.sql)