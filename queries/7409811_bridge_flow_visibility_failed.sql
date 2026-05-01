-- This query is kept for provenance. It failed because Dune's bridge.flows
-- stored view returned an internal UNION type incompatibility at execution time.
WITH flows AS (
    SELECT
        DATE(block_time) AS block_date,
        project,
        transfer_type,
        token_symbol,
        source_chain_name,
        destination_chain_name,
        bridge_path_name,
        token_amount_usd
    FROM bridge.flows
    WHERE DATE(block_time) >= CURRENT_DATE - INTERVAL '90' DAY
      AND token_amount_usd > 0
      AND token_symbol IN ('USDC', 'USDT', 'DAI', 'USDS', 'PYUSD', 'crvUSD', 'USD₮0')
      AND (
          lower(source_chain_name) IN ('ethereum', 'base', 'arbitrum', 'optimism')
          OR lower(destination_chain_name) IN ('ethereum', 'base', 'arbitrum', 'optimism')
          OR lower(blockchain) IN ('ethereum', 'base', 'arbitrum', 'optimism')
      )
)
SELECT
    source_chain_name,
    destination_chain_name,
    bridge_path_name,
    project,
    token_symbol,
    SUM(token_amount_usd) AS bridge_volume_usd,
    COUNT(*) AS bridge_transfer_count,
    AVG(token_amount_usd) AS avg_bridge_transfer_usd,
    approx_percentile(token_amount_usd, 0.5) AS median_bridge_transfer_usd
FROM flows
GROUP BY 1, 2, 3, 4, 5
HAVING SUM(token_amount_usd) >= 1000000
ORDER BY bridge_volume_usd DESC
LIMIT 100;

