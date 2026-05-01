WITH transfers AS (
    SELECT
        block_date,
        blockchain,
        amount_usd,
        lower("from") AS from_address,
        lower("to") AS to_address
    FROM stablecoins_multichain.transfers
    WHERE block_date >= CURRENT_DATE - INTERVAL '90' DAY
      AND blockchain IN ('ethereum', 'base', 'arbitrum', 'optimism')
      AND currency = 'USD'
      AND amount_usd > 0
      AND lower("from") <> '0x0000000000000000000000000000000000000000'
      AND lower("to") <> '0x0000000000000000000000000000000000000000'
), daily AS (
    SELECT
        block_date,
        blockchain,
        SUM(amount_usd) AS circulation_volume_usd,
        SUM(CASE WHEN amount_usd >= 1000000 THEN amount_usd ELSE 0 END) AS whale_volume_usd
    FROM transfers
    GROUP BY 1, 2
), shares AS (
    SELECT
        block_date,
        blockchain,
        whale_volume_usd / NULLIF(circulation_volume_usd, 0) AS whale_volume_share
    FROM daily
)
SELECT
    block_date,
    MAX(CASE WHEN blockchain = 'ethereum' THEN whale_volume_share END) AS ethereum_whale_volume_share,
    MAX(CASE WHEN blockchain = 'base' THEN whale_volume_share END) AS base_whale_volume_share,
    MAX(CASE WHEN blockchain = 'arbitrum' THEN whale_volume_share END) AS arbitrum_whale_volume_share,
    MAX(CASE WHEN blockchain = 'optimism' THEN whale_volume_share END) AS optimism_whale_volume_share
FROM shares
GROUP BY 1
ORDER BY 1;

