/// Ready-to-edit example CSV offered by the assets import dialog. One row per
/// asset (the instrument only — no transactions). `market`/`currency` may be
/// omitted (defaulted from the kind); shown here for clarity. See
/// `docs/specs/csv_import.md`.
const assetsCsvSample = '''
ticker,name,kind,market,currency
SOXX,iShares Semiconductor ETF,etfUs,us,usd
QQQ,Invesco QQQ Trust,etfUs,us,usd
PETR4,Petrobras PN,stockBr,br,brl
HGLG11,CSHG Logística FII,fiiBr,br,brl
BTC,Bitcoin,crypto,global,usd
''';
