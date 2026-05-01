WITH filtered_transfers AS (
    SELECT
        block_date,
        blockchain,
        token_symbol,
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
)
SELECT
    block_date,
    blockchain,
    SUM(amount_usd) AS volume_usd,
    COUNT(*) AS transfer_count,
    approx_distinct(from_address) AS active_senders,
    approx_distinct(to_address) AS active_receivers,
    approx_distinct(from_address || ':' || to_address) AS active_pairs,
    AVG(amount_usd) AS avg_transfer_usd,
    approx_percentile(amount_usd, 0.5) AS median_transfer_usd,
    approx_percentile(amount_usd, 0.9) AS p90_transfer_usd,
    approx_percentile(amount_usd, 0.99) AS p99_transfer_usd
FROM filtered_transfers
GROUP BY 1, 2
ORDER BY 1, 2;

