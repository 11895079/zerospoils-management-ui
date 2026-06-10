-- Analytics Marts: Pre-aggregated tables for dashboard queries
-- Optimized for real-time metric queries (refreshed every 10 min)

-- Mart 1: Daily Installs & Retention (for "New Installs 24h" metric)
CREATE TABLE IF NOT EXISTS mart_daily_installs (
  date_id DATE,
  platform_id INT,
  install_count INT,
  reinstall_count INT,
  first_time_install_count INT,
  source VARCHAR,
  primary key (date_id, platform_id, source)
);

-- Mart 2: Daily Active Users (D1, D7 retention cohorts)
CREATE TABLE IF NOT EXISTS mart_daily_active_users (
  date_id DATE,
  platform_id INT,
  app_version_id INT,
  dau INT,                                    -- Daily Active Users
  primary_key (date_id, platform_id, app_version_id)
);

-- Mart 3: Entry Source Mix (Camera adoption rates)
CREATE TABLE IF NOT EXISTS mart_camera_adoption (
  date_id DATE,
  platform_id INT,
  entry_source_id INT,
  item_count INT,
  avg_barcode_confidence FLOAT,
  avg_expiry_confidence FLOAT,
  barcode_accepted_pct FLOAT,                -- Percentage of camera barcodes user accepted
  expiry_accepted_pct FLOAT,
  primary key (date_id, platform_id, entry_source_id)
);

-- Mart 4: Waste Metrics by Category & Reason
CREATE TABLE IF NOT EXISTS mart_waste_analysis (
  date_id DATE,
  platform_id INT,
  category_id INT,
  waste_reason_id INT,
  wasted_item_count INT,
  total_cost_cents INT,                      -- Sum of estimated_cost_cents
  avg_days_in_inventory INT,
  primary key (date_id, platform_id, category_id, waste_reason_id)
);

-- Mart 5: Barcode & Expiry Recognition Quality
CREATE TABLE IF NOT EXISTS mart_barcode_quality (
  date_id DATE,
  platform_id INT,
  barcode_source_id INT,
  item_count INT,
  avg_barcode_confidence FLOAT,
  avg_expiry_confidence FLOAT,
  items_with_expiry_pct FLOAT,
  primary key (date_id, platform_id, barcode_source_id)
);

-- Mart 6: Retention Cohorts (D0, D1, D7, D30)
CREATE TABLE IF NOT EXISTS mart_retention_cohorts (
  install_date DATE,
  platform_id INT,
  cohort_size INT,
  d0_retained INT,
  d1_retained INT,
  d7_retained INT,
  d30_retained INT,
  d0_pct FLOAT,
  d1_pct FLOAT,
  d7_pct FLOAT,
  d30_pct FLOAT,
  primary key (install_date, platform_id)
);

-- Mart 7: Engagement Funnel (Installs → Items Added → Items Wasted)
CREATE TABLE IF NOT EXISTS mart_engagement_funnel (
  date_id DATE,
  platform_id INT,
  install_count INT,
  users_added_items INT,
  users_wasted_items INT,
  avg_items_per_user FLOAT,
  avg_waste_cost_cents INT,
  primary key (date_id, platform_id)
);

-- Mart 8: Notification Engagement (Reminders)
CREATE TABLE IF NOT EXISTS mart_reminder_engagement (
  date_id DATE,
  platform_id INT,
  reminder_type VARCHAR,
  sent_count INT,
  opened_count INT,
  action_taken_count INT,
  open_rate_pct FLOAT,
  action_rate_pct FLOAT,
  primary key (date_id, platform_id, reminder_type)
);

-- Mart 9: Category Popularity
CREATE TABLE IF NOT EXISTS mart_category_usage (
  date_id DATE,
  platform_id INT,
  category_id INT,
  items_added INT,
  items_wasted INT,
  avg_days_in_inventory INT,
  total_waste_cost_cents INT,
  primary key (date_id, platform_id, category_id)
);

-- Mart 10: Platform Version Distribution
CREATE TABLE IF NOT EXISTS mart_version_distribution (
  date_id DATE,
  platform_id INT,
  app_version_id INT,
  dau INT,
  crash_free_rate FLOAT,
  avg_session_duration_seconds INT,
  primary key (date_id, platform_id, app_version_id)
);

-- Mart 11: Crash-Free Metrics (for dashboard alert)
CREATE TABLE IF NOT EXISTS mart_crash_metrics (
  date_id DATE,
  platform_id INT,
  app_version_id INT,
  session_count INT,
  crash_count INT,
  crash_free_rate FLOAT,                     -- (session_count - crash_count) / session_count
  primary key (date_id, platform_id, app_version_id)
);

-- Mart 12: 24h Summary (aggregated across all dimensions, for single-number queries)
CREATE TABLE IF NOT EXISTS mart_24h_summary (
  summary_timestamp TIMESTAMP,               -- When this summary was calculated
  new_installs_24h INT,
  reinstalls_24h INT,
  active_users_24h INT,
  items_added_24h INT,
  items_wasted_24h INT,
  total_waste_cost_cents_24h INT,
  camera_assist_items_pct FLOAT,             -- % of items added via camera
  d1_retention_pct FLOAT,
  crash_free_rate_pct FLOAT,
  avg_session_duration_seconds INT,
  notification_opt_in_rate_pct FLOAT,
  primary key (summary_timestamp)
);

-- Mart 13: Inventory State (snapshot for "Avg inventory per user")
CREATE TABLE IF NOT EXISTS mart_inventory_snapshot (
  snapshot_timestamp TIMESTAMP,
  platform_id INT,
  app_version_id INT,
  user_count INT,
  avg_items_per_user FLOAT,
  avg_expired_items_per_user FLOAT,
  primary key (snapshot_timestamp, platform_id, app_version_id)
);

-- Mart 14: Location Usage (fridge, freezer, pantry distribution)
CREATE TABLE IF NOT EXISTS mart_location_usage (
  date_id DATE,
  platform_id INT,
  location_id INT,
  items_stored INT,
  items_wasted INT,
  primary key (date_id, platform_id, location_id)
);

-- Create VIEW for easy "current metrics" queries (last 24h aggregation)
CREATE VIEW IF NOT EXISTS v_current_metrics AS
  SELECT
    new_installs_24h,
    reinstalls_24h,
    active_users_24h,
    items_added_24h,
    items_wasted_24h,
    total_waste_cost_cents_24h,
    camera_assist_items_pct,
    d1_retention_pct,
    crash_free_rate_pct,
    avg_session_duration_seconds,
    notification_opt_in_rate_pct,
    summary_timestamp
  FROM mart_24h_summary
  ORDER BY summary_timestamp DESC
  LIMIT 1;

-- Create VIEW for retention cohort analysis
CREATE VIEW IF NOT EXISTS v_retention_analysis AS
  SELECT
    install_date,
    platform_id,
    cohort_size,
    d0_pct,
    d1_pct,
    d7_pct,
    d30_pct,
    (d1_pct - d7_pct) AS d1_to_d7_drop_pct,
    (d7_pct - d30_pct) AS d7_to_d30_drop_pct
  FROM mart_retention_cohorts
  ORDER BY install_date DESC;

-- Create VIEW for camera adoption trends
CREATE VIEW IF NOT EXISTS v_camera_adoption_trend AS
  SELECT
    date_id,
    platform_id,
    SUM(CASE WHEN is_camera_assisted THEN item_count ELSE 0 END) AS camera_assisted_items,
    SUM(item_count) AS total_items,
    100.0 * SUM(CASE WHEN is_camera_assisted THEN item_count ELSE 0 END) / SUM(item_count) AS camera_adoption_pct,
    AVG(barcode_accepted_pct) AS avg_barcode_acceptance
  FROM (
    SELECT
      date_id,
      platform_id,
      item_count,
      barcode_accepted_pct,
      CASE
        WHEN entry_source_id IN (2, 3, 4, 6) THEN TRUE
        ELSE FALSE
      END AS is_camera_assisted
    FROM mart_camera_adoption
  )
  GROUP BY date_id, platform_id
  ORDER BY date_id DESC;
