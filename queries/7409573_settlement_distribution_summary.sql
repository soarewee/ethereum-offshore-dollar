WITH filtered_transfers AS (
    SELECT
        block_time,
        block_date,
        blockchain,
        amount_usd,
        "from" AS from_address,
        "to" AS to_address
    FROM stablecoins_multichain.transfers
    WHERE block_date >= CURRENT_DATE - INTERVAL '180' DAY
      AND blockchain IN ('ethereum', 'base', 'arbitrum', 'optimism')
      AND currency = 'USD'
      AND amount_usd > 0
      AND lower("from") <> '0x0000000000000000000000000000000000000000'
      AND lower("to") <> '0x0000000000000000000000000000000000000000'
), participants AS (
    SELECT blockchain, from_address AS address FROM filtered_transfers
    UNION ALL
    SELECT blockchain, to_address AS address FROM filtered_transfers
), participant_counts AS (
    SELECT
        blockchain,
        approx_distinct(address) AS active_addresses
    FROM participants
    GROUP BY 1
), chain_metrics AS (
    SELECT
        blockchain,
        SUM(amount_usd) AS volume_usd,
        COUNT(*) AS transfer_count,
        AVG(amount_usd) AS avg_transfer_usd,
        approx_percentile(amount_usd, 0.5) AS median_transfer_usd,
        approx_percentile(amount_usd, 0.9) AS p90_transfer_usd,
        approx_percentile(amount_usd, 0.99) AS p99_transfer_usd,
        SUM(CASE WHEN day_of_week(block_time) IN (6, 7) THEN amount_usd ELSE 0 END) AS weekend_volume_usd,
        COUNT_IF(day_of_week(block_time) IN (6, 7)) AS weekend_transfer_count
    FROM filtered_transfers
    GROUP BY 1
)
SELECT
    m.blockchain,
    m.volume_usd,
    m.transfer_count,
    p.active_addresses,
    m.avg_transfer_usd,
    m.median_transfer_usd,
    m.p90_transfer_usd,
    m.p99_transfer_usd,
    m.volume_usd / NULLIF(m.transfer_count, 0) AS volume_per_transfer_usd,
    m.transfer_count * 1.0 / NULLIF(p.active_addresses, 0) AS transfers_per_active_address,
    m.weekend_volume_usd / NULLIF(m.volume_usd, 0) AS weekend_volume_share,
    m.weekend_transfer_count * 1.0 / NULLIF(m.transfer_count, 0) AS weekend_transfer_share
FROM chain_metrics m
JOIN participant_counts p ON m.blockchain = p.blockchain
ORDER BY m.volume_usd DESC;

