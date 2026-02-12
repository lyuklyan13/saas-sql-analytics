# 📈 SaaS Metrics Definitions

### This document describes the business logic behind calculated metrics.


### 1️⃣ Gross MRR

Monthly Recurring Revenue calculated as:

```sql
SUM(invoices.amount)
WHERE paid_at IS NOT NULL
GROUP BY invoice_month
```
Only paid invoices are included.


### 2️⃣ Refunds

Refunds are aggregated by refund month:

```sql
SUM(refund_amount)
GROUP BY date_trunc('month', refunded_at)
```


### 3️⃣ Net MRR

```sql
Net MRR = Gross MRR - Refunds
```
Represents actual recurring revenue.





### 4️⃣ MoM Growth

Month-over-month change calculated using:
```sql
LAG(net_mrr) OVER (ORDER BY month)
```

### 5️⃣ Cohort Retention

Cohort defined by:
```sql
date_trunc('month', accounts.created_at)
```

Active account = at least one paid invoice in a given month.

Retention rate:

```sql
retained_accounts / cohort_size
```

### 6️⃣ Time-to-First-Value (TTFV)
```sql
first_value_date - signup_date
```

Where first_value is defined as first 'export' event.

Median calculated using:

```sql
PERCENTILE_CONT(0.5)
```

### 7️⃣ Expansion / Contraction

Change in billed amount between invoices:

expansion → amount increased

contraction → amount decreased

flat → no change

### 8️⃣ Churn Early Warning

Usage drop detected when:

```sql
current_week_usage <= previous_week_usage * 0.6
```

### 9️⃣ Pareto (80/20 Rule)

Users ranked by usage.
Minimal set of users generating ≥80% total usage identified using cumulative window sum.

### 🔟 Plan Upgrade Path

Transitions detected using:

```sql
LAG(plan_id) OVER (PARTITION BY account ORDER BY started_at)
```

Only actual plan changes counted.