-- Run against DB_NAME before starting the updated server.
-- If duplicate ratings already exist, ALTER TABLE fails without deleting data.
-- Resolve those duplicates explicitly, then run this script again.
SET @has_unique_rating = (
  SELECT COUNT(*) FROM (
    SELECT INDEX_NAME
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'rating' AND NON_UNIQUE = 0
    GROUP BY INDEX_NAME
    HAVING COUNT(*) = 2
      AND SUM(COLUMN_NAME IN ('member_id', 'movie_id')) = 2
  ) AS matching_indexes
);
SET @rating_unique_sql = IF(
  @has_unique_rating > 0,
  'SELECT ''rating unique constraint already exists'' AS result',
  'ALTER TABLE rating ADD CONSTRAINT UQ_rating_member_movie UNIQUE (member_id, movie_id)'
);
PREPARE rating_unique_statement FROM @rating_unique_sql;
EXECUTE rating_unique_statement;
DEALLOCATE PREPARE rating_unique_statement;
