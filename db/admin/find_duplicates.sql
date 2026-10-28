-- =============================================================
-- GTVET-IDMS  Institution Duplicate Finder
-- Run these queries one at a time in psql or pgAdmin
-- =============================================================

-- ---------------------------------------------------------------
-- STEP 1: Count total institutions (should be 263)
-- ---------------------------------------------------------------
SELECT COUNT(*) AS total_institutions FROM institutions;


-- ---------------------------------------------------------------
-- STEP 2: Export all institutions to CSV
-- Change /tmp/institutions_export.csv to a path you can access.
-- In pgAdmin: use the "Save results" button after running STEP 3.
-- ---------------------------------------------------------------
COPY (
  SELECT
    i.institution_id,
    i.institution_name,
    i.cssps_code,
    r.region_name,
    d.district_name,
    i.location,
    i.institution_type,
    i.gender_type,
    i.is_active,
    i.created_at
  FROM institutions i
  JOIN regions r ON r.region_id = i.region_id
  LEFT JOIN districts d ON d.district_id = i.district_id
  ORDER BY r.region_name, i.institution_name
) TO '/tmp/institutions_export.csv' WITH CSV HEADER;


-- ---------------------------------------------------------------
-- STEP 3: View all institutions (use in pgAdmin to Save to CSV)
-- ---------------------------------------------------------------
SELECT
  i.institution_id,
  i.institution_name,
  i.cssps_code,
  r.region_name,
  d.district_name,
  i.location,
  i.institution_type,
  i.gender_type,
  i.is_active,
  i.created_at
FROM institutions i
JOIN regions r ON r.region_id = i.region_id
LEFT JOIN districts d ON d.district_id = i.district_id
ORDER BY r.region_name, i.institution_name;


-- ---------------------------------------------------------------
-- STEP 4: Find duplicate names (same name appearing > 1 time)
-- ---------------------------------------------------------------
SELECT
  institution_name,
  COUNT(*) AS count,
  STRING_AGG(institution_id::text, ', ' ORDER BY institution_id) AS institution_ids,
  STRING_AGG(cssps_code,           ', ' ORDER BY institution_id) AS cssps_codes
FROM institutions
GROUP BY institution_name
HAVING COUNT(*) > 1
ORDER BY institution_name;


-- ---------------------------------------------------------------
-- STEP 5: Find duplicate CSSPS codes (same code > 1 time)
-- NULL codes do NOT match each other, so this catches real dupe codes
-- ---------------------------------------------------------------
SELECT
  cssps_code,
  COUNT(*) AS count,
  STRING_AGG(institution_id::text, ', ' ORDER BY institution_id) AS institution_ids,
  STRING_AGG(institution_name,     ', ' ORDER BY institution_id) AS names
FROM institutions
WHERE cssps_code IS NOT NULL
GROUP BY cssps_code
HAVING COUNT(*) > 1
ORDER BY cssps_code;


-- ---------------------------------------------------------------
-- STEP 6: Find institutions with NULL cssps_code
-- These are at risk of being inserted multiple times
-- ---------------------------------------------------------------
SELECT
  institution_id,
  institution_name,
  cssps_code,
  region_id,
  created_at
FROM institutions
WHERE cssps_code IS NULL
ORDER BY institution_name;


-- ---------------------------------------------------------------
-- STEP 7: Find near-duplicate names (same name, same region)
-- Useful if the name was slightly different between two records
-- ---------------------------------------------------------------
SELECT
  a.institution_id   AS id_a,
  b.institution_id   AS id_b,
  a.institution_name AS name_a,
  b.institution_name AS name_b,
  a.cssps_code       AS code_a,
  b.cssps_code       AS code_b,
  a.region_id        AS region_a,
  b.region_id        AS region_b
FROM institutions a
JOIN institutions b
  ON  a.region_id = b.region_id
  AND a.institution_id < b.institution_id
  AND (
    -- Same name ignoring case/spaces
    lower(trim(a.institution_name)) = lower(trim(b.institution_name))
    OR
    -- One name contains the other (catches shortened names)
    lower(trim(a.institution_name)) LIKE '%' || lower(trim(b.institution_name)) || '%'
    OR
    lower(trim(b.institution_name)) LIKE '%' || lower(trim(a.institution_name)) || '%'
  )
ORDER BY a.region_id, a.institution_name;


-- ---------------------------------------------------------------
-- STEP 8: Once you identify the duplicate institution_id,
-- check it has no data before deleting
-- Replace 999 with the actual institution_id to delete
-- ---------------------------------------------------------------
SELECT 'users'       AS tbl, COUNT(*) AS rows FROM users        WHERE institution_id = 999
UNION ALL
SELECT 'submissions' AS tbl, COUNT(*) AS rows FROM submissions  WHERE institution_id = 999
UNION ALL
SELECT 'inst_progs'  AS tbl, COUNT(*) AS rows FROM institution_programmes WHERE institution_id = 999;


-- ---------------------------------------------------------------
-- STEP 9: Delete the duplicate (ONLY after confirming it is safe)
-- Replace 999 with the actual institution_id to delete
-- ---------------------------------------------------------------
-- BEGIN;
-- DELETE FROM institution_programmes WHERE institution_id = 999;
-- DELETE FROM institutions           WHERE institution_id = 999;
-- COMMIT;
-- If anything looks wrong: ROLLBACK;
