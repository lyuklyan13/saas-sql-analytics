# 📚 Data Dictionary

### This document describes the structure of the SaaS analytics database.

### 🏢 accounts

| Column | Type | Description |
|--------|------|-------------|
| account_id | PK | Unique company identifier |
| created_at | timestamp | Account signup date |
| country | text | Country |
| industry | text | Industry segment |

### 👥 users

| Column | Type | Description |
|--------|------|-------------|
| user_id | PK | Unique user identifier |
| account_id | FK → accounts | Belongs to account |
| created_at | timestamp | User signup date |
| role | text | User role |

### 💳 plans

| Column        | Type     | Description                        |
|---------------|----------|------------------------------------|
| plan_id       | PK       | Plan identifier                    |
| plan_name     | text     | Plan name (Basic, Pro, Enterprise) |
| monthly_price | numeric  | Monthly subscription price         |


### 🔁 subscriptions

| Column          | Type              | Description                |
|-----------------|-------------------|----------------------------|
| subscription_id | PK                | Subscription identifier    |
| account_id      | FK → accounts     | Linked account             |
| plan_id         | FK → plans        | Selected plan              |
| started_at      | timestamp         | Subscription start date    |
| ended_at        | timestamp         | End date (if canceled)     |
| status          | text              | active / canceled          |


### 🧾 invoices

| Column          | Type                    | Description         |
|-----------------|------------------------|---------------------|
| invoice_id      | PK                     | Invoice identifier  |
| subscription_id | FK → subscriptions     | Linked subscription |
| invoice_month   | date                   | Billing month       |
| amount          | numeric                | Billed amount       |
| issued_at       | timestamp              | Invoice issued date |
| paid_at         | timestamp              | Payment date        |


### 💸 refunds

| Column        | Type              | Description       |
|---------------|------------------|-------------------|
| refund_id     | PK               | Refund identifier |
| invoice_id    | FK → invoices    | Linked invoice    |
| refunded_at   | timestamp        | Refund date       |
| refund_amount | numeric          | Refunded amount   |


### 📊 product_events

| Column      | Type           | Description                         |
|-------------|---------------|-------------------------------------|
| event_id    | PK            | Event identifier                    |
| user_id     | FK → users    | Linked user                         |
| event_time  | timestamp     | Event time                          |
| event_type  | text          | Event name (login, export, etc.)    |
| meta        | json/text     | Event metadata                      |


### 🎯 acquisition

| Column      | Type                | Description          |
|-------------|--------------------|----------------------|
| account_id  | PK / FK → accounts | Account              |
| source      | text               | Marketing channel    |
| campaign    | text               | Campaign name        |
| acquired_at | timestamp          | Acquisition date     |
