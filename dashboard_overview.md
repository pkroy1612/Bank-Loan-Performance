# Power BI Dashboard Documentation

## Dashboard Overview

This Power BI dashboard provides comprehensive insights into the bank's loan portfolio performance, enabling data-driven decision-making and real-time monitoring of key metrics.

---

## Dashboard Structure

### 1. Summary Dashboard (Page 1)

**Purpose:** High-level overview of portfolio performance

**Key Visuals:**

1. **KPI Cards (Top Row)**
   - Total Loan Applications (with MoM indicator)
   - Total Funded Amount (with MoM indicator)
   - Total Amount Received (with MoM indicator)
   - Average Interest Rate
   - Average DTI

2. **Good Loan vs Bad Loan Analysis**
   - Donut Chart: Good Loan % vs Bad Loan %
   - Cards showing Good Loan applications, funded amount, received amount
   - Cards showing Bad Loan applications, funded amount, received amount

3. **Monthly Trends**
   - Area Chart: Total Applications by Month
   - Line Chart: Total Funded Amount by Month
   - Combined Chart: Total Received Amount by Month

4. **Filters Panel (Left Side)**
   - Grade Slicer
   - Purpose Slicer
   - State Slicer
   - Date Range Slicer

---

### 2. Overview Dashboard (Page 2)

**Purpose:** Detailed breakdown by various dimensions

**Key Visuals:**

1. **Loan Status Grid**
   - Matrix showing count and amount by loan status
   - Conditional formatting for quick status identification

2. **Monthly Loan Statistics**
   - Table with Month, Applications, Funded Amount, Received Amount
   - Sparklines showing trends

3. **Regional Analysis**
   - Filled Map: Loan distribution by state
   - Drill-through capability to state-level details

4. **Grade Distribution**
   - Clustered Bar Chart: Loan count by grade
   - Color-coded by performance

5. **Purpose Breakdown**
   - Tree Map: Loan purposes sized by volume
   - Color intensity by profitability

---

### 3. Details Dashboard (Page 3)

**Purpose:** Transaction-level details and loan-specific information

**Key Visuals:**

1. **Loan Details Table**
   - Columns: Loan ID, Member ID, Grade, Amount, Rate, DTI, Status, Issue Date
   - Sortable and filterable
   - Conditional formatting highlighting high-risk loans

2. **Customer Segmentation**
   - Scatter Plot: Loan Amount vs Interest Rate
   - Bubble size represents DTI
   - Color by loan status

3. **Purpose & Term Analysis**
   - Stacked Bar Chart: Loan Purpose by Term
   - Shows distribution patterns

4. **Employment Length Impact**
   - Column Chart: Default Rate by Employment Length
   - Identifies risk patterns

---

### 4. Risk Analysis Dashboard (Page 4)

**Purpose:** Risk assessment and portfolio health monitoring

**Key Visuals:**

1. **Risk Matrix**
   - Scatter Plot: DTI vs Interest Rate
   - Quadrant analysis for risk categorization
   - Color-coded by loan status

2. **Default Rate Trends**
   - Line Chart: Monthly default rate with moving average
   - Shows trend direction and volatility

3. **Grade Performance**
   - Waterfall Chart: Profit/Loss by Grade
   - Identifies profitable vs unprofitable segments

4. **Geographic Risk Heatmap**
   - Filled Map: Default rate by state
   - Color intensity shows risk level

5. **High-Risk Loans Table**
   - Lists loans with composite risk score > 5
   - Includes recommended actions

---

## Data Model

### Tables

1. **bank_loan** (Fact Table)
   - Contains all loan transaction data
   - Primary Key: loan_id

2. **Calendar** (Dimension Table)
   - Date dimension for time intelligence
   - Includes fiscal periods, quarters, months

3. **Geography** (Dimension Table) [Optional]
   - State-level information
   - Population, economic indicators

### Relationships

```
Calendar[Date] --1:* --> bank_loan[issue_date]
Geography[State] --1:* --> bank_loan[address_state]
```

---

## Key Measures (DAX)

### Basic Metrics

```dax
Total Applications = COUNT(bank_loan[loan_id])

Total Funded Amount = SUM(bank_loan[loan_amount])

Total Amount Received = SUM(bank_loan[total_payment])

Average Interest Rate = AVERAGE(bank_loan[int_rate])

Average DTI = AVERAGE(bank_loan[dti])
```

### Good Loan Metrics

```dax
Good Loan Applications = 
CALCULATE(
    COUNT(bank_loan[loan_id]),
    bank_loan[loan_status] IN {"Fully Paid", "Current"}
)

Good Loan Percentage = 
DIVIDE([Good Loan Applications], [Total Applications], 0) * 100

Good Loan Funded Amount = 
CALCULATE(
    SUM(bank_loan[loan_amount]),
    bank_loan[loan_status] IN {"Fully Paid", "Current"}
)

Good Loan Received Amount = 
CALCULATE(
    SUM(bank_loan[total_payment]),
    bank_loan[loan_status] IN {"Fully Paid", "Current"}
)
```

### Bad Loan Metrics

```dax
Bad Loan Applications = 
CALCULATE(
    COUNT(bank_loan[loan_id]),
    bank_loan[loan_status] = "Charged Off"
)

Bad Loan Percentage = 
DIVIDE([Bad Loan Applications], [Total Applications], 0) * 100

Bad Loan Funded Amount = 
CALCULATE(
    SUM(bank_loan[loan_amount]),
    bank_loan[loan_status] = "Charged Off"
)

Bad Loan Received Amount = 
CALCULATE(
    SUM(bank_loan[total_payment]),
    bank_loan[loan_status] = "Charged Off"
)
```

### Month-over-Month (MoM) Metrics

```dax
MTD Applications = 
TOTALMTD([Total Applications], Calendar[Date])

PMTD Applications = 
CALCULATE(
    [MTD Applications],
    DATEADD(Calendar[Date], -1, MONTH)
)

MoM Applications Change = 
[MTD Applications] - [PMTD Applications]

MoM Applications % = 
DIVIDE([MoM Applications Change], [PMTD Applications], 0) * 100
```

### Performance Metrics

```dax
Net Profit = 
[Total Amount Received] - [Total Funded Amount]

ROI Percentage = 
DIVIDE([Net Profit], [Total Funded Amount], 0) * 100

Default Rate = 
DIVIDE([Bad Loan Applications], [Total Applications], 0) * 100

Average Loan Size = 
DIVIDE([Total Funded Amount], [Total Applications], 0)
```

### Risk Metrics

```dax
High Risk Loans = 
CALCULATE(
    COUNT(bank_loan[loan_id]),
    bank_loan[grade] IN {"D", "E", "F", "G"},
    bank_loan[dti] > 20
)

Portfolio Risk Score = 
DIVIDE(
    CALCULATE(
        SUM(bank_loan[loan_amount]),
        bank_loan[loan_status] = "Charged Off"
    ),
    [Total Funded Amount],
    0
) * 100
```

---

## Slicers and Filters

### Global Filters (Apply to All Pages)

1. **Date Range Slicer**
   - Type: Between
   - Field: issue_date
   - Default: Last 12 months

2. **Grade Slicer**
   - Type: Dropdown / List
   - Field: grade
   - Multi-select: Enabled

3. **State Slicer**
   - Type: Dropdown
   - Field: address_state
   - Multi-select: Enabled

### Page-Specific Filters

**Summary Dashboard:**
- Loan Status (Visual level)
- Term (Visual level)

**Overview Dashboard:**
- Verification Status
- Home Ownership

**Details Dashboard:**
- Member ID (for individual customer analysis)
- Loan Amount range

**Risk Analysis:**
- DTI range
- Interest Rate range

---

## Interactivity Features

### Drill-Through

1. **From Summary → Details**
   - Right-click any data point
   - Drill through to see transaction details

2. **From Map → State Details**
   - Click state on map
   - Opens detailed state analysis page

### Cross-Filtering

- All visuals on the same page cross-filter each other
- Clicking a bar/slice/point filters other visuals
- Use Ctrl+Click for multi-select

### Tooltips

- Custom tooltips showing:
  - Loan count
  - Average metrics
  - Trend indicators
  - Risk scores

---

## Conditional Formatting

### KPI Cards

- **Green:** Positive MoM change (↑ indicator)
- **Red:** Negative MoM change (↓ indicator)
- **Gray:** No change (→ indicator)

### Tables and Matrices

1. **Loan Status Column**
   - Fully Paid: Green background
   - Current: Yellow background
   - Charged Off: Red background

2. **Grade Column**
   - A, B: Green
   - C: Yellow
   - D, E, F, G: Orange to Red gradient

3. **Default Rate**
   - < 10%: Green
   - 10-15%: Yellow
   - > 15%: Red

4. **DTI**
   - < 15%: Green
   - 15-25%: Yellow
   - > 25%: Red

---

## Refresh Schedule

### Data Refresh

- **Frequency:** Daily at 6:00 AM
- **Source:** SQL Server database
- **Incremental Refresh:** Last 3 months (full), older data (refresh only new)

### Performance Optimization

- Aggregations created for large fact tables
- Composite models for faster loading
- Query folding enabled for all transformations

---

## Mobile View

### Optimized Pages

1. **Mobile Summary**
   - Vertical layout
   - Top KPIs
   - Single trend chart
   - Simple filters

2. **Mobile Details**
   - Scrollable loan list
   - Tap to see details
   - Search functionality

---

## Bookmarks

1. **Good Loans View**
   - Filters to show only good loans
   - Highlights positive metrics

2. **Bad Loans View**
   - Filters to show only charged-off loans
   - Highlights risk factors

3. **Top 10 States**
   - Shows best performing states
   - Sorted by volume

4. **High Risk Focus**
   - Filters to grades D-G
   - DTI > 20%
   - Current loans only

---

## Export Options

### Available Exports

1. **Excel**
   - All table data
   - Includes underlying details

2. **PDF**
   - Current dashboard view
   - Maintains formatting

3. **PowerPoint**
   - Selected visuals
   - For presentations

4. **CSV**
   - Raw data export
   - For further analysis

---

## Access Control

### Row-Level Security (RLS)

- Regional managers see only their states
- Loan officers see only their portfolios
- Executives see all data

### Sharing Settings

- Published to Power BI Service workspace
- Shared with specific user groups
- Scheduled refresh enabled

---

## Best Practices for Users

1. **Always use date range filters** to avoid performance issues
2. **Clear filters** between analyses for accurate results
3. **Use bookmarks** for consistent views
4. **Export data** for detailed offline analysis
5. **Check last refresh time** in footer before making decisions

---

## Troubleshooting

### Common Issues

1. **Slow Loading**
   - Reduce date range
   - Clear browser cache
   - Check network connection

2. **Missing Data**
   - Verify filters are cleared
   - Check data refresh status
   - Confirm database connectivity

3. **Incorrect Totals**
   - Review active filters
   - Check measure definitions
   - Validate data model relationships

---

## Future Enhancements

### Planned Features

1. Predictive analytics for default probability
2. Machine learning integration for risk scoring
3. Real-time data streaming
4. Advanced customer segmentation
5. Automated email alerts for KPI thresholds

---

## Support and Feedback

For questions, issues, or enhancement requests:
- Email: dataanalytics@yourbank.com
- Internal Wiki: [Link to documentation]
- Training Videos: [Link to tutorials]

---

**Last Updated:** April 2025  
**Dashboard Version:** 2.0  
**Created By:** Your Name
