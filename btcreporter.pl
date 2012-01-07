#!/usr/bin/env perl

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

use IO::File;
use Text::CSV_XS;
use Math::BigFloat;
use Getopt::Long;

my $verbose;
my $help;
my $summary;
my $nomtgox=0;
my $noth=0;
my $nocbx=0;
my $noexchb=0;
GetOptions ('verbose' => \$verbose, 
	    'help' => \$help,
	    'summary' => \$summary,
	    'no-mtgox' => \$nomtgox,
            'no-th' => \$noth,
            'no-cbx' => \$nocbx,
            'no-exchb' => \$noexchb);

my %total;
my %total_by_pair;
my %total_fees;
my %total_fees_in_fiat;

if( $help ) { print "BTCReporter v0.6. (c) 2012 David Sterry\n\tUsage:
\t\t    --no-mtgox\tdon't process MtGox logs
\t\t    --no-th\tdon't process TradeHill log
\t\t    --no-cbx\tdon't process CampBX log
\t\t    --no-exchb\tdon't process ExchB log
\t\t-s, --summary\tprints summary info to stdout
\t\t-v, --verbose\tdisplays runtime messages
\t\t-h, --help\tdisplays this help\n"; 
exit; }

my @rows;

my $csv = Text::CSV_XS->new ({ binary => 1 }) or
  die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

my @header_row = ('Service','Index','Date','Type','Info','Value',
'Balance','Quantity','Price','Total','FiatType','BTCFee','USDFee','EURFee');
push @rows, \@header_row; 

if ( !$nomtgox and -e 'history_BTC.csv' and -e 'history_USD.csv' ) {
  if( $verbose ) { print "Found MtGox CSV files\n"; }

  open my $fh, "<:encoding(utf8)", "history_BTC.csv" or die "history_BTC.csv: $!";

  while (my $row = $csv->getline ($fh)) {

    # Skip header row 
    if( $row->[0] =~ m/Index/ ) {
      next;

    # BTC bought
    } elsif( $row->[2] =~ m/in/ and $row->[3] =~ m/bought/ ) {
      $row->[3] =~ m/(\d+\.\d+).*\$(\d+\.\d+)/;
      my $quantity = $1;
      my $price = $2;
      my $delta_fiat = -$quantity * $price;
      $total{'USD'} += $delta_fiat;
      $total{'BTC'} += $quantity;
      $total_by_pair{'USD'} += $quantity;
      
      $row->[6] = $quantity;
      $row->[7] = $price;
      $row->[8] = $delta_fiat;

    # BTC bought fee
    } elsif( $row->[2] =~ m/fee/ and $row->[3] =~ m/bought/ ) {
      $row->[3] =~ m/(\d+\.\d+).*\$(\d+\.\d+)/;
      my $price = $2;
      $total_fees{'BTC'} += $row->[4];
      $total_fees_in_fiat{'USD'} += $price * $row->[4];
      $row->[10] = $row->[4];

    # BTC sold
    } elsif( $row->[2] =~ m/out/ and $row->[3] =~ m/sold/ ) {
      $row->[3] =~ m/(\d+\.\d+).*\$(\d+\.\d+)/;
      my $quantity = $1;
      my $price = $2;
      my $delta_fiat = $quantity * $price;
      $total{'USD'} += $delta_fiat;
      $total{'BTC'} -= $quantity;
      $total_by_pair{'USD'} -= $quantity;

      $row->[6] = $quantity;
      $row->[7] = $price; 
      $row->[8] = $delta_fiat;

    }
    unshift(@$row,'mtgox');
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
      $total_fees{'USD'} += $row->[4];
      $total_fees_in_fiat{'USD'} += $row->[4];
      $row->[11] = $row->[4];
      $row->[0] = 's'.$row->[0];

      unshift(@$row,'mtgox');
      push @rows, $row;
    }
  }
  $csv->eof or $csv->error_diag ();
  close $fh;
} 

if ( !$noth and -e 'TradeHill-TradeHistory.csv' ) {
  if( $verbose ) { print "Found TradeHill CSV file\n"; }

  open my $fh, "<:encoding(utf8)", "TradeHill-TradeHistory.csv" or die "TradeHill-TradeHistory.csv: $!";

  while (my $row = $csv->getline ($fh)) {
    my @output_row;
    if( not $row->[0] =~ m/Date/ ) {

      $output_row[1] = $row->[0]; #Date

      # BTC bought
      if( $row->[2] =~ m/BTC/ ) {  
        my $quantity = $row->[1];
        my $delta_fiat = $row->[3];
        my $price = $delta_fiat / $quantity;
        my $fiat_currency = $row->[4];
        my %fee;
	$fee{$fiat_currency} = $row->[5];
	$total{'BTC'} += $quantity;
	$total{$fiat_currency} -= $delta_fiat;
	$total_fees{$fiat_currency} += $fee{$fiat_currency};
        $total_by_pair{$fiat_currency} += $quantity;

        $output_row[3] = 'BTC bought:';
        $output_row[6] = $quantity;
        $output_row[7] = $price;
        $output_row[8] = -$delta_fiat;
        $output_row[9] = $fiat_currency;
	if($fiat_currency eq 'USD') {
          $total_fees_USD_value += $fee{$fiat_currency};
	  $output_row[11] = $fee{$fiat_currency};
	} else {
	  $output_row[12] = $fee{$fiat_currency};
	}

      # BTC sold
      } else {
        my $quantity = $row->[3];
        my $delta_fiat = $row->[1];
        my $price = $delta_fiat / $quantity;
        my $fiat_currency = $row->[2];
        my %fee;
	$fee{$fiat_currency} = $row->[5];
	$total{'BTC'} -= $quantity;
	$total{$fiat_currency} += $delta_fiat;
	$total_fees{$fiat_currency} += $fee{$fiat_currency};
        $total_by_pair{$fiat_currency} -= $quantity;

        $output_row[3] = 'BTC sold:';
        $output_row[6] = -$quantity;
        $output_row[7] = $price;
        $output_row[8] = $delta_fiat;
        $output_row[9] = $fiat_currency;
	if($fiat_currency eq 'USD') {
          $total_fees_USD_value += $fee{$fiat_currency};
	  $output_row[11] = $fee{$fiat_currency};
	} else {
	  $output_row[12] = $fee{$fiat_currency};
	}        
      }

      unshift(@output_row,'th'); 
      push @rows, \@output_row;
    }
  }
}

if ( !$nocbx and -e 'CampBXActivity.csv' ) {
  if( $verbose ) { print "Found CambBX CSV file\n"; }

  open my $fh, "<:encoding(utf8)", "CampBXActivity.csv" or die "CampBXActivity.csv: $!";

  while (my $row = $csv->getline ($fh)) {
    my @output_row;
    if( not $row->[0] =~ m/Executed On/ ) {

      $output_row[1] = $row->[0]; #Date

      # BTC bought
      if( $row->[3] =~ m/Quick Buy/ ) {  
        my $quantity = $row->[5];
        my $price = $row->[6];
        $price =~ s/\$//;
        my $delta_fiat = -$price * $quantity;
        my $fiat_currency = 'USD';
        my %fee;
	$fee{$fiat_currency} = $row->[11];
        $fee{$fiat_currency} =~ s/\$//;
	$total{'BTC'} += $quantity;
	$total{$fiat_currency} += $delta_fiat;
	$total_fees{$fiat_currency} += $fee{$fiat_currency};
        $total_by_pair{$fiat_currency} += $quantity;

        $output_row[3] = 'BTC bought:';
        $output_row[6] = $quantity;
        $output_row[7] = $price;
        $output_row[8] = $delta_fiat;
        $output_row[9] = $fiat_currency;
	if($fiat_currency eq 'USD') {
          $total_fees_USD_value += $fee{$fiat_currency};
	  $output_row[11] = $fee{$fiat_currency};
	} else {
	  $output_row[12] = $fee{$fiat_currency};
	}

        unshift(@output_row,'cbx'); 
        push @rows, \@output_row;
      } elsif( $row->[3] =~ m/Quick Sell/ ) {  
        my $quantity = $row->[5];
        my $price = $row->[6];
        $price =~ s/\$//;
        my $delta_fiat = $price * $quantity;
        my $fiat_currency = 'USD';
        my %fee;
	$fee{$fiat_currency} = $row->[11];
        $fee{$fiat_currency} =~ s/\$//;
	$total{'BTC'} -= $quantity;
	$total{$fiat_currency} += $delta_fiat;
	$total_fees{$fiat_currency} += $fee{$fiat_currency};
        $total_by_pair{$fiat_currency} -= $quantity;

        $output_row[3] = 'BTC sold:';
        $output_row[6] = -$quantity;
        $output_row[7] = $price;
        $output_row[8] = $delta_fiat;
        $output_row[9] = $fiat_currency;
	if($fiat_currency eq 'USD') {
          $total_fees_USD_value += $fee{$fiat_currency};
	  $output_row[11] = $fee{$fiat_currency};
	} else {
	  $output_row[12] = $fee{$fiat_currency};
	}

        unshift(@output_row,'cbx'); 
        push @rows, \@output_row;
      }

    }
  }
}

if ( !$noexchb and -e 'exchb.csv' ) {
  if( $verbose ) { print "Found ExchB tab-delimted file\n"; }

  open my $fh, "<:encoding(utf8)", "exchb.csv" or die "exchb.csv: $!";

  my $csvtab = Text::CSV_XS->new ({ binary => 1, sep_char => "\t" }) or
  die "Cannot use CSV: ".Text::CSV_XS->error_diag ();

  while (my $row = $csvtab->getline ($fh)) {
    my @output_row;
    if( not $row->[0] =~ m/id/ ) {

      $output_row[1] = $row->[1]; #Date

      # BTC bought
      if( $row->[2] =~ m/Bought BTC/ ) {  
	my $id = $row->[0];
        my $quantity = $row->[5];
        $row->[3] =~ m/(\d+\.*\d*)\D*\$(\d+\.\d+)/;
        my $order_quantity = $1;
        my $price = $2;
        $price =~ s/\$//;
        my $delta_fiat = $price * $quantity;
        my $fiat_currency = 'USD';
        my %fee;
	$fee{'BTC'} = $order_quantity - $quantity;
	$total{'BTC'} += $quantity;
	$total_fees{'BTC'} += $fee{'BTC'};
        $total_fees_in_fiat{'USD'} += $fee{'BTC'} * $price;
        $total_by_pair{$fiat_currency} += $quantity;

        $output_row[0] = $id;
        $output_row[3] = 'BTC bought: '.$row->[3];
        $output_row[6] = $quantity;
        $output_row[7] = $price;
        $output_row[8] = $delta_fiat;
        $output_row[9] = $fiat_currency;
        $output_row[10] = $fee{'BTC'};

        unshift(@output_row,'exchb'); 
        push @rows, \@output_row;

      # BTC sold
      } elsif( $row->[2] =~ m/Sold BTC/ ) {  
	my $id = $row->[0];
        my $quantity = $row->[5];
        $row->[3] =~ m/(\d+\.*\d*)\D*\$(\d+\.\d+)/;
        my $price = $2;
        $price =~ s/\$//;

	# ExchB doesn't list fees seperately so they must be calculated
	# from the information in description and +/- USD fields
        my $order_delta_fiat = $price * $quantity;
        my %fee;
        my $fiat_currency = 'USD';
	my $delta_fiat = $row->[4];
	$delta_fiat =~ s/\$//;
	$fee{$fiat_currency} = -($order_delta_fiat + $delta_fiat);

        $delta_fiat = $price * $quantity - $fee{$fiat_currency};
	$total{'BTC'} -= $quantity;
	$total{$fiat_currency} += $delta_fiat;
	$total_fees{$fiat_currency} += $fee{$fiat_currency};
        $total_by_pair{$fiat_currency} -= $quantity;
        $total_fees_in_fiat{$fiat_currency} += $fee{$fiat_currency};

        $output_row[0] = $id;
        $output_row[3] = 'BTC sold: '.$row->[3];
        $output_row[6] = $quantity;
        $output_row[7] = $price;
        $output_row[8] = $delta_fiat;
        $output_row[9] = $fiat_currency;
        $output_row[11] = $fee{$fiat_currency};

        unshift(@output_row,'exchb'); 
        push @rows, \@output_row;
      }

    }
  }
}

my @summary;

my $index = 0;
foreach( keys %total ) {
  $summary[$index]->[0] = "Net $_ Change";
  $summary[$index++]->[1] = $total{$_};

  if( $_ ne 'BTC' ) { 
    $summary[$index]->[0] = "Net BTC via $_";
    $summary[$index++]->[1] = $total_by_pair{$_};

    $summary[$index]->[0] = "Average $_ Price";
    $summary[$index++]->[1] = abs($total{$_}/$total_by_pair{$_});
  }

  $summary[$index]->[0] = "Total $_ Fees";
  $summary[$index++]->[1] = $total_fees{$_};

  if( $_ ne 'BTC' ) { 
    $summary[$index]->[0] = "BTC Fees in $_";
    $summary[$index++]->[1] = $total_fees_in_fiat{$_};
  }
  $summary[$index++]->[0]= '';
} 

unshift @rows, @summary;

$csv->eol ("\r\n");
open $fh, ">:encoding(utf8)", "report.csv" or die "report.csv: $!";
$csv->print ($fh, $_) for @rows;
close $fh or die "report.csv: $!";

if($summary) {
  foreach(@summary) {
    if($_->[0] ne '') { 
      print $_->[0].": ".$_->[1]."\n"; 
    } else {
      print "\n";
    }
  }
}
