#!/usr/bin/env bash

./btcreporter.pl -s 
mv report.csv test/report-all.csv

./btcreporter.pl -s --no-th --no-cbx --no-exchb
mv report.csv test/report-mtgox.csv

./btcreporter.pl -s --no-mtgox --no-cbx --no-exchb
mv report.csv test/report-th.csv

./btcreporter.pl -s --no-mtgox --no-th --no-exchb
mv report.csv test/report-cbx.csv

./btcreporter.pl -s --no-mtgox --no-th --no-cbx 
mv report.csv test/report-exchb.csv
