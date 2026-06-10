/**
 * DuckDB Service
 *
 * Manages DuckDB database connection and schema initialization
 */

import { Database, connect } from 'duckdb';
import fs from 'fs';
import path from 'path';

let dbInstance: Database | null = null;

/**
 * Initialize DuckDB connection and create schema
 */
export async function initializeDuckDB(dbPath: string): Promise<Database> {
  if (dbInstance) {
    return dbInstance;
  }

  console.log('[DuckDB] Initializing database at:', dbPath);

  // Ensure directory exists
  const dbDir = path.dirname(dbPath);
  if (!fs.existsSync(dbDir)) {
    fs.mkdirSync(dbDir, { recursive: true });
  }

  // Connect to DuckDB
  dbInstance = await connect(dbPath);

  // Load schema files in order
  const schemaDir = path.join(__dirname, '../../../duckdb/schema');

  // Create dimensions first (they're referenced by facts)
  console.log('[DuckDB] Loading dimensions schema...');
  const dimensionsSQL = fs.readFileSync(
    path.join(schemaDir, 'dimensions.sql'),
    'utf-8'
  );
  await executeSQLFile(dbInstance, dimensionsSQL);

  // Create fact tables
  console.log('[DuckDB] Loading facts schema...');
  const factsSQL = fs.readFileSync(
    path.join(schemaDir, 'facts.sql'),
    'utf-8'
  );
  await executeSQLFile(dbInstance, factsSQL);

  // Create analytics marts
  console.log('[DuckDB] Loading marts schema...');
  const martsSQL = fs.readFileSync(
    path.join(schemaDir, 'marts.sql'),
    'utf-8'
  );
  await executeSQLFile(dbInstance, martsSQL);

  console.log('[DuckDB] Schema initialized successfully');

  return dbInstance;
}

/**
 * Get DuckDB instance (assumes already initialized)
 */
export function getDatabase(): Database {
  if (!dbInstance) {
    throw new Error('DuckDB not initialized. Call initializeDuckDB first.');
  }
  return dbInstance;
}

/**
 * Close DuckDB connection
 */
export async function closeDuckDB(): Promise<void> {
  if (dbInstance) {
    try {
      await dbInstance.close();
      dbInstance = null;
      console.log('[DuckDB] Connection closed');
    } catch (error) {
      console.error('[DuckDB] Error closing connection:', error);
    }
  }
}

/**
 * Execute SQL file, handling comments and batch statements
 */
async function executeSQLFile(db: Database, sql: string): Promise<void> {
  // Split by semicolon but respect comments
  const statements = sql
    .split(';')
    .map(stmt => stmt.trim())
    .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'))
    .map(stmt => {
      // Remove SQL comments
      return stmt
        .split('\n')
        .filter(line => !line.trim().startsWith('--'))
        .join('\n')
        .trim();
    })
    .filter(stmt => stmt.length > 0);

  for (const statement of statements) {
    try {
      await db.run(statement);
    } catch (error) {
      console.error('[DuckDB] Error executing statement:', statement.substring(0, 100));
      console.error('[DuckDB] Error:', error);
      // Continue to next statement rather than failing
    }
  }
}

/**
 * Test DuckDB connection by running a simple query
 */
export async function testConnection(db: Database): Promise<boolean> {
  try {
    const result = await db.all('SELECT 1 as test');
    return result.length > 0;
  } catch (error) {
    console.error('[DuckDB] Connection test failed:', error);
    return false;
  }
}

/**
 * Get current metrics from the 24h summary mart
 */
export async function getCurrentMetrics(db: Database) {
  try {
    const result = await db.all(`
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
      FROM v_current_metrics
      LIMIT 1
    `);

    if (result.length === 0) {
      return null;
    }

    return result[0];
  } catch (error) {
    console.error('[DuckDB] Error fetching current metrics:', error);
    return null;
  }
}

/**
 * Get historical metrics for charts
 */
export async function getHistoricalMetrics(db: Database, days: number = 7) {
  try {
    const result = await db.all(`
      SELECT
        summary_timestamp,
        new_installs_24h,
        active_users_24h,
        items_added_24h,
        d1_retention_pct,
        crash_free_rate_pct
      FROM mart_24h_summary
      WHERE summary_timestamp > NOW() - INTERVAL '${days}' DAY
      ORDER BY summary_timestamp DESC
      LIMIT ${days * 24}
    `);

    return result;
  } catch (error) {
    console.error('[DuckDB] Error fetching historical metrics:', error);
    return [];
  }
}

/**
 * Get ETL execution history
 */
export async function getETLHistory(db: Database, limit: number = 20) {
  try {
    const result = await db.all(`
      SELECT
        load_id,
        load_timestamp,
        event_type,
        raw_event_count,
        deduplicated_count,
        validation_failures,
        processing_duration_ms,
        mart_refresh_duration_ms
      FROM fact_etl_metadata
      ORDER BY load_timestamp DESC
      LIMIT ${limit}
    `);

    return result;
  } catch (error) {
    console.error('[DuckDB] Error fetching ETL history:', error);
    return [];
  }
}

/**
 * Get camera adoption statistics
 */
export async function getCameraAdoptionStats(db: Database) {
  try {
    const result = await db.all(`
      SELECT
        platform_id,
        100.0 * SUM(CASE WHEN entry_source_id IN (2, 3, 4, 6) THEN item_count ELSE 0 END) /
          SUM(item_count) AS camera_adoption_pct,
        AVG(barcode_accepted_pct) AS avg_barcode_acceptance,
        AVG(expiry_accepted_pct) AS avg_expiry_acceptance
      FROM mart_camera_adoption
      WHERE date_id >= DATE_SUB(CURRENT_DATE, INTERVAL 7 DAY)
      GROUP BY platform_id
    `);

    return result;
  } catch (error) {
    console.error('[DuckDB] Error fetching camera adoption stats:', error);
    return [];
  }
}

/**
 * Get waste analysis by category
 */
export async function getWasteAnalysisByCategory(db: Database) {
  try {
    const result = await db.all(`
      SELECT
        c.category_name,
        SUM(w.wasted_item_count) AS total_wasted,
        SUM(w.total_cost_cents) / 100.0 AS total_cost_usd,
        AVG(w.avg_days_in_inventory) AS avg_days_in_inventory
      FROM mart_waste_analysis w
      LEFT JOIN dim_category c ON w.category_id = c.category_id
      WHERE w.date_id >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
      GROUP BY c.category_name
      ORDER BY total_cost_usd DESC
    `);

    return result;
  } catch (error) {
    console.error('[DuckDB] Error fetching waste analysis:', error);
    return [];
  }
}
