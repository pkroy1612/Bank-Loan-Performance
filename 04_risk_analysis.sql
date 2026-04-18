-- ============================================================================
-- Risk Analysis and Default Prediction
-- ============================================================================
-- Description: Advanced risk assessment queries
-- Author: Your Name
-- Date: March 2025
-- ============================================================================

USE bank_loan_db;

-- ============================================================================
-- 1. DEFAULT RATE ANALYSIS BY MULTIPLE DIMENSIONS
-- ============================================================================

-- Default rate by Grade and Purpose
SELECT 
    grade,
    purpose,
    COUNT(*) as total_loans,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) as defaults,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as default_rate,
    AVG(int_rate) as avg_interest_rate,
    AVG(dti) as avg_dti,
    SUM(loan_amount) as total_exposure
FROM bank_loan
GROUP BY grade, purpose
HAVING COUNT(*) >= 50
ORDER BY default_rate DESC
LIMIT 20;

-- ============================================================================
-- 2. HIGH-RISK SEGMENT IDENTIFICATION
-- ============================================================================

-- Identify high-risk customer segments
SELECT 
    grade,
    CASE 
        WHEN dti < 15 THEN 'Low DTI'
        WHEN dti >= 15 AND dti < 25 THEN 'Medium DTI'
        ELSE 'High DTI'
    END as dti_category,
    home_ownership,
    COUNT(*) as loan_count,
    SUM(loan_amount) as total_exposure,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as default_rate,
    AVG(int_rate) as avg_rate
FROM bank_loan
GROUP BY 
    grade,
    CASE 
        WHEN dti < 15 THEN 'Low DTI'
        WHEN dti >= 15 AND dti < 25 THEN 'Medium DTI'
        ELSE 'High DTI'
    END,
    home_ownership
HAVING COUNT(*) >= 30 AND 
       SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 15
ORDER BY default_rate DESC;

-- ============================================================================
-- 3. EARLY WARNING INDICATORS
-- ============================================================================

-- Loans with multiple risk factors
SELECT 
    loan_id,
    loan_status,
    grade,
    dti,
    int_rate,
    loan_amount,
    verification_status,
    -- Risk score calculation (simple model)
    (CASE WHEN grade IN ('D', 'E', 'F', 'G') THEN 3 ELSE 0 END +
     CASE WHEN dti > 25 THEN 2 ELSE 0 END +
     CASE WHEN int_rate > 15 THEN 2 ELSE 0 END +
     CASE WHEN verification_status = 'Not Verified' THEN 1 ELSE 0 END +
     CASE WHEN home_ownership = 'RENT' THEN 1 ELSE 0 END) as risk_score
FROM bank_loan
WHERE loan_status = 'Current'
HAVING risk_score >= 5
ORDER BY risk_score DESC, loan_amount DESC
LIMIT 100;

-- ============================================================================
-- 4. DTI IMPACT ON DEFAULT RATES
-- ============================================================================

SELECT 
    CASE 
        WHEN dti < 5 THEN '0-5%'
        WHEN dti >= 5 AND dti < 10 THEN '5-10%'
        WHEN dti >= 10 AND dti < 15 THEN '10-15%'
        WHEN dti >= 15 AND dti < 20 THEN '15-20%'
        WHEN dti >= 20 AND dti < 25 THEN '20-25%'
        WHEN dti >= 25 AND dti < 30 THEN '25-30%'
        ELSE '30%+'
    END as dti_range,
    COUNT(*) as loan_count,
    SUM(loan_amount) as total_funded,
    AVG(int_rate) as avg_interest_rate,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) as defaults,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as default_rate
FROM bank_loan
GROUP BY 
    CASE 
        WHEN dti < 5 THEN '0-5%'
        WHEN dti >= 5 AND dti < 10 THEN '5-10%'
        WHEN dti >= 10 AND dti < 15 THEN '10-15%'
        WHEN dti >= 15 AND dti < 20 THEN '15-20%'
        WHEN dti >= 20 AND dti < 25 THEN '20-25%'
        WHEN dti >= 25 AND dti < 30 THEN '25-30%'
        ELSE '30%+'
    END
ORDER BY MIN(dti);

-- ============================================================================
-- 5. GEOGRAPHIC RISK ASSESSMENT
-- ============================================================================

-- States with highest default rates
SELECT 
    address_state,
    COUNT(*) as total_loans,
    SUM(loan_amount) as total_exposure,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) as defaults,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as default_rate,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount ELSE 0 END) as charged_off_amount,
    AVG(int_rate) as avg_interest_rate,
    AVG(dti) as avg_dti
FROM bank_loan
GROUP BY address_state
HAVING COUNT(*) >= 100
ORDER BY default_rate DESC
LIMIT 15;

-- ============================================================================
-- 6. INTEREST RATE VS DEFAULT CORRELATION
-- ============================================================================

SELECT 
    CASE 
        WHEN int_rate < 8 THEN '< 8%'
        WHEN int_rate >= 8 AND int_rate < 10 THEN '8-10%'
        WHEN int_rate >= 10 AND int_rate < 12 THEN '10-12%'
        WHEN int_rate >= 12 AND int_rate < 14 THEN '12-14%'
        WHEN int_rate >= 14 AND int_rate < 16 THEN '14-16%'
        WHEN int_rate >= 16 AND int_rate < 18 THEN '16-18%'
        ELSE '18%+'
    END as interest_rate_bracket,
    COUNT(*) as loan_count,
    AVG(loan_amount) as avg_loan_amount,
    AVG(dti) as avg_dti,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as default_rate,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount ELSE 0 END) as loss_amount
FROM bank_loan
GROUP BY 
    CASE 
        WHEN int_rate < 8 THEN '< 8%'
        WHEN int_rate >= 8 AND int_rate < 10 THEN '8-10%'
        WHEN int_rate >= 10 AND int_rate < 12 THEN '10-12%'
        WHEN int_rate >= 12 AND int_rate < 14 THEN '12-14%'
        WHEN int_rate >= 14 AND int_rate < 16 THEN '14-16%'
        WHEN int_rate >= 16 AND int_rate < 18 THEN '16-18%'
        ELSE '18%+'
    END
ORDER BY MIN(int_rate);

-- ============================================================================
-- 7. VERIFICATION STATUS RISK ANALYSIS
-- ============================================================================

SELECT 
    verification_status,
    grade,
    COUNT(*) as loan_count,
    SUM(loan_amount) as total_funded,
    AVG(annual_income) as avg_income,
    AVG(dti) as avg_dti,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as default_rate
FROM bank_loan
GROUP BY verification_status, grade
HAVING COUNT(*) >= 30
ORDER BY verification_status, default_rate DESC;

-- ============================================================================
-- 8. EMPLOYMENT LENGTH STABILITY ANALYSIS
-- ============================================================================

SELECT 
    emp_length,
    COUNT(*) as loan_count,
    AVG(loan_amount) as avg_loan_amount,
    AVG(annual_income) as avg_income,
    AVG(dti) as avg_dti,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as default_rate,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount ELSE 0 END) as total_losses
FROM bank_loan
WHERE emp_length IS NOT NULL
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
-- 9. LOAN TERM RISK COMPARISON
-- ============================================================================

SELECT 
    term,
    grade,
    COUNT(*) as loan_count,
    SUM(loan_amount) as total_funded,
    AVG(int_rate) as avg_rate,
    AVG(installment) as avg_monthly_payment,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as default_rate,
    -- Calculate total interest over life of loan
    AVG((installment * CAST(SUBSTRING_INDEX(term, ' ', 1) AS UNSIGNED)) - loan_amount) as avg_total_interest
FROM bank_loan
GROUP BY term, grade
ORDER BY term, grade;

-- ============================================================================
-- 10. PURPOSE-BASED RISK PROFILING
-- ============================================================================

SELECT 
    purpose,
    COUNT(*) as total_loans,
    SUM(loan_amount) as total_exposure,
    AVG(loan_amount) as avg_loan_size,
    AVG(int_rate) as avg_rate,
    AVG(dti) as avg_dti,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as default_rate,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount ELSE 0 END) as potential_loss,
    -- Risk-adjusted return
    ROUND(
        (SUM(total_payment) - SUM(loan_amount)) / 
        NULLIF(SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount ELSE 0 END), 0),
    2) as risk_adjusted_roi
FROM bank_loan
GROUP BY purpose
ORDER BY default_rate DESC;

-- ============================================================================
-- 11. CONCENTRATION RISK ANALYSIS
-- ============================================================================

-- Top borrowers by funded amount
SELECT 
    member_id,
    COUNT(*) as number_of_loans,
    SUM(loan_amount) as total_borrowed,
    AVG(int_rate) as avg_rate,
    AVG(dti) as avg_dti,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) as defaults,
    STRING_AGG(DISTINCT loan_status, ', ') as loan_statuses
FROM bank_loan
GROUP BY member_id
HAVING COUNT(*) > 1
ORDER BY total_borrowed DESC
LIMIT 20;

-- ============================================================================
-- 12. LOSS GIVEN DEFAULT (LGD) ANALYSIS
-- ============================================================================

SELECT 
    grade,
    COUNT(*) as defaulted_loans,
    SUM(loan_amount) as total_defaulted_amount,
    SUM(total_payment) as amount_recovered,
    SUM(loan_amount - total_payment) as total_loss,
    ROUND(
        SUM(loan_amount - total_payment) * 100.0 / SUM(loan_amount), 
    2) as loss_given_default_pct,
    AVG(loan_amount - total_payment) as avg_loss_per_loan
FROM bank_loan
WHERE loan_status = 'Charged Off'
GROUP BY grade
ORDER BY grade;

-- ============================================================================
-- 13. PREDICTIVE RISK SCORING MODEL
-- ============================================================================

-- Create risk tiers based on multiple factors
SELECT 
    loan_id,
    loan_status,
    loan_amount,
    -- Composite risk score
    (
        CASE WHEN grade = 'A' THEN 1 WHEN grade = 'B' THEN 2 WHEN grade = 'C' THEN 3 
             WHEN grade = 'D' THEN 4 WHEN grade = 'E' THEN 5 ELSE 6 END +
        CASE WHEN dti < 10 THEN 0 WHEN dti < 20 THEN 1 WHEN dti < 30 THEN 2 ELSE 3 END +
        CASE WHEN int_rate < 10 THEN 0 WHEN int_rate < 15 THEN 1 ELSE 2 END +
        CASE WHEN verification_status = 'Verified' THEN 0 ELSE 1 END +
        CASE WHEN home_ownership IN ('MORTGAGE', 'OWN') THEN 0 ELSE 1 END
    ) as composite_risk_score,
    CASE 
        WHEN (
            CASE WHEN grade = 'A' THEN 1 WHEN grade = 'B' THEN 2 WHEN grade = 'C' THEN 3 
                 WHEN grade = 'D' THEN 4 WHEN grade = 'E' THEN 5 ELSE 6 END +
            CASE WHEN dti < 10 THEN 0 WHEN dti < 20 THEN 1 WHEN dti < 30 THEN 2 ELSE 3 END +
            CASE WHEN int_rate < 10 THEN 0 WHEN int_rate < 15 THEN 1 ELSE 2 END +
            CASE WHEN verification_status = 'Verified' THEN 0 ELSE 1 END +
            CASE WHEN home_ownership IN ('MORTGAGE', 'OWN') THEN 0 ELSE 1 END
        ) <= 3 THEN 'Low Risk'
        WHEN (
            CASE WHEN grade = 'A' THEN 1 WHEN grade = 'B' THEN 2 WHEN grade = 'C' THEN 3 
                 WHEN grade = 'D' THEN 4 WHEN grade = 'E' THEN 5 ELSE 6 END +
            CASE WHEN dti < 10 THEN 0 WHEN dti < 20 THEN 1 WHEN dti < 30 THEN 2 ELSE 3 END +
            CASE WHEN int_rate < 10 THEN 0 WHEN int_rate < 15 THEN 1 ELSE 2 END +
            CASE WHEN verification_status = 'Verified' THEN 0 ELSE 1 END +
            CASE WHEN home_ownership IN ('MORTGAGE', 'OWN') THEN 0 ELSE 1 END
        ) <= 6 THEN 'Medium Risk'
        ELSE 'High Risk'
    END as risk_tier
FROM bank_loan
WHERE loan_status = 'Current'
ORDER BY composite_risk_score DESC
LIMIT 100;

-- ============================================================================
-- 14. PORTFOLIO STRESS TESTING
-- ============================================================================

-- Simulate different default scenarios
SELECT 
    'Current Portfolio' as scenario,
    COUNT(*) as total_loans,
    SUM(loan_amount) as total_exposure,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount ELSE 0 END) as current_losses,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount ELSE 0 END) * 100.0 / SUM(loan_amount),
    2) as loss_rate

UNION ALL

SELECT 
    '+5% Default Rate Scenario',
    COUNT(*),
    SUM(loan_amount),
    SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount ELSE 0 END) + (SUM(loan_amount) * 0.05),
    ROUND(
        (SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount ELSE 0 END) + (SUM(loan_amount) * 0.05)) * 100.0 / SUM(loan_amount),
    2)
FROM bank_loan

UNION ALL

SELECT 
    '+10% Default Rate Scenario',
    COUNT(*),
    SUM(loan_amount),
    SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount ELSE 0 END) + (SUM(loan_amount) * 0.10),
    ROUND(
        (SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount ELSE 0 END) + (SUM(loan_amount) * 0.10)) * 100.0 / SUM(loan_amount),
    2)
FROM bank_loan;

-- ============================================================================
-- End of Risk Analysis
-- ============================================================================
