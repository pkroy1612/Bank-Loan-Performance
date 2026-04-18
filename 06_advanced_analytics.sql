-- ============================================================================
-- Advanced Analytics - Complex Joins, Subqueries, and CTEs
-- ============================================================================
-- Description: Demonstrates advanced SQL techniques
-- Author: Your Name
-- Date: March 2025
-- ============================================================================

USE bank_loan_db;

-- ============================================================================
-- 1. RECURSIVE CTE - GRADE HIERARCHY ANALYSIS
-- ============================================================================

WITH RECURSIVE grade_performance AS (
    -- Base case: Individual grade performance
    SELECT 
        grade,
        sub_grade,
        COUNT(*) as loan_count,
        SUM(loan_amount) as total_funded,
        AVG(int_rate) as avg_rate,
        ROUND(
            SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2) as default_rate,
        1 as level
    FROM bank_loan
    GROUP BY grade, sub_grade
),
aggregated_grades AS (
    -- Aggregate to grade level
    SELECT 
        grade,
        NULL as sub_grade,
        SUM(loan_count) as loan_count,
        SUM(total_funded) as total_funded,
        AVG(avg_rate) as avg_rate,
        ROUND(
            SUM(loan_count * default_rate) / SUM(loan_count), 
        2) as default_rate,
        2 as level
    FROM grade_performance
    GROUP BY grade
)
SELECT * FROM grade_performance
UNION ALL
SELECT * FROM aggregated_grades
ORDER BY grade, level, sub_grade;

-- ============================================================================
-- 2. COMPLEX JOIN - CUSTOMER PORTFOLIO ANALYSIS
-- ============================================================================

WITH customer_summary AS (
    SELECT 
        member_id,
        COUNT(*) as total_loans,
        SUM(loan_amount) as total_borrowed,
        SUM(total_payment) as total_paid,
        AVG(int_rate) as avg_rate,
        MIN(issue_date) as first_loan_date,
        MAX(issue_date) as last_loan_date,
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) as defaults
    FROM bank_loan
    GROUP BY member_id
),
customer_categories AS (
    SELECT 
        member_id,
        CASE 
            WHEN total_loans = 1 THEN 'Single Loan'
            WHEN total_loans BETWEEN 2 AND 3 THEN 'Multiple Loans'
            ELSE 'Heavy Borrower'
        END as customer_type,
        CASE 
            WHEN defaults = 0 THEN 'No Defaults'
            WHEN defaults = 1 THEN 'One Default'
            ELSE 'Multiple Defaults'
        END as default_category
    FROM customer_summary
)
SELECT 
    cc.customer_type,
    cc.default_category,
    COUNT(DISTINCT cs.member_id) as customer_count,
    AVG(cs.total_loans) as avg_loans_per_customer,
    SUM(cs.total_borrowed) as total_exposure,
    AVG(cs.total_borrowed) as avg_borrowed_per_customer,
    SUM(cs.total_paid) as total_collected,
    ROUND(
        (SUM(cs.total_paid) - SUM(cs.total_borrowed)) * 100.0 / SUM(cs.total_borrowed), 
    2) as roi_percentage
FROM customer_summary cs
JOIN customer_categories cc ON cs.member_id = cc.member_id
GROUP BY cc.customer_type, cc.default_category
ORDER BY customer_count DESC;

-- ============================================================================
-- 3. SUBQUERY - TOP PERFORMING VS UNDERPERFORMING SEGMENTS
-- ============================================================================

WITH segment_performance AS (
    SELECT 
        grade,
        purpose,
        address_state,
        COUNT(*) as loan_count,
        SUM(loan_amount) as total_funded,
        SUM(total_payment - loan_amount) as net_profit,
        ROUND(
            SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2) as default_rate
    FROM bank_loan
    GROUP BY grade, purpose, address_state
    HAVING COUNT(*) >= 20
),
avg_metrics AS (
    SELECT 
        AVG(default_rate) as avg_default_rate,
        AVG(net_profit / total_funded) as avg_profit_margin
    FROM segment_performance
)
SELECT 
    sp.grade,
    sp.purpose,
    sp.address_state,
    sp.loan_count,
    sp.total_funded,
    sp.net_profit,
    sp.default_rate,
    CASE 
        WHEN sp.default_rate < am.avg_default_rate AND 
             (sp.net_profit / sp.total_funded) > am.avg_profit_margin 
        THEN 'Top Performer'
        WHEN sp.default_rate > am.avg_default_rate AND 
             (sp.net_profit / sp.total_funded) < am.avg_profit_margin 
        THEN 'Underperformer'
        ELSE 'Average'
    END as performance_category,
    ROUND(sp.default_rate - am.avg_default_rate, 2) as default_rate_vs_avg,
    ROUND((sp.net_profit / sp.total_funded - am.avg_profit_margin) * 100, 2) as profit_margin_vs_avg
FROM segment_performance sp
CROSS JOIN avg_metrics am
ORDER BY performance_category, sp.net_profit DESC;

-- ============================================================================
-- 4. WINDOW FUNCTIONS - PERCENTILE RANKING
-- ============================================================================

WITH loan_metrics AS (
    SELECT 
        loan_id,
        loan_amount,
        int_rate,
        dti,
        grade,
        loan_status,
        total_payment - loan_amount as profit_loss
    FROM bank_loan
)
SELECT 
    loan_id,
    grade,
    loan_amount,
    int_rate,
    dti,
    profit_loss,
    -- Percentile rankings
    NTILE(100) OVER (ORDER BY loan_amount) as loan_amount_percentile,
    NTILE(100) OVER (ORDER BY int_rate) as interest_rate_percentile,
    NTILE(100) OVER (ORDER BY dti) as dti_percentile,
    NTILE(4) OVER (ORDER BY profit_loss DESC) as profit_quartile,
    -- Within-grade rankings
    RANK() OVER (PARTITION BY grade ORDER BY profit_loss DESC) as grade_profit_rank,
    DENSE_RANK() OVER (PARTITION BY grade ORDER BY int_rate DESC) as grade_rate_rank
FROM loan_metrics
WHERE loan_status != 'Current'
ORDER BY profit_loss DESC
LIMIT 100;

-- ============================================================================
-- 5. CORRELATED SUBQUERY - IDENTIFY OUTLIERS
-- ============================================================================

SELECT 
    bl.loan_id,
    bl.grade,
    bl.loan_amount,
    bl.int_rate,
    bl.dti,
    bl.loan_status,
    (SELECT AVG(int_rate) 
     FROM bank_loan bl2 
     WHERE bl2.grade = bl.grade) as grade_avg_rate,
    (SELECT AVG(dti) 
     FROM bank_loan bl3 
     WHERE bl3.grade = bl.grade) as grade_avg_dti,
    -- Deviation from grade average
    bl.int_rate - (SELECT AVG(int_rate) FROM bank_loan bl2 WHERE bl2.grade = bl.grade) as rate_deviation,
    bl.dti - (SELECT AVG(dti) FROM bank_loan bl3 WHERE bl3.grade = bl.grade) as dti_deviation
FROM bank_loan bl
WHERE 
    ABS(bl.int_rate - (SELECT AVG(int_rate) FROM bank_loan WHERE grade = bl.grade)) > 3
    OR ABS(bl.dti - (SELECT AVG(dti) FROM bank_loan WHERE grade = bl.grade)) > 10
ORDER BY ABS(rate_deviation) DESC
LIMIT 50;

-- ============================================================================
-- 6. MULTI-LEVEL AGGREGATION WITH GROUPING SETS
-- ============================================================================

SELECT 
    COALESCE(address_state, 'ALL STATES') as state,
    COALESCE(grade, 'ALL GRADES') as grade,
    COALESCE(purpose, 'ALL PURPOSES') as purpose,
    COUNT(*) as loan_count,
    SUM(loan_amount) as total_funded,
    AVG(int_rate) as avg_rate,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as default_rate
FROM bank_loan
WHERE address_state IN ('CA', 'NY', 'TX', 'FL', 'IL')
GROUP BY address_state, grade, purpose WITH ROLLUP
HAVING COUNT(*) >= 10
ORDER BY state, grade, purpose;

-- ============================================================================
-- 7. SELF-JOIN - COMPARE LOAN COHORTS
-- ============================================================================

WITH monthly_cohorts AS (
    SELECT 
        DATE_FORMAT(issue_date, '%Y-%m') as cohort,
        COUNT(*) as cohort_size,
        AVG(loan_amount) as avg_loan_size,
        AVG(int_rate) as avg_rate,
        ROUND(
            SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2) as default_rate
    FROM bank_loan
    GROUP BY DATE_FORMAT(issue_date, '%Y-%m')
)
SELECT 
    c1.cohort as cohort1,
    c2.cohort as cohort2,
    c1.cohort_size as cohort1_size,
    c2.cohort_size as cohort2_size,
    ROUND(c1.avg_loan_size - c2.avg_loan_size, 2) as loan_size_diff,
    ROUND(c1.avg_rate - c2.avg_rate, 2) as rate_diff,
    ROUND(c1.default_rate - c2.default_rate, 2) as default_rate_diff,
    CASE 
        WHEN c1.default_rate < c2.default_rate THEN 'Cohort1 Better'
        WHEN c1.default_rate > c2.default_rate THEN 'Cohort2 Better'
        ELSE 'Similar'
    END as performance_comparison
FROM monthly_cohorts c1
JOIN monthly_cohorts c2 ON c1.cohort < c2.cohort
WHERE c1.cohort >= '2024-01' AND c2.cohort <= '2024-12'
ORDER BY ABS(c1.default_rate - c2.default_rate) DESC
LIMIT 20;

-- ============================================================================
-- 8. ADVANCED FILTERING - COMPLEX WHERE CONDITIONS
-- ============================================================================

SELECT 
    loan_id,
    grade,
    sub_grade,
    loan_amount,
    int_rate,
    dti,
    annual_income,
    purpose,
    loan_status,
    -- Risk indicators
    CASE 
        WHEN grade IN ('E', 'F', 'G') AND dti > 25 THEN 'High Risk'
        WHEN grade IN ('C', 'D') AND dti > 20 THEN 'Medium-High Risk'
        WHEN grade IN ('A', 'B') AND dti < 15 THEN 'Low Risk'
        ELSE 'Medium Risk'
    END as risk_category
FROM bank_loan
WHERE 
    -- Complex filtering conditions
    (
        (grade IN ('D', 'E', 'F') AND dti > 20) OR
        (int_rate > 15 AND verification_status = 'Not Verified') OR
        (loan_amount > 25000 AND annual_income < 50000)
    )
    AND loan_status = 'Current'
    AND home_ownership != 'OWN'
ORDER BY 
    CASE grade 
        WHEN 'A' THEN 1 WHEN 'B' THEN 2 WHEN 'C' THEN 3 
        WHEN 'D' THEN 4 WHEN 'E' THEN 5 ELSE 6 
    END,
    dti DESC
LIMIT 100;

-- ============================================================================
-- 9. LATERAL JOIN SIMULATION - TOP N PER GROUP
-- ============================================================================

WITH ranked_loans AS (
    SELECT 
        address_state,
        loan_id,
        loan_amount,
        int_rate,
        loan_status,
        ROW_NUMBER() OVER (PARTITION BY address_state ORDER BY loan_amount DESC) as rank_in_state
    FROM bank_loan
)
SELECT 
    address_state,
    loan_id,
    loan_amount,
    int_rate,
    loan_status
FROM ranked_loans
WHERE rank_in_state <= 3
ORDER BY address_state, rank_in_state;

-- ============================================================================
-- 10. PIVOT-LIKE ANALYSIS - LOAN STATUS BY GRADE
-- ============================================================================

SELECT 
    grade,
    SUM(CASE WHEN loan_status = 'Fully Paid' THEN 1 ELSE 0 END) as fully_paid_count,
    SUM(CASE WHEN loan_status = 'Current' THEN 1 ELSE 0 END) as current_count,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) as charged_off_count,
    ROUND(
        SUM(CASE WHEN loan_status = 'Fully Paid' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as fully_paid_pct,
    ROUND(
        SUM(CASE WHEN loan_status = 'Current' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as current_pct,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as charged_off_pct,
    COUNT(*) as total_loans
FROM bank_loan
GROUP BY grade
ORDER BY grade;

-- ============================================================================
-- 11. ADVANCED AGGREGATION - NESTED GROUP BY
-- ============================================================================

WITH purpose_grade_metrics AS (
    SELECT 
        purpose,
        grade,
        COUNT(*) as loan_count,
        SUM(loan_amount) as total_funded,
        AVG(int_rate) as avg_rate,
        ROUND(
            SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2) as default_rate
    FROM bank_loan
    GROUP BY purpose, grade
),
purpose_totals AS (
    SELECT 
        purpose,
        SUM(loan_count) as purpose_total_loans,
        SUM(total_funded) as purpose_total_funded
    FROM purpose_grade_metrics
    GROUP BY purpose
)
SELECT 
    pgm.purpose,
    pgm.grade,
    pgm.loan_count,
    pgm.total_funded,
    pgm.avg_rate,
    pgm.default_rate,
    -- Percentage of purpose total
    ROUND(pgm.loan_count * 100.0 / pt.purpose_total_loans, 2) as pct_of_purpose_loans,
    ROUND(pgm.total_funded * 100.0 / pt.purpose_total_funded, 2) as pct_of_purpose_funded,
    -- Ranking within purpose
    RANK() OVER (PARTITION BY pgm.purpose ORDER BY pgm.loan_count DESC) as grade_rank_by_volume,
    RANK() OVER (PARTITION BY pgm.purpose ORDER BY pgm.default_rate ASC) as grade_rank_by_quality
FROM purpose_grade_metrics pgm
JOIN purpose_totals pt ON pgm.purpose = pt.purpose
ORDER BY pgm.purpose, pgm.loan_count DESC;

-- ============================================================================
-- 12. UNION ALL - COMPREHENSIVE PORTFOLIO SUMMARY
-- ============================================================================

SELECT 
    'Total Portfolio' as segment,
    NULL as segment_value,
    COUNT(*) as loan_count,
    SUM(loan_amount) as total_funded,
    AVG(int_rate) as avg_rate,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as default_rate
FROM bank_loan

UNION ALL

SELECT 
    'By Grade' as segment,
    grade as segment_value,
    COUNT(*),
    SUM(loan_amount),
    AVG(int_rate),
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2)
FROM bank_loan
GROUP BY grade

UNION ALL

SELECT 
    'By Purpose' as segment,
    purpose as segment_value,
    COUNT(*),
    SUM(loan_amount),
    AVG(int_rate),
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2)
FROM bank_loan
GROUP BY purpose

ORDER BY segment, segment_value;

-- ============================================================================
-- End of Advanced Analytics
-- ============================================================================
