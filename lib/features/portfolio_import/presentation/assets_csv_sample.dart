/// Ready-to-edit example CSV offered by the assets import dialog. One row per
/// asset. `market`/`currency` may be omitted (defaulted from the kind); shown
/// here for clarity. See `docs/specs/csv_import.md`.
const assetsCsvSample = '''
ticker,name,kind,market,currency,institution
SOXX,iShares Semiconductor ETF,etfUs,us,usd,Avenue
QQQ,Invesco QQQ Trust,etfUs,us,usd,Avenue
PETR4,Petrobras PN,stockBr,br,brl,Nubank
HGLG11,CSHG Logistica FII,fiiBr,br,brl,Nubank
BTC,Bitcoin,crypto,global,usd,Nubank Crypto
''';
