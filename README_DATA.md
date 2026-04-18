# Sample Loan Data

## Note on Data Files

Due to file size constraints and privacy considerations, the actual loan dataset (35,000+ records) is not included in this repository.

## Getting the Data

### Option 1: Generate Sample Data

Run the SQL script to generate sample data:

```sql
-- See sql_queries/01_database_setup.sql for table structure
-- Add sample data generation queries as needed
```

### Option 2: Use Public Datasets

You can use similar loan datasets from:
- **Kaggle:** Search for "loan data" or "lending club data"
- **Data.gov:** Search for financial/lending datasets
- **UCI Machine Learning Repository:** Loan default prediction datasets

### Option 3: Request Sample Data

Contact the repository owner for a sanitized sample dataset.

## Expected Data Format

The CSV should have the following columns (see data_dictionary.md for details):

```
loan_id,member_id,loan_amount,funded_amount,term,int_rate,installment,grade,sub_grade,
emp_title,emp_length,home_ownership,annual_income,verification_status,issue_date,
loan_status,purpose,address_state,dti,total_acc,total_payment,application_type,
last_payment_date,last_credit_pull_date,next_payment_date
```

## Data Volume

- **Training:** ~35,000 records
- **File Size:** ~15-20 MB
- **Time Period:** 2021-2024

## Privacy Note

This project analyzes financial data. Ensure any real data used complies with:
- GDPR (if applicable)
- CCPA (California residents)
- FCRA (Fair Credit Reporting Act)
- Internal data governance policies

**Never commit real customer PII to public repositories.**


