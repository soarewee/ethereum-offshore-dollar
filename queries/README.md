# Dune Queries

These are the Dune queries used for the Ethereum offshore-dollar PoC dashboard.

Dashboard: https://dune.com/soarewee/ethereum-offshore-dollar-poc-stablecoin-rails

## Query Index

- `7409572_daily_rail_metrics.sql`: daily volume, count, active addresses, and transfer-size metrics by chain.
- `7409573_settlement_distribution_summary.sql`: 180-day settlement/distribution summary by chain.
- `7409574_hour_of_week_activity.sql`: hour-of-week volume and transfer count.
- `7409575_token_mix_by_chain.sql`: stablecoin token mix by chain.
- `7409576_counterparty_classification.sql`: rough CEX/DEX/contract/wallet classification.
- `7409601_daily_volume_pivot.sql`: daily volume with explicit chain columns for charting.
- `7409603_daily_transfer_count_pivot.sql`: daily transfer count with explicit chain columns for charting.
- `7409809_observable_offshore_dollar_signals.sql`: daily observable signals: whale volume share, mints, burns, net issuance, active addresses.
- `7409810_holder_concentration_snapshot.sql`: latest balance concentration snapshot by chain.
- `7409811_bridge_flow_visibility_failed.sql`: attempted `bridge.flows` query; kept for provenance, but the Dune view failed at execution time.
- `7409812_stress_and_burst_days.sql`: rolling 30-day burst detector for volume and transfer counts.
- `7409820_bridge_proxy_flows.sql`: lower-bound bridge-touch proxy using known Ethereum bridge addresses.
- `7410362_daily_whale_transfer_share_pivot.sql`: daily whale transfer share with explicit chain columns for charting.
- `7410363_daily_net_issuance_pivot.sql`: daily net issuance with explicit chain columns for charting.

## Method Notes

- Scope: `ethereum`, `base`, `arbitrum`, `optimism`.
- Source table: `stablecoins_multichain.transfers`.
- Main metrics use a 180-day window.
- Counterparty classification uses a 90-day window because address-label joins are heavier.
- Mint/burn zero-address transfers are excluded to focus on circulation.
- Classification is approximate and should be presented as directional, not definitive.
- Bridge proxy results are lower-bound estimates because they only capture transfers touching known Ethereum bridge addresses.
- Pivoted chart queries are used where Dune visualizations do not clearly distinguish grouped chain series.
