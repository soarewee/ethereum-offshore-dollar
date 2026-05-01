WITH bridge_addresses AS (
    SELECT
        'ethereum' AS blockchain,
        lower(address) AS address,
        bridge_name
    FROM addresses_ethereum.bridges
), transfers AS (
    SELECT
        t.block_date,
        t.blockchain,
        t.token_symbol,
        t.amount_usd,
        lower(t."from") AS from_address,
        lower(t."to") AS to_address
    FROM stablecoins_multichain.transfers t
    WHERE t.block_date >= CURRENT_DATE - INTERVAL '90' DAY
      AND t.blockchain = 'ethereum'
      AND t.currency = 'USD'
      AND t.amount_usd > 0
      AND lower(t."from") <> '0x0000000000000000000000000000000000000000'
      AND lower(t."to") <> '0x0000000000000000000000000000000000000000'
), bridge_touching AS (
    SELECT
        t.block_date,
        t.token_symbol,
        t.amount_usd,
        COALESCE(bf.bridge_name, bt.bridge_name) AS bridge_name,
        CASE
            WHEN bf.address IS NOT NULL THEN 'from_bridge'
            WHEN bt.address IS NOT NULL THEN 'to_bridge'
        END AS direction_proxy
    FROM transfers t
    LEFT JOIN bridge_addresses bf ON t.from_address = bf.address
    LEFT JOIN bridge_addresses bt ON t.to_address = bt.address
    WHERE bf.address IS NOT NULL OR bt.address IS NOT NULL
), daily_totals AS (
    SELECT
        block_date,
        SUM(amount_usd) AS ethereum_stablecoin_volume_usd
    FROM transfers
    GROUP BY 1
), bridge_daily AS (
    SELECT
        block_date,
        SUM(amount_usd) AS bridge_touching_volume_usd,
        COUNT(*) AS bridge_touching_transfer_count
    FROM bridge_touching
    GROUP BY 1
)
SELECT
    b.block_date,
    b.bridge_touching_volume_usd,
    b.bridge_touching_transfer_count,
    b.bridge_touching_volume_usd / NULLIF(t.ethereum_stablecoin_volume_usd, 0) AS bridge_touching_volume_share
FROM bridge_daily b
JOIN daily_totals t ON b.block_date = t.block_date
ORDER BY b.block_date;

