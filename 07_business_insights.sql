-- ============================================================================
-- Business Insights and Strategic Queries
-- ============================================================================
-- Description: Actionable insights for business decision-making
-- Author: Your Name
-- Date: March 2025
-- ============================================================================

USE bank_loan_db;

-- ============================================================================
-- 1. PORTFOLIO OPTIMIZATION OPPORTUNITIES
-- ============================================================================

-- Identify underperforming segments to reduce
SELECT 
    'Reduce Exposure' as recommendation,
    grade,
    purpose,
    address_state,
    COUNT(*) as loan_count,
    SUM(loan_amount) as current_exposure,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as default_rate,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount ELSE 0 END), 
    2) as estimated_losses,
    'High risk, consider tightening lending criteria' as action
FROM bank_loan
GROUP BY grade, purpose, address_state
HAVING 
    COUNT(*) >= 100 
    AND SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 20
ORDER BY default_rate DESC, current_exposure DESC
LIMIT 10;

-- Identify high-performing segments to expand
SELECT 
    'Expand Exposure' as recommendation,
    grade,
    purpose,
    address_state,
    COUNT(*) as loan_count,
    SUM(loan_amount) as current_exposure,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as default_rate,
    ROUND(
        (SUM(total_payment) - SUM(loan_amount)) * 100.0 / SUM(loan_amount), 
    2) as roi_pct,
    'Low risk, high return, consider marketing expansion' as action
FROM bank_loan
GROUP BY grade, purpose, address_state
HAVING 
    COUNT(*) >= 50 
    AND SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) < 8
    AND (SUM(total_payment) - SUM(loan_amount)) * 100.0 / SUM(loan_amount) > 15
ORDER BY roi_pct DESC
LIMIT 10;

-- ============================================================================
-- 2. PRICING STRATEGY RECOMMENDATIONS
-- ============================================================================

-- Interest rate adjustments by risk profile
WITH risk_return_analysis AS (
    SELECT 
        grade,
        ROUND(AVG(int_rate), 2) as current_avg_rate,
        ROUND(
            SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2) as actual_default_rate,
        ROUND(
            (SUM(total_payment) - SUM(loan_amount)) * 100.0 / SUM(loan_amount), 
        2) as actual_roi,
        COUNT(*) as loan_volume
    FROM bank_loan
    GROUP BY grade
)
SELECT 
    grade,
    current_avg_rate,
    actual_default_rate,
    actual_roi,
    loan_volume,
    -- Suggested rate adjustment
    CASE 
        WHEN actual_default_rate > 15 AND actual_roi < 10 
            THEN ROUND(current_avg_rate * 1.15, 2)
        WHEN actual_default_rate < 8 AND actual_roi > 20 
            THEN ROUND(current_avg_rate * 0.95, 2)
        ELSE current_avg_rate
    END as suggested_rate,
    CASE 
        WHEN actual_default_rate > 15 AND actual_roi < 10 
            THEN 'Increase rate by 15% to compensate for high defaults'
        WHEN actual_default_rate < 8 AND actual_roi > 20 
            THEN 'Decrease rate by 5% to attract more volume'
        ELSE 'Maintain current pricing'
    END as pricing_recommendation
FROM risk_return_analysis
ORDER BY grade;

-- ============================================================================
-- 3. CUSTOMER ACQUISITION STRATEGY
-- ============================================================================

-- Best customer profiles to target
SELECT 
    grade,
    emp_length,
    home_ownership,
    verification_status,
    COUNT(*) as successful_customers,
    AVG(loan_amount) as avg_loan_size,
    AVG(annual_income) as avg_income,
    AVG(dti) as avg_dti,
    ROUND(
        SUM(CASE WHEN loan_status = 'Fully Paid' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as success_rate,
    SUM(total_payment - loan_amount) as total_profit
FROM bank_loan
WHERE loan_status IN ('Fully Paid', 'Current')
GROUP BY grade, emp_length, home_ownership, verification_status
HAVING 
    COUNT(*) >= 50
    AND SUM(CASE WHEN loan_status = 'Fully Paid' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 85
ORDER BY total_profit DESC
LIMIT 15;

-- ============================================================================
-- 4. GEOGRAPHIC EXPANSION ANALYSIS
-- ============================================================================

-- States with growth potential
WITH state_metrics AS (
    SELECT 
        address_state,
        COUNT(*) as current_loans,
        SUM(loan_amount) as current_exposure,
        AVG(loan_amount) as avg_loan_size,
        ROUND(
            SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2) as default_rate,
        ROUND(
            (SUM(total_payment) - SUM(loan_amount)) * 100.0 / SUM(loan_amount), 
        2) as roi_pct
    FROM bank_loan
    GROUP BY address_state
),
state_rankings AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY current_loans DESC) as volume_rank,
        RANK() OVER (ORDER BY default_rate ASC) as quality_rank,
        RANK() OVER (ORDER BY roi_pct DESC) as profitability_rank
    FROM state_metrics
)
SELECT 
    address_state,
    current_loans,
    current_exposure,
    avg_loan_size,
    default_rate,
    roi_pct,
    (volume_rank + quality_rank + profitability_rank) / 3 as composite_score,
    CASE 
        WHEN current_loans < 500 AND default_rate < 12 AND roi_pct > 12 
            THEN 'High Potential - Expand Aggressively'
        WHEN current_loans >= 500 AND default_rate < 10 
            THEN 'Stable Market - Maintain Growth'
        WHEN default_rate > 18 
            THEN 'High Risk - Reduce Exposure'
        ELSE 'Standard Market - Monitor'
    END as expansion_strategy
FROM state_rankings
ORDER BY composite_score
LIMIT 20;

-- ============================================================================
-- 5. PRODUCT MIX OPTIMIZATION
-- ============================================================================

-- Optimal purpose distribution
WITH purpose_performance AS (
    SELECT 
        purpose,
        COUNT(*) as volume,
        SUM(loan_amount) as funded,
        ROUND(AVG(int_rate), 2) as avg_rate,
        ROUND(
            SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2) as default_rate,
        ROUND(
            (SUM(total_payment) - SUM(loan_amount)) / SUM(loan_amount) * 100, 
        2) as roi_pct
    FROM bank_loan
    GROUP BY purpose
),
current_mix AS (
    SELECT 
        purpose,
        ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM bank_loan), 2) as current_pct_of_portfolio
    FROM bank_loan
    GROUP BY purpose
)
SELECT 
    pp.purpose,
    pp.volume,
    cm.current_pct_of_portfolio,
    pp.default_rate,
    pp.roi_pct,
    -- Suggested portfolio allocation
    CASE 
        WHEN pp.default_rate < 10 AND pp.roi_pct > 15 
            THEN ROUND(cm.current_pct_of_portfolio * 1.2, 2)
        WHEN pp.default_rate > 18 OR pp.roi_pct < 5 
            THEN ROUND(cm.current_pct_of_portfolio * 0.8, 2)
        ELSE cm.current_pct_of_portfolio
    END as suggested_pct_of_portfolio,
    CASE 
        WHEN pp.default_rate < 10 AND pp.roi_pct > 15 
            THEN 'Increase allocation by 20%'
        WHEN pp.default_rate > 18 OR pp.roi_pct < 5 
            THEN 'Decrease allocation by 20%'
        ELSE 'Maintain current allocation'
    END as recommendation
FROM purpose_performance pp
JOIN current_mix cm ON pp.purpose = cm.purpose
ORDER BY pp.roi_pct DESC;

-- ============================================================================
-- 6. RISK MITIGATION STRATEGIES
-- ============================================================================

-- High-risk loans requiring intervention
SELECT 
    loan_id,
    member_id,
    loan_amount,
    grade,
    dti,
    int_rate,
    loan_status,
    DATEDIFF(CURDATE(), issue_date) as days_since_origination,
    -- Risk score
    (CASE WHEN grade IN ('E', 'F', 'G') THEN 4 ELSE 0 END +
     CASE WHEN dti > 25 THEN 3 ELSE 0 END +
     CASE WHEN int_rate > 18 THEN 2 ELSE 0 END +
     CASE WHEN verification_status = 'Not Verified' THEN 2 ELSE 0 END) as risk_score,
    CASE 
        WHEN grade IN ('E', 'F', 'G') AND dti > 25 
            THEN 'Immediate follow-up required'
        WHEN int_rate > 18 AND verification_status = 'Not Verified' 
            THEN 'Enhanced monitoring'
        ELSE 'Standard monitoring'
    END as recommended_action
FROM bank_loan
WHERE loan_status = 'Current'
    AND (grade IN ('D', 'E', 'F', 'G') OR dti > 20 OR int_rate > 16)
ORDER BY 
    (CASE WHEN grade IN ('E', 'F', 'G') THEN 4 ELSE 0 END +
     CASE WHEN dti > 25 THEN 3 ELSE 0 END +
     CASE WHEN int_rate > 18 THEN 2 ELSE 0 END +
     CASE WHEN verification_status = 'Not Verified' THEN 2 ELSE 0 END) DESC
LIMIT 100;

-- ============================================================================
-- 7. VERIFICATION PROCESS OPTIMIZATION
-- ============================================================================

-- ROI of verification by grade
SELECT 
    grade,
    verification_status,
    COUNT(*) as loan_count,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as default_rate,
    ROUND(
        (SUM(total_payment) - SUM(loan_amount)) / SUM(loan_amount) * 100, 
    2) as roi_pct,
    CASE 
        WHEN verification_status = 'Not Verified' 
            THEN 'Consider requiring verification'
        ELSE 'Continue current process'
    END as recommendation
FROM bank_loan
GROUP BY grade, verification_status
HAVING COUNT(*) >= 30
ORDER BY grade, verification_status;

-- ============================================================================
-- 8. LOAN TERM STRATEGY
-- ============================================================================

-- Optimal term by customer segment
SELECT 
    term,
    grade,
    purpose,
    COUNT(*) as loan_count,
    AVG(loan_amount) as avg_amount,
    AVG(installment) as avg_monthly_payment,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as default_rate,
    ROUND(
        SUM(total_payment - loan_amount) / SUM(loan_amount) * 100, 
    2) as roi_pct,
    CASE 
        WHEN default_rate < 10 AND roi_pct > 15 
            THEN 'Promote this term for this segment'
        WHEN default_rate > 20 
            THEN 'Limit this term for this segment'
        ELSE 'Standard offering'
    END as strategy
FROM bank_loan
GROUP BY term, grade, purpose
HAVING COUNT(*) >= 20
ORDER BY roi_pct DESC;

-- ============================================================================
-- 9. INCOME-TO-LOAN RATIO ANALYSIS
-- ============================================================================

-- Optimal loan sizing guidelines
WITH income_loan_ratios AS (
    SELECT 
        grade,
        loan_amount,
        annual_income,
        ROUND(loan_amount / NULLIF(annual_income, 0) * 100, 2) as loan_to_income_ratio,
        loan_status
    FROM bank_loan
    WHERE annual_income > 0
)
SELECT 
    grade,
    CASE 
        WHEN loan_to_income_ratio < 15 THEN '< 15%'
        WHEN loan_to_income_ratio >= 15 AND loan_to_income_ratio < 25 THEN '15-25%'
        WHEN loan_to_income_ratio >= 25 AND loan_to_income_ratio < 35 THEN '25-35%'
        ELSE '35%+'
    END as loan_to_income_bracket,
    COUNT(*) as loan_count,
    ROUND(
        SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2) as default_rate,
    CASE 
        WHEN SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) < 10 
            THEN 'Safe lending range'
        ELSE 'Risky lending range - implement caps'
    END as guideline
FROM income_loan_ratios
GROUP BY 
    grade,
    CASE 
        WHEN loan_to_income_ratio < 15 THEN '< 15%'
        WHEN loan_to_income_ratio >= 15 AND loan_to_income_ratio < 25 THEN '15-25%'
        WHEN loan_to_income_ratio >= 25 AND loan_to_income_ratio < 35 THEN '25-35%'
        ELSE '35%+'
    END
HAVING COUNT(*) >= 30
ORDER BY grade, MIN(loan_to_income_ratio);

-- ============================================================================
-- 10. EXECUTIVE SUMMARY DASHBOARD QUERY
-- ============================================================================

-- Comprehensive performance summary
SELECT 
    'Portfolio Overview' as metric_category,
    'Total Loans' as metric_name,
    CAST(COUNT(*) AS CHAR) as metric_value
FROM bank_loan

UNION ALL SELECT 'Portfolio Overview', 'Total Funded', CONCAT('$', FORMAT(SUM(loan_amount), 2)) FROM bank_loan
UNION ALL SELECT 'Portfolio Overview', 'Total Received', CONCAT('$', FORMAT(SUM(total_payment), 2)) FROM bank_loan
UNION ALL SELECT 'Portfolio Overview', 'Net Profit', CONCAT('$', FORMAT(SUM(total_payment - loan_amount), 2)) FROM bank_loan

UNION ALL SELECT 'Performance', 'Avg Interest Rate', CONCAT(ROUND(AVG(int_rate), 2), '%') FROM bank_loan
UNION ALL SELECT 'Performance', 'Avg DTI', CONCAT(ROUND(AVG(dti), 2), '%') FROM bank_loan
UNION ALL SELECT 'Performance', 'ROI %', CONCAT(ROUND((SUM(total_payment) - SUM(loan_amount)) * 100.0 / SUM(loan_amount), 2), '%') FROM bank_loan

UNION ALL SELECT 'Risk Metrics', 'Default Rate', 
    CONCAT(ROUND(SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2), '%') FROM bank_loan
UNION ALL SELECT 'Risk Metrics', 'Good Loan %', 
    CONCAT(ROUND(SUM(CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2), '%') FROM bank_loan
UNION ALL SELECT 'Risk Metrics', 'Charged Off Amount', 
    CONCAT('$', FORMAT(SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount ELSE 0 END), 2)) FROM bank_loan

ORDER BY metric_category, metric_name;

-- ============================================================================
-- End of Business Insights
-- ============================================================================
