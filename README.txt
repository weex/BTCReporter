#  BTCReporter v0.6 <http://www.sterryit.com/btcreporter> 
#  Copyright (c) 2012 David Sterry <david@sterryit.com>
#
#      This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
###########################################################################

BTCReporter helps you analyze your trading on Bitcoin exchanges like MtGox, Tradehill, CampBX, and ExchB.

Understand your gains/losses, fees paid, and average purchase price or use BTCReporter to pre-process your logs for further analysis.

Simply download your CSV files from MtGox, TradeHill, or CampBX and drop them in the same directory as this script. Run the script from Linux or Windows/Mac(with Perl installed) and it'll spit out a single report that shows:

* Net change in BTC, USD, and EUR
* Total fees in BTC, USD, and EUR.
* Fees converted to fiat using each individual trade price to help with taxes.
* Prices, fees, and quantities broken out into additional columns.

Supports BTC/USD/EUR with planned support for all currencies and any exchanges or services that are relevant to Bitcoin trading and exchange.

===========================================================================

To use: 

1. Download CSV files from the services you use and drop them in the same folder as this script.

2. Run the command:

   perl btcreporter.pl

===========================================================================

ExchB does not provide CSV download of history so you would need to login to your account there and copy the table with headings from your account's History page and paste the entire table in a file called: exchb.csv

===========================================================================

Get the latest version from https://github.com/weex/BTCReporter

For priority email support email david@sterryit.com or purchase this script from http://www.sterryit.com/btcreporter

===========================================================================

Changelog:

0.6 

* Net values now negative for amounts spent and positive for amounts received
* Supports Tradehill, CampBX, and ExchB
* Average price broken out by currency
* Command line switches added (--help shows them)

0.5
 
* First release


