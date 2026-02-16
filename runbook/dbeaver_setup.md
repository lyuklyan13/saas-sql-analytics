# 🛠 DBeaver Setup Guide

This guide explains how to set up PostgreSQL and connect to the database using DBeaver.

---

## 1️⃣ Install Required Tools

- PostgreSQL (version 14+ recommended)
- DBeaver Community Edition

Make sure PostgreSQL service is running.

---

## 2️⃣ Create a New Database

Open DBeaver → SQL Editor and run:

```sql
CREATE DATABASE saas_sql_practice;
```

--- 

## 3️⃣ Create a Connection in DBeaver

1. Click New Database Connection

2. Choose PostgreSQL

3. Fill in:

* Host: localhost

* Port: 5432

* Database: saas_sql_practice

* Username: your postgres user

* Password: your password

4. Click Test Connection

5. Click Finish

---

## 4️⃣ Run Setup Scripts

Execute the following files in order:
```sql
sql/00_setup/00_create_schema.sql
sql/00_setup/01_constraints_indexes.sql
sql/00_setup/02_seed.sql
```


## 5️⃣ Verify Data Loaded Correctly

Run:
```sql
SELECT COUNT(*) FROM saas.accounts;
SELECT COUNT(*) FROM saas.invoices;
SELECT COUNT(*) FROM saas.product_events;
```

## ⚠ Common Issue

If you see:

```sql
ERROR: relation "invoices" does not exist
```

Run:
```sql
SET search_path TO saas;
```

or reference tables as:

```sql
SELECT * FROM saas.invoices;
```