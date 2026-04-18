-- ============================================================================
-- Trend Analysis - Time Series and Window Functions
-- ============================================================================
-- Description: Advanced trend analysis using window functions and CTEs
-- Author: Your Name
-- Date: March 2025
-- ============================================================================

USE bank_loan_db;

-- ============================================================================
-- 1. MONTHLY LOAN TRENDS WITH MOVING AVERAGES
-- ============================================================================

WITH monthly_metrics AS (
    SELECT 
        DATE_FORMAT(issue_date, '%Y-%m') as month,
        COUNT(*) as applications,
        SUM(loan_amount) as funded_amount,
        AVG(int_rate) as avg_rate,
        AVG(dti) as avg_dti,
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) as defaults
    FROM bank_loan
    GROUP BY DATE_FORMAT(issue_date, '%Y-%m')
)
SELECT 
    month,
    applications,
    funded_amount,
    avg_rate,
    -- 3-month moving average
    AVG(applications) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as ma_3month_apps,
    AVG(funded_amount) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as ma_3month_funded,
    -- Month-over-month growth
    applications - LAG(applications, 1) OVER (ORDER BY month) as mom_app_change,
    ROUND(
        (applications - LAG(applications, 1) OVER (ORDER BY month)) * 100.0 / 
        NULLIF(LAG(applications, 1) OVER (ORDER BY month), 0), 
    2) as mom_app_growth_pct,
    -- Year-over-year growth
    applications - LAG(applications, 12) OVER (ORDER BY month) as yoy_app_change,
    ROUND(
        (applications - LAG(applications, 12) OVER (ORDER BY month)) * 100.0 / 
        NULLIF(LAG(applications, 12) OVER (ORDER BY month), 0), 
    2) as yoy_app_growth_pct
FROM monthly_metrics
ORDER BY month;

-- ============================================================================
-- 2. CUMULATIVE STATISTICS BY MONTH
-- ============================================================================

WITH monthly_data AS (
    SELECT 
        DATE_FORMAT(issue_date, '%Y-%m') as month,
        COUNT(*) as monthly_applications,
        SUM(loan_amount) as monthly_funded,
        SUM(total_payment) as monthly_received
    FROM bank_loan
    GROUP BY DATE_FORMAT(issue_date, '%Y-%m')
)
SELECT 
    month,
    monthly_applications,
    monthly_funded,
    monthly_received,
    SUM(monthly_applications) OVER (ORDER BY month) as cumulative_applications,
    SUM(monthly_funded) OVER (ORDER BY month) as cumulative_funded,
    SUM(monthly_received) OVER (ORDER BY month) as cumulative_received,
    -- Running average
    AVG(monthly_applications) OVER (ORDER BY month) as running_avg_applications,
    -- Percentage of total
    ROUND(monthly_applications * 100.0 / SUM(monthly_applications) OVER (), 2) as pct_of_total_apps
FROM monthly_data
ORDER BY month;

-- ============================================================================
-- 3. SEASONAL PATTERN ANALYSIS
-- ============================================================================

SELECT 
    MONTH(issue_date) as month_number,
    MONTHNAME(issue_date) as month_name,
    COUNT(*) as total_applications,
    AVG(loan_amount) as avg_loan_amount,
    SUM(loan_amount) as total_funded,
    AVG(int_rate) as avg_interest_rate,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as default_rate
FROM bank_loan
GROUP BY MONTH(issue_date), MONTHNAME(issue_date)
ORDER BY month_number;

-- ============================================================================
-- 4. QUARTER-OVER-QUARTER ANALYSIS
-- ============================================================================

WITH quarterly_metrics AS (
    SELECT 
        YEAR(issue_date) as year,
        QUARTER(issue_date) as quarter,
        CONCAT('Q', QUARTER(issue_date), ' ', YEAR(issue_date)) as quarter_label,
        COUNT(*) as applications,
        SUM(loan_amount) as funded_amount,
        AVG(int_rate) as avg_rate,
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) as defaults
    FROM bank_loan
    GROUP BY YEAR(issue_date), QUARTER(issue_date)
)
SELECT 
    quarter_label,
    applications,
    funded_amount,
    avg_rate,
    defaults,
    -- Quarter-over-quarter growth
    applications - LAG(applications, 1) OVER (ORDER BY year, quarter) as qoq_app_change,
    ROUND(
        (applications - LAG(applications, 1) OVER (ORDER BY year, quarter)) * 100.0 / 
        NULLIF(LAG(applications, 1) OVER (ORDER BY year, quarter), 0), 
    2) as qoq_growth_pct,
    -- Year-over-year quarterly comparison
    applications - LAG(applications, 4) OVER (ORDER BY year, quarter) as yoy_app_change,
    ROUND(
        (applications - LAG(applications, 4) OVER (ORDER BY year, quarter)) * 100.0 / 
        NULLIF(LAG(applications, 4) OVER (ORDER BY year, quarter), 0), 
    2) as yoy_growth_pct
FROM quarterly_metrics
ORDER BY year, quarter;

-- ============================================================================
-- 5. GRADE MIGRATION OVER TIME
-- ============================================================================

WITH monthly_grade_dist AS (
    SELECT 
        DATE_FORMAT(issue_date, '%Y-%m') as month,
        grade,
        COUNT(*) as loan_count,
        SUM(COUNT(*)) OVER (PARTITION BY DATE_FORMAT(issue_date, '%Y-%m')) as total_month_loans
    FROM bank_loan
    GROUP BY DATE_FORMAT(issue_date, '%Y-%m'), grade
)
SELECT 
    month,
    grade,
    loan_count,
    ROUND(loan_count * 100.0 / total_month_loans, 2) as percentage_of_month,
    -- Compare to previous month
    LAG(loan_count, 1) OVER (PARTITION BY grade ORDER BY month) as prev_month_count,
    loan_count - LAG(loan_count, 1) OVER (PARTITION BY grade ORDER BY month) as count_change
FROM monthly_grade_dist
ORDER BY month, grade;

-- ============================================================================
-- 6. DEFAULT RATE TRENDS
-- ============================================================================

WITH monthly_defaults AS (
    SELECT 
        DATE_FORMAT(issue_date, '%Y-%m') as month,
        COUNT(*) as total_loans,
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) as defaults,
        ROUND(
            SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2) as default_rate
    FROM bank_loan
    GROUP BY DATE_FORMAT(issue_date, '%Y-%m')
)
SELECT 
    month,
    total_loans,
    defaults,
    default_rate,
    -- 3-month moving average of default rate
    AVG(default_rate) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as ma_3month_default_rate,
    -- Trend direction
    CASE 
        WHEN default_rate > LAG(default_rate, 1) OVER (ORDER BY month) THEN 'Increasing'
        WHEN default_rate < LAG(default_rate, 1) OVER (ORDER BY month) THEN 'Decreasing'
        ELSE 'Stable'
    END as trend_direction,
    -- Change from previous month
    default_rate - LAG(default_rate, 1) OVER (ORDER BY month) as mom_change
FROM monthly_defaults
ORDER BY month;

-- ============================================================================
-- 7. INTEREST RATE TRENDS
-- ============================================================================

WITH rate_trends AS (
    SELECT 
        DATE_FORMAT(issue_date, '%Y-%m') as month,
        AVG(int_rate) as avg_rate,
        MIN(int_rate) as min_rate,
        MAX(int_rate) as max_rate,
        STDDEV(int_rate) as rate_std_dev
    FROM bank_loan
    GROUP BY DATE_FORMAT(issue_date, '%Y-%m')
)
SELECT 
    month,
    ROUND(avg_rate, 2) as avg_rate,
    ROUND(min_rate, 2) as min_rate,
    ROUND(max_rate, 2) as max_rate,
    ROUND(rate_std_dev, 2) as std_dev,
    -- Moving average
    ROUND(AVG(avg_rate) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) as ma_3month,
    -- Rate change
    ROUND(avg_rate - LAG(avg_rate, 1) OVER (ORDER BY month), 2) as mom_rate_change,
    -- Volatility trend
    ROUND(rate_std_dev - LAG(rate_std_dev, 1) OVER (ORDER BY month), 2) as volatility_change
FROM rate_trends
ORDER BY month;

-- ============================================================================
-- 8. COHORT ANALYSIS BY ISSUE MONTH
-- ============================================================================

WITH loan_cohorts AS (
    SELECT 
        DATE_FORMAT(issue_date, '%Y-%m') as cohort_month,
        loan_status,
        COUNT(*) as loan_count,
        SUM(loan_amount) as total_amount,
        AVG(int_rate) as avg_rate
    FROM bank_loan
    GROUP BY DATE_FORMAT(issue_date, '%Y-%m'), loan_status
)
SELECT 
    cohort_month,
    SUM(loan_count) as total_cohort_size,
    SUM(CASE WHEN loan_status = 'Fully Paid' THEN loan_count ELSE 0 END) as fully_paid,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_count ELSE 0 END) as charged_off,
    SUM(CASE WHEN loan_status = 'Current' THEN loan_count ELSE 0 END) as current,
    ROUND(
        SUM(CASE WHEN loan_status = 'Fully Paid' THEN loan_count ELSE 0 END) * 100.0 / SUM(loan_count), 
    2) as fully_paid_rate,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_count ELSE 0 END) * 100.0 / SUM(loan_count), 
    2) as default_rate
FROM loan_cohorts
GROUP BY cohort_month
ORDER BY cohort_month;

-- ============================================================================
-- 9. LOAN SIZE TRENDS OVER TIME
-- ============================================================================

WITH size_trends AS (
    SELECT 
        DATE_FORMAT(issue_date, '%Y-%m') as month,
        AVG(loan_amount) as avg_loan_size,
        MIN(loan_amount) as min_loan,
        MAX(loan_amount) as max_loan,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY loan_amount) as median_loan
    FROM bank_loan
    GROUP BY DATE_FORMAT(issue_date, '%Y-%m')
)
SELECT 
    month,
    ROUND(avg_loan_size, 2) as avg_loan_size,
    min_loan,
    max_loan,
    median_loan,
    -- Growth rates
    ROUND(
        (avg_loan_size - LAG(avg_loan_size, 1) OVER (ORDER BY month)) * 100.0 / 
        NULLIF(LAG(avg_loan_size, 1) OVER (ORDER BY month), 0), 
    2) as mom_avg_growth_pct,
    -- 6-month moving average
    ROUND(AVG(avg_loan_size) OVER (ORDER BY month ROWS BETWEEN 5 PRECEDING AND CURRENT ROW), 2) as ma_6month
FROM size_trends
ORDER BY month;

-- ============================================================================
-- 10. PORTFOLIO COMPOSITION CHANGES
-- ============================================================================

WITH monthly_composition AS (
    SELECT 
        DATE_FORMAT(issue_date, '%Y-%m') as month,
        purpose,
        COUNT(*) as loan_count,
        SUM(loan_amount) as total_funded
    FROM bank_loan
    GROUP BY DATE_FORMAT(issue_date, '%Y-%m'), purpose
),
monthly_totals AS (
    SELECT 
        month,
        SUM(loan_count) as total_month_loans,
        SUM(total_funded) as total_month_funded
    FROM monthly_composition
    GROUP BY month
)
SELECT 
    mc.month,
    mc.purpose,
    mc.loan_count,
    mc.total_funded,
    ROUND(mc.loan_count * 100.0 / mt.total_month_loans, 2) as pct_of_applications,
    ROUND(mc.total_funded * 100.0 / mt.total_month_funded, 2) as pct_of_funded_amount,
    -- Compare to previous month
    LAG(mc.loan_count, 1) OVER (PARTITION BY mc.purpose ORDER BY mc.month) as prev_month_count,
    ROUND(
        (mc.loan_count - LAG(mc.loan_count, 1) OVER (PARTITION BY mc.purpose ORDER BY mc.month)) * 100.0 / 
        NULLIF(LAG(mc.loan_count, 1) OVER (PARTITION BY mc.purpose ORDER BY mc.month), 0), 
    2) as mom_growth_pct
FROM monthly_composition mc
JOIN monthly_totals mt ON mc.month = mt.month
ORDER BY mc.month, mc.loan_count DESC;

-- ============================================================================
-- 11. PERFORMANCE RANKING BY MONTH
-- ============================================================================

WITH monthly_performance AS (
    SELECT 
        DATE_FORMAT(issue_date, '%Y-%m') as month,
        COUNT(*) as applications,
        SUM(loan_amount) as funded_amount,
        SUM(total_payment) as received_amount,
        (SUM(total_payment) - SUM(loan_amount)) as net_profit,
        ROUND(
            SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2) as default_rate
    FROM bank_loan
    GROUP BY DATE_FORMAT(issue_date, '%Y-%m')
)
SELECT 
    month,
    applications,
    funded_amount,
    received_amount,
    net_profit,
    default_rate,
    -- Rank months by various metrics
    RANK() OVER (ORDER BY applications DESC) as applications_rank,
    RANK() OVER (ORDER BY funded_amount DESC) as funded_rank,
    RANK() OVER (ORDER BY net_profit DESC) as profit_rank,
    RANK() OVER (ORDER BY default_rate ASC) as risk_rank,
    -- Overall performance score (lower is better)
    (RANK() OVER (ORDER BY applications DESC) +
     RANK() OVER (ORDER BY funded_amount DESC) +
     RANK() OVER (ORDER BY net_profit DESC) +
     RANK() OVER (ORDER BY default_rate ASC)) as composite_score
FROM monthly_performance
ORDER BY composite_score;

-- ============================================================================
-- 12. WEEK-OVER-WEEK TRENDING (Recent Data)
-- ============================================================================

WITH weekly_data AS (
    SELECT 
        YEARWEEK(issue_date) as year_week,
        DATE(DATE_SUB(issue_date, INTERVAL WEEKDAY(issue_date) DAY)) as week_start,
        COUNT(*) as applications,
        SUM(loan_amount) as funded_amount,
        AVG(int_rate) as avg_rate
    FROM bank_loan
    WHERE issue_date >= DATE_SUB(CURDATE(), INTERVAL 12 WEEK)
    GROUP BY YEARWEEK(issue_date), DATE(DATE_SUB(issue_date, INTERVAL WEEKDAY(issue_date) DAY))
)
SELECT 
    week_start,
    applications,
    funded_amount,
    avg_rate,
    -- Week-over-week change
    applications - LAG(applications, 1) OVER (ORDER BY week_start) as wow_app_change,
    ROUND(
        (applications - LAG(applications, 1) OVER (ORDER BY week_start)) * 100.0 / 
        NULLIF(LAG(applications, 1) OVER (ORDER BY week_start), 0), 
    2) as wow_growth_pct
FROM weekly_data
ORDER BY week_start DESC;

-- ============================================================================
-- End of Trend Analysis
-- ============================================================================
