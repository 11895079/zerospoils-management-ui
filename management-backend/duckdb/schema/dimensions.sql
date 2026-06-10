-- Dimension Tables for ZeroSpoils Analytics
-- Support time-series analysis of app metrics, feature adoption, and user behavior

-- Platform Dimension (iOS, Android)
CREATE TABLE IF NOT EXISTS dim_platform (
  platform_id INTEGER PRIMARY KEY,
  platform_name VARCHAR NOT NULL UNIQUE,  -- 'ios', 'android'
  created_at TIMESTAMP DEFAULT now()
);

INSERT INTO dim_platform (platform_id, platform_name) VALUES
  (1, 'ios'),
  (2, 'android')
ON CONFLICT (platform_name) DO NOTHING;

-- App Version Dimension
CREATE TABLE IF NOT EXISTS dim_app_version (
  version_id INTEGER PRIMARY KEY DEFAULT nextval('seq_version_id'),
  version VARCHAR NOT NULL UNIQUE,        -- e.g., '1.0.0', '1.2.3'
  major INT,
  minor INT,
  patch INT,
  release_channel VARCHAR,                -- 'stable', 'beta', 'alpha'
  created_at TIMESTAMP DEFAULT now()
);

CREATE SEQUENCE IF NOT EXISTS seq_version_id START 1;

-- Release Channel Dimension
CREATE TABLE IF NOT EXISTS dim_release_channel (
  channel_id INTEGER PRIMARY KEY,
  channel_name VARCHAR NOT NULL UNIQUE,   -- 'stable', 'beta', 'alpha'
  created_at TIMESTAMP DEFAULT now()
);

INSERT INTO dim_release_channel (channel_id, channel_name) VALUES
  (1, 'stable'),
  (2, 'beta'),
  (3, 'alpha')
ON CONFLICT (channel_name) DO NOTHING;

-- Event Type Dimension
CREATE TABLE IF NOT EXISTS dim_event_type (
  event_type_id INTEGER PRIMARY KEY,
  event_name VARCHAR NOT NULL UNIQUE,    -- 'app_installed', 'item_added', 'item_wasted', etc.
  description VARCHAR,
  created_at TIMESTAMP DEFAULT now()
);

INSERT INTO dim_event_type (event_type_id, event_name, description) VALUES
  (1, 'app_installed', 'App launched for first time or after uninstall'),
  (2, 'item_added', 'User saved item to inventory'),
  (3, 'item_wasted', 'User marked item as wasted'),
  (4, 'reminder_opened', 'User opened a reminder notification'),
  (5, 'inventory_viewed', 'User viewed inventory list'),
  (10, 'category_assigned', 'Category assigned to item'),
  (11, 'category_created', 'Custom category created'),
  (12, 'category_deleted', 'Custom category deleted')
ON CONFLICT (event_name) DO NOTHING;

-- Item Entry Source Dimension (for item_added analysis)
CREATE TABLE IF NOT EXISTS dim_entry_source (
  source_id INTEGER PRIMARY KEY,
  source_name VARCHAR NOT NULL UNIQUE,   -- 'manual', 'camera_barcode', 'camera_expiry', etc.
  is_camera_assisted BOOLEAN,
  created_at TIMESTAMP DEFAULT now()
);

INSERT INTO dim_entry_source (source_id, source_name, is_camera_assisted) VALUES
  (1, 'manual', FALSE),
  (2, 'camera_barcode', TRUE),
  (3, 'camera_expiry', TRUE),
  (4, 'camera_barcode_and_expiry', TRUE),
  (5, 'shopping_convert', FALSE),
  (6, 'receipt_batch_camera', TRUE)
ON CONFLICT (source_name) DO NOTHING;

-- Category Dimension (groceries)
CREATE TABLE IF NOT EXISTS dim_category (
  category_id INTEGER PRIMARY KEY,
  category_name VARCHAR NOT NULL UNIQUE, -- 'dairy', 'produce', 'meat', etc.
  is_custom BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT now()
);

INSERT INTO dim_category (category_id, category_name, is_custom) VALUES
  (1, 'dairy', FALSE),
  (2, 'produce', FALSE),
  (3, 'meat', FALSE),
  (4, 'frozen', FALSE),
  (5, 'canned', FALSE),
  (6, 'bakery', FALSE),
  (7, 'pantry', FALSE),
  (8, 'beverages', FALSE),
  (9, 'condiments', FALSE),
  (10, 'other', FALSE)
ON CONFLICT (category_name) DO NOTHING;

-- Storage Location Dimension
CREATE TABLE IF NOT EXISTS dim_location (
  location_id INTEGER PRIMARY KEY,
  location_name VARCHAR NOT NULL UNIQUE, -- 'fridge', 'freezer', 'pantry', 'counter', 'other'
  created_at TIMESTAMP DEFAULT now()
);

INSERT INTO dim_location (location_id, location_name) VALUES
  (1, 'fridge'),
  (2, 'freezer'),
  (3, 'pantry'),
  (4, 'counter'),
  (5, 'other')
ON CONFLICT (location_name) DO NOTHING;

-- Waste Reason Dimension
CREATE TABLE IF NOT EXISTS dim_waste_reason (
  reason_id INTEGER PRIMARY KEY,
  reason_name VARCHAR NOT NULL UNIQUE,  -- 'expired', 'spoiled', 'overcrowded', 'other'
  created_at TIMESTAMP DEFAULT now()
);

INSERT INTO dim_waste_reason (reason_id, reason_name) VALUES
  (1, 'expired'),
  (2, 'spoiled'),
  (3, 'overcrowded'),
  (4, 'other')
ON CONFLICT (reason_name) DO NOTHING;

-- Barcode Source Dimension (for item_added camera analysis)
CREATE TABLE IF NOT EXISTS dim_barcode_source (
  source_id INTEGER PRIMARY KEY,
  source_name VARCHAR NOT NULL UNIQUE,  -- 'seed_catalog', 'learned_mapping', 'unknown', 'none'
  created_at TIMESTAMP DEFAULT now()
);

INSERT INTO dim_barcode_source (source_id, source_name) VALUES
  (1, 'seed_catalog'),
  (2, 'learned_mapping'),
  (3, 'unknown'),
  (4, 'none')
ON CONFLICT (source_name) DO NOTHING;

-- Date Dimension (for time-series analysis)
CREATE TABLE IF NOT EXISTS dim_date (
  date_id DATE PRIMARY KEY,
  date_key VARCHAR,                     -- 'YYYY-MM-DD'
  year INT,
  month INT,
  day INT,
  day_of_week INT,                      -- 0=Sunday, 6=Saturday
  week_of_year INT,
  is_weekend BOOLEAN,
  created_at TIMESTAMP DEFAULT now()
);
