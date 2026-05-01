WITH filtered_transfers AS (
    SELECT
        block_time,
        blockchain,
        amount_usd
    FROM stablecoins_multichain.transfers
    WHERE block_date >= CURRENT_DATE - INTERVAL '180' DAY
      AND blockchain IN ('ethereum', 'base', 'arbitrum', 'optimism')
      AND currency = 'USD'
      AND amount_usd > 0
      AND lower("from") <> '0x0000000000000000000000000000000000000000'
      AND lower("to") <> '0x0000000000000000000000000000000000000000'
)
SELECT
    blockchain,
    day_of_week(block_time) AS day_of_week_num,
    CASE day_of_week(block_time)
        WHEN 1 THEN 'Mon'
        WHEN 2 THEN 'Tue'
        WHEN 3 THEN 'Wed'
        WHEN 4 THEN 'Thu'
        WHEN 5 THEN 'Fri'
        WHEN 6 THEN 'Sat'
        WHEN 7 THEN 'Sun'
    END AS day_of_week,
    hour(block_time) AS hour_utc,
    SUM(amount_usd) AS volume_usd,
    COUNT(*) AS transfer_count,
    AVG(amount_usd) AS avg_transfer_usd,
    approx_percentile(amount_usd, 0.5) AS median_transfer_usd
FROM filtered_transfers
GROUP BY 1, 2, 3, 4
ORDER BY 1, 2, 4;

