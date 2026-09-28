-- =============================================================================
-- Advanced SQL Analytical Queries for Sustainability Data Analysis
-- Internship Task: Week 2 - SQL Query Development for Sustainability Data
-- =============================================================================

-- QUERY 1: Monthly Energy Trend, MoM Growth Rate, and 3-Month Moving Average
WITH MonthlyEnergy AS (
    SELECT 
        f.facility_name,
        f.country,
        DATE_TRUNC('month', e.reading_date) AS reading_month,
        SUM(e.consumption_kwh) AS total_kwh
    FROM energy_consumption e
    JOIN facilities f ON e.facility_id = f.facility_id
    WHERE e.energy_type = 'Electricity'
    GROUP BY f.facility_name, f.country, DATE_TRUNC('month', e.reading_date)
),
TrendCalculations AS (
    SELECT 
        facility_name,
        country,
        reading_month,
        total_kwh,
        LAG(total_kwh, 1) OVER (PARTITION BY facility_name ORDER BY reading_month) AS prev_month_kwh,
        AVG(total_kwh) OVER (PARTITION BY facility_name ORDER BY reading_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3m
    FROM MonthlyEnergy
)
SELECT 
    facility_name,
    country,
    TO_CHAR(reading_month, 'YYYY-MM') AS month_year,
    ROUND(total_kwh, 2) AS current_kwh,
    ROUND(prev_month_kwh, 2) AS previous_kwh,
    ROUND(COALESCE(((total_kwh - prev_month_kwh) / NULLIF(prev_month_kwh, 0)) * 100, 0), 2) AS mom_growth_pct,
    ROUND(moving_avg_3m, 2) AS rolling_3m_avg_kwh
FROM TrendCalculations
ORDER BY facility_name, reading_month;


-- QUERY 2: Carbon Footprint Scope 1 vs Scope 2 Intensity Analysis
SELECT 
    f.facility_id,
    f.facility_name,
    f.country,
    f.area_sqm,
    ROUND(SUM(CASE WHEN ef.scope_category = 1 THEN c.co2e_emissions_ton ELSE 0 END), 3) AS scope_1_tonnes,
    ROUND(SUM(CASE WHEN ef.scope_category = 2 THEN c.co2e_emissions_ton ELSE 0 END), 3) AS scope_2_tonnes,
    ROUND(SUM(c.co2e_emissions_ton), 3) AS total_co2e_tonnes,
    ROUND(SUM(c.co2e_emissions_ton) / NULLIF(f.area_sqm, 0), 5) AS carbon_intensity_per_sqm
FROM facilities f
JOIN carbon_emissions c ON f.facility_id = c.facility_id
JOIN emission_factors ef ON c.factor_id = ef.factor_id
WHERE c.calculation_date BETWEEN '2026-01-01' AND '2026-06-30'
GROUP BY f.facility_id, f.facility_name, f.country, f.area_sqm
ORDER BY carbon_intensity_per_sqm DESC;


-- QUERY 3: Waste Management Diversion Rate Benchmarking & Ranking
WITH WasteMetrics AS (
    SELECT 
        f.facility_id,
        f.facility_name,
        f.country,
        SUM(w.weight_kg) AS total_waste_kg,
        SUM(CASE WHEN w.is_diverted = TRUE THEN w.weight_kg ELSE 0 END) AS diverted_waste_kg,
        SUM(CASE WHEN w.waste_category = 'Landfill' THEN w.weight_kg ELSE 0 END) AS landfill_waste_kg
    FROM waste_management w
    JOIN facilities f ON w.facility_id = f.facility_id
    WHERE w.disposal_date >= '2026-01-01'
    GROUP BY f.facility_id, f.facility_name, f.country
)
SELECT 
    facility_name,
    country,
    ROUND(total_waste_kg, 2) AS total_waste_kg,
    ROUND(diverted_waste_kg, 2) AS diverted_waste_kg,
    ROUND(landfill_waste_kg, 2) AS landfill_waste_kg,
    ROUND((diverted_waste_kg / NULLIF(total_waste_kg, 0)) * 100, 2) AS diversion_rate_pct,
    DENSE_RANK() OVER (PARTITION BY country ORDER BY (diverted_waste_kg / NULLIF(total_waste_kg, 0)) DESC) AS national_rank
FROM WasteMetrics
ORDER BY country, national_rank;


-- QUERY 4: Identifying Energy Consumption Outliers/Anomalies
WITH FacilityStats AS (
    SELECT 
        facility_id,
        AVG(consumption_kwh) AS avg_daily_kwh,
        STDDEV(consumption_kwh) AS stddev_daily_kwh
    FROM energy_consumption
    WHERE energy_type = 'Electricity'
    GROUP BY facility_id
)
SELECT 
    f.facility_name,
    e.reading_date,
    e.energy_type,
    e.consumption_kwh AS actual_kwh,
    ROUND(fs.avg_daily_kwh, 2) AS facility_avg_kwh,
    ROUND(e.consumption_kwh - fs.avg_daily_kwh, 2) AS variance_from_avg_kwh,
    ROUND((e.consumption_kwh / NULLIF(fs.avg_daily_kwh, 0)) * 100, 2) AS pct_of_average
FROM energy_consumption e
JOIN facilities f ON e.facility_id = f.facility_id
JOIN FacilityStats fs ON e.facility_id = fs.facility_id
WHERE e.consumption_kwh > (fs.avg_daily_kwh + (1.5 * fs.stddev_daily_kwh))
  AND e.reading_date >= '2026-01-01'
ORDER BY variance_from_avg_kwh DESC;


-- QUERY 5: Unified Executive ESG Dashboard Aggregation
WITH EnergySummary AS (
    SELECT facility_id, SUM(consumption_kwh) AS total_energy_kwh
    FROM energy_consumption
    WHERE reading_date BETWEEN '2026-01-01' AND '2026-06-30'
    GROUP BY facility_id
),
CarbonSummary AS (
    SELECT facility_id, SUM(co2e_emissions_ton) AS total_carbon_tonnes
    FROM carbon_emissions
    WHERE calculation_date BETWEEN '2026-01-01' AND '2026-06-30'
    GROUP BY facility_id
),
WasteSummary AS (
    SELECT 
        facility_id, 
        SUM(weight_kg) AS total_waste_kg,
        SUM(CASE WHEN is_diverted = TRUE THEN weight_kg ELSE 0 END) AS diverted_waste_kg
    FROM waste_management
    WHERE disposal_date BETWEEN '2026-01-01' AND '2026-06-30'
    GROUP BY facility_id
)
SELECT 
    f.facility_name,
    f.country,
    COALESCE(e.total_energy_kwh, 0) AS total_energy_kwh,
    COALESCE(c.total_carbon_tonnes, 0) AS total_carbon_tonnes,
    COALESCE(w.total_waste_kg, 0) AS total_waste_kg,
    ROUND(COALESCE((w.diverted_waste_kg / NULLIF(w.total_waste_kg, 0)) * 100, 0), 2) AS waste_diversion_rate_pct
FROM facilities f
LEFT JOIN EnergySummary e ON f.facility_id = e.facility_id
LEFT JOIN CarbonSummary c ON f.facility_id = c.facility_id
LEFT JOIN WasteSummary w ON f.facility_id = w.facility_id
WHERE f.is_active = TRUE
ORDER BY total_carbon_tonnes DESC;
