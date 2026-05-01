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
), classified AS (
    SELECT
        block_date,
        blockchain,
        amount_usd,
        from_address,
        to_address,
        CASE
            WHEN from_address = '0x0000000000000000000000000000000000000000' THEN 'mint'
            WHEN to_address = '0x0000000000000000000000000000000000000000' THEN 'burn'
            WHEN amount_usd >= 1000000 THEN 'whale_transfer'
            ELSE 'circulation'
        END AS signal_type
    FROM transfers
), participants AS (
    SELECT block_date, blockchain, from_address AS address
    FROM classified
    WHERE signal_type NOT IN ('mint', 'burn')
    UNION ALL
    SELECT block_date, blockchain, to_address AS address
    FROM classified
    WHERE signal_type NOT IN ('mint', 'burn')
), daily AS (
    SELECT
        block_date,
        blockchain,
        SUM(CASE WHEN signal_type NOT IN ('mint', 'burn') THEN amount_usd ELSE 0 END) AS circulation_volume_usd,
        COUNT_IF(signal_type NOT IN ('mint', 'burn')) AS circulation_transfer_count,
        SUM(CASE WHEN signal_type = 'whale_transfer' THEN amount_usd ELSE 0 END) AS whale_volume_usd,
        COUNT_IF(signal_type = 'whale_transfer') AS whale_transfer_count,
        SUM(CASE WHEN signal_type = 'mint' THEN amount_usd ELSE 0 END) AS mint_volume_usd,
        SUM(CASE WHEN signal_type = 'burn' THEN amount_usd ELSE 0 END) AS burn_volume_usd
    FROM classified
    GROUP BY 1, 2
), active AS (
    SELECT
        block_date,
        blockchain,
        approx_distinct(address) AS active_addresses
    FROM participants
    GROUP BY 1, 2
)
SELECT
    d.block_date,
    d.blockchain,
    d.circulation_volume_usd,
    d.circulation_transfer_count,
    a.active_addresses,
    d.whale_volume_usd,
    d.whale_transfer_count,
    d.whale_volume_usd / NULLIF(d.circulation_volume_usd, 0) AS whale_volume_share,
    d.mint_volume_usd,
    d.burn_volume_usd,
    d.mint_volume_usd - d.burn_volume_usd AS net_issuance_volume_usd
FROM daily d
JOIN active a ON d.block_date = a.block_date AND d.blockchain = a.blockchain
ORDER BY 1, 2;

