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
), daily AS (
    SELECT
        block_date,
        blockchain,
        SUM(CASE WHEN from_address = '0x0000000000000000000000000000000000000000' THEN amount_usd ELSE 0 END) AS mint_volume_usd,
        SUM(CASE WHEN to_address = '0x0000000000000000000000000000000000000000' THEN amount_usd ELSE 0 END) AS burn_volume_usd
    FROM transfers
    GROUP BY 1, 2
), net AS (
    SELECT
        block_date,
        blockchain,
        mint_volume_usd - burn_volume_usd AS net_issuance_volume_usd
    FROM daily
)
SELECT
    block_date,
    MAX(CASE WHEN blockchain = 'ethereum' THEN net_issuance_volume_usd END) AS ethereum_net_issuance_usd,
    MAX(CASE WHEN blockchain = 'base' THEN net_issuance_volume_usd END) AS base_net_issuance_usd,
    MAX(CASE WHEN blockchain = 'arbitrum' THEN net_issuance_volume_usd END) AS arbitrum_net_issuance_usd,
    MAX(CASE WHEN blockchain = 'optimism' THEN net_issuance_volume_usd END) AS optimism_net_issuance_usd
FROM net
GROUP BY 1
ORDER BY 1;

