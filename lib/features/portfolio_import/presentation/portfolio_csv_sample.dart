/// Ready-to-edit example CSV offered by the import dialog. One row per position
/// (asset + the buy that created it). Columns are the common subset; market and
/// currency default from the kind, operation defaults to buy. See
/// `docs/specs/csv_import.md`. The rows are real US ETFs so the file imports
/// cleanly as-is; the user edits quantities, prices and dates to match.
const portfolioCsvSample = '''
ticker,name,kind,institution,quantity,price,date
SOXX,iShares Semiconductor ETF,etfUs,Avenue,1.92012,233.91,02/01/2024
BITQ,Bitwise Crypto Industry Innovators ETF,etfUs,Avenue,33.68626,12.78,02/01/2024
THNQ,ROBO Global Artificial Intelligence ETF,etfUs,Avenue,8,49.31,02/01/2024
QQQ,Invesco QQQ Trust Series 1,etfUs,Avenue,2.11947,478.17,02/01/2024
IVV,iShares Core S&P 500 ETF,etfUs,Avenue,1.05887,577.05,02/01/2024
VT,Vanguard Total World Stock ETF,etfUs,Avenue,5.30612,120.14,02/01/2024
VWO,Vanguard FTSE Emerging Markets ETF,etfUs,Avenue,12.24693,46.03,02/01/2024
VTI,Vanguard Total Stock Market ETF,etfUs,Avenue,5.24303,291.67,02/01/2024
VNQ,Vanguard Real Estate Index Fund ETF,etfUs,Avenue,29.88756,90.64,02/01/2024
VNQI,Vanguard Global ex-US Real Estate ETF,etfUs,Avenue,102.82221,45.85,02/01/2024
''';
