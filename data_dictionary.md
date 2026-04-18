# Data Dictionary - Bank Loan Dataset

## Overview

This document provides detailed descriptions of all fields in the bank loan dataset, including data types, valid values, and business definitions.

---

## Dataset Information

- **Dataset Name:** bank_loan
- **Record Count:** 35,000+ loan records
- **Time Period:** 2021 - 2024
- **Update Frequency:** Daily
- **Primary Key:** loan_id

---

## Field Descriptions

### Identification Fields

| Field Name | Data Type | Description | Example | Notes |
|------------|-----------|-------------|---------|-------|
| `id` | INT | System-generated unique record identifier | 1, 2, 3 | Auto-increment primary key |
| `loan_id` | VARCHAR(50) | Unique loan identifier | LOAN12345 | Business key for loan |
| `member_id` | INT | Customer/member unique identifier | 1001, 1002 | Links multiple loans to same customer |

---

### Geographic Information

| Field Name | Data Type | Description | Example | Valid Values |
|------------|-----------|-------------|---------|--------------|
| `address_state` | VARCHAR(2) | US state abbreviation where customer resides | CA, NY, TX | Standard US state codes (50 states + DC) |

**State Coverage:** All 50 US states + District of Columbia

**Top States by Volume:**
- CA (California)
- NY (New York)  
- TX (Texas)
- FL (Florida)
- IL (Illinois)

---

### Loan Characteristics

| Field Name | Data Type | Description | Example | Valid Values / Range |
|------------|-----------|-------------|---------|---------------------|
| `loan_amount` | DECIMAL(12,2) | Principal amount of the loan | 15000.00 | $500 - $40,000 |
| `funded_amount` | DECIMAL(12,2) | Amount actually funded (usually equals loan_amount) | 15000.00 | ≤ loan_amount |
| `loan_status` | VARCHAR(20) | Current status of the loan | Fully Paid | Fully Paid, Current, Charged Off |
| `term` | VARCHAR(10) | Loan repayment period | 36 months | 36 months, 60 months |
| `int_rate` | DECIMAL(5,2) | Interest rate as percentage | 12.50 | 5.00% - 25.00% |
| `installment` | DECIMAL(10,2) | Monthly payment amount | 450.00 | Calculated based on amount, rate, term |
| `grade` | VARCHAR(1) | Loan grade assigned by bank | A, B, C | A (best) to G (highest risk) |
| `sub_grade` | VARCHAR(3) | Sub-classification within grade | B2, C3 | A1-A5, B1-B5, C1-C5, etc. |
| `purpose` | VARCHAR(50) | Stated purpose of the loan | debt_consolidation | See Purpose Values below |

**Loan Status Definitions:**
- **Fully Paid:** Loan has been completely repaid
- **Current:** Loan is active and payments are current
- **Charged Off:** Loan defaulted, no expectation of further payment

**Grade System:**
- **A:** Lowest risk, typically <8% interest rate
- **B:** Low risk, 8-12% interest rate
- **C:** Medium risk, 12-15% interest rate
- **D:** Medium-high risk, 15-18% interest rate
- **E:** High risk, 18-21% interest rate
- **F:** Very high risk, 21-24% interest rate
- **G:** Highest risk, >24% interest rate

**Purpose Values:**
- debt_consolidation
- credit_card
- home_improvement
- other
- major_purchase
- medical
- small_business
- car
- moving
- vacation
- house
- wedding
- renewable_energy
- educational

---

### Borrower Information

| Field Name | Data Type | Description | Example | Range / Notes |
|------------|-----------|-------------|---------|---------------|
| `annual_income` | DECIMAL(12,2) | Borrower's self-reported annual income | 75000.00 | $12,000 - $500,000+ |
| `dti` | DECIMAL(5,2) | Debt-to-Income ratio as percentage | 15.50 | 0.00% - 50.00% |
| `emp_length` | VARCHAR(20) | Years of employment | 10+ years | See Employment Length Values |
| `emp_title` | VARCHAR(100) | Job title | Software Engineer | Free text |
| `home_ownership` | VARCHAR(20) | Home ownership status | MORTGAGE | RENT, OWN, MORTGAGE, OTHER, NONE |
| `verification_status` | VARCHAR(30) | Income verification status | Verified | Verified, Source Verified, Not Verified |
| `total_acc` | INT | Total number of credit accounts | 15 | 2 - 100+ |

**DTI Calculation:**
```
DTI = (Monthly Debt Payments / Monthly Gross Income) × 100
```

**Employment Length Values:**
- < 1 year
- 1 year
- 2 years
- 3 years
- 4 years
- 5-9 years
- 10+ years

**Verification Status:**
- **Verified:** Income verified through tax documents
- **Source Verified:** Income verified through pay stubs or bank statements
- **Not Verified:** Income self-reported, not verified

**Home Ownership:**
- **RENT:** Borrower rents their residence
- **MORTGAGE:** Borrower has a mortgage
- **OWN:** Borrower owns outright
- **OTHER:** Other arrangement
- **NONE:** No primary residence

---

### Payment Information

| Field Name | Data Type | Description | Example | Notes |
|------------|-----------|-------------|---------|-------|
| `total_payment` | DECIMAL(12,2) | Total amount paid to date | 16209.50 | Includes principal + interest |
| `installment` | DECIMAL(10,2) | Fixed monthly payment amount | 450.00 | Amortized payment |

---

### Application Information

| Field Name | Data Type | Description | Example | Values |
|------------|-----------|-------------|---------|--------|
| `application_type` | VARCHAR(20) | Type of application | Individual | Individual, Joint |

---

### Date Fields

| Field Name | Data Type | Description | Example | Range |
|------------|-----------|-------------|---------|-------|
| `issue_date` | DATE | Date loan was funded | 2024-01-15 | 2021-01-01 to 2024-12-31 |
| `last_payment_date` | DATE | Date of most recent payment | 2024-03-15 | Can be NULL for never paid |
| `next_payment_date` | DATE | Date next payment is due | 2024-04-15 | NULL if paid off |
| `last_credit_pull_date` | DATE | Date credit was last pulled | 2024-01-10 | Usually before issue_date |
| `created_at` | TIMESTAMP | Record creation timestamp | 2024-01-15 10:30:00 | System generated |
| `updated_at` | TIMESTAMP | Record last update timestamp | 2024-03-20 14:22:00 | Auto-updated |

---

## Calculated Fields (Not in raw data)

These fields can be derived from existing fields:

| Field Name | Formula | Description |
|------------|---------|-------------|
| Profit/Loss | total_payment - loan_amount | Net profit or loss on the loan |
| ROI % | (total_payment - loan_amount) / loan_amount × 100 | Return on investment percentage |
| Loan Age | Current Date - issue_date | Number of days since loan origination |
| Default Flag | loan_status = 'Charged Off' ? 1 : 0 | Binary indicator of default |
| Monthly Income | annual_income / 12 | Estimated monthly income |
| Monthly Debt Payment | monthly_income × (dti / 100) | Estimated total monthly debt |

---

## Data Quality Rules

### Required Fields (NOT NULL)
- loan_id
- member_id
- loan_amount
- loan_status
- issue_date
- int_rate
- grade

### Valid Ranges
- loan_amount: > 0 and < 50,000
- int_rate: >= 5.0 and <= 30.0
- dti: >= 0 and <= 50
- annual_income: > 0

### Referential Integrity
- Each loan_id must be unique
- member_id can appear multiple times (same customer, multiple loans)
- issue_date must be <= current date

---

## Common Filters and Segments

### Good Loans
```sql
WHERE loan_status IN ('Fully Paid', 'Current')
```

### Bad Loans
```sql
WHERE loan_status = 'Charged Off'
```

### High-Risk Loans
```sql
WHERE grade IN ('D', 'E', 'F', 'G') AND dti > 20
```

### Prime Loans
```sql
WHERE grade IN ('A', 'B') AND verification_status = 'Verified'
```

### Recent Loans (Last 6 Months)
```sql
WHERE issue_date >= DATE_SUB(CURRENT_DATE, INTERVAL 6 MONTH)
```

---

## Business Metrics Definitions

### Key Performance Indicators (KPIs)

**Total Applications**
```
COUNT(loan_id)
```

**Total Funded Amount**
```
SUM(loan_amount)
```

**Average Interest Rate**
```
AVG(int_rate)
```

**Default Rate**
```
COUNT(CASE WHEN loan_status = 'Charged Off' THEN 1 END) / COUNT(*) × 100
```

**Good Loan Percentage**
```
COUNT(CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 1 END) / COUNT(*) × 100
```

**ROI (Return on Investment)**
```
(SUM(total_payment) - SUM(loan_amount)) / SUM(loan_amount) × 100
```

---

## Data Lineage

### Source Systems
- **Origination System:** Loan applications and approvals
- **Servicing System:** Payment tracking and status updates
- **Credit Bureau:** Credit scores and verification

### ETL Process
1. Extract from source systems (daily at 2:00 AM)
2. Transform and validate data
3. Load into analytics database (6:00 AM)
4. Power BI refresh (6:30 AM)

### Data Retention
- Active loans: Indefinite
- Paid-off loans: 7 years from payoff date
- Charged-off loans: 10 years for regulatory compliance

---

## Privacy and Security

### PII (Personally Identifiable Information)
- **NOT included in this dataset:**
  - Customer name
  - Social Security Number
  - Address (only state included)
  - Phone number
  - Email address

### Data Access
- Classified as Internal Use Only
- Requires database authentication
- Row-level security based on user role
- Audit logging enabled

---

## Change Log

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2024-03-01 | 1.0 | Initial documentation | Your Name |
| 2024-03-15 | 1.1 | Added calculated fields section | Your Name |
| 2024-04-01 | 1.2 | Updated data ranges and examples | Your Name |

---

## Contact Information

For questions about this data dictionary:
- **Data Owner:** Analytics Team
- **Technical Contact:** your.email@example.com
- **Last Updated:** April 2025
