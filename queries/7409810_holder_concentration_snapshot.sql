WITH latest_day AS (
    SELECT MAX(day) AS day
    FROM stablecoins_multichain.balances
    WHERE day >= CURRENT_DATE - INTERVAL '14' DAY
      AND blockchain IN ('ethereum', 'base', 'arbitrum', 'optimism')
      AND currency = 'USD'
), balances AS (
    SELECT
        b.blockchain,
        b.address,
        SUM(b.balance_usd) AS balance_usd
    FROM stablecoins_multichain.balances b
    JOIN latest_day d ON b.day = d.day
    WHERE b.blockchain IN ('ethereum', 'base', 'arbitrum', 'optimism')
      AND b.currency = 'USD'
      AND b.balance_usd > 0
    GROUP BY 1, 2
), ranked AS (
    SELECT
        blockchain,
        address,
        balance_usd,
        ROW_NUMBER() OVER (PARTITION BY blockchain ORDER BY balance_usd DESC) AS holder_rank,
        SUM(balance_usd) OVER (PARTITION BY blockchain) AS chain_balance_usd
    FROM balances
), buckets AS (
    SELECT
        blockchain,
        COUNT(*) AS holders,
        SUM(balance_usd) AS total_balance_usd,
        SUM(CASE WHEN holder_rank <= 10 THEN balance_usd ELSE 0 END) AS top_10_balance_usd,
        SUM(CASE WHEN holder_rank <= 100 THEN balance_usd ELSE 0 END) AS top_100_balance_usd,
        SUM(CASE WHEN balance_usd >= 1000000 THEN balance_usd ELSE 0 END) AS millionaire_balance_usd,
        COUNT_IF(balance_usd >= 1000000) AS millionaire_holders,
        approx_percentile(balance_usd, 0.5) AS median_holder_balance_usd,
        approx_percentile(balance_usd, 0.9) AS p90_holder_balance_usd,
        approx_percentile(balance_usd, 0.99) AS p99_holder_balance_usd
    FROM ranked
    GROUP BY 1
)
SELECT
    blockchain,
    holders,
    total_balance_usd,
    top_10_balance_usd / NULLIF(total_balance_usd, 0) AS top_10_share,
    top_100_balance_usd / NULLIF(total_balance_usd, 0) AS top_100_share,
    millionaire_balance_usd / NULLIF(total_balance_usd, 0) AS millionaire_balance_share,
    millionaire_holders,
    median_holder_balance_usd,
    p90_holder_balance_usd,
    p99_holder_balance_usd
FROM buckets
ORDER BY total_balance_usd DESC;

