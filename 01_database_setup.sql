-- ============================================================================
-- Bank Loan Analysis Database Setup
-- ============================================================================
-- Description: Creates database, tables, and loads sample data
-- Author: Your Name
-- Date: March 2025
-- ============================================================================

-- Create Database
CREATE DATABASE IF NOT EXISTS bank_loan_db;
USE bank_loan_db;

-- ============================================================================
-- Main Loan Table Creation
-- ============================================================================

DROP TABLE IF EXISTS bank_loan;

CREATE TABLE bank_loan (
    id INT PRIMARY KEY AUTO_INCREMENT,
    loan_id VARCHAR(50) UNIQUE NOT NULL,
    address_state VARCHAR(2),
    application_type VARCHAR(20),
    emp_length VARCHAR(20),
    emp_title VARCHAR(100),
    grade VARCHAR(1),
    sub_grade VARCHAR(3),
    home_ownership VARCHAR(20),
    issue_date DATE,
    last_credit_pull_date DATE,
    last_payment_date DATE,
    loan_status VARCHAR(20),
    next_payment_date DATE,
    member_id INT,
    purpose VARCHAR(50),
    term VARCHAR(10),
    verification_status VARCHAR(30),
    annual_income DECIMAL(12, 2),
    dti DECIMAL(5, 2),
    installment DECIMAL(10, 2),
    int_rate DECIMAL(5, 2),
    loan_amount DECIMAL(12, 2),
    total_acc INT,
    total_payment DECIMAL(12, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================================================
-- Indexes for Performance Optimization
-- ============================================================================

CREATE INDEX idx_loan_status ON bank_loan(loan_status);
CREATE INDEX idx_issue_date ON bank_loan(issue_date);
CREATE INDEX idx_grade ON bank_loan(grade);
CREATE INDEX idx_state ON bank_loan(address_state);
CREATE INDEX idx_purpose ON bank_loan(purpose);
CREATE INDEX idx_verification ON bank_loan(verification_status);
CREATE INDEX idx_composite_analysis ON bank_loan(loan_status, grade, issue_date);

-- ============================================================================
-- Load Data Instructions
-- ============================================================================

/*
To load data from CSV file:

Method 1: Using LOAD DATA INFILE (MySQL)
LOAD DATA INFILE '/path/to/loan_data.csv'
INTO TABLE bank_loan
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

Method 2: Using SQL Server BULK INSERT
BULK INSERT bank_loan
FROM '/path/to/loan_data.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);

Method 3: Using PostgreSQL COPY
COPY bank_loan FROM '/path/to/loan_data.csv' 
DELIMITER ',' 
CSV HEADER;

Method 4: Using Import Wizard in your database tool
*/

-- ============================================================================
-- Data Quality Checks
-- ============================================================================

-- Check for NULL values in critical columns
SELECT 
    COUNT(*) as total_records,
    SUM(CASE WHEN loan_id IS NULL THEN 1 ELSE 0 END) as null_loan_id,
    SUM(CASE WHEN loan_amount IS NULL THEN 1 ELSE 0 END) as null_loan_amount,
    SUM(CASE WHEN loan_status IS NULL THEN 1 ELSE 0 END) as null_loan_status,
    SUM(CASE WHEN issue_date IS NULL THEN 1 ELSE 0 END) as null_issue_date
FROM bank_loan;

-- Check for duplicate loan IDs
SELECT 
    loan_id, 
    COUNT(*) as count
FROM bank_loan
GROUP BY loan_id
HAVING COUNT(*) > 1;

-- Verify data ranges
SELECT 
    MIN(issue_date) as earliest_loan,
    MAX(issue_date) as latest_loan,
    MIN(loan_amount) as min_loan_amount,
    MAX(loan_amount) as max_loan_amount,
    MIN(int_rate) as min_interest_rate,
    MAX(int_rate) as max_interest_rate
FROM bank_loan;

-- ============================================================================
-- Sample Data Generation (For Testing)
-- ============================================================================

/*
If you need to generate sample data for testing:

INSERT INTO bank_loan (
    loan_id, address_state, application_type, emp_length, grade, 
    home_ownership, issue_date, loan_status, purpose, term, 
    verification_status, annual_income, dti, installment, 
    int_rate, loan_amount, total_payment
)
VALUES 
    ('LOAN001', 'CA', 'Individual', '10+ years', 'A', 'MORTGAGE', 
     '2024-01-15', 'Fully Paid', 'debt_consolidation', '36 months',
     'Verified', 75000.00, 15.50, 450.25, 8.50, 15000.00, 16209.00),
    
    ('LOAN002', 'NY', 'Individual', '5-9 years', 'B', 'RENT',
     '2024-01-20', 'Current', 'credit_card', '60 months',
     'Source Verified', 62000.00, 18.25, 325.75, 12.25, 18000.00, 3895.00),
     
    -- Add more sample records as needed
;
*/

-- ============================================================================
-- Create Views for Common Queries
-- ============================================================================

-- Good Loans View
CREATE OR REPLACE VIEW v_good_loans AS
SELECT *
FROM bank_loan
WHERE loan_status IN ('Fully Paid', 'Current');

-- Bad Loans View
CREATE OR REPLACE VIEW v_bad_loans AS
SELECT *
FROM bank_loan
WHERE loan_status = 'Charged Off';

-- Monthly Summary View
CREATE OR REPLACE VIEW v_monthly_summary AS
SELECT 
    DATE_FORMAT(issue_date, '%Y-%m') as month,
    COUNT(*) as total_applications,
    SUM(loan_amount) as total_funded,
    AVG(int_rate) as avg_interest_rate,
    AVG(dti) as avg_dti,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) as defaults
FROM bank_loan
GROUP BY DATE_FORMAT(issue_date, '%Y-%m');

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Quick statistics check
SELECT 
    COUNT(*) as total_loans,
    COUNT(DISTINCT loan_id) as unique_loans,
    COUNT(DISTINCT address_state) as states_covered,
    COUNT(DISTINCT grade) as loan_grades,
    MIN(issue_date) as first_loan_date,
    MAX(issue_date) as last_loan_date
FROM bank_loan;

-- Status distribution
SELECT 
    loan_status,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM bank_loan
GROUP BY loan_status
ORDER BY count DESC;

COMMIT;

-- ============================================================================
-- End of Database Setup
-- ============================================================================
