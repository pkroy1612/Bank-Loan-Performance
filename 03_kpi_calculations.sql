-- ============================================================================
-- KPI Calculations
-- ============================================================================
-- Description: Key Performance Indicators for loan portfolio analysis
-- Author: Your Name
-- Date: March 2025
-- ============================================================================

USE bank_loan_db;

-- ============================================================================
-- 1. PRIMARY KPIs
-- ============================================================================

-- Total Loan Applications
SELECT 
    'Total Loan Applications' as KPI,
    COUNT(*) as Value,
    'Count' as Unit
FROM bank_loan;

-- Total Funded Amount
SELECT 
    'Total Funded Amount' as KPI,
    CONCAT('$', FORMAT(SUM(loan_amount), 2)) as Value,
    'USD' as Unit
FROM bank_loan;

-- Total Amount Received
SELECT 
    'Total Amount Received' as KPI,
    CONCAT('$', FORMAT(SUM(total_payment), 2)) as Value,
    'USD' as Unit
FROM bank_loan;

-- Average Interest Rate
SELECT 
    'Average Interest Rate' as KPI,
    CONCAT(ROUND(AVG(int_rate), 2), '%') as Value,
    'Percentage' as Unit
FROM bank_loan;

-- Average DTI (Debt-to-Income Ratio)
SELECT 
    'Average DTI' as KPI,
    CONCAT(ROUND(AVG(dti), 2), '%') as Value,
    'Percentage' as Unit
FROM bank_loan;

-- ============================================================================
-- 2. GOOD LOAN KPIs
-- ============================================================================

-- Good Loan Percentage
SELECT 
    'Good Loan Percentage' as KPI,
    CONCAT(ROUND(
        (COUNT(CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 1 END) * 100.0 / COUNT(*)), 
    2), '%') as Value
FROM bank_loan;

-- Good Loan Applications
SELECT 
    'Good Loan Applications' as KPI,
    COUNT(*) as Value
FROM bank_loan
WHERE loan_status IN ('Fully Paid', 'Current');

-- Good Loan Funded Amount
SELECT 
    'Good Loan Funded Amount' as KPI,
    CONCAT('$', FORMAT(SUM(loan_amount), 2)) as Value
FROM bank_loan
WHERE loan_status IN ('Fully Paid', 'Current');

-- Good Loan Total Received Amount
SELECT 
    'Good Loan Total Received' as KPI,
    CONCAT('$', FORMAT(SUM(total_payment), 2)) as Value
FROM bank_loan
WHERE loan_status IN ('Fully Paid', 'Current');

-- ============================================================================
-- 3. BAD LOAN KPIs
-- ============================================================================

-- Bad Loan Percentage
SELECT 
    'Bad Loan Percentage' as KPI,
    CONCAT(ROUND(
        (COUNT(CASE WHEN loan_status = 'Charged Off' THEN 1 END) * 100.0 / COUNT(*)), 
    2), '%') as Value
FROM bank_loan;

-- Bad Loan Applications
SELECT 
    'Bad Loan Applications' as KPI,
    COUNT(*) as Value
FROM bank_loan
WHERE loan_status = 'Charged Off';

-- Bad Loan Funded Amount
SELECT 
    'Bad Loan Funded Amount' as KPI,
    CONCAT('$', FORMAT(SUM(loan_amount), 2)) as Value
FROM bank_loan
WHERE loan_status = 'Charged Off';

-- Bad Loan Total Received Amount
SELECT 
    'Bad Loan Total Received' as KPI,
    CONCAT('$', FORMAT(SUM(total_payment), 2)) as Value
FROM bank_loan
WHERE loan_status = 'Charged Off';

-- ============================================================================
-- 4. COMPREHENSIVE KPI DASHBOARD
-- ============================================================================

SELECT 
    'All Loans' as Category,
    COUNT(*) as Total_Applications,
    CONCAT('$', FORMAT(SUM(loan_amount), 2)) as Total_Funded,
    CONCAT('$', FORMAT(SUM(total_payment), 2)) as Total_Received,
    CONCAT('$', FORMAT(AVG(loan_amount), 2)) as Avg_Loan_Amount,
    CONCAT(ROUND(AVG(int_rate), 2), '%') as Avg_Interest_Rate,
    CONCAT(ROUND(AVG(dti), 2), '%') as Avg_DTI
FROM bank_loan

UNION ALL

SELECT 
    'Good Loans',
    COUNT(*),
    CONCAT('$', FORMAT(SUM(loan_amount), 2)),
    CONCAT('$', FORMAT(SUM(total_payment), 2)),
    CONCAT('$', FORMAT(AVG(loan_amount), 2)),
    CONCAT(ROUND(AVG(int_rate), 2), '%'),
    CONCAT(ROUND(AVG(dti), 2), '%')
FROM bank_loan
WHERE loan_status IN ('Fully Paid', 'Current')

UNION ALL

SELECT 
    'Bad Loans',
    COUNT(*),
    CONCAT('$', FORMAT(SUM(loan_amount), 2)),
    CONCAT('$', FORMAT(SUM(total_payment), 2)),
    CONCAT('$', FORMAT(AVG(loan_amount), 2)),
    CONCAT(ROUND(AVG(int_rate), 2), '%'),
    CONCAT(ROUND(AVG(dti), 2), '%')
FROM bank_loan
WHERE loan_status = 'Charged Off';

-- ============================================================================
-- 5. MONTH-OVER-MONTH (MoM) ANALYSIS
-- ============================================================================

-- MTD (Month-to-Date) Loan Applications
SELECT 
    DATE_FORMAT(issue_date, '%Y-%m') as Month,
    COUNT(*) as MTD_Applications
FROM bank_loan
WHERE DATE_FORMAT(issue_date, '%Y-%m') = DATE_FORMAT(CURRENT_DATE, '%Y-%m')
GROUP BY DATE_FORMAT(issue_date, '%Y-%m');

-- MoM Applications
WITH monthly_stats AS (
    SELECT 
        DATE_FORMAT(issue_date, '%Y-%m') as month,
        COUNT(*) as applications,
        SUM(loan_amount) as funded_amount
    FROM bank_loan
    GROUP BY DATE_FORMAT(issue_date, '%Y-%m')
)
SELECT 
    month,
    applications,
    LAG(applications) OVER (ORDER BY month) as prev_month_applications,
    applications - LAG(applications) OVER (ORDER BY month) as mom_change,
    ROUND(
        (applications - LAG(applications) OVER (ORDER BY month)) * 100.0 / 
        NULLIF(LAG(applications) OVER (ORDER BY month), 0), 
    2) as mom_change_percentage
FROM monthly_stats
ORDER BY month DESC
LIMIT 12;

-- ============================================================================
-- 6. MONTHLY TREND KPIs
-- ============================================================================

SELECT 
    DATE_FORMAT(issue_date, '%Y-%m') as Month,
    COUNT(*) as Total_Applications,
    SUM(loan_amount) as Total_Funded_Amount,
    SUM(total_payment) as Total_Received_Amount,
    AVG(int_rate) as Avg_Interest_Rate,
    AVG(dti) as Avg_DTI,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) as Charged_Off_Count,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as Default_Rate_Percentage
FROM bank_loan
GROUP BY DATE_FORMAT(issue_date, '%Y-%m')
ORDER BY Month DESC;

-- ============================================================================
-- 7. STATE-WISE KPIs
-- ============================================================================

SELECT 
    address_state as State,
    COUNT(*) as Total_Applications,
    SUM(loan_amount) as Total_Funded,
    SUM(total_payment) as Total_Received,
    AVG(int_rate) as Avg_Interest_Rate,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) as Bad_Loans,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as Default_Rate
FROM bank_loan
GROUP BY address_state
ORDER BY Total_Applications DESC;

-- ============================================================================
-- 8. TERM-WISE KPIs
-- ============================================================================

SELECT 
    term as Loan_Term,
    COUNT(*) as Total_Applications,
    SUM(loan_amount) as Total_Funded,
    SUM(total_payment) as Total_Received,
    AVG(int_rate) as Avg_Interest_Rate,
    AVG(installment) as Avg_Monthly_Payment,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as Default_Rate
FROM bank_loan
GROUP BY term
ORDER BY Total_Applications DESC;

-- ============================================================================
-- 9. PURPOSE-WISE KPIs
-- ============================================================================

SELECT 
    purpose as Loan_Purpose,
    COUNT(*) as Total_Applications,
    SUM(loan_amount) as Total_Funded,
    SUM(total_payment) as Total_Received,
    AVG(int_rate) as Avg_Interest_Rate,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as Default_Rate
FROM bank_loan
GROUP BY purpose
ORDER BY Total_Applications DESC;

-- ============================================================================
-- 10. GRADE-WISE KPIs
-- ============================================================================

SELECT 
    grade as Loan_Grade,
    COUNT(*) as Total_Applications,
    SUM(loan_amount) as Total_Funded,
    SUM(total_payment) as Total_Received,
    AVG(int_rate) as Avg_Interest_Rate,
    AVG(dti) as Avg_DTI,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as Default_Rate
FROM bank_loan
GROUP BY grade
ORDER BY grade;

-- ============================================================================
-- 11. VERIFICATION STATUS KPIs
-- ============================================================================

SELECT 
    verification_status,
    COUNT(*) as Total_Applications,
    SUM(loan_amount) as Total_Funded,
    AVG(annual_income) as Avg_Annual_Income,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as Default_Rate
FROM bank_loan
GROUP BY verification_status
ORDER BY Total_Applications DESC;

-- ============================================================================
-- 12. HOME OWNERSHIP KPIs
-- ============================================================================

SELECT 
    home_ownership,
    COUNT(*) as Total_Applications,
    SUM(loan_amount) as Total_Funded,
    AVG(loan_amount) as Avg_Loan_Amount,
    AVG(int_rate) as Avg_Interest_Rate,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as Default_Rate
FROM bank_loan
GROUP BY home_ownership
ORDER BY Total_Applications DESC;

-- ============================================================================
-- 13. PERFORMANCE RATIOS
-- ============================================================================

SELECT 
    -- Return on Investment
    ROUND(
        (SUM(total_payment) - SUM(loan_amount)) * 100.0 / SUM(loan_amount), 
    2) as ROI_Percentage,
    
    -- Net Profit/Loss
    SUM(total_payment) - SUM(loan_amount) as Net_Profit_Loss,
    
    -- Average Return per Loan
    AVG(total_payment - loan_amount) as Avg_Return_Per_Loan,
    
    -- Portfolio Risk Score (weighted default rate)
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount ELSE 0 END) * 100.0 / 
        SUM(loan_amount), 
    2) as Portfolio_Risk_Score
FROM bank_loan;

-- ============================================================================
-- 14. REAL-TIME DASHBOARD KPIs (Current Month Focus)
-- ============================================================================

SELECT 
    'Current Month Performance' as Period,
    COUNT(*) as Applications,
    SUM(loan_amount) as Funded_Amount,
    AVG(int_rate) as Avg_Rate,
    SUM(CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 1 ELSE 0 END) as Good_Loans,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) as Bad_Loans
FROM bank_loan
WHERE DATE_FORMAT(issue_date, '%Y-%m') = DATE_FORMAT(CURRENT_DATE, '%Y-%m')

UNION ALL

SELECT 
    'Previous Month Performance',
    COUNT(*),
    SUM(loan_amount),
    AVG(int_rate),
    SUM(CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 1 ELSE 0 END),
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END)
FROM bank_loan
WHERE DATE_FORMAT(issue_date, '%Y-%m') = DATE_FORMAT(DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH), '%Y-%m');

-- ============================================================================
-- End of KPI Calculations
-- ============================================================================
