#!/usr/bin/perl

use DBI;
my $db = DBI->connect("dbi:SQLite:$ARGV[0]", "", "", {RaiseError => 1, AutoCommit => 1});

$db->do("CREATE TABLE IF NOT EXISTS results (sec INTEGER, threads INTEGER, tps REAL, reads REAL, writes REAL, rt REAL, runid TEXT)");

open FILE, $ARGV[1];
my $line;
while ($line=<FILE>){
        if ($line=~/\[\s+(.*?)s\s+\]\sthds:\s(.*?)\stps:\s(.*?)\sqps:\s(.*?)\s\(r\/w\/o:\s(.*?)\/(.*?)\/(.*?)\)\slat\s\(ms\,.*?\):\s(.*?)\s/){
        print $1,",",$2,",",$3,",",$5,",",$6,",",$8,"\n";
        $db->do("INSERT INTO results VALUES ($1, $2, $3,$5,$6,$8,'$ARGV[2]')");
}
}
