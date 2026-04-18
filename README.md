# 🏦 Bank Loan Performance Analysis

![Project Banner](images/banner.png)

## 📊 Project Overview

A comprehensive data analytics project analyzing 35,000+ bank loan records to evaluate lending performance, identify risk trends, and support strategic decision-making. This project demonstrates advanced SQL analysis, interactive Power BI dashboards, and data-driven insights for financial services.

**Duration:** March 2025 - April 2025  
**Total Funded Amount Analyzed:** $435.8M+  
**Records Analyzed:** 35,000+

---

## 🎯 Key Achievements

- ✅ Analyzed 35,000+ loan records using advanced SQL techniques
- ✅ Developed interactive Power BI dashboard with real-time KPI monitoring
- ✅ Identified risk patterns and lending trends across multiple dimensions
- ✅ Generated actionable insights for optimizing lending strategies
- ✅ Tracked key metrics: 12% avg interest rate, 13.3% debt-to-income ratio

---

## 🛠️ Technologies Used

- **Database:** SQL Server / MySQL / PostgreSQL
- **Visualization:** Power BI Desktop
- **Languages:** SQL, DAX
- **Tools:** Excel (initial data processing)

---

## 📁 Project Structure

```
bank_loan_analysis/
│
├── README.md                          # Project documentation
├── data/                              # Sample datasets
│   ├── loan_data.csv                  # Main loan dataset
│   └── data_dictionary.md             # Data field descriptions
│
├── sql_queries/                       # SQL analysis scripts
│   ├── 01_database_setup.sql          # Database and table creation
│   ├── 02_data_exploration.sql        # Initial data profiling
│   ├── 03_kpi_calculations.sql        # Key performance indicators
│   ├── 04_risk_analysis.sql           # Risk and default analysis
│   ├── 05_trend_analysis.sql          # Time-based trend queries
│   ├── 06_advanced_analytics.sql      # Complex joins, CTEs, window functions
│   └── 07_business_insights.sql       # Strategic insight queries
│
├── powerbi_documentation/             # Power BI details
│   ├── dashboard_overview.md          # Dashboard documentation
│   ├── dax_measures.txt               # DAX formulas used
│   └── data_model.md                  # Data model documentation
│
├── images/                            # Screenshots and visuals
│   ├── dashboard_screenshot.png
│   ├── kpi_overview.png
│   └── trends_analysis.png
│
└── documentation/                     # Additional documentation
    ├── insights_report.md             # Key findings and insights
    ├── methodology.md                 # Analysis approach
    └── recommendations.md             # Strategic recommendations
```

---

## 📈 Key Performance Indicators (KPIs)

### Financial Metrics
- **Total Funded Amount:** $435.8M
- **Total Amount Received:** $473.1M
- **Average Interest Rate:** 12.0%
- **Average Debt-to-Income Ratio:** 13.3%

### Loan Performance
- **Total Loan Applications:** 38,576
- **Good Loan Percentage:** 86.2%
- **Bad Loan Percentage:** 13.8%
- **Month-over-Month Growth:** 6.9%

### Risk Indicators
- **Default Rate:** 13.8%
- **Charged-off Amount:** $65.5M
- **Average Loan Amount:** $11,295

---

## 🔍 Analysis Highlights

### 1. **Loan Status Distribution**
- Fully Paid: 32,145 loans (86.2%)
- Charged Off: 5,333 loans (13.8%)
- Current: 1,098 active loans

### 2. **Purpose Analysis**
- Debt Consolidation: 60% of total applications
- Credit Card Refinancing: 18%
- Home Improvement: 8%
- Other: 14%

### 3. **Geographic Insights**
- Top performing states: CA, NY, TX, FL
- Regional risk variation identified
- Urban vs Rural lending patterns analyzed

### 4. **Temporal Trends**
- Seasonal patterns in loan applications
- Interest rate trends over time
- Default rate correlation with economic indicators

---

## 🚀 Getting Started

### Prerequisites
- SQL Server 2019+ / MySQL 8.0+ / PostgreSQL 13+
- Power BI Desktop (Latest version)
- Basic understanding of SQL and data visualization

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/bank-loan-analysis.git
   cd bank-loan-analysis
   ```

2. **Set up the database**
   ```sql
   -- Run the setup script
   source sql_queries/01_database_setup.sql
   ```

3. **Load the data**
   - Import `data/loan_data.csv` into your database
   - Follow instructions in `sql_queries/01_database_setup.sql`

4. **Run analysis queries**
   - Execute SQL scripts in numerical order
   - Review output and insights

5. **Open Power BI Dashboard**
   - Open the `.pbix` file (if provided)
   - Or follow `powerbi_documentation/dashboard_overview.md` to rebuild

---

## 📊 SQL Analysis Examples

### Risk Assessment Query
```sql
-- Identify high-risk loan segments
SELECT 
    loan_grade,
    loan_purpose,
    COUNT(*) as total_loans,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) as defaults,
    ROUND(AVG(int_rate), 2) as avg_interest_rate,
    ROUND(AVG(dti), 2) as avg_dti
FROM bank_loan
GROUP BY loan_grade, loan_purpose
HAVING COUNT(*) > 100
ORDER BY defaults DESC;
```

### Performance Trend Analysis
```sql
-- Monthly loan performance with window functions
SELECT 
    DATE_FORMAT(issue_date, '%Y-%m') as month,
    COUNT(*) as applications,
    SUM(loan_amount) as funded_amount,
    AVG(int_rate) as avg_rate,
    SUM(COUNT(*)) OVER (ORDER BY DATE_FORMAT(issue_date, '%Y-%m')) as cumulative_loans
FROM bank_loan
GROUP BY month
ORDER BY month;
```

---

## 📉 Power BI Dashboard Features

### Summary Dashboard
- **Total Applications:** Dynamic card visual
- **Funded Amount:** KPI with MoM trend
- **Good vs Bad Loans:** Donut chart comparison
- **Monthly Trends:** Area chart with forecasting

### Detailed Analytics
- **Geographic Distribution:** Filled map with drill-through
- **Loan Purpose Breakdown:** Tree map visualization
- **Grade Analysis:** Clustered bar chart
- **Risk Matrix:** Scatter plot (DTI vs Interest Rate)

### Interactive Filters
- Date range slicer
- Loan status filter
- State/Region selector
- Loan grade and purpose filters

---

## 🎓 Key Insights & Recommendations

### Critical Findings

1. **Risk Concentration:** 13.8% default rate concentrated in specific loan grades (D, E, F)
2. **Purpose Impact:** Debt consolidation loans show lower default rates (11%) vs small business (17%)
3. **Geographic Variance:** Default rates vary significantly by state (8%-22% range)
4. **DTI Correlation:** Strong correlation between DTI > 20% and default probability

### Strategic Recommendations

1. **Tighten Lending Criteria:** For grades D-F in high-risk states
2. **Adjust Interest Rates:** Risk-based pricing model implementation
3. **Enhanced Verification:** Strengthen income verification for DTI > 15%
4. **Product Optimization:** Focus on debt consolidation products
5. **Regional Strategy:** Customize lending approach by geographic risk profile

---

## 📚 Learning Outcomes

Through this project, I demonstrated proficiency in:

- ✅ Advanced SQL (Joins, Subqueries, CTEs, Window Functions, Aggregations)
- ✅ Database design and optimization
- ✅ Power BI dashboard development and DAX
- ✅ Financial metrics analysis and KPI tracking
- ✅ Risk assessment methodologies
- ✅ Data storytelling and visualization best practices
- ✅ Business intelligence and strategic thinking

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📧 Contact

**Your Name**  
- LinkedIn: [your-linkedin-profile](https://linkedin.com/in/yourprofile)
- Email: your.email@example.com
- Portfolio: [your-portfolio-website](https://yourwebsite.com)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Dataset inspired by real-world banking scenarios
- Analysis framework based on industry best practices
- Dashboard design follows financial services UX standards

---

**⭐ If you find this project useful, please consider giving it a star!**
