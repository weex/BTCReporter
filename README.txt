#  BTCReporter v0.5 <http://www.sterryit.com/btcreporter> 
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

Analyze your trading on MtGox with this script. Download your USD and BTC CSV files from MtGox (under Account History) and drop them in the same directory as this script. Run the script from Linux or Windows/Mac(with Perl installed) with the command:

   perl btcreporter.pl

and it'll spit out a CSV file that shows:

  * Net BTC purchased
  * Net USD spent
  * Total USD fees and USD value of all fees at time of trading
  * Prices, fees, and quantities broken out into additional columns

Get source code from http://www.github.com/weex/btcreporter

For priority email support email david@sterryit.com or purchase this script from http://www.sterryit.com/btcreporter

Changelog: ==================================================================

0.5
 
* First release
