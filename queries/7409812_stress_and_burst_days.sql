WITH daily AS (
    SELECT
        block_date,
        blockchain,
        SUM(amount_usd) AS volume_usd,
        COUNT(*) AS transfer_count,
        SUM(CASE WHEN amount_usd >= 1000000 THEN amount_usd ELSE 0 END) AS whale_volume_usd,
        COUNT_IF(amount_usd >= 1000000) AS whale_transfer_count
    FROM stablecoins_multichain.transfers
    WHERE block_date >= CURRENT_DATE - INTERVAL '180' DAY
      AND blockchain IN ('ethereum', 'base', 'arbitrum', 'optimism')
      AND currency = 'USD'
      AND amount_usd > 0
      AND lower("from") <> '0x0000000000000000000000000000000000000000'
      AND lower("to") <> '0x0000000000000000000000000000000000000000'
    GROUP BY 1, 2
), rolling AS (
    SELECT
        block_date,
        blockchain,
        volume_usd,
        transfer_count,
        whale_volume_usd,
        whale_transfer_count,
        AVG(volume_usd) OVER (
            PARTITION BY blockchain
            ORDER BY block_date
            ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING
        ) AS rolling_30d_avg_volume_usd,
        AVG(transfer_count) OVER (
            PARTITION BY blockchain
            ORDER BY block_date
            ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING
        ) AS rolling_30d_avg_transfer_count
    FROM daily
)
SELECT
    block_date,
    blockchain,
    volume_usd,
    transfer_count,
    whale_volume_usd,
    whale_transfer_count,
    whale_volume_usd / NULLIF(volume_usd, 0) AS whale_volume_share,
    volume_usd / NULLIF(rolling_30d_avg_volume_usd, 0) AS volume_burst_ratio,
    transfer_count * 1.0 / NULLIF(rolling_30d_avg_transfer_count, 0) AS transfer_count_burst_ratio
FROM rolling
WHERE rolling_30d_avg_volume_usd IS NOT NULL
ORDER BY volume_burst_ratio DESC;

