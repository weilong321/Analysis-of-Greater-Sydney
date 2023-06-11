WITH
health AS (
	SELECT
	  industry_name,
	  sa2_code,
	  b.sa2_name,
	  total_businesses,
	  total_people,
	  total_businesses::float/ (total_people/1000::float) AS "health per 1000 people"
	FROM
	  businesses B
	  JOIN sa2_regions S ON (b.sa2_code = s."SA2_CODE21")
	  JOIN population USING (sa2_code)
	WHERE
	  industry_name = 'Health Care and Social Assistance'
	  AND total_people >= 100
	ORDER BY
	  sa2_code
),
zscore_health AS (
	SELECT 
		AVG("health per 1000 people") as mean,
		STDDEV("health per 1000 people") as stddev
	FROM health
),
polls_per_region AS (
    SELECT sa."SA2_CODE21" AS sa2_code,
           sa."SA2_NAME21" AS sa2_name,
           COUNT(pp."FID") AS num_polls
    FROM sa2_regions sa
    JOIN polling_places pp ON ST_Contains(sa.geom, pp.geom)
	INNER JOIN population pop ON pop.sa2_code = sa."SA2_CODE21"
	WHERE pop.total_people >= 100
    GROUP BY sa."SA2_CODE21"
),
zscore_polls AS (
    SELECT AVG(polls_per_region.num_polls) AS mean,
           STDDEV(polls_per_region.num_polls) AS stddev
    FROM polls_per_region
),
retail AS (
	SELECT
	  industry_name,
	  sa2_code,
	  b.sa2_name,
	  total_businesses,
	  total_people,
	  total_businesses::float/ (total_people/1000::float) AS "retail per 1000 people"
	FROM
	  businesses B
	  JOIN sa2_regions S ON (b.sa2_code = s."SA2_CODE21")
	  JOIN population USING (sa2_code)
	WHERE
	  industry_name = 'Retail Trade'
	  AND total_people >= 100
	ORDER BY
	  sa2_code
),
zscore_retails AS (
	SELECT 
		AVG("retail per 1000 people") as mean,
		STDDEV("retail per 1000 people") as stddev
	FROM retail
),
schools_per_region AS (
    SELECT sa."SA2_CODE21" AS sa2_code,
           sa."SA2_NAME21" AS sa2_name,
           (COUNT(s."USE_ID")::float / pop.young_people::float) * 1000 AS "schools per 1000 young people"
    FROM sa2_regions sa
    JOIN schools s ON ST_Contains(sa.geom, s.geom)
	INNER JOIN population pop ON pop.sa2_code = sa."SA2_CODE21"
	WHERE pop.total_people >= 100
    GROUP BY sa."SA2_CODE21", pop.young_people
),
zscore_schools AS (
    SELECT AVG(schools_per_region."schools per 1000 young people") AS mean,
           STDDEV(schools_per_region."schools per 1000 young people") AS stddev
    FROM schools_per_region
),
stops_per_region AS (
    SELECT sa."SA2_CODE21" AS sa2_code,
           sa."SA2_NAME21" AS sa2_name,
           COUNT(s.stop_id) AS num_stops
    FROM sa2_regions sa
    JOIN stops s ON ST_Contains(sa.geom, s.geom)
	INNER JOIN population pop ON pop.sa2_code = sa."SA2_CODE21"
	WHERE pop.total_people >= 100
    GROUP BY sa."SA2_CODE21"
),
zscore_stops AS (
    SELECT AVG(stops_per_region.num_stops) AS mean,
           STDDEV(stops_per_region.num_stops) AS stddev
    FROM stops_per_region
),
births_per_region AS (
  	SELECT
    	sa."SA2_CODE21" AS sa2_code,
    	sa."SA2_NAME21" AS sa2_name,
    	total_fertility_rate,
    	total_people,
    	births_no / (total_people / 1000) AS "births per 1000 people"
  	FROM
    	births br
    	JOIN sa2_regions sa ON (br.sa2_code = sa."SA2_CODE21")
    	JOIN population USING (sa2_code)
  	WHERE
    	total_people >= 100
  	ORDER BY
    	sa2_code 
),
zscore_births AS (
  	SELECT
    	AVG("births per 1000 people") AS mean,
    	STDDEV("births per 1000 people") AS stddev
  	FROM
    	births_per_region
),
crimes_per_region AS (
  	SELECT sa."SA2_CODE21" AS sa2_code, 
	   sa."SA2_NAME21" AS sa2_name,
	   COUNT(crime.objectid)::float/ (pop.total_people::float / 1000) AS "crimespots per 1000 people"
	FROM sa2_regions sa
	JOIN crime ON ST_CONTAINS(sa.geom, crime.geom)
	JOIN population pop ON (sa."SA2_CODE21" = pop.sa2_code)
	WHERE total_people >= 100
	GROUP BY sa."SA2_CODE21", pop.total_people
),
zscore_crimes AS (
    SELECT AVG(crimes_per_region."crimespots per 1000 people") AS mean,
           STDDEV(crimes_per_region."crimespots per 1000 people") AS stddev
    FROM crimes_per_region
),
zb AS (
	SELECT births_per_region.sa2_code,
		   (("births per 1000 people" - mean) / stddev) as z_score_births
	FROM births_per_region, zscore_births
),
zc AS (
	SELECT crimes_per_region.sa2_code,
		   (("crimespots per 1000 people" - mean) / stddev) as z_score_crimes
	FROM crimes_per_region, zscore_births
),
zst AS (
	SELECT stops_per_region.sa2_code,
		   stops_per_region.sa2_name,
		   ((num_stops - mean) / stddev) as z_score_stops
	FROM stops_per_region, zscore_stops
),
zsc AS (
	SELECT schools_per_region.sa2_code,
		   (("schools per 1000 young people" - mean) / stddev) as z_score_schools
	FROM schools_per_region, zscore_schools
),
zr AS (
	SELECT retail.sa2_code,  
		   (("retail per 1000 people" - mean) / stddev) as z_score_retail
	FROM retail, zscore_retails
),
zp AS (
	SELECT polls_per_region.sa2_code,
		   ((num_polls - mean) / stddev) as z_score_polls
	FROM polls_per_region, zscore_polls
),
zh AS (
	SELECT health.sa2_code, 
		   (("health per 1000 people" - mean) / stddev) as z_score_health
	FROM health, zscore_health
),
all_zscores AS (
	SELECT "SA2_CODE21" AS sa2_code,
		   "SA2_NAME21" AS sa2_name,
		   COALESCE(z_score_stops, 0) + COALESCE(z_score_polls, 0) + COALESCE(z_score_health, 0) + COALESCE(z_score_retail, 0) + COALESCE(z_score_schools, 0) + COALESCE(z_score_births, 0) - COALESCE(z_score_crimes, 0) AS total_zscore
	FROM sa2_regions sa
	FULL OUTER JOIN zst ON (sa."SA2_CODE21" = zst.sa2_code)
	FULL OUTER JOIN zp ON (sa."SA2_CODE21" = zp.sa2_code)
	FULL OUTER JOIN zh ON (sa."SA2_CODE21" = zh.sa2_code)
	FULL OUTER JOIN zr ON (sa."SA2_CODE21" = zr.sa2_code)
	FULL OUTER JOIN zsc ON (sa."SA2_CODE21" = zsc.sa2_code)
	FULL OUTER JOIN zb ON (sa."SA2_CODE21" = zb.sa2_code)
	FULL OUTER JOIN zc ON (sa."SA2_CODE21" = zc.sa2_code)
	ORDER BY sa2_code
),
zscore_stats AS (
    SELECT AVG(total_zscore) AS mean,
           STDDEV(total_zscore) AS stddev
    FROM all_zscores
),
normalised AS (
	SELECT all_zscores.sa2_code,
		   all_zscores.sa2_name,
		   (total_zscore - mean) / stddev AS normalised_zscore
	FROM all_zscores, zscore_stats
),
z_and_sigmoid AS (
	SELECT *, 1 / (1 + EXP(-normalised_zscore)) AS sigmoid
	FROM normalised
),
results AS (
	SELECT sa2_code,
		   sa2_name,
		   ROUND(CAST(normalised_zscore AS numeric), 4) AS normalised_zscore,
		   ROUND(CAST(sigmoid AS numeric), 4) AS sigmoid
	FROM z_and_sigmoid
),
joined_data AS (
    SELECT r.sa2_code, r.sa2_name, median_income, normalised_zscore, sigmoid
    FROM income i JOIN results r USING (sa2_code)
),
means AS (
    SELECT AVG(median_income) AS mean_income,
           AVG(sigmoid) AS mean_score
    FROM joined_data
),
stddevs AS (
    SELECT STDDEV(median_income) AS stddev_income,
           STDDEV(sigmoid) AS stddev_score
    FROM joined_data
),
correlation AS (
    SELECT (SUM((median_income - mean_income) * (sigmoid - mean_score)) / (COUNT(*) * stddevs.stddev_income * stddevs.stddev_score)) AS pearson_correlation
    FROM joined_data, means, stddevs
	GROUP BY stddevs.stddev_income, stddevs.stddev_score
)
SELECT ROUND(CAST(pearson_correlation AS numeric), 4) AS pearson_correlation FROM correlation;