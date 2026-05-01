WITH filtered_transfers AS (
    SELECT
        block_date,
        blockchain
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
    COUNT_IF(blockchain = 'ethereum') AS ethereum_transfer_count,
    COUNT_IF(blockchain = 'base') AS base_transfer_count,
    COUNT_IF(blockchain = 'arbitrum') AS arbitrum_transfer_count,
    COUNT_IF(blockchain = 'optimism') AS optimism_transfer_count
FROM filtered_transfers
GROUP BY 1
ORDER BY 1;

