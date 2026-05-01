WITH filtered_transfers AS (
    SELECT
        t.blockchain,
        t.amount_usd,
        lower(t."from") AS from_address,
        lower(t."to") AS to_address
    FROM stablecoins_multichain.transfers t
    WHERE t.block_date >= CURRENT_DATE - INTERVAL '90' DAY
      AND t.blockchain IN ('ethereum', 'base', 'arbitrum', 'optimism')
      AND t.currency = 'USD'
      AND t.amount_usd > 0
      AND lower(t."from") <> '0x0000000000000000000000000000000000000000'
      AND lower(t."to") <> '0x0000000000000000000000000000000000000000'
), cex AS (
    SELECT DISTINCT
        blockchain,
        lower('0x' || to_hex(address)) AS address
    FROM cex.addresses
    WHERE blockchain IN ('ethereum', 'base', 'arbitrum', 'optimism')
), dex AS (
    SELECT DISTINCT
        blockchain,
        lower('0x' || to_hex(address)) AS address
    FROM dex.addresses
    WHERE blockchain IN ('ethereum', 'base', 'arbitrum', 'optimism')
), contract_addresses AS (
    SELECT DISTINCT
        blockchain,
        lower('0x' || to_hex(address)) AS address
    FROM addresses.stats
    WHERE blockchain IN ('ethereum', 'base', 'arbitrum', 'optimism')
      AND is_smart_contract
), classified AS (
    SELECT
        f.blockchain,
        f.amount_usd,
        CASE
            WHEN cf.address IS NOT NULL OR ct.address IS NOT NULL THEN 'CEX-touching'
            WHEN df.address IS NOT NULL OR dt.address IS NOT NULL THEN 'DEX-touching'
            WHEN sf.address IS NOT NULL OR st.address IS NOT NULL THEN 'Other smart contract-touching'
            ELSE 'Unlabeled wallet-to-wallet / other'
        END AS counterparty_class
    FROM filtered_transfers f
    LEFT JOIN cex cf ON f.blockchain = cf.blockchain AND f.from_address = cf.address
    LEFT JOIN cex ct ON f.blockchain = ct.blockchain AND f.to_address = ct.address
    LEFT JOIN dex df ON f.blockchain = df.blockchain AND f.from_address = df.address
    LEFT JOIN dex dt ON f.blockchain = dt.blockchain AND f.to_address = dt.address
    LEFT JOIN contract_addresses sf ON f.blockchain = sf.blockchain AND f.from_address = sf.address
    LEFT JOIN contract_addresses st ON f.blockchain = st.blockchain AND f.to_address = st.address
), totals AS (
    SELECT blockchain, SUM(amount_usd) AS chain_volume_usd, COUNT(*) AS chain_transfer_count
    FROM classified
    GROUP BY 1
)
SELECT
    c.blockchain,
    c.counterparty_class,
    SUM(c.amount_usd) AS volume_usd,
    COUNT(*) AS transfer_count,
    SUM(c.amount_usd) / NULLIF(t.chain_volume_usd, 0) AS chain_volume_share,
    COUNT(*) * 1.0 / NULLIF(t.chain_transfer_count, 0) AS chain_transfer_share,
    AVG(c.amount_usd) AS avg_transfer_usd,
    approx_percentile(c.amount_usd, 0.5) AS median_transfer_usd
FROM classified c
JOIN totals t ON c.blockchain = t.blockchain
GROUP BY 1, 2, t.chain_volume_usd, t.chain_transfer_count
ORDER BY c.blockchain, volume_usd DESC;

