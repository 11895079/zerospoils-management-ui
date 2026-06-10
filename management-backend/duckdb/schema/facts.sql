-- Fact Tables for ZeroSpoils Telemetry Events
-- Event-level data with dimensional keys for detailed analysis

-- ETL Metadata (tracks loads, deduplication, redaction)
CREATE TABLE IF NOT EXISTS fact_etl_metadata (
  load_id VARCHAR PRIMARY KEY,                -- Unique load identifier
  load_timestamp TIMESTAMP,                   -- When this load batch started
  event_type VARCHAR,                          -- Which event type this load processed
  raw_event_count INT,                         -- Events before deduplication
  deduplicated_count INT,                      -- After removing duplicates
  redacted_fields_count INT,                   -- Total fields redacted (counts)
  masked_fields_count INT,                     -- Total fields masked (hashed)
  validation_failures INT,                     -- Events that failed validation
  processing_duration_ms INT,                  -- Time to process this batch
  mart_refresh_duration_ms INT,                -- Time to refresh analytics marts
  created_at TIMESTAMP DEFAULT now()
);

-- Fact: app_installed events (user acquisition, platform distribution)
CREATE TABLE IF NOT EXISTS fact_app_installed (
  event_id VARCHAR PRIMARY KEY,                -- Globally unique event ID (stable hash for dedup)
  event_timestamp TIMESTAMP,                   -- When the event occurred
  platform_id INT,                             -- FK to dim_platform
  app_version_id INT,                          -- FK to dim_app_version
  release_channel_id INT,                      -- FK to dim_release_channel
  is_first_install BOOLEAN,                    -- TRUE if new install, FALSE if reinstall
  source VARCHAR,                              -- 'app_store', 'direct', 'web', 'referral'
  previous_version VARCHAR,                    -- For reinstalls: what version was last used
  session_duration_seconds INT,                -- Length of first session
  items_added_in_first_session INT,            -- Engagement: items added in onboarding
  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_app_installed_timestamp ON fact_app_installed(event_timestamp);
CREATE INDEX IF NOT EXISTS idx_app_installed_platform ON fact_app_installed(platform_id);

-- Fact: item_added events (engagement, camera adoption, entry method analysis)
CREATE TABLE IF NOT EXISTS fact_item_added (
  event_id VARCHAR PRIMARY KEY,                -- Globally unique event ID (stable hash for dedup)
  event_timestamp TIMESTAMP,                   -- When item was added
  platform_id INT,                             -- FK to dim_platform
  app_version_id INT,                          -- FK to dim_app_version
  entry_source_id INT,                         -- FK to dim_entry_source (manual, camera_barcode, etc.)
  category_id INT,                             -- FK to dim_category
  location_id INT,                             -- FK to dim_location
  barcode_source_id INT,                       -- FK to dim_barcode_source (seed_catalog, learned_mapping, etc.)

  -- Camera-specific metrics (for entry_source = camera_*)
  barcode_confidence FLOAT,                    -- 0-1 confidence score if barcode scanned
  expiry_confidence FLOAT,                     -- 0-1 confidence score if expiry detected
  barcode_accepted BOOLEAN,                    -- Did user accept camera's barcode detection?
  expiry_accepted BOOLEAN,                     -- Did user accept camera's expiry detection?

  -- Item details
  has_barcode BOOLEAN,                         -- Does this item have a barcode?
  has_expiry_date BOOLEAN,                     -- Does this item have an expiry date?
  expiry_days_out INT,                         -- Days until expiry from add time
  item_name VARCHAR,                           -- Item name (PII redacted per policy)

  -- Engagement
  quantity INT,                                -- Number of items (for bulk adds)
  session_duration_seconds INT,                -- How long they've been using app

  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_item_added_timestamp ON fact_item_added(event_timestamp);
CREATE INDEX IF NOT EXISTS idx_item_added_platform ON fact_item_added(platform_id);
CREATE INDEX IF NOT EXISTS idx_item_added_entry_source ON fact_item_added(entry_source_id);
CREATE INDEX IF NOT EXISTS idx_item_added_category ON fact_item_added(category_id);

-- Fact: item_wasted events (waste patterns, cost impact, reasons)
CREATE TABLE IF NOT EXISTS fact_item_wasted (
  event_id VARCHAR PRIMARY KEY,                -- Globally unique event ID (stable hash for dedup)
  event_timestamp TIMESTAMP,                   -- When item was marked as wasted
  platform_id INT,                             -- FK to dim_platform
  app_version_id INT,                          -- FK to dim_app_version
  category_id INT,                             -- FK to dim_category
  location_id INT,                             -- FK to dim_location
  waste_reason_id INT,                         -- FK to dim_waste_reason (expired, spoiled, etc.)

  -- Item lifecycle
  days_since_added INT,                        -- How long item was in inventory
  original_entry_source VARCHAR,               -- How it was added (manual, camera, etc.)
  was_camera_assisted BOOLEAN,                 -- Was the original add camera-assisted?

  -- Cost impact (estimate)
  estimated_cost_cents INT,                    -- Estimated item cost in cents (from catalog)

  -- User behavior
  user_reminder_count INT,                     -- How many reminders were sent for this item
  user_acted_on_reminder BOOLEAN,              -- Did user open/interact with reminders?

  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_item_wasted_timestamp ON fact_item_wasted(event_timestamp);
CREATE INDEX IF NOT EXISTS idx_item_wasted_platform ON fact_item_wasted(platform_id);
CREATE INDEX IF NOT EXISTS idx_item_wasted_reason ON fact_item_wasted(waste_reason_id);

-- Fact: reminder_opened events (notification engagement)
CREATE TABLE IF NOT EXISTS fact_reminder_opened (
  event_id VARCHAR PRIMARY KEY,                -- Globally unique event ID (stable hash for dedup)
  event_timestamp TIMESTAMP,                   -- When reminder was opened
  platform_id INT,                             -- FK to dim_platform
  app_version_id INT,                          -- FK to dim_app_version

  -- Notification details
  reminder_type VARCHAR,                       -- 'expiry', 'restock', 'weekly_summary', etc.
  item_category_id INT,                        -- FK to dim_category (if applicable)

  -- Engagement
  action_taken VARCHAR,                        -- 'none', 'viewed_item', 'marked_wasted', 'dismissed'
  time_to_action_seconds INT,                  -- How quickly user acted (null if no action)
  session_duration_seconds INT,                -- Session length before/after reminder

  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_reminder_opened_timestamp ON fact_reminder_opened(event_timestamp);
CREATE INDEX IF NOT EXISTS idx_reminder_opened_platform ON fact_reminder_opened(platform_id);

-- Fact: inventory_viewed events (engagement pattern)
CREATE TABLE IF NOT EXISTS fact_inventory_viewed (
  event_id VARCHAR PRIMARY KEY,                -- Globally unique event ID (stable hash for dedup)
  event_timestamp TIMESTAMP,                   -- When inventory was viewed
  platform_id INT,                             -- FK to dim_platform
  app_version_id INT,                          -- FK to dim_app_version

  -- View context
  view_type VARCHAR,                           -- 'full_inventory', 'category_filter', 'location_filter', 'search'
  filtered_category_id INT,                    -- FK to dim_category (if filtered)
  filtered_location_id INT,                    -- FK to dim_location (if filtered)

  -- Inventory state at view time
  item_count INT,                              -- Total items in inventory when viewed
  expired_item_count INT,                      -- How many are expired
  days_until_next_expiry INT,                  -- Soonest expiry

  -- Engagement
  scroll_depth INT,                            -- How far user scrolled (0-100%)
  session_duration_seconds INT,                -- Session length

  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_inventory_viewed_timestamp ON fact_inventory_viewed(event_timestamp);
CREATE INDEX IF NOT EXISTS idx_inventory_viewed_platform ON fact_inventory_viewed(platform_id);

-- Fact: Redaction Log (for compliance audit trail)
CREATE TABLE IF NOT EXISTS fact_redaction_audit (
  audit_id VARCHAR PRIMARY KEY,                -- Audit record ID
  load_id VARCHAR,                             -- References fact_etl_metadata.load_id
  event_id VARCHAR,                            -- Event that was redacted
  event_type VARCHAR,                          -- Type of event
  blocked_fields VARCHAR[],                    -- Fields that were removed (e.g., ['password', 'email_address'])
  masked_fields VARCHAR[],                     -- Fields that were hashed (e.g., ['user_id', 'household_id'])
  redaction_policy_version VARCHAR,            -- Version of redaction.yaml applied
  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_redaction_audit_event_id ON fact_redaction_audit(event_id);
CREATE INDEX IF NOT EXISTS idx_redaction_audit_load_id ON fact_redaction_audit(load_id);
