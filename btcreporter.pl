#!/usr/bin/env perl

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

use Text::CSV_XS;
use bigrat;

my $total_USD = 0;
my $total_BTC = 0;
my $total_USD_fees = 0;
my $total_BTC_fees = 0;
my $total_fees_USD_value = 0;

my @rows;
my $csv = Text::CSV_XS->new ({ binary => 1 }) or
  die "Cannot use CSV: ".Text::CSV_XS->error_diag ();
open my $fh, "<:encoding(utf8)", "history_BTC.csv" or die "history_BTC.csv: $!";

while (my $row = $csv->getline ($fh)) {

  # Header row additions
  if( $row->[0] =~ m/Index/ ) {
    $row->[6] = 'Quantity';
    $row->[7] = 'Price';
    $row->[8] = 'Total';
    $row->[9] = 'BTCFee';
    $row->[10] = 'USDFee';

  # BTC bought
  } elsif( $row->[2] =~ m/in/ and $row->[3] =~ m/bought/ ) {
    $row->[3] =~ m/(\d+\.\d+).*\$(\d+\.\d+)/;
    my $quantity = $1;
    my $price = $2;
    my $delta_USD = $quantity * $price;
    $total_USD += $delta_USD;
    $total_BTC += $quantity;
    $row->[6] = $quantity;
    $row->[7] = $price;
    $row->[8] = $delta_USD;

  # BTC bought fee
  } elsif( $row->[2] =~ m/fee/ and $row->[3] =~ m/bought/ ) {
    $row->[3] =~ m/(\d+\.\d+).*\$(\d+\.\d+)/;
    my $price = $2;
    $total_BTC_fees += $row->[4];
    $total_fees_USD_value += $price * $row->[4];
    $row->[9] = $row->[4];

  # BTC sold
  } elsif( $row->[2] =~ m/out/ and $row->[3] =~ m/sold/ ) {
    $row->[3] =~ m/(\d+\.\d+).*\$(\d+\.\d+)/;
    my $quantity = -$1;
    my $price = $2;
    my $delta_USD = $quantity * $price;
    $total_USD += $delta_USD;
    $total_BTC += $quantity;
    $row->[6] = $quantity;
    $row->[7] = $price; 
    $row->[8] = $delta_USD;

  # BTC sold fee
#  } elsif( $row->[2] =~ m/fee/ and $row->[3] =~ m/sold/ ) {
#    $row->[3] =~ m/(\d+\.\d+).*\$(\d+\.\d+)/;
#    my $price = $2;
#    $total_USD_fees += $row->[4];
#    $total_fees_USD_value += $row->[4];
#    $row->[10] = $row->[4];
  }

  push @rows, $row;
}
$csv->eof or $csv->error_diag ();
close $fh;

open my $fh, "<:encoding(utf8)", "history_USD.csv" or die "history_USD.csv: $!";

while (my $row = $csv->getline ($fh)) {

  # BTC sold fee
  if( $row->[2] =~ m/fee/ and $row->[3] =~ m/sold/ ) {
    $row->[3] =~ m/(\d+\.\d+).*\$(\d+\.\d+)/;
    my $price = $2;
    $total_USD_fees += $row->[4];
    $total_fees_USD_value += $row->[4];
    $row->[10] = $row->[4];
    $row->[0] = 's'.$row->[0];
    push @rows, $row;
  }
}
$csv->eof or $csv->error_diag ();
close $fh;

my @summary;
$summary[0]->[0] = "Total Fees in USD";
$summary[0]->[1] = $total_fees_USD_value;

$summary[1]->[0] = "Total USD Fees";
$summary[1]->[1] = $total_USD_fees;

$summary[2]->[0] = "Total BTC Fees";
$summary[2]->[1] = $total_BTC_fees;

$summary[3]->[0] = "Net USD Investment";
$summary[3]->[1] = $total_USD;

$summary[4]->[0] = "Net BTC Received";
$summary[4]->[1] = $total_BTC;
$summary[5]->[0]= '';

unshift @rows, @summary;

$csv->eol ("\r\n");
open $fh, ">:encoding(utf8)", "report.csv" or die "report.csv: $!";
$csv->print ($fh, $_) for @rows;
close $fh or die "report.csv: $!";
