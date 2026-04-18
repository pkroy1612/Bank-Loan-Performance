-- ============================================================================
-- Data Exploration and Profiling
-- ============================================================================
-- Description: Initial data exploration queries
-- Author: Your Name
-- Date: March 2025
-- ============================================================================

USE bank_loan_db;

-- ============================================================================
-- 1. BASIC DATA PROFILING
-- ============================================================================

-- Overall dataset statistics
SELECT 
    'Total Records' as Metric,
    COUNT(*) as Value
FROM bank_loan

UNION ALL

SELECT 
    'Date Range' as Metric,
    CONCAT(MIN(issue_date), ' to ', MAX(issue_date)) as Value
FROM bank_loan

UNION ALL

SELECT 
    'Unique Loan IDs' as Metric,
    COUNT(DISTINCT loan_id) as Value
FROM bank_loan

UNION ALL

SELECT 
    'States Covered' as Metric,
    COUNT(DISTINCT address_state) as Value
FROM bank_loan;

-- ============================================================================
-- 2. LOAN STATUS DISTRIBUTION
-- ============================================================================

SELECT 
    loan_status,
    COUNT(*) as loan_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage,
    SUM(loan_amount) as total_funded,
    AVG(loan_amount) as avg_loan_amount,
    AVG(int_rate) as avg_interest_rate
FROM bank_loan
GROUP BY loan_status
ORDER BY loan_count DESC;

-- ============================================================================
-- 3. LOAN GRADE ANALYSIS
-- ============================================================================

SELECT 
    grade,
    COUNT(*) as total_loans,
    SUM(loan_amount) as total_amount,
    AVG(loan_amount) as avg_loan_amount,
    AVG(int_rate) as avg_interest_rate,
    AVG(dti) as avg_dti,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) as charged_off_count,
    ROUND(SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as default_rate
FROM bank_loan
GROUP BY grade
ORDER BY grade;

-- ============================================================================
-- 4. LOAN PURPOSE BREAKDOWN
-- ============================================================================

SELECT 
    purpose,
    COUNT(*) as application_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage,
    SUM(loan_amount) as total_funded,
    AVG(loan_amount) as avg_loan_size,
    AVG(int_rate) as avg_rate,
    ROUND(SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as default_rate
FROM bank_loan
GROUP BY purpose
ORDER BY application_count DESC;

-- ============================================================================
-- 5. GEOGRAPHIC DISTRIBUTION
-- ============================================================================

-- Top 10 states by loan volume
SELECT 
    address_state,
    COUNT(*) as total_loans,
    SUM(loan_amount) as total_funded,
    AVG(loan_amount) as avg_loan_amount,
    AVG(int_rate) as avg_interest_rate,
    ROUND(SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as default_rate
FROM bank_loan
GROUP BY address_state
ORDER BY total_loans DESC
LIMIT 10;

-- ============================================================================
-- 6. TERM ANALYSIS
-- ============================================================================

SELECT 
    term,
    COUNT(*) as loan_count,
    SUM(loan_amount) as total_amount,
    AVG(loan_amount) as avg_amount,
    AVG(int_rate) as avg_rate,
    AVG(installment) as avg_installment,
    ROUND(SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as default_rate
FROM bank_loan
GROUP BY term
ORDER BY loan_count DESC;

-- ============================================================================
-- 7. HOME OWNERSHIP ANALYSIS
-- ============================================================================

SELECT 
    home_ownership,
    COUNT(*) as loan_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage,
    AVG(loan_amount) as avg_loan_amount,
    AVG(int_rate) as avg_interest_rate,
    AVG(dti) as avg_dti,
    ROUND(SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as default_rate
FROM bank_loan
GROUP BY home_ownership
ORDER BY loan_count DESC;

-- ============================================================================
-- 8. VERIFICATION STATUS IMPACT
-- ============================================================================

SELECT 
    verification_status,
    COUNT(*) as loan_count,
    SUM(loan_amount) as total_funded,
    AVG(loan_amount) as avg_amount,
    AVG(annual_income) as avg_income,
    ROUND(SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as default_rate
FROM bank_loan
GROUP BY verification_status
ORDER BY loan_count DESC;

-- ============================================================================
-- 9. EMPLOYMENT LENGTH ANALYSIS
-- ============================================================================

SELECT 
    emp_length,
    COUNT(*) as loan_count,
    AVG(loan_amount) as avg_loan_amount,
    AVG(annual_income) as avg_income,
    AVG(dti) as avg_dti,
    ROUND(SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as default_rate
FROM bank_loan
GROUP BY emp_length
ORDER BY 
    CASE 
        WHEN emp_length = '< 1 year' THEN 0
        WHEN emp_length = '1 year' THEN 1
        WHEN emp_length = '2 years' THEN 2
        WHEN emp_length = '3 years' THEN 3
        WHEN emp_length = '4 years' THEN 4
        WHEN emp_length = '5-9 years' THEN 5
        WHEN emp_length = '10+ years' THEN 10
    END;

-- ============================================================================
-- 10. INTEREST RATE DISTRIBUTION
-- ============================================================================

SELECT 
    CASE 
        WHEN int_rate < 8 THEN '< 8%'
        WHEN int_rate >= 8 AND int_rate < 12 THEN '8-12%'
        WHEN int_rate >= 12 AND int_rate < 16 THEN '12-16%'
        WHEN int_rate >= 16 AND int_rate < 20 THEN '16-20%'
        ELSE '20%+'
    END as interest_rate_range,
    COUNT(*) as loan_count,
    AVG(loan_amount) as avg_loan_amount,
    AVG(dti) as avg_dti,
    ROUND(SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as default_rate
FROM bank_loan
GROUP BY 
    CASE 
        WHEN int_rate < 8 THEN '< 8%'
        WHEN int_rate >= 8 AND int_rate < 12 THEN '8-12%'
        WHEN int_rate >= 12 AND int_rate < 16 THEN '12-16%'
        WHEN int_rate >= 16 AND int_rate < 20 THEN '16-20%'
        ELSE '20%+'
    END
ORDER BY MIN(int_rate);

-- ============================================================================
-- 11. DTI DISTRIBUTION ANALYSIS
-- ============================================================================

SELECT 
    CASE 
        WHEN dti < 10 THEN '< 10%'
        WHEN dti >= 10 AND dti < 15 THEN '10-15%'
        WHEN dti >= 15 AND dti < 20 THEN '15-20%'
        WHEN dti >= 20 AND dti < 25 THEN '20-25%'
        ELSE '25%+'
    END as dti_range,
    COUNT(*) as loan_count,
    AVG(loan_amount) as avg_loan_amount,
    AVG(int_rate) as avg_interest_rate,
    ROUND(SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as default_rate
FROM bank_loan
GROUP BY 
    CASE 
        WHEN dti < 10 THEN '< 10%'
        WHEN dti >= 10 AND dti < 15 THEN '10-15%'
        WHEN dti >= 15 AND dti < 20 THEN '15-20%'
        WHEN dti >= 20 AND dti < 25 THEN '20-25%'
        ELSE '25%+'
    END
ORDER BY MIN(dti);

-- ============================================================================
-- 12. LOAN AMOUNT DISTRIBUTION
-- ============================================================================

SELECT 
    CASE 
        WHEN loan_amount < 5000 THEN '< $5K'
        WHEN loan_amount >= 5000 AND loan_amount < 10000 THEN '$5K-$10K'
        WHEN loan_amount >= 10000 AND loan_amount < 15000 THEN '$10K-$15K'
        WHEN loan_amount >= 15000 AND loan_amount < 20000 THEN '$15K-$20K'
        ELSE '$20K+'
    END as loan_amount_range,
    COUNT(*) as loan_count,
    AVG(int_rate) as avg_interest_rate,
    AVG(dti) as avg_dti,
    ROUND(SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as default_rate
FROM bank_loan
GROUP BY 
    CASE 
        WHEN loan_amount < 5000 THEN '< $5K'
        WHEN loan_amount >= 5000 AND loan_amount < 10000 THEN '$5K-$10K'
        WHEN loan_amount >= 10000 AND loan_amount < 15000 THEN '$10K-$15K'
        WHEN loan_amount >= 15000 AND loan_amount < 20000 THEN '$15K-$20K'
        ELSE '$20K+'
    END
ORDER BY MIN(loan_amount);

-- ============================================================================
-- 13. MISSING DATA ANALYSIS
-- ============================================================================

SELECT 
    'loan_id' as column_name,
    COUNT(*) - COUNT(loan_id) as null_count,
    ROUND((COUNT(*) - COUNT(loan_id)) * 100.0 / COUNT(*), 2) as null_percentage
FROM bank_loan

UNION ALL

SELECT 'address_state', COUNT(*) - COUNT(address_state), 
       ROUND((COUNT(*) - COUNT(address_state)) * 100.0 / COUNT(*), 2) FROM bank_loan
UNION ALL
SELECT 'emp_length', COUNT(*) - COUNT(emp_length),
       ROUND((COUNT(*) - COUNT(emp_length)) * 100.0 / COUNT(*), 2) FROM bank_loan
UNION ALL
SELECT 'annual_income', COUNT(*) - COUNT(annual_income),
       ROUND((COUNT(*) - COUNT(annual_income)) * 100.0 / COUNT(*), 2) FROM bank_loan
UNION ALL
SELECT 'dti', COUNT(*) - COUNT(dti),
       ROUND((COUNT(*) - COUNT(dti)) * 100.0 / COUNT(*), 2) FROM bank_loan;

-- ============================================================================
-- 14. OUTLIER DETECTION
-- ============================================================================

-- Find loans with unusually high interest rates
SELECT 
    loan_id,
    loan_amount,
    int_rate,
    dti,
    loan_status,
    grade
FROM bank_loan
WHERE int_rate > (SELECT AVG(int_rate) + 2 * STDDEV(int_rate) FROM bank_loan)
ORDER BY int_rate DESC
LIMIT 20;

-- Find loans with unusually high DTI
SELECT 
    loan_id,
    loan_amount,
    annual_income,
    dti,
    loan_status,
    grade
FROM bank_loan
WHERE dti > (SELECT AVG(dti) + 2 * STDDEV(dti) FROM bank_loan)
ORDER BY dti DESC
LIMIT 20;

-- ============================================================================
-- End of Data Exploration
-- ============================================================================
