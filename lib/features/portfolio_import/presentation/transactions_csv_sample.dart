/// Ready-to-edit example CSV offered by the transactions import dialog. One row
/// per movement. The tickers must already exist as assets (import those first);
/// these match the assets example. `amount` is only for dividends. See
/// `docs/specs/csv_import.md`.
const transactionsCsvSample = '''
ticker,institution,operation,quantity,price,date,amount
SOXX,Avenue,buy,2,233.91,02/01/2024,
QQQ,Avenue,buy,1,478.17,02/01/2024,
PETR4,Nubank,buy,100,38.50,15/03/2024,
HGLG11,Nubank,buy,50,160.00,15/03/2024,
PETR4,Nubank,dividend,0,0,10/04/2024,12.50
''';
