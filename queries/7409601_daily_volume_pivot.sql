WITH filtered_transfers AS (
    SELECT
        block_date,
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
    block_date,
    SUM(CASE WHEN blockchain = 'ethereum' THEN amount_usd ELSE 0 END) AS ethereum_volume_usd,
    SUM(CASE WHEN blockchain = 'base' THEN amount_usd ELSE 0 END) AS base_volume_usd,
    SUM(CASE WHEN blockchain = 'arbitrum' THEN amount_usd ELSE 0 END) AS arbitrum_volume_usd,
    SUM(CASE WHEN blockchain = 'optimism' THEN amount_usd ELSE 0 END) AS optimism_volume_usd
FROM filtered_transfers
GROUP BY 1
ORDER BY 1;

