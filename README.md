# Analysis-of-Greater-Sydney
Analysis of Greater Sydney using numerical and spatial data. Python is used to insert data into PostgreSQL databases whilst SQL queries are used to gather informative tables

Link to report: https://github.com/weilong321/Analysis-of-Greater-Sydney/blob/main/report.pdf

All python code is documented in the Data Cleaning jupyter notebook.

## Step 1:
  - Import all datasets into PostgreSQL server using a well-defined data schema. This is done through SQL script in schema.sql

## Step 2:
  - Compute a score for how ”well-resourced” each individual neighbourhood is according to the following formula, where S is the
sigmoid function, z is the normalised z-score, and ’young people’ are defined as anyone aged 0-19
  - Done via SQL script z_and_sigmoid_2.sql

Score = S(zretail + zhealth + zstops + zpolls + zschools)

## Step 3:
  - Find some new datasets based on spatial data as well as impact on Greater Sydney and repeat step 2 to extend the score from step 2.
    - Done via SQL script z_and_sigmoid_3.sql
  - Provide map-overlay visualisations based on key results
    - Done via SQL script map_overlay_plot_2.sql and map_overlay_plot_3.sql for comparison
  - Determine if there is any correlation between score and median income of each region
    - Done via SQL script score_income_correlation.sql
    - This correlation is calculated using Pearson's coefficient that I have manually written using SQL
