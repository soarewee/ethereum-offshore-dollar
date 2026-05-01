WITH filtered_transfers AS (
    SELECT
        blockchain,
        token_symbol,
        amount_usd
    FROM stablecoins_multichain.transfers
    WHERE block_date >= CURRENT_DATE - INTERVAL '180' DAY
      AND blockchain IN ('ethereum', 'base', 'arbitrum', 'optimism')
      AND currency = 'USD'
      AND amount_usd > 0
      AND lower("from") <> '0x0000000000000000000000000000000000000000'
      AND lower("to") <> '0x0000000000000000000000000000000000000000'
), totals AS (
    SELECT blockchain, SUM(amount_usd) AS chain_volume_usd
    FROM filtered_transfers
    GROUP BY 1
)
SELECT
    f.blockchain,
    f.token_symbol,
    SUM(f.amount_usd) AS volume_usd,
    COUNT(*) AS transfer_count,
    SUM(f.amount_usd) / NULLIF(t.chain_volume_usd, 0) AS chain_volume_share,
    AVG(f.amount_usd) AS avg_transfer_usd,
    approx_percentile(f.amount_usd, 0.5) AS median_transfer_usd
FROM filtered_transfers f
JOIN totals t ON f.blockchain = t.blockchain
GROUP BY 1, 2, t.chain_volume_usd
HAVING SUM(f.amount_usd) >= 1000000
ORDER BY volume_usd DESC;

