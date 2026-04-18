# Analysis Methodology

## Project Approach

This document outlines the systematic approach used to analyze the bank loan portfolio data.

---

## 1. Data Collection & Preparation

### Data Sources
- **Primary:** Bank loan origination and servicing systems
- **Volume:** 35,000+ loan records
- **Time Period:** January 2021 - December 2024
- **Attributes:** 25+ fields per loan record

### Data Quality Checks
1. **Completeness:** Verified all required fields present
2. **Accuracy:** Cross-validated amounts and dates
3. **Consistency:** Standardized categorical values
4. **Validity:** Checked ranges for numerical fields
5. **Uniqueness:** Ensured no duplicate loan_ids

### Data Cleaning Steps
```sql
-- Remove duplicates
DELETE FROM bank_loan 
WHERE id NOT IN (
    SELECT MIN(id) 
    FROM bank_loan 
    GROUP BY loan_id
);

-- Handle NULL values
UPDATE bank_loan 
SET emp_length = 'Unknown' 
WHERE emp_length IS NULL;

-- Standardize formats
UPDATE bank_loan 
SET address_state = UPPER(TRIM(address_state));

-- Remove outliers
DELETE FROM bank_loan 
WHERE loan_amount < 500 OR loan_amount > 50000;
```

---

## 2. Exploratory Data Analysis (EDA)

### Statistical Summary

**Descriptive Statistics:**
```sql
SELECT 
    COUNT(*) as total_records,
    AVG(loan_amount) as mean_loan,
    STDDEV(loan_amount) as std_loan,
    MIN(loan_amount) as min_loan,
    PERCENTILE_CONT(0.25) as Q1,
    PERCENTILE_CONT(0.50) as median,
    PERCENTILE_CONT(0.75) as Q3,
    MAX(loan_amount) as max_loan
FROM bank_loan;
```

### Distribution Analysis
- Loan amount distribution (right-skewed)
- Interest rate distribution (bimodal)
- DTI distribution (normal)
- Grade distribution (concentrated in B-C)

### Correlation Analysis
Examined relationships between:
- Loan amount ↔ Interest rate
- DTI ↔ Default rate
- Employment length ↔ Loan approval
- Verification status ↔ Default rate

---

## 3. Analytical Techniques Used

### SQL Analysis Methods

#### 1. Aggregations
```sql
-- Group By analysis
SELECT 
    grade,
    COUNT(*) as loans,
    AVG(int_rate) as avg_rate,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) as defaults
FROM bank_loan
GROUP BY grade;
```

#### 2. Window Functions
```sql
-- Ranking and running totals
SELECT 
    loan_id,
    loan_amount,
    RANK() OVER (PARTITION BY grade ORDER BY loan_amount DESC) as rank,
    SUM(loan_amount) OVER (ORDER BY issue_date) as running_total
FROM bank_loan;
```

#### 3. Common Table Expressions (CTEs)
```sql
-- Multi-step analysis
WITH monthly_metrics AS (
    SELECT DATE_FORMAT(issue_date, '%Y-%m') as month,
           COUNT(*) as applications
    FROM bank_loan
    GROUP BY month
)
SELECT month,
       applications,
       LAG(applications) OVER (ORDER BY month) as prev_month
FROM monthly_metrics;
```

#### 4. Complex Joins
```sql
-- Self-join for cohort comparison
SELECT 
    c1.cohort,
    c2.cohort,
    c1.default_rate - c2.default_rate as rate_diff
FROM cohort_stats c1
JOIN cohort_stats c2 ON c1.cohort > c2.cohort;
```

#### 5. Subqueries
```sql
-- Correlated subquery for outlier detection
SELECT * FROM bank_loan b1
WHERE int_rate > (
    SELECT AVG(int_rate) + 2*STDDEV(int_rate)
    FROM bank_loan b2
    WHERE b2.grade = b1.grade
);
```

---

## 4. Key Performance Metrics

### Financial Metrics
- **Total Funded Amount:** Sum of all loan amounts
- **Total Received Amount:** Sum of all payments
- **Net Profit/Loss:** Received - Funded
- **ROI:** (Received - Funded) / Funded × 100

### Risk Metrics
- **Default Rate:** Charged Off / Total × 100
- **Loss Given Default:** (Funded - Received) / Funded for defaulted loans
- **Portfolio Risk Score:** Weighted default rate by exposure

### Operational Metrics
- **Application Volume:** Count of loans
- **Average Loan Size:** Mean loan amount
- **Approval Rate:** Approved / Applied × 100
- **Time to Fund:** Issue date - Application date

### Growth Metrics
- **MoM Growth:** (Current - Previous) / Previous × 100
- **YoY Growth:** (Current Year - Last Year) / Last Year × 100
- **CAGR:** Compound Annual Growth Rate

---

## 5. Segmentation Strategy

### Dimensional Analysis

**By Risk Grade:**
- A (Prime)
- B (Near-prime)
- C (Standard)
- D-G (Subprime)

**By Purpose:**
- Debt Consolidation
- Credit Card
- Home Improvement
- Small Business
- Other

**By Geography:**
- Top 10 states by volume
- States grouped by default rate
- Regional performance comparison

**By Time:**
- Monthly cohorts
- Quarterly trends
- Seasonal patterns
- Year-over-year comparison

**By Customer Profile:**
- Employment length
- Home ownership status
- Income level
- Verification status

---

## 6. Trend Analysis Approach

### Time Series Techniques

**Moving Averages:**
```sql
-- 3-month moving average
AVG(applications) OVER (
    ORDER BY month 
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
) as ma_3month
```

**Growth Calculations:**
```sql
-- Month-over-month growth
(current_value - LAG(current_value, 1)) * 100.0 / 
LAG(current_value, 1)
```

**Seasonality Detection:**
- Month-of-year comparisons
- Quarter-over-quarter analysis
- Holiday period impacts

---

## 7. Risk Assessment Framework

### Multi-Factor Risk Model

**Risk Score Components:**
1. **Grade Weight:** A=1, B=2, C=3, D=4, E=5, F=6, G=7
2. **DTI Weight:** <10=0, 10-20=1, 20-30=2, >30=3
3. **Verification Weight:** Verified=0, Source=1, Not=2
4. **Home Ownership:** Own/Mortgage=0, Rent=1
5. **Employment:** 10+=0, 5-9=1, <5=2

**Composite Risk Score:**
```sql
(grade_weight + dti_weight + verification_weight + 
 home_weight + employment_weight) as risk_score
```

**Risk Categories:**
- Low Risk: Score 0-3
- Medium Risk: Score 4-7
- High Risk: Score 8-12
- Very High Risk: Score 13+

---

## 8. Power BI Dashboard Design

### Design Principles
1. **User-Centric:** Designed for different user roles
2. **Progressive Disclosure:** Summary → Details → Drill-through
3. **Consistency:** Uniform color schemes and formatting
4. **Actionability:** Clear insights drive decisions
5. **Performance:** Optimized for fast loading

### Visual Selection Criteria
- **KPI Cards:** For headline numbers
- **Line Charts:** For trends over time
- **Bar Charts:** For categorical comparisons
- **Maps:** For geographic distribution
- **Scatter Plots:** For correlation analysis
- **Tree Maps:** For hierarchical data
- **Tables:** For detailed drill-down

### Interactivity Features
- Cross-filtering between visuals
- Drill-through to detail pages
- Slicers for filtering
- Bookmarks for saved views
- Tooltips for context

---

## 9. Statistical Methods

### Hypothesis Testing
- Tested if default rates differ by grade (Chi-square test)
- Tested if DTI correlates with defaults (t-test)
- Tested geographic variation significance (ANOVA)

### Confidence Intervals
- 95% CI for portfolio default rate
- Margin of error calculations
- Sample size adequacy checks

### Outlier Detection
- IQR method for continuous variables
- Z-score method for normally distributed data
- Visual inspection with box plots

---

## 10. Validation & Quality Assurance

### Data Validation Steps
1. **Cross-footing:** Verify totals match
2. **Reconciliation:** Compare to source systems
3. **Reasonableness:** Check for logical consistency
4. **Trend Validation:** Ensure trends make sense
5. **Peer Review:** Have another analyst review

### Query Testing
```sql
-- Test query accuracy
SELECT 
    SUM(loan_amount) as sql_total,
    (SELECT SUM(loan_amount) FROM bank_loan) as validation_total,
    SUM(loan_amount) - (SELECT SUM(loan_amount) FROM bank_loan) as difference
FROM bank_loan;
```

---

## 11. Limitations & Assumptions

### Data Limitations
- **Historical Bias:** Past performance may not predict future
- **Missing Variables:** Some risk factors not captured
- **Survivorship Bias:** Only current portfolio analyzed
- **Data Lag:** Analysis based on month-old data

### Assumptions Made
1. Economic conditions remain relatively stable
2. Lending policies unchanged during analysis period
3. Customer behavior patterns consistent
4. External factors (competition) held constant
5. Data quality from source systems is accurate

---

## 12. Tools & Technologies

### Database
- **MySQL 8.0+** / **PostgreSQL 13+** / **SQL Server 2019+**
- Database design and optimization
- Index creation for performance
- Query optimization techniques

### Visualization
- **Power BI Desktop** (Latest version)
- DAX for calculated measures
- Power Query for transformations
- Custom visuals where needed

### Documentation
- **Markdown** for all documentation
- **Git** for version control
- **VS Code** for script editing

---

## 13. Reproducibility

### Environment Setup
```bash
# Clone repository
git clone https://github.com/yourusername/bank-loan-analysis.git

# Set up database
mysql -u username -p < sql_queries/01_database_setup.sql

# Load data
# (See data/README_DATA.md for instructions)

# Run analysis queries in order
mysql -u username -p database_name < sql_queries/02_data_exploration.sql
```

### Version Control
- All SQL scripts version controlled
- Documentation updated with changes
- Change log maintained

---

## 14. Ethical Considerations

### Privacy Protection
- No PII included in analysis
- Aggregated data only
- Compliance with data protection regulations

### Bias Awareness
- Acknowledged potential for algorithmic bias
- Reviewed for disparate impact
- Recommended fairness audits

### Responsible Use
- Results intended for legitimate business purposes
- Not for discriminatory practices
- Transparent methodology

---

## References

### Industry Standards
- Basel III banking regulations
- FICO score methodologies
- Federal Reserve lending guidelines

### Academic Research
- Credit risk modeling literature
- Default prediction studies
- Portfolio optimization theory

### Tools Documentation
- MySQL Documentation
- Power BI Documentation
- DAX Function Reference

---

**Methodology Prepared By:** Your Name  
**Last Updated:** April 2025  
**Version:** 1.0
