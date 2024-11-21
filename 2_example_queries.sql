-- ASSUMPTIONS: Using BigQuery SQL as SQL dialect
-- What are the top 5 brands by receipts scanned for most recent month?
WITH cte AS
(SELECT
    b.name,
    RANK() OVER (ORDER BY COUNT(DISTINCT r._id) DESC) AS rk
FROM
    receipts r
    JOIN transactions t ON r._id = t.receipt_id,
    UNNEST(t.item_barcode) AS item_barcode
    JOIN items i ON item_barcode = i.item_barcode
    JOIN brands b ON i.brandCode = b.brandCode
WHERE
    FORMAT_DATE('%Y-%m', r.dateScanned) = FORMAT_DATE('%Y-%m', CURRENT_DATE())
GROUP BY
    b.name)
SELECT b.name
FROM cte
WHERE rk <= 5
ORDER BY rk;



-- How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?
WITH cte1 AS (
  SELECT
    b.name,
    RANK() OVER (ORDER BY COUNT(DISTINCT r._id) DESC) AS current_rank
  FROM
    receipts r
    JOIN transactions t ON r._id = t.receipt_id,
    UNNEST(t.item_barcode) AS item_barcode
    JOIN items i ON item_barcode = i.item_barcode
    JOIN brands b ON i.brandCode = b.brandCode
  WHERE
    FORMAT_DATE('%Y-%m', r.dateScanned) = FORMAT_DATE('%Y-%m', CURRENT_DATE())
  GROUP BY b.name
),
cte2 AS (
  SELECT
    b.name,
    RANK() OVER (ORDER BY COUNT(DISTINCT r._id) DESC) AS last_month_rank
  FROM
    receipts r
    JOIN transactions t ON r._id = t.receipt_id,
    UNNEST(t.item_barcode) AS item_barcode
    JOIN items i ON item_barcode = i.item_barcode
    JOIN brands b ON i.brandCode = b.brandCode
  WHERE
    FORMAT_DATE('%Y-%m', r.dateScanned) = FORMAT_DATE('%Y-%m', DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH))
  GROUP BY b.name
)
SELECT
  cte1.name,
  cte1.current_rank - cte2.last_month_rank AS delta_rank
FROM
  cte1
  LEFT JOIN cte2 USING (name)
WHERE
  cte1.current_rank <= 5
ORDER BY
  cte1.current_rank;



-- When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
WITH cte1 AS (
  SELECT
    AVG(totalSpent) AS avg_spend_accepted
  FROM
    receipts
  WHERE
    rewardsReceiptStatus = 'FINISHED'
),
cte2 AS (
  SELECT
    AVG(totalSpent) AS avg_spend_rejected
  FROM
    receipts
  WHERE
    rewardsReceiptStatus = 'REJECTED'
)
SELECT
  CASE
    WHEN cte1.avg_spend_accepted > cte2.avg_spend_rejected THEN 'ACCEPTED'
    WHEN cte2.avg_spend_rejected > cte1.avg_spend_accepted THEN 'REJECTED'
    ELSE 'NEITHER'
  END AS accepted_or_rejected_spend_greater
FROM
  cte1, cte2;



-- When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
WITH cte1 AS (
  SELECT
    SUM(t.quantityPurchased) AS total_qty_accepted
  FROM
    receipts r
    JOIN transactions t ON r._id = t.receipt_id
  WHERE
    r.rewardsReceiptStatus = 'FINISHED'
),
cte2 AS (
  SELECT
    SUM(t.quantityPurchased) AS total_qty_rejected
  FROM
    receipts r
    JOIN transactions t ON r._id = t.receipt_id
  WHERE
    r.rewardsReceiptStatus = 'REJECTED'
)
SELECT
  CASE
    WHEN cte1.total_qty_accepted > cte2.total_qty_rejected THEN 'ACCEPTED'
    WHEN cte2.total_qty_rejected > cte1.total_qty_accepted THEN 'REJECTED'
    ELSE 'NEITHER'
  END AS accepted_or_rejected_qty_greater
FROM
  cte1, cte2;


